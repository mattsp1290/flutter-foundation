"""Read-only observations exposed only by the synthetic catalog build."""

OBSERVATION = """
const text=[...document.querySelectorAll('flt-semantics')].map(el =>
  el.getAttribute('aria-label') || el.textContent).find(text => text.startsWith('Editor observation '));
return text ? JSON.parse(text.slice(19)) : null;
"""


def observation(driver):
    return driver.js(OBSERVATION)
