-- Escapes HTML special characters (<, >, &) in the content of elements
-- matching a selector
--
-- Sample configuration that converts content of <pre> elements to its HTML source:
-- [plugins.escape_html]
--   file = "plugins/escape-html.lua"
--
-- [widgets.raw-html-in-pre]
--   widget = "escape_html"
--   selector = "pre"
--
-- Minimum soupault version: 1.6
-- Author: Daniil Baturin
-- License: MIT

selector = config["selector"]
if not selector then
  Plugin.fail("Missing required option \"selector\"")
end

function escape_html(element)
  content = HTML.inner_html(element)
  -- HTML.create_text escapes HTML special characters
  content = HTML.create_text(content)
  HTML.replace_content(element, content)
end

elements = HTML.select(page, selector)

if not elements then
  Plugin.exit("No elements found, nothing to do")
end

local index = 1
while elements[index] do
  escape_html(elements[index])
  index = index + 1
end
