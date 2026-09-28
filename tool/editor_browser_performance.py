"""Measure browser keydown to a painted frame after exact-source recovery."""

import math
import json

from editor_fixture_protocol import OBSERVATION, observation, viewport
from editor_webdriver import wait_for


# Temporary maintainer-approved budget for the software-rendered CI reference.
EDIT_P95_BUDGET_MS = 250
READY_BUDGET_MS = 3000


def sample_key(driver, generation):
    driver.js("""
      const expected=arguments[0];
      window.editorSample=null;
      let started=null;
      const key=(event)=>{ if(event.key==='x') started=performance.now(); };
      document.addEventListener('keydown',key,true);
      const observer=new MutationObserver(()=>{
        const value=(()=>{ """ + OBSERVATION + """ })();
        if(started!==null && value && value.generation===expected) {
          observer.disconnect();
          document.removeEventListener('keydown',key,true);
          // The mutation follows Flutter's frame. The next rAF observes a
          // completed paint of the source and the synchronous recovery label.
          requestAnimationFrame(()=>window.editorSample=performance.now()-started);
        }
      });
      observer.observe(document.querySelector('flt-semantics-host'),
        {subtree:true,childList:true,characterData:true,attributes:true});
    """, generation)
    driver.key('x')
    return wait_for(lambda: driver.js('return window.editorSample;'))


def run_performance(driver, server, base_path, focus_source):
    driver.request('POST', '/url', {'url': server.origin + base_path + '?editor-fixture=large'})
    wait_for(lambda: driver.js("return !!document.querySelector('flt-semantics-placeholder');"))
    started = driver.js('return performance.now();')
    driver.click(48, 208)
    driver.frames()
    driver.js("document.querySelector('flt-semantics-placeholder').click();")
    initial = wait_for(lambda: observation(driver))
    driver.frames()
    ready_ms = driver.js('return performance.now();') - started
    if initial['length'] != 65536:
        raise RuntimeError(f"Wrong performance fixture: {initial}")
    focus_source(driver)
    generation = initial['generation']
    samples = []
    # Warm both parsing and input paths using real key events; do not reload.
    for index in range(120):
        generation += 1
        elapsed = sample_key(driver, generation)
        value = observation(driver)
        if value['length'] != 65536 + index + 1:
            raise RuntimeError('A measured keystroke did not insert exactly one code unit')
        if index >= 20:
            samples.append(elapsed)
    driver.screenshot('warmed-edits.png')
    before_scroll = observation(driver)
    before_offset = viewport(driver)
    for _ in range(20):
        driver.request('POST', '/actions', {'actions': [{'type': 'wheel', 'id': 'scroll', 'actions': [
            {'type': 'scroll', 'origin': 'viewport', 'x': 600, 'y': 450,
             'deltaX': 0, 'deltaY': 100, 'duration': 16},
        ]}]})
        driver.frames()
    driver.screenshot('scroll-without-reload.png')
    after_offset = viewport(driver)
    if before_offset is None or after_offset is None or after_offset <= before_offset:
        raise RuntimeError(f'Wheel input did not advance source viewport: {before_offset} -> {after_offset}')
    if observation(driver) != before_scroll:
        raise RuntimeError('Scrolling unexpectedly changed the document')
    p95 = sorted(samples)[math.ceil(.95 * len(samples)) - 1]
    record = {'fixture_bytes': 65536, 'fixture_lines': 2000, 'warmup_edits': 20,
              'measured_edits': len(samples), 'samples_ms': samples, 'p95_ms': p95,
              'edit_p95_budget_ms': EDIT_P95_BUDGET_MS,
              'ready_budget_ms': READY_BUDGET_MS,
              'cold_editor_ready_ms_after_flutter_startup': ready_ms,
              'build_mode': 'release', 'scroll_without_document_replacement': 'pass',
              'scroll_offset_before': before_offset, 'scroll_offset_after': after_offset,
              'measurement': 'real browser keydown to rAF following recovery semantics and source frame'}
    # Persist failed measurements as evidence too; never silently loosen budgets.
    (driver.output / 'performance.json').write_text(json.dumps(record, indent=2) + '\n')
    if p95 > EDIT_P95_BUDGET_MS or ready_ms > READY_BUDGET_MS:
        raise RuntimeError(
            f'Editor performance budget exceeded: p95={p95:.1f}ms '
            f'(limit {EDIT_P95_BUDGET_MS}ms), ready={ready_ms:.1f}ms '
            f'(limit {READY_BUDGET_MS}ms)')
    return record
