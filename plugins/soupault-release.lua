Plugin.require_version("1.8")

base_url = "https://files.baturin.org/software/soupault"

elements = HTML.select(page, "soupault-release")

count = size(elements)
index = 1

function make_release_link(elem)
  version = String.trim(HTML.strip_tags(elem))
  platform = HTML.get_attribute(elem, "platform")

  if not platform then
    Log.warning("Found a <soupault-release> element without platform attribute")
    return nil
  end

  if not version then
    Log.warning("Found a <soupault-release> element without version data")
    return nil
  end

  extension = "tar.gz"
  if platform == "win32" then
    extension = "zip"
  end

  local url = format("%s/%s", base_url, version)

  dl_file = format("soupault-%s-%s.%s", version, platform, extension)
  dl_url = format("%s/%s", url, dl_file)
  
  sig_file = format("%s.minisig", dl_file)
  sig_url = format("%s/%s", url, sig_file)

  dl_links = HTML.parse(format("<a href=\"%s\">%s</a> (<a href=\"%s\">sig</a>)", dl_url, dl_file, sig_url))

  HTML.insert_after(elem, dl_links)
end

local index = 1
while elements[index] do
  elem = elements[index]

  make_release_link(elem)
  HTML.delete_element(elem)

  index = index + 1
end

