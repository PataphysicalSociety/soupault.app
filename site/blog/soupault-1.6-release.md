<h1 id="post-title">Soupault 1.6 release</h1>

<p>Date: <time id="post-date">2019-11-30</time> </p>

<p id="post-excerpt">
Soupault 1.6 is now available for <a href="/#downloads">download</a>. The first big improvement is a built-in index generator
that supports mustache templates, so you can make blog feeds and lists of pages without any external scripts now.
The second improvement is a bunch of new plugin API functions that should make writing plugins easier
and add more capabilities.
</p>

## Built-in index generator with mustache templates

Older versions used to include a mostly useless built-in index generator that would just copy
elements unchanged, with all their original tags. That would produce a very odd-looking index.

My assumption was that everyone will use an external script anyway, but for many people,
especially on Windows or those without programming experience, an external script is a much bigger headache than
for a programmer on a UNIX-like system.

There’s no sensible default for the index. One person will want a simple list of pages, someone else will want
a blog feed, or something else entirely.

So I went for adding support for <a href="https://mustache.github.io/">mustache</a> templates. It’s a simple
and lightweight, logicless template language that should cover the basic needs without bloating the executable
too much (the library I used only adds about 200 kbytes to the executable).

This is what settings for a simple blog feed may look like now:

```toml
[index]
  index = true
  # Insert into a <div id="blog-index">
  index_selector = "div#blog-index"

  index_title_selector = "h1"
  index_date_selector = ["time#post-date", "time"]
  index_excerpt_selector = ["p#post-excerpt", "p"]

  newest_entries_first = true

  index_item_template = """
    <h2><a href="{{url}}">{{title}}</a></h2>
    <p><strong>Last update:</strong> {{date}}.</p>
    <p>{{{excerpt}}}</p>
    <a href="{{url}}">Read more</a>
  """
```

Of course, support for external index generators is not going anywhere. If you want something advanced,
you can get the index data in JSON and process it as you want.

## `strip_tags` option for ToC headings and index data

Soupault, generally, makes a point to preserve the original HTML whenever possible. However, sometimes
you may not want to preserve it.

Now the `toc` widget and the `[index]` section offer a `strip_tags` option. In the ToC widget, it removes
all HTML tags from the ToC headings. In the index generator, it removes tags from all index data,
including titles and excerpts.

Examples:

```toml
[widgets.insert-toc]
  widget = "toc"
  strip_tags = true
  ...

[index]
  index = true
  strip_tags = true
```

That’s an easy way to prevent tags inserted by other widgets, like footnotes, from polluting the blog feed etc.

Sometimes, however, the situation is more nuanced. You may want to keep HTML that originally was there,
but prevent widgets from inserting new tags before index data extraction is complete. Now it’s possible too.

## Metadata extraction scheduling

In pre-1.6 versions, the metadata used for site index used to be extracted after all widgets have run.
It could cause unfortunate interactions with some widgets. For example, the ToC widget adds section links
to all headings if the `heading_links` option is true. In a blog feed, those links make no sense.

A simple solution would be to just do metadata extraction before any widgets had a chance to modify the page.
However, that would make certain workflows impossible. For example, if you want to insert &ldquo;last modified&rdquo;
data into pages from VCS revision history using an `exec` widget, and then use it as a post date in your blog feed, you need to schedule
metadata extraction _after_ the widget that inserts it.

It’s clear that running them after all widgets is a bad idea, so since 1.6, by default it’s done before any widgets.

However, you also have some control over it. Using the `extract_after_widgets` option, you can specify a list of widgets that must run before
index data is extracted. Here’s an example for the page date in git situation:

```toml
[widgets.last-modified]
  widget = "exec"
  selector = "#git-timestamp"
  command = "git log -n 1 --pretty=format:%ad --date=format:%Y-%m-%d -- $PAGE_FILE"

[index]
  extract_after_widgets = ["last-modified"]
  date_selector = "#git-timestamp"
```

If you have `debug = true` in the settings section, it will display the lists of widgets that will run before and after that step.

Note that it has no effect on the widget processing order. It only means that when all widgets specified in `extract_after_widgets`
have run, soupault stops to extract the metadata and continues running widgets as usual.

This means you can still run into adverse interactions if you aren’t careful. When widgets don’t have any dependencies specified,
their processing order is arbitrary. To make sure a widget only runs after metadata is extracted, you should add all widgets
that from the `extract_after_widgets` option to its dependencies.

## New plugin APIs

First, it’s not possible to exit early. The `Plugin.exit` function exists normally, while `Plugin.fail` causes an error.

```toml
if not config["selector"] then
  Plugin.fail("Missing required option selector")
end

target_element = HTML.select(page, config
if not target_element then
  Plugin.exit("Could not find the target element, nothing to do")
end

Plugin.exit()
```

There’s also a `Regex.split` option for splitting strings. Example:

The `HTML` module has two additions: `HTML.create_text` and `HTML.strip_tags`. The `HTML.create_text` function
creates a text node that can be used with `HTML.append_child` and similar functions. This is handy if you want
to insert raw text into the page.

The `HTML.strip_tags` is similar to `HTML.inner_html`, but it returns a string representation of an element content
with all tags removed.

With `Sys.read_file` function, you can read a file into a string in one step, without having to keep track of any
file handles. There’s also `Sys.join_path` for easily concatenating file paths without having to deal with separators
by hand (it takes two strings, not a list).

There’s also `page_url` variable now that holds the relative URL like `/about` or `/about.html`, depending on whether
clean URLs are used or not.

Last but not least, you can now pass integer options to plugins through the config. You can also pass booleans,
but they are converted to strings `"true"` and `"false"`.

## Bug fixes and improvements

* Widget options `section` and `exclude_section` now behave as expected.
* The default page template now includes a charset meta tag, set to UTF-8.
* Debug messages for pages excluded by exclude_section/page/regex options now say which widget they are talking about.
* There’s now a debug message telling whether page template was used or not (in generator mode only).
