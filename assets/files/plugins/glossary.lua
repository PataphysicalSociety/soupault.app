-- This plugin provides a hyperlinked glossary (within a single page only)
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
-- Then you can refer to them like this: <term>sepulka</term> anywhere in the page
-- These <term> elements will be automatically converted to hyperlinks,
-- and the glossary will be made into a <dl>
--

Plugin.require_version("3.0.0")

definitions = HTML.select(page, "glossary definition")

glossary = {}

function make_term_slug(t)
  slug = "glossary-" .. Regex.replace_all(t, "\\s+", "-")
  return slug
end

function add_term(t)
  local name = strlower(HTML.get_attribute(t, "name"))
  local def = HTML.inner_html(t)
  glossary[name] = String.trim(def)
end

-- First, collect glossary terms in a table
Table.iter_values(add_term, definitions)

-- Build the glossary HTML
dl = HTML.create_element("dl")

function add_glossary_term(term, def)
  dt = HTML.create_element("dt", term)
  -- Use term slugs for ids
  HTML.set_attribute(dt, "id", make_term_slug(term))
  dd = HTML.create_element("dd")
  HTML.append_child(dd, HTML.parse(def))
  HTML.append_child(dl, dt)
  HTML.append_child(dl, dd)
end

Table.iter(add_glossary_term, glossary)

-- Insert the glossary <dl> container
glossary_elem = HTML.select_one(page, "glossary")
HTML.insert_before(glossary_elem, dl)

-- Delete the original <glossary> elements
Table.iter_values(HTML.delete_element, HTML.select(page, "glossary"))

-- Make all terms into hyperlinks
function process_term_elem(term_elem)
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
end

terms = HTML.select(page, "term")
Table.iter_values(process_term_elem, terms)
