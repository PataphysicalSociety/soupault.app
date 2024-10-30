-- Adds a bunch of fake HTML elements for easily making links to popular websites
--
-- Supported elements:
--   <wikipedia lang="de" page="Philippe Soupault">surrealist writer</wikipedia>
--   <github project="dmbaturin/soupault">soupault</github>
--   <sourcehut vcs="git" project="~dmbaturin/soupault">soupault</sourcehut>
--   <mastodon user="@dmbaturin@mastodon.social">me on mastodon</mastodon>
--   <twitter user="dmbaturin">me on twitter</twitter>
--   <rfc number="1918">HTTP RFC</rfc>
--
-- All elements also support a short form where the content becomes the link data:
--   <wikipedia>Philippe Soupault</wikipedia>
--   <github>dmbaturin/soupault</github>
--   <gitlab>dmbaturin</gitlab>
--   <sourcehut>~dmbaturin/soupault</sourcehut>
--   <mastodon>@dmbaturin@mastodon.social</mastodon>
--   <twitter>@dmbaturin</twitter> -- "@" is optional
--   <rfc>RFC1945</rfc> -- yes, it can extract the number from this
--
-- To run it, you need to add something like this to soupault.conf:
-- [plugins.quick-links]
--   file = "plugins/quick-links.lua"
--
-- [widgets.convert-quick-links]
--   widget = "quick-links"
--   wikipedia_default_language = "fr"
--
-- Author: Daniil Baturin
-- License: MIT

Plugin.require_version("1.10")

wikipedia_default_lang = config["wikipedia_default_language"]
if not wikipedia_default_lang then
  wikipedia_default_lang = "en"
end

-- Helper functions

-- Gets data from specified attribute
-- If that attribute is missing or empty, gets element content instead
function get_link_data(element, attr_name)
  link_data = HTML.get_attribute(element, attr_name)
  if not link_data then
    link_data = HTML.strip_tags(element)
  end

  return link_data
end

-- Creates an <a> element with given href,
-- and content cloned from the original element
function make_link(orig_elem, href)
  link = HTML.create_element("a")
  HTML.set_attribute(link, "href", href)
  content = HTML.clone_content(orig_elem)
  HTML.append_child(link, content)

  return link
end

-- Sets rel="me" if original element has a "me" attribute
function set_rel_me(orig_elem, target_elem)
  rel = HTML.get_attribute(orig_elem, "me")
  if rel ~= nil then
    HTML.set_attribute(target_elem, "rel", "me")
  end
end

-- Generic link generator for URLs with only one parameter like Github or Twitter
function make_simple_link(element, attr_name, url_format)
  link_data = get_link_data(element, attr_name)

  if not link_data then
    Log.warning(format("Found a <%s> element with no project attribute or content", HTML.get_tag_name(element)))
    return nil
  end

    href = format(url_format, link_data)
    real_link = make_link(element, href)
    set_rel_me(element, real_link)

    return real_link
end


-- Site-specific functions

function make_wikipedia_link(element)
  wp_page = get_link_data(element, "page")

  if not wp_page then
    Log.warning("Found a <wikipedia> element with no page attribute or content")
  else
    lang = HTML.get_attribute(element, "lang")
    if not lang then
      lang = wikipedia_default_lang
    end

    wp_page = String.trim(wp_page)
    wp_page = Regex.replace_all(wp_page, "\\s+", "_")

    href = format("https://%s.wikipedia.org/wiki/%s", lang, wp_page)
    real_link = make_link(element, href)

    return real_link
  end
end

function make_rfc_link(element)
  number = HTML.get_attribute(element, "number")
  if not number then
    content_data = HTML.strip_tags(element)
    int_matches = Regex.find_all(content_data, "([0-9]+)")
    number = int_matches[1]
    if not number then
      Log.warning("Found an <rfc> element without a number attribute and nothing that looks like a number in its content")
      return nil
    end
  end
      
  href = format("https://tools.ietf.org/html/rfc%s", number)
  real_link = make_link(element, href)

  return real_link
end

function make_mastodon_link(element)
  user = get_link_data(element, "user")

  if not Regex.match(user, "@(.*)@(.*)") then
    Log.warning("Found a <mastodon> element without a valid mastodon id in content or user attribute. Example of a valid id: @user@example.com")
    return nil
  end

  -- Regex.split ignores the leading separator
  -- So the following will split "@user@mastodon.example.com" into ["user", "mastodon.example.com"]
  data = Regex.split(user, "@")
  href = format("https://%s/@%s", data[2], data[1])

  real_link = make_link(element, href)
  set_rel_me(element, real_link)
  return real_link
end

function make_twitter_link(element)
  user = get_link_data(element, "user")

  if not user then
    Log.warning("Found a <twitter> element with empty content and no user attribute")
    return nil
  end

  -- Remove the leading @ if necessary
  user = Regex.replace(user, "^@", "")

  href = format("https://twitter.com/%s", user)
  real_link = make_link(element, href)
  set_rel_me(element, real_link)

  return real_link
end

elements = HTML.select_all_of(page, {
  "wikipedia", "github", "gitlab", "sourcehut", "codeberg", "mastodon", "twitter", "linkedin", "rfc"
})

local index = 1
while elements[index] do
  elem = elements[index]

  tag_name = HTML.get_tag_name(elem)
  if (tag_name == "wikipedia") then
    new_elem = make_wikipedia_link(elem)
  elseif (tag_name == "github") then
    new_elem = make_simple_link(elem, "project", "https://github.com/%s")
  elseif (tag_name == "gitlab") then
    new_elem = make_simple_link(elem, "project", "https://gitlab.com/%s")
  elseif (tag_name == "sourcehut") then
    -- SourceHut supports multiple version control systems as well as
    -- having a project page without a subdomain.
    local vcs = HTML.get_attribute(elem, "vcs")
    if vcs then
       new_elem = make_simple_link(elem, "project", "https://" .. vcs .. ".sr.ht/%s")
    else
       new_elem = make_simple_link(elem, "project", "https://sr.ht/%s")
    end
  elseif (tag_name == "codeberg") then
    new_elem = make_simple_link(elem, "project", "https://codeberg.org/%s")
  elseif (tag_name == "mastodon") then
    new_elem = make_mastodon_link(elem)
  elseif (tag_name == "twitter") then
    new_elem = make_twitter_link(elem)
  elseif (tag_name == "linkedin") then
    new_elem = make_simple_link(elem, "user", "https://www.linkedin.com/in/%s")
  elseif (tag_name == "rfc") then
    new_elem = make_rfc_link(elem)
  end

  if new_elem then
    HTML.replace(elem, new_elem)
  else
    HTML.delete(elem)
  end

  index = index + 1
end
