Plugin.require_version("2.3.0")

base_url = "https://files.baturin.org/software/soupault"

version = soupault_config["custom_options"]["latest_soupault_version"]

if not version then
  Plugin.fail("custom_options.latest_soupault_version is undefined, cannot generate release links")
end

function make_release_link(elem)
  platform = HTML.get_attribute(elem, "platform")

  if not platform then
    Log.warning("Found a <soupault-release> element without platform attribute")
    return nil
  end

  local extension = "tar.gz"
  if (platform == "win32") or (platform == "win64") then
    extension = "zip"
  end

  local url = format("%s/%s", base_url, version)

  dl_file = format("soupault-%s-%s.%s", version, platform, extension)
  dl_url = format("%s/%s", url, dl_file)
  
  sig_file = format("%s.minisig", dl_file)
  sig_url = format("%s/%s", url, sig_file)

  dl_links = HTML.parse(format("<a href=\"%s\">%s</a> (<a href=\"%s\">sig</a>)", dl_url, dl_file, sig_url))

  HTML.replace(elem, dl_links)
end

elements = HTML.select(page, "soupault-release")
Table.iter_values(make_release_link, elements)
