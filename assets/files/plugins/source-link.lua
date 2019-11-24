-- Creates a "source link" from a given repo base and injects the link into the page.
--
-- Minimal soupault version: 1.3
-- Author: Hristos N. Triantafillou
-- License: MIT

link_text = config["link_text"]
selector = config["selector"]
repo_base = config["repo_base"]

if (not link_text) then
  Log.warning("Missing option \"link_text\", using default (\"This page's source code\")")
  link_text = "This page's source code"
end

if (not selector) then
  Log.warning("Missing required option \"selector\", using default (\"div#source-link\")")
  selector = "div#source-link"
end

if (not repo_base) then
  Log.warning("Missing required option \"repo_base\"")
  -- Nothing to do
else
  -- Remove trailing slashes
  repo_base = Regex.replace(repo_base, "\\/?$", "")

  source_link_container = HTML.select_one(page, selector)

  if (source_link_container) then
    url = repo_base .. "/" .. page_file
    source_link = HTML.create_element("a", link_text)
    HTML.set_attribute(source_link, "href", url)

    HTML.append_child(source_link_container, source_link)
  end
end

