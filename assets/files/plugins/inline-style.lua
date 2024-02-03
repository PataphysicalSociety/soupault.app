-- Moves CSS from <inlineStyle> elements in the page body
-- to <style> elements in its <head>
--
-- While it's possible to _just_ use <style> elements in <body>,
-- keeping them in <head> is arguably cleaner and more idiomatic
-- and has less potential to cause strange behavior with browsers
-- and HTML tools
--
-- To run it, you need to add something like this to soupault.toml:
-- [plugins.inline-styles]
--   file = "plugins/inline-style.lua"
--
-- [widgets.inline-styles]
--   widget = "inline-styles"
--
-- Author: Daniil Baturin
-- License: MIT

styles = HTML.select(page, "inlineStyle")

function add_style(s)
  css = HTML.inner_html(s)
  e = HTML.create_element("style", css)
  head = HTML.select_one(page, "head")
  HTML.append_child(head, e)
end

Table.iter_values(add_style, styles)

Table.iter_values(HTML.delete, styles)
