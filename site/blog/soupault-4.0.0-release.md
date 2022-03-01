<h1 id="post-title">Soupault 4.0.0 release: as extensible as Jekyll, still statically linked</h1>

<p>Date: <time id="post-date">2022-11-23</time> </p>

<div id="generated-toc"> </div>

## Introduction

<p id="post-excerpt">
Soupault 4.0.0, is available for download from <a href="https://files.baturin.org/software/soupault/4.0.0">my own server</a>
and from <a href="https://github.com/PataphysicalSociety/soupault/releases/tag/4.0.0">GitHub releases</a>.
It features support for page processing hooks, a way to write index rendering code in Lua and create pagination/taxonomies from it,
a new option to make the site index available to content pages, an option to process certain pages before all other,
a way to mark certain index fields as required, and a bunch of new Lua plugin API functions. Well, and a few bug fixes, of course.
</p>

In short, this release takes extensibility to a new level, comparable with static site generators
written in interpreted languages.

If you allow me a digression, I find it odd that the static site generator "scene" tends to treat extensibility
and native code implementation as mutually exclusive properties.

On one end of the spectrum we have projects like [Jekyll](https://jekyllrb.com/) or [Nikola](https://www.getnikola.com/)
that are infinitely extensible and allow plugins to redefine almost any built-in behavior, but need an interpreter and
have a lot of runtime dependencies.
If some functionality is not there, you find or write a plugin that adds it, from scratch or using a library from gems/pypi/etc.

On the other end there are projects like [Hugo](https://gohugo.io) or [Zola](https://getzola.org) that are available
as native, statically linked executables, but don't offer any extensibility other than a Turing-complete template language.
If something is not there, all you can do is to hope for its inclusion in the mainline, maintain a fork, or look elsewhere.

Soupault was already the most extensible static site generator
[available as a native, statically linked executable](https://tvtropes.org/pmwiki/pmwiki.php/Main/OverlyNarrowSuperlative).
By working on the HTML element tree level, it made all functionality work the same for any source format,
and it allows automatically loading any format with [user-defined page preprocessors](/reference-manual/#page-preprocessors).
By embedding a [Lua interpeter](/reference-manual/#plugin-api), it allows manipulating the page element tree ("DOM") in the same ways as client-side JS
(without interactivity, of course). It can also [pipe element tree nodes through external helpers](/reference-manual/#preprocess-element-widget)
and inject their output back into the page—in place or in addition to the original node.

Still, quite a few things were only possible with inelegant workarounds.

For example, taxonomies and paginated index pages could only be made with a LaTeX-like approach:
run `soupault --index-only` to produce a JSON dump of the index data, then run a custom script to generate
new pages in `site/` from it, and finally run soupault again to render a complete site.

That approach is certainly workable, I've been using it for [my own blog](https://baturin.org/blog/) for a long time already.
But it's also clunky and takes more build setup than many people are willing to tolerate for a static site generator,
_especially_ when other projects provide easy (if not always very flexible) ways to do the same.

I could add a "magical" pagination and taxonomy generator that would suite most common needs, but my goal for soupault is to give
every user complete control over the website generation process. Every time I want new functionality, I start with thinking
about a general mechanism that would allow me to do that if I couldn't modify soupault itself.

Now there are two major features that allow doing those things without external tools and multi-pass workflows:

* It's now possible to write index generators in Lua and have them also generate new pages (e.g. taxonomies and paginated indices).
* There are now page processing hooks that allow Lua code take over processing steps or run between them: `pre-parse`, `pre-process`, `post-index`, `render`, and `save`.

Read on for details. But before that let's discuss a closely related developent.

## Introducing soupault "blueprints"

A common complaint about soupault is that it's hard to get started with or even see its full capabilities.
It's a fair point. The usual way for static site generators to give people a quick start is
to maintain a repository of "themes".

I find the word "theme" deceptive though. In reality they are more like applications on top of the SSG framework
that include both presentation and logic. Even themes with similar structure may not be interchangeable.
Theme compatibility with newer SSG versions is also a very real issue for some SSGs.
In any case, once you choose and download a theme, switching to another theme isn't guaranteed to be simple,
especially if you modify anything.

I suppose the real reason why soupault users aren't actively making reusable theme is not that they also think
a theme repository isn't a solution to all beginner problems. It's likely that people turn to soupault
for use cases that no other SSG supports and they were going to make their own setup from the start.

However, the quick start problem does exist. Which is why I took time to prepare two reusable
soupault setups that you can take and build upon: one for blogs and another one for books.
There's also a wiki setup in development, but it needs more design effort and work on the code.
Instead of "themes" I'm calling them "blueprints".

### Blog

You can find the blog blueprint at <github>PataphysicalSociety/soupault-blueprints-blog</github>
or <codeberg>PataphysicalSociety/soupault-blueprints-blog</codeberg>.

It's more or less a reusable version of [my own blog](https://baturin.org/blog/) and it supports
post archives organized by tag and per-tag Atom feeds.

### Book

The book blueprint is at <github>PataphysicalSociety/soupault-blueprints-book</github>
or <codeberg>PataphysicalSociety/soupault-blueprints-book</codeberg>.

You can see a real book based on it at [ocamlbook.org](https://ocamlbook.org/).

It's similar to [mdBook](https://rust-lang.github.io/mdBook/) in functionality,
but doesn't require a `summary.md` file: the chapter list in the sidebar is generated automatically.

Chapter numbers are stored in _file names_, like `01_introduction.md`. One Lua hooks then
extracts that number from the file name to add it to the page metadata, and another hook removes it from the target path,
so that its URL becomes just `/introduction`.



## Breaking changes

## Index views have no default template anymore

One change that triggered version bump to 4.0.0 affects a single option in a rare scenario,
but semver is semver.

The index view option `index_item_template` does not have a default value anymore.

If you had an index view that didn't have either `index_template`, `index_item_template`, or `index_processor`
and it was working fine for you, you need to add its original default value to your view explicitly
to make it work like before.

```toml
[index.views.some_view]
  index_item_template = '''<div> <a href="{{url}}">{{title}}</a> </div>'''
```

The reason for removing its implicit default value is that it continuted to refer to the `{{title}}` field
long after the content model dehardcoding in [soupault 2.0.0](/blog/soupault-2.0.0-beta1-release/).
The `{{url}}` field is a built-in, one of the technical fields that is guaranteed to be present.
The `{{title}}` field there is a remnant from the built-in content model of soupault 1.x.x
that made `title`, `date`, and `author` fields special.

Now that the content model is completely user-defined, it's very strange to have a hardcoded reference
to a field that may not exist in user's configuration, so I decided to remove it. My survey
of existing websites built with soupault shows that everyone specifies that option explicitly,
so this change shouldn't affect many people.

On a side note, I briefly thought of removing the `index_item_template` option itself
because `index_item_template = '<div> <a href="{{url}}">{{title}}</a> </div>'` is merely a syntactic sugar for:

```toml
index_template = '''
{% for e in entries %}
  <div> <a href="{{e.url}}">{{e.title}}</a> </div>
{% endfor %}
'''
```

However, my survery shows that surprisingly many people use `index_item_template` in their configs,
and if people see value in it, I definitely shouldn't remove it.

## `absolute_links` widgets without `prefix` cause errors now

The old implementation of the [`absolute_links`](/reference-manual/#absolute-links) widget
would just do nothing if you forgot to specify the site URL in `prefix`, so this configuration was valid:

```toml
[widgets.add_site_url]
  widget = "absolute_links"
  # prefix = "https://example.com/~jrandomhacker"
```

Now it causes an error because most likely it's a configuration mistake that shouldn't be silently ignored.
Explicitly setting the prefix to `""` will not cause any errors.

## New features

### Required index fields

It's now possible to mark certain index fields as required. If a required field is not present in a page,
soupault will display an error and stop.

Example:

```toml
[index.fields.title]
  selector = ["h1#post-title", "h1"]
  required = true
```

### Processing certain pages before all other

By default, soupault processes content pages in an essentially random order. What if a page serves as a source
of [persistent data](/reference-manual/#plugin-persistent-data) for a Lua plugin? Or what if you are experimenting
with some new code on that page and want the build to fail very early?

Now there's an option to tell soupault which pages to process first:

```toml
[settings]
  process_pages_first = ["about.md"]
```

Note that it must be a _content_ page, not an index page (normally, not a page named `index.*`, unless you
set your own `settings.index_page` option). Index pages are always processed after content pages
so that extracted metadata can be inserted into them.

### Page processing hooks

The first big feature in this release is the long-promised system of page processing hooks.

As of this release, there are the following hooks: `pre-parse`, `pre-process`, `post-index`, `render`, and `save`.

* `pre-parse`: operates on the page text before it's parsed, must place the modified page source in the `page_source` variable.
* `pre-process`: operates on the page element tree just after parsing, may modify the `page` variable and set `target_dir` and `target_file` variables.
* `post-index`: operates on the page element tree after index data extraction, can add more fields and override fields in the `index_entry` variable.
* `render`: takes over the rendering process, must put rendered page text in the `page_source` variable.
* `save`: takes over the page output process.

For example, this is how you can do global variable substituion with a pre-parse hook:

```toml
[hooks.pre-parse]
  lua_source = '''
soupault_release = soupault_config["custom_options"]["latest_soupault_version"]
Log.debug("running pre-parse hook")
page_source = Regex.replace_all(page_source, "\\$SOUPAULT_RELEASE\\$", soupault_release)
'''
```

### Lua index processors

The second big feature is an option to write site index rendering code in Lua rather than
use an external script or supply a template. Here's a reimplementation of the built-in `index_template`
option in Lua:

```toml
[index.views.blog]
  index_selector = "div#blog-index"

  index_template = """
    {% for e in entries %}
      <div class="entry">
        <a href="{{e.url}}">{{e.title}}</a> (<time>{{e.date}}</time>)
      </div>
    {% endfor %}
  """

  lua_source = """
    env = {}
    rendered_entries = HTML.parse(String.render_template(config["index_template"], env))
    container = HTML.select_one(page, config["index_selector"])
    HTML.append_child(container, rendered_entries)
  """
```

However, it's not just a new way to do the same thing: it's also a way to create paginated index pages and generate taxonomies.

Here's the plot twist: Lua index processors can set the `pages` variable to a list of new pages.
Each page is a record with two fields: `page_file` (the path it would be at if it was a hand-made page)
and `page_content` (HTML source of the page).

Soupault will then inject those pages in the queue and process them exactly in the same way as if they were real pages loaded
from disk. Of course, it makes sure not to extract metadata from them and not to allow them to generate more pages,
since that would lead to infinite multiplication of autogenerated pages.

This way you can generate the complete website in a single soupault run, but you also have total control
over the process and can make arbitrary taxonomy generators and paginators.


### Accessing the index entry of the page from plugins

By default, soupault separates the list of all pages into "content" pages and "index" pages,
extracts metadata from "content" pages, and inserts rendered metadata in "index" pages.

That approach works well for _most_ websites, but sometimes content pages need access to the site index as well.
For example, if you want your soupault setup to work like [Sphinx](https://www.sphinx-doc.org) or [mdBook](https://rust-lang.github.io/mdBook/)
and insert a site-wide ToC in every page, you need the complete site index metadata available to every page.

Obviously, this is a chicken and egg problem. Since soupault doesn't use "front matter", but rather extracts metadata directly from HTML
and allows Lua plugins to generate new source material for index field extraction, every page needs to be at least partially processed
to retrieve its index entry.

Until this release, the only way to do that was to dump the index data to JSON and read it from plugins on a second pass.
Now a two-pass approach is a built-in feature. You can enable it with `index.index_first = true`.


```toml
[index]
  index_first = true
```

When set to `true`, that option will make soupault perform a reduced first pass where it does the bare minimum of work required
to produce the site index. It will read pages and run widgets specified in `index.extract_after_widgets`, but will not finish
processing any pages and will not write them to disk.

Then it will perform a second pass to actually render the website. Every plugin running on every page can access that page's index entry
via a new `index_entry` variable. This way you can avoid having to store index data externally and run soupault twice,
even though a certain amount of work is still done twice behind the scenes.


### Per-view index entry sorting settings

Before this release, if you wanted to use different sorting key or comparison method for different index views,
you'd have to done it in the index processor script or template.

Now you can just specify `sort_by` and `sort_type` options in your views.

```toml
[index.views.blog]
  index_selector = "#blog-index"
  sort_by = "date"
  sort_type = "calendar"
  ...
```

### Index view actions

Just like inclusion widgets, index views now allow you to choose how generated HTML will be inserted
in the page using the same [`action`](/reference-manual/#glossary-action) option.

### Inline Lua plugins

Lua plugin code can now be inlined in `soupault.toml`:

```toml
[plugins.test-plugin]
  lua_source = '''
    Log.debug("Test plugin!")
    Plugin.exit("Test plugin executed successfully")
'''
```

### Support for all HTML elements in `relative_links` and `absolute_links`

Link rewriting widgets ([`relative_links`](https://soupault.app/reference-manual/#relative-links) and [`absolute_links`](/reference-manual/#absolute-links)
now support all imaginable HTML elements and attributes that may contain URLs, from `<bgsound>` (that no browser supports anymore)
to `<portal>` (that may never see mainstream browser support). Well, I might have missed some, but for all practical purposes
it supports everything now.

The most practically important improvement is support for `srcset`: `<img srcset="foo1.png 1x, foo2.png 2x">` can be converted
to `<<img srcset="../foo1.png 1x, ../foo2.png 2x">` by `relative_links`
or to `<img srcset="https://example.com/foo1.png 1x, https://example.com/foo2.png 2x">` by `absolute_links`.

### New Lua plugin API functions and variables

#### New variables

* `target_file` (path to the output file, relative to the current working directory).
* `index_entry` (the index entry of the page being processed if `index.index_first = true`, otherwise it's `nil`).

#### New functions

* `String.slugify_soft(string)` replaces all whitespace with hyphens, but doesn't touch any other characters.
* `String.url_encode(str)` and `String.url_decode(str)` for working with percent-encoded URLs.
* `String.join_url` as an alias for `String.join_path_unix`.
* `HTML.to_string(etree)` and `HTML.pretty_print(etree)` return string representations of element trees, useful for save hooks.
* `HTML.create_document()` creates an empty element tree.
* `HTML.clone_document(etree)` make a copy of a complete element tree.
* `HTML.append_root(etree, node)` adds a node after the last element.
* `HTML.child_count(elem)` returns the number of children of an element.
* `HTML.unwrap(elem)` yanks the child elements out of a parent and inserts them in its former place.
* `Table.take(table, limit)` removes up to `limit` items from a table and returns them.
* `Table.chunks(table, size)` splits a table into chunks of up to `size` items.
* `Table.has_value(table, value)` returns true if `value` is present in `table`.
* `Table.apply_to_values(func, table)` applies function `func` to every value in `table` (a simpler version of `Table.apply` if you don't care about keys).
* `Table.get_nested(table, {"key", "sub-key", ...})` and `Table.get_nested_default(table, {"key", "sub-key", ...}, default)` for easily retrieving values from nested tables (handy for getting config options).
* `Table.keys(table)` returns a list of all keys in `table`.
* `Sys.list_dir(path)` returns a list of all files in `path`.
* `Value.repr(value)` returns a string representation of a Lua value for debug output (similar to Python's `__repr__` in spirit).

#### Unicode string functions

* `String.length` is now Unicode-aware, the old ASCII-only version is now available as `String.length_ascii`
* `String.truncate` is now Unicode-aware, the old ASCII-only version is now available as `String.truncate_ascii`

### New command line options

* `--dump-index-json <file>` allows you to produce a JSON dump of extracted metadata without adding `index.dump_json` to the config file.

### Misc

* Jingoo templates in `index_template` options now have `soupault_config` in their environment so they can access the global config if needed. 

## Bug fixes

* The `numeric` index entry sorting method works correctly again.
* The `include_subsections` option is now available to all widgets and documented (it makes `section` apply to a dir and all its subdirs).
* Nested inline tables in `soupault.toml` work correctly now (fixed in OTOML 1.0.1).
* Fixed an unhandled exception when handling misconfigured index views.
* Fixed a possible unhandled exception during page processing.
* `Sys.list_dir` correctly handles errors when the argument is not a directory.

## Behaviour changes

* If `index.sort_by` is not set, entries are now sorted by their `url` field rather than displayed in arbitrary order.
* Newlines are now inserted after HTML doctype declarations.
* Index entries are no longer sorted twice, so performance may be marginally better.
* The ToC widget now logs ignored headings to make easier to debug configuration issues.
* Internal errors now produce a message that tells the user how to enable debug and get an exception trace, if it's not enabled. I hope this feature goes unused. ;)
* Preprocessor commands are now quoted in debug logs for better readability (e.g. `running preprocessor "cmark --unsafe --smart"...`).
* Many debug log messages are improved and clarified.

## Website improvements

* Many previously undocumented plugin functions and a few options are now documented.
* The reference manual now features lists of functions for all Lua modules, like [this](/reference-manual/#HTML-function-list).

## Future plans

Introduction of the hook system is a big milestone but there are other long-standing plans
that require significant design and development effort.

### Caching and incremental builds

Right now soupault does not have any caching and always rebuilds everything.
It isn't really a problem for most websites. For example, this website takes me just four seconds to build,
despite its heavy use of external helpers (pandoc for Markdown pages import, highlight for syntax highlighting).

For very large sites with thousands pages, caching can make builds faster and more environmentally-friendly though.
I'm by no means opposed to incremental builds and I'm going to work on it in future versions,
but I don't have a complete design in mind yet.

The problem is that there are lots of events that must invalidate at least some parts of the cache, other than page source change.
If the soupault config changed or any of the plugin files changed, there's a good chance that the cache is no longer fully valid.
And that's just _easily detectable_ changes! What if a third-party tool used as a page preprocessor was upgraded for a bug fix?
What if a data file referenced by a Lua plugin changed?

I haven't studied caching architectures of any other SSGs yet, so I don't know how they try to solve these problems, if they do.
If you want incremental builds and caching, please let me know how exactly you want them to work.

### Embedded scripting language improvements

[Lua-ML](https://github.com/lindig/lua-ml), the Lua interpreter that soupault uses for its plugin API,
was way ahead of its time in terms of integration with the host program. Since it's written in OCaml,
it automatically solves the memory safety issue since the "Lua values" are just original OCaml values
in thin wrappers. It goes much further than that though, and also allows users to add their own modules
and even _replace_ built-in modules via [functors](https://ocaml.org/learn/tutorials/functors.html).

However, the language it implements wasn't ahead of its time even when Lua-ML was new. It's roughly Lua 2.5.
Fair for its day—Lua-ML is a research project from the early '00s, revived after almost two decades of dormancy,
but still ancient.
No anonymous functions, in particular—a maddening misfeature for any functional programming enthusiast.
Its syntax and runtime error reporting are also very rudimentary.

I'm planning to spend some time modernizing its parser and the AST to provide better errors and to bring
at least some features of the modern Lua to it. Then other OCaml projects can also benefit from it
if they want an embedded scripting language.

### Multicore support

Right now soupault is strictly sequential and doesn't support processing anything in parallel at all.
It's still fast _despite_ that fact, thanks to being a native code executable
written in a rather fast language.

Still there _may_ be great opportunities to make soupault even faster by parallelizing it,
since in many setups it spends quite a lot of time wating for external helpers to produce their output,
and different pages can definitely be processed in parallel.

Multicore OCaml is already usable and it's very likely to go mainline this year, which makes that task easier.
I also laid the groundwork for parallelization back in 2020 to structure the main processing code
as a `List.fold_left` over a list of pages, which is fairly easy to replace with a parallel fold.

Ironically, the biggest blocker for it is Lua-ML. It has a lot of mutable state inside and even its parser
isn't thread-safe: when I experimented with the multicore branch and tried a parallel fold,
the OCaml parts worked well, but Lua code from plugins was failing to parse due to race conditions.
That's understandable because Lua-ML is a resurrected research project that was written in a time
when multi-processor computers were rare and very expensive, and writing purely functional code
wasn't a common trend yet. Still, now it needs to be modernized before it can be used in multithreaded code.

We'll see how it works out.

## Acknowledgements

Special thanks to Hristos N. Triantofillou and Soni for testing new features and finding bugs.

<div id="footnotes">
