-- Adds a fake HTML element <include>path/to/file</include>
-- that is replaced with the content of the file,
-- much like {% include "path/to/file" %} in template processors.
-- You can use <include raw="true">path/to/file</include>
-- to include the file as raw text with HTML special characters escaped.
--
-- To run it, you need to add something like this to soupault.conf:
-- [plugins.include-tag]
--   file = "plugins/include.lua"
--
-- [widgets.process-include-tags]
--   widget = "include-tag"
--
-- Author: Daniil Baturin
-- License: MIT

Plugin.require_version("1.8")

elements = HTML.select(page, "include")

count = size(elements)
index = 1

function include_file(file_path, elem, raw)
  data = Sys.read_file(file_path)
  if not data then
    Log.warning("No data, nothing to include")
  else
    if raw then
      html = HTML.create_text(data)
    else
      html = HTML.parse(data)
    end
    HTML.replace(elem, html)
  end
end

while (index <= count) do
  elem = elements[index]
  file_path = String.trim(HTML.inner_html(elem))
  raw = HTML.get_attribute(elem, "raw")
  if not file_path then
    Log.warning("Ignoring empty <include> element")
  else
    Log.info("Inserting file " .. file_path)
    include_file(file_path, elem, raw)
  end

  index = index + 1
end
