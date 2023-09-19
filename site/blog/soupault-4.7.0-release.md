<h1 id="post-title">Soupault 4.7.0 release: CSV support, global shared data, post-build hook, and more</h1>

<p>Date: <time id="post-date">2023-09-19</time> </p>

<p id="post-excerpt">
Soupault 4.7.0 is available for download from <a href="https://files.baturin.org/software/soupault/4.7.0">my own server</a>
and from <a href="https://github.com/PataphysicalSociety/soupault/releases/tag/4.7.0">GitHub releases</a>.
It adds support for loading CSV files, a variable for passing global data between plugins and hooks,
a way to determine which two-pass workflow pass is a plugin is executed for, and a few more improvements.
</p>

## Configurable page character encoding

By default, soupault assumes that all pages are stored in UTF-8. I would encourage everyone to migrate to it,
now that all operating systems use it by default. But there are certainly sites that are older than the 
widespread deployment of UTF-8, and there are tools that still produce legacy encodings as well.

Now it's possible to specify the encoding explicitly for such cases:

```toml
[settings]
  page_character_encoding = 'utf-8'
```

The following encodings are supported: `ascii`, `iso-8859-1`, `windows-1251`, `windows-1252`, `utf-8`,
`utf-16`, `utf-16le`, `utf-16be`, `utf-32le`, `utf-32be`, and `ebcdic`.
You can write those options in either upper or lower case (e.g., `UTF-16LE`, `UTF-16le`, and `utf-16le`
are equally acceptable). You cannot omit hyphens or replace them with underscores, though.

## Plugin support for the two-pass workflow

Soupault supports a [two-pass workflow](/reference-manual/#making-index-data-available-to-every-page)
that allows users to make the index data available to all pages (even to content pages).

That feature comes at the cost of duplicating some of the page processing work (at the very least, HTML parsing
and index extraction), but enables use cases that would be impossible otherwise.
For example, the [book blueprint](https://github.com/PataphysicalSociety/soupault-blueprints-book)
uses that capability to inject a fully auto-generated chapter list sidebar in every page,
while its main competitor, [mdBook](https://rust-lang.github.io/mdBook/), requires a hand-written chapter list.

However, until this release, plugins could only guess where soupault was in its website build process,
e.g., by checking if the `site_index` table was empty. That approach is not foolproof and absolutely not flexible.

Now there's a new `soupault_pass` plugin environment variable: 0 when `index_first = false`, 1 and 2 for the first and the second pass respectively when it's true.
Thus plugins can check if the two-pass workflow enabled at all and find out which pass is it.

```lua
if soupault_pass < 2 then
  -- Do nothing
else
  -- Do things that require index data
end
```

## Global data shared between all plugins and hooks

There was already `peristent_data` variable that plugins could use to preserve data — for example,
to calculate the total reading time of all pages and output it on a specific page.

However, there was no way for plugins and hooks to share any data. For example, suppose you want to profile
your website build and measure the time it takes to build each page. You could call `Date.now_timestamp()`
in `pre-parse` and `post-save` hooks, then subtract the start time from the end time... but where would you store
that data to make it available to both hooks? Technically, you could inject it in the page,
but that's a rather dirty hack.

Now there's a new variable named `global_data` that allows different plugins and hooks to communicate
without any dirty hacks. You could just do something like `global_data["start_time"] = Date.now_timestamp()`
in the `pre-parse` hook and access it from the `post-render` hook easily.

This feature certainly comes at the cost of making soupault process pages in parallel harder in the future.
Making soupault use more than one worker thread is now blocked by the fact that Lua-ML, the Lua interpreter it uses,
it neither reentrant nor thread-safe and needs a deep refactoring to make it so. When that part is done,
there will be more questions about the right design for multi-core soupault workflows, but that's a question for the future.

## CSV support

Soupault can already load JSON, TOML, and YAML data files. However, what if you want to create a website
for a product catalog for a small store? A lot of data is kept in spreadsheets or local databases,
and the most common export format for such data is CSV.

Now soupault supports loading CSV files, but that's not all — it can also convert CSV data with a correct header
to a list of objects that you can easily pass to a template for rendering.

These are the new functions:

* `CSV.from_string(str)` — parses CSV data and returns it as a list (i.e., an int-indexed table) of lists.
* `CSV.unsafe_from_string(str)` — like `CSV.from_string` but returns `nil` on errors instead or raising an exception.
* `CSV.to_list_of_tables(csv_data)` — converts CSV data with a header returned by `CSV.from_string` into a list of string-indexed tables for easy rendering.

Now let's look at the `CSV.to_list_of_tables` function in action. Let's write a Lua snippet with a CSV data embedded in it for demonstration:

```lua
csv_source = [[name,price,comment
baby shoes,5,never worn
fake amulet of Yendor,1,uncursed
]]

csv_data = CSV.from_string(csv_source)
Log.debug(format("Raw CSV data: %s", JSON.pretty_print(csv_data)))
csv_table = CSV.to_list_of_tables(csv_data)
Log.debug(format("Converted CSV data: %s", JSON.pretty_print(csv_table)))
```

If you add it to a plugin and run soupault, you will see the following output:

```
[INFO] Processing widget csv-test on page site/index.html
[DEBUG] Raw CSV data: [
  [
    "name",
    "price",
    "comment"
  ],
  [
    "baby shoes",
    5,
    "never worn"
  ],
  [
    "fake amulet of Yendor",
    1,
    "uncursed"
  ]
]

[DEBUG] Converted CSV data: [
  {
    "price": 5,
    "comment": "never worn",
    "name": "baby shoes"
  },
  {
    "price": 1,
    "comment": "uncursed",
    "name": "fake amulet of Yendor"
  }
]
```

As you can see, the "converted CSV data" can be directly passed to a template like this:

```jinja2
{% for i in items %}
Item {{i.name}} ({{i.comment}} is sold for {{i.price}}.
{% endfor %}
```

## Other new features and improvements

* New `max_items` option in index views allows limiting the number of displayed items.
* New `post-build` hook that runs when all pages are processed and soupault is about to terminate.
* Info logs to indicate the first and second passes in the `index_first = true` mode.
* Debug logs now tell why a page is included or excluded from an index view: `"page_included checks for %s: regex=%b, page=%b, section=%b"`

### Other new plugin API functions

* `HTML.swap(l, r)` — swaps two elements in an element tree.
* `HTML.wrap(node, elem)` — wraps `node` in `elem`.

## Bug fixes

* Fixed an unhandled exception on index entry sorting failures when `sort_strict = true` and `sort_by` is unspecified.
* Fixed a typo in the comments of the config generated by `soupault --init` (s/ULRs/URLs/).

## Platform support

Official binaries are now available for Linux on ARM64 (e.g., RaspberryPi 3 and 4).
