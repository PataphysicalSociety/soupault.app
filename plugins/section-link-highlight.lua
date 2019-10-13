-- Highlights the link to the current page/section in the navigation menu
-- Quite hacky, if you ask me: it compares the href with the page path relative to site/
-- I.e. if you have <a href="/about">, it will add a class to it in page site/about.html
-- It assumes you are using relative links
--
-- Sample configuration:
-- [plugins.active-link-hightlight]
--   active_link_class = "active"
--   selector = "nav"
--
-- Minimal soupault version: 1.3
-- Author: Daniil Baturin
-- License: MIT


active_link_class = config["active_link_class"]
nav_menu_selector = config["selector"]

if (not active_link_class) then
  Log.warning("Missing required option \"active_link_class\", using default (\"active\")")
  active_link_class = "active"
end

if (not nav_menu_selector) then
  Log.warning("Missing required option \"selector\", using default (\"nav\")")
  nav_menu_selector = "nav"
end

menu = HTML.select_one(page, nav_menu_selector)
links = HTML.select(menu, "a")

-- For those who want to try it on Windows
page_file = Regex.replace_all(page_file, "\\\\", "/")

index, link = next(links)
while index do
  href = strlower(HTML.get_attribute(link, "href"))
  -- Don't highlight the main page
  -- That would also highlight all paths since they all have / in them
  if href ~= "/" then
    if Regex.match(page_file, href) then
      HTML.add_class(link, active_link_class)
    end
  end
  index, link = next(links, index)
end
