-- Inserts a generator meta tag (if it doesn't exist in the page already)
--
-- [widgets.insert-generator-meta]
--   widget = "generator-meta"
--
-- Minimum soupault version: 2.0
-- Author: Daniil Baturin
-- License: MIT

if HTML.select_one(page, "head meta[name=\"generator\"]") then
  Log.debug("Page already has a generator meta tag, ignoring")
else
  Log.debug("Inserting the generator meta tag")

  -- Create the <meta name="generator" content="soupault $current_version"> element
  --
  -- We use HTML.parse rather than HTML.create_element and HTML.set_attribute
  -- because HTML.set_attribute doesn't guarantee attribute order,
  -- and we want the name attribute to come before the content attribute,
  -- the way a human would write it.
  generator_meta = HTML.parse(format([[<meta name="generator" content="soupault %s">]], Plugin.soupault_version()))

  -- Try to group the new tag with existing <meta> tags
  first_existing_meta = HTML.select_one(page, "head meta")
  if first_existing_meta then
    HTML.insert_before(first_existing_meta, generator_meta)
  else
    head = HTML.select_one(page, "head")
    if head then
      HTML.append_child(head, meta)
    else
      Log.warning("Page has no <head> element, nowhere to insert a generator meta tag")
    end
  end
end
