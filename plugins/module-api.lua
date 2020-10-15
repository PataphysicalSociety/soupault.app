-- Half-baked plugin for making Lua module API reference nicer

modules = HTML.select(page, "module")

local n = 1
local count = size(modules)
while (n <= count) do
  module = modules[n]

  HTML.set_tag_name(module, "div")

  module_name = HTML.get_attribute(module, "name")
  module_heading = HTML.create_element("h4")
  HTML.replace_content(module_heading, HTML.create_text(module_name))
  HTML.set_attribute(module_heading, "id", module_name)
  HTML.prepend_child(module, module_heading)

  -- Process function elements
  local k = 1
  fns = HTML.select(module, "function")
  local fn_count = size(fns)
  while (k <= fn_count) do
    fn = fns[k]
    HTML.set_tag_name(fn, "span")

    -- Set the heading id for linking
    heading = HTML.parent(fn)
    fn_name = Regex.replace(HTML.strip_tags(fn), "\\(.*\\)", "")
    Log.warning(fn_name)
    HTML.set_attribute(heading, "id", fn_name)

    k = k + 1
  end

  n = n + 1
end
