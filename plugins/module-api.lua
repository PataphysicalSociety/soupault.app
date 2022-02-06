-- Half-baked plugin for making Lua module API reference nicer

module_toc_tmpl = [[
<h5 id="{{module}}-function-list">List of module functions</h5>
<ul>
  {% for f in fns %}
  <li><a href="#{{f.id}}">{{f.name}}</a></li>
  {% endfor %}
</ul>
]]


modules = HTML.select(page, "module")

local n = 1
local count = size(modules)
while (n <= count) do
  local module = modules[n]

  HTML.set_tag_name(module, "div")

  module_name = HTML.get_attribute(module, "name")
  module_heading = HTML.create_element("h4")
  HTML.replace_content(module_heading, HTML.create_text(module_name))
  HTML.set_attribute(module_heading, "id", module_name)
  HTML.prepend_child(module, module_heading)
  HTML.add_class(module_heading, "api-module")

  -- Process function elements
  local k = 1
  local module_funcs = {}
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

    HTML.add_class(fn, "api-function")

    module_funcs[k] = {}
    module_funcs[k]["id"] = fn_name
    module_funcs[k]["name"] = HTML.inner_html(fn)

    k = k + 1
  end
  local env = {}
  env["fns"] = module_funcs
  env["module"] = module_name
  local module_toc = HTML.parse(String.render_template(module_toc_tmpl, env))
  local module_heading = HTML.select_one(module, "h4")
  HTML.insert_after(module_heading, module_toc)

  n = n + 1
end
