-- Inserts an HTML snippet iff the page has a certain element
--
-- To run it, you need to add something like this to soupault.conf:
-- [plugins.conditional-insert]
--   file = "plugins/conditional-insert.lua"
--
-- [widgets.blink-warning]
--   widget = "conditional-insert"
--   html = "<div><strong>Warning: blink elements are obsolete!</strong></div>"
--   selector = "body"
--   check_selector = "blink"
--
-- Minimum soupault version: 1.3
-- Author: Daniil Baturin
-- License: MIT


-- Configuration
snippet = config["html"]
selector = config["selector"]
check_selector = config["check_selector"]

-- Plugin code

if not snippet then
  Log.warning("Missing html option, using an empty string")
  snippet = ""
end

if (not selector) or (not check_selector) then
  Log.warning("selector and check_selector options must be configured")
else
  elem = HTML.select_one(page, check_selector)
  if elem then
    target = HTML.select_one(page, selector)
    if not target then
      Log.info("Page has no element matching selector " .. selector)
    else
      snippet_html = HTML.parse(snippet)
      HTML.append_child(target, snippet_html)
    end
  end
end

