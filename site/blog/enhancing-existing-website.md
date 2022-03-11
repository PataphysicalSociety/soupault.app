<h1 id="post-title">Enhancing an existing site with a custom plugin</h1>

<span>Date: <time id="post-date">2019-11-28</time> </span>

Among static site generators that are compiled to native executables, soupault is unique
in that it can be extended using a real scripting language rather than a template processor that
evolved Turing completeness.

One of my main goals was to make a tool that can work with existing site structures, rather than make
the user redo everything to fit a tool.

<p id="post-excerpt">
Today we’ll see how to enhance an otherwise unmodified website with a custom plugin.
I picked <a href="https://districts.neocities.org">Neocities Districts</a> website
for a showcase. I’m not affiliated with Districts, I just like their website,
but I also think it’s a bit hard to navigate and could really benefit from alphabetic indices. Let’s see how it could be
done with soupault. Its authors are free to reuse the solution if they like it, of course.
The result will be fully static and will not need any JS, so it will work even in text browsers and with JS disabled.
</p>

## The idea

The basic idea is to create a list of clickable links that take you to a specific section.

If you look into the source of <a href="https://districts.neocities.org/arcadia/">districts.neocities.org/arcadia</a> for example,
you’ll notice that every section heading is an `<h2>` element, like `<h2>A</h2>`. This means we can easily reuse the heading content
for the anchor. The heading for sites that start with a number is `#`, which may be problematic, but in practice `id="##"` works well
in browsers, oddly.

Every page also has an `<h1>` element with the district name. A good place for the index would be before or after that heading,
I went for the latter option.

So, here’s the idea. First, insert a container for the index at the top of the page, before the first `<h1>` heading.
For example, `<div id="index">`. Then, for every heading, create a link inside that element, so that `<h2>A</h2>` becomes
`<a href="#A">A</a>`. And finally, add an `id` attribute to every heading so that those links actually work.

This is	what the result	will look like:

<img src="/images/neocities_districts_index.png">   

## Writing the plugin

The plugin language is Lua 2.5, and the API is somewhat reminiscent of the JavaScript DOM API.
To select one element you can use the `HTML.select_one` function, and to select all elements that
match a certain selector you can use `HTML.select`.

One annoying part is that Lua 2.5 standard lacked a modern `for` loop for iterating over a list in numeric order.
Well, the annoying thing about Lua in general is that arrays are really dicts indexed by integers, so any kind
of traversal in numeric order is a hack. We’ll use a simple loop with a counter, from 1 to `size(headings)`.

The selector of the target element where links are inserted will be configurable. Plugins have access to their own
config via `config` variable, with one caveat: you can only pass string options that way.

So, this is the plugin source:

```lua
-- Get the selector option from the config
selector = config["selector"]

-- Find the index container
index_container = HTML.select_one(page, selector)

-- Extract all second level headings from the <main> element
headings = HTML.select(page, "main h2")

max = size(headings)
n = 1

while n <= max do
  heading_content = HTML.inner_html(headings[n])

  -- Set an id for each heading to use it as an anchor
  HTML.set_attribute(headings[n], "id", heading_content)

  -- Create a link to the heading
  link = HTML.create_element("a", heading_content)
  HTML.set_attribute(link, "href", "#" .. heading_content)

  -- Insert the link to the index container
  HTML.append_child(index_container, link)

  n = n + 1
end
```

## Setting it up

I’ve created a directory for the project, `districts`, then a subdirectory for the pages, `districts/site`.
Then I’ve mirrored districts.neocities.org into `districts/site` with wget (it’s small, so that hasn’t created excessive load on the Neocities servers).

Then I’ve created a `districts/plugins` directory for plugins. It’s not really necessary, but for a real site rather than a one time showcase,
it’s better to keep them in a separate directory.

Since the goal is to modify an existing site automatically, rather than create a site from a template and page bodies, I switched soupault to
the HTML processor mode with `generator_mode = false`.

This is the complete config (`districts/soupault.conf`):

```toml
[settings]
  strict = true

  verbose = true

  site_dir = "site"
  build_dir = "build"

  page_file_extensions = ["htm", "html"]

  generator_mode = false
  clean_urls = false

  doctype = "<!DOCTYPE html>"

# Load the plugin
[plugins.alphabetic-index]
  file = "plugins/alphabetic-index.lua"

# Insert the container for the index
[widgets.insert-index-container]
  # Special pages don’t need it
  exclude_page = ["index.html", "updates/index.html", "about/index.html", "buttons/index.html"]
  widget = "insert_html"
  selector = "h1"
  action = "insert_before"
  html = '<div id="index" style="display: flex; justify-content: space-evenly;"> </div>'

# Now call the plugin
[widgets.insert-index]
  after = "insert-index-container"
  exclude_page = ["index.html", "updates/index.html", "about/index.html", "buttons/index.html"]
  widget = "alphabetic-index"

  # Available to the plugin as config["selector"]
  selector = "div#index"

```

Plugins, once loaded, can be configured just like built-in widgets. Here we are using an `exclude_page` option
to prevent it from running on pages that don’t need an index, and an `after` option to make sure the plugin
only runs after the index container is inserted by the `insert-index-container` widget.

Now the only thing left is to run `soupault` in the `districts` directory, and check out the result in `build`,
for example with `python3 -m http.server --directory build/`.

If you look inside `build/arcadia/index.html` or inspect the page with debugger, you’ll see the new elements inside:

<img src="/images/neocities_districts_index_html.png">

And that’s all really. As you can see, there’s no need to subscribe to someone else’s workflow to use soupault.

