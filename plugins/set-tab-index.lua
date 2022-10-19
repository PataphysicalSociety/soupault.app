selectors = config["selectors"]
tab_index = config["tab_index"]

if not Value.is_list(selectors) then
  Plugin.fail("selectors option must be a list")
end

if not Value.is_int(tab_index) then
  Plugin.fail("tab_index option must be an integer")
end

-- Set the tabindex attribute for a single element
function set_elem_tab_index(elem, index)
  current_index = HTML.get_attribute(elem, "tabindex")

  -- Only set tabindex for elements where it's not set already
  if current_index == nil then
    HTML.set_attribute(elem, "tabindex", tab_index)
  end
end

-- Sets the tabindex attribute for all elements that match a selector
function set_tab_index(selector)
  elems = HTML.select(page, selector)
  Table.iter_values(set_elem_tab_index, elems)
end

Table.iter_values(set_tab_index, selectors)
