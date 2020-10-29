-- This plugin provides a hyperlinked glossary.
--
------ Usage ------
--  First, define glossary terms like this:
--
--  <glossary>
--    <definition name="sepulka">
--      A prominent element of the civilization of Ardrites from the planet of Enteropia; see "sepuling".
--    </definition>
--    <definition name="sepuling">
--      An activity of Ardrites from the planet of Enteropia; see "sepulka".
--    </definition>
--  </glossary>
--
-- Then you can refer to them like this: <term>sepulka</term>
-- These <term> elements will be automatically converted to hyperlinks,
-- and the glossary will be made into a <dl>
--

Plugin.require_version("2.0.0")

definitions = HTML.select(page, "glossary definition")

glossary = {}

function make_term_slug(t)
  slug = "glossary-" .. Regex.replace_all(t, "\\s+", "-")
  return slug
end

-- First, collect glossary terms in a table
local count = size(definitions)
local n = 1
while (n <= count) do
  def = definitions[n]
  name = strlower(HTML.get_attribute(def, "name"))
  text = HTML.inner_html(def)
  glossary[name] = String.trim(text)

  n = n + 1
end

-- Build the glossary HTML
dl = HTML.create_element("dl")

name = next(glossary)
while name do
  Log.warning(name)
  dt = HTML.create_element("dt", name)
  -- Use term slugs for ids
  HTML.set_attribute(dt, "id", make_term_slug(name))
  dd = HTML.create_element("dd")
  HTML.append_child(dd, HTML.parse(glossary[name]))
  HTML.append_child(dl, dt)
  HTML.append_child(dl, dd)

  name = next(glossary, name)
end

-- Insert the 
glossary_elem = HTML.select_one(page, "glossary")
HTML.insert_before(glossary_elem, dl)

-- Delete the original <glossary> elements
Caml.List.iter(HTML.delete_element, HTML.select(page, "glossary"))

-- Make all terms into hyperlinks
terms = HTML.select(page, "term")
local count = size(terms)
local n = 1
while (n <= count) do
  term_elem = terms[n]

  term_name = HTML.get_attribute(term_elem, "name")
  term_text = strlower(String.trim(HTML.inner_text(term_elem)))

  if not term_name then
    term_name = term_text
  else
    term_name = strlower(String.trim(term_name))
  end

  if glossary[term_name] then
    term_link = HTML.create_element("a")
    HTML.set_attribute(term_link, "href", "#" .. make_term_slug(term_name))
    HTML.append_child(term_link, HTML.clone_content(term_elem))
    HTML.replace_element(term_elem, term_link)
  else
    -- No such term, unwrap the element from <term>
    Log.warning(format("Ignoring undefined term \"%s\"", term_name))
    HTML.replace_element(term_elem, HTML.clone_content(term_elem))
  end

  n = n + 1
end
