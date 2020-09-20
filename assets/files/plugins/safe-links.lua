-- Adds attributes to external links
-- The main purpose is to add nofollow, noopener and other security attributes
--
-- Example configuration:
-- [widgets.safe-external-links]
--   widget = "link-rel"
--   attributes = ["noopener", "noreferrer", "nofollow"]
--
-- Author: Daniil Baturin
-- License: MIT

Plugin.require_version("1.13")

attributes = config["attributes"]
if not attributes then
  attributes = {"nofollow", "noopener"}
end

rel = String.join(" ", attributes)

links = HTML.select(page, "a")
local count = size(links)
local i = 1
while (i <= count) do
  -- Check if a URL schema is present,
  -- relative links should be left alone
  href = HTML.get_attribute(links[i], "href")
  if href and Regex.match(href, "^([a-zA-Z0-9]+):") then
    HTML.set_attribute(links[i], "rel", rel)
  end
  i = i + 1
end
