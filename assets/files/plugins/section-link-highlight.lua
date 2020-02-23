-- Highlights the link to the current page/section in the navigation menu
-- If you have <a href="/about">, it will add a CSS class to it on page site/about.html
-- It assumes you are using relative links
--
-- Sample configuration:
-- [plugins.active-link-hightlight]
--   active_link_class = "active"
--   nav_menu_selector = "nav"
--
-- Minimum soupault version: 1.6
-- Author: Daniil Baturin
-- License: MIT

active_link_class = config["active_link_class"]
nav_menu_selector = config["selector"]

if (not active_link_class) then
  Log.warning("active_link_class option is not set, using default (\"active\")")
  Plugin.fail()
  active_link_class = "active"
end

if (not nav_menu_selector) then
  Log.warning("nav_menu_selector option is not set, using default (\"nav\")")
  nav_menu_selector = "nav"
end

menu = HTML.select_one(page, nav_menu_selector)
if (not menu) then
  Plugin.exit("No element matched selector " .. nav_menu_selector .. ", nothing to do")
end


links = HTML.select(menu, "a")

local index = 1
while links[index] do
  link = links[index]

  href = HTML.get_attribute(link, "href")

  if not href then
    -- Link has no href attribute, ignore
  else
    href = strlower(href)

    -- Remove leading and trailing slashes
    href = Regex.replace_all(href, "(\\/?$|^\\/)", "")
    page_url = Regex.replace_all(page_url, "(\\/?$|^\\/)", "")

    -- Normalize slashes
    href = Regex.replace_all(href, "\\/+", "\\/")

    -- Edge case: the / link that becomes "" after normalization
    -- Anything would match the empty string and higlight all links,
    -- so we handle this case explicitly
    if ((page_url == "") and (href == ""))
      or ((href ~= "") and Regex.match(page_url, "^" .. href))
    then
      HTML.add_class(link, active_link_class)
    end
  end

  index = index + 1
end
