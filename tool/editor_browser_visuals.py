"""Capture real light/dark, preset and responsive editor states for inspection."""

import time

from editor_fixture_protocol import observation
from editor_webdriver import wait_for

PRESETS = ('Foundation', 'Dracula', 'GitHub Light', 'GitHub Dark')


def run_visuals(driver, server, base_path, focus_source):
    driver.request('POST', '/window/rect', {'width': 1280, 'height': 1400})
    driver.request('POST', '/url', {'url': server.origin + base_path})
    wait_for(lambda: driver.js("return !!document.querySelector('flt-semantics-placeholder');"))
    driver.click(48, 208)
    driver.frames()
    driver.js("document.querySelector('flt-semantics-placeholder').click();")
    original = wait_for(lambda: observation(driver))
    focus_source(driver)
    driver.key('x')
    driver.frames()
    edited = observation(driver)
    if edited['length'] != original['length'] + 1:
        raise RuntimeError('Visual fixture did not receive its real edit')
    driver.button('Enable wrap')
    driver.button('Editor commands')
    driver.button('Larger code')
    wait_for(lambda: observation(driver))
    current_preset = 'Foundation'
    current_narrow = current_large = False
    captures = []
    for brightness in ('light', 'dark'):
        driver.request('POST', '/goog/cdp/execute', {'cmd': 'Emulation.setEmulatedMedia',
            'params': {'features': [{'name': 'prefers-color-scheme', 'value': brightness}]}})
        driver.frames()
        for preset in PRESETS:
            if preset != current_preset:
                driver.button('Editor theme\nEditor theme: ' + current_preset)
                driver.button(preset)
                current_preset = preset
            for narrow, large in ((False, False), (True, False), (False, True), (True, True)):
                if narrow != current_narrow:
                    driver.button('320 px preview')
                    current_narrow = narrow
                if large != current_large:
                    driver.button('200% text')
                    current_large = large
                if wait_for(lambda: observation(driver)) != edited:
                    raise RuntimeError('Theme, font, wrap or responsive changes reset document state')
                # Move off controls, then allow theme and tooltip animations to
                # finish before judging colors from the rendered pixels.
                driver.request('POST', '/actions', {'actions': [{
                    'type': 'pointer', 'id': 'mouse',
                    'parameters': {'pointerType': 'mouse'},
                    'actions': [{'type': 'pointerMove', 'duration': 0,
                                 'x': 100, 'y': 20, 'origin': 'viewport'}],
                }]})
                time.sleep(.35)
                driver.frames()
                name = f"{brightness}-{preset.lower().replace(' ', '-')}-{'320' if narrow else 'wide'}-{'200' if large else '100'}.png"
                clip = {'x': 512, 'y': 100, 'width': 352, 'height': 1050, 'scale': 1} if narrow else None
                driver.screenshot(name, clip=clip)
                captures.append(name)
    driver.button('Undo')
    driver.frames()
    if observation(driver)['units'] != original['units']:
        raise RuntimeError('History did not survive the visual matrix')
    errors = [entry for entry in driver.request('POST', '/log', {'type': 'browser'})
              if entry['level'] == 'SEVERE']
    if errors:
        raise RuntimeError(f'Visual matrix browser errors: {errors}')
    return {'captures': captures, 'wrap': True, 'font_scale': 1.125,
            'same_controller_history_after_matrix': 'pass',
            'scope': 'Screenshots require visual inspection; this does not establish screen-reader behavior'}
