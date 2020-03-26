-- Replaces relative URLs with absolute
-- e.g. "/about" -> "https://www.example.com/about"
--
-- To run it, you need to add something like this to soupault.conf:
-- [plugins.site-url]
--   file = "plugins/site-url.lua"
--
-- [widgets.set-site-url]
--   widget = "site-url"
--   site_url = "https://www.example.com"
--
-- Minimum soupault version: 1.3
-- Author: Daniil Baturin
-- License: MIT

-- Configuration
site_url = config["site_url"]


-- Plugin code
if not site_url then
  Log.warning("site_url is not configured, using default")
  site_url = ""
end

if not Regex.match(site_url, "(.*)/$") then
  site_url = site_url .. "/"
end

function make_absolute(elem_name, attr)
  elems = HTML.select(page, elem_name)

  local index = 1
  while elems[index] do
    elem = elems[index]
    target = HTML.get_attribute(elem, attr)
    if target then
      -- Check if URL schema is present
      if not Regex.match(target, "^([a-zA-Z0-9]+):") then
        -- If not, check if it starts with a /
        -- Truly relative URLs like "about.html" or "../" should be left alone.
        if Regex.match(target, "^/(.*)") then
          -- Remove leading slashes
          target = Regex.replace(target, "^/*", "")
          target = site_url .. target
          HTML.set_attribute(elem, attr, target)
        end
      end
    end
    index = index + 1
  end
end

make_absolute("a", "href")
make_absolute("link", "href")
make_absolute("img", "src")
make_absolute("script", "src")
make_absolute("audio", "src")
make_absolute("video", "src")
make_absolute("embed", "src")
make_absolute("object", "data")
