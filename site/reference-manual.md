<div id="refman">

<div id="refman-sidebar">
  <div id="generated-toc"> </div>
</div>
<div id="refman-main">

# Reference manual

This manual applies to soupault $SOUPAULT_RELEASE$.
Earlier versions may not support some of the features described here.<fn id="minimum-version">Ideally, everything should be marked with minimum version,
like &ldquo;since 2.0.0&rdquo;. Unfortunately, it’s not the case because when a project has a very small community, versioned documentation isn’t 
a big concern… and when it grows, it’s harder to add after the fact. If you want to add minimum version marks, your patches are welcome</fn>
If you are running an older version, consider updating to the latest release.

## Installation

### Binary release packages

Soupault is distributed as a single, self-contained executable, so installing it from a binary release package it trivial.

You can download it from [files.baturin.org/software/soupault](https://files.baturin.org/software/soupault) or from [GitHub releases](https://github.com/PataphysicalSociety/soupault/releases).
Prebuilt executables are available for Linux (x86-64, statically linked), macOS (x86-64), and Microsoft Windows (64-bit).

Just unpack the archive and copy the executable wherever you want.

Prebuilt executables are compiled with debug symbols. It makes them a couple of megabytes larger than they could be, but you can get better error messages if something goes wrong.
If you encounter an internal error, you can run `soupault --debug` to enable detailed logging and exception traces.

###  Building from source

If you are familiar with the [OCaml](https://ocaml.org) programming language, you may want to install from source.

Since version 1.6, soupault is available from the [opam](https://opam.ocaml.org) repository. If you already have opam installed, you can install it with opam install soupault.

If you want the latest development version, the git repository is at [github.com/PataphysicalSociety/soupault](https://github.com/PataphysicalSociety/soupault).
There’s also a Codeberg mirror at [codeberg.org/PataphysicalSociety/soupault](https://codeberg.org/PataphysicalSociety/soupault).

To build a statically linked executable for Linux, identical to the official one, first install a `+musl+static+flambda` compiler flavor, then uncomment the `(flags (-ccopt -static))` line in `src/dune`.

###  Using soupault on Windows

Windows is a supported platform and soupault includes some fixups to account for the differences.
This document makes a UNIX cultural assumption throughout, but most of the time the same configs will work on both systems. Some differences, however, require user intervention to resolve.

If a file path is only used by soupault itself, then the UNIX convention will work, i.e. `file = 'templates/header.html'` and `file = 'templates\header.html'` are both valid options for the include widget.
However, if it’s passed to something else in the system, then you must use the Windows convention with back slashes.
This applies to the preprocessors, the command option of the exec widget, and the `index_processor` option.

So, if you are on Windows, remember to adjust the paths if needed, e.g.:

```toml
[widgets.some-script]
  widget = 'exec'
  command = 'scripts\myscript.bat'
  selector = 'body'
```

Note that inside double quotes, the backslash is an escape character, so you should either use single quotes for such paths (`'scripts\myscript.bat'`) or use a double backslash (`\.\.\."scripts\\myscript.bat"`).

## Overview

In the website generator mode (the default), soupault takes a page “template”—an HTML file devoid of content, parses it into an element tree, and locates the content container element inside it.

By default the content container is `<body>`, but you can use any selector: `div#content` (a `<div id="content">` element), `article` (an HTML5 `<article>` element), `#post` (any element with `id="post"`)
or any other valid CSS selector.

Then it traverses your site directory where page source files are stored, takes a page file, and parses it into an HTML element tree too.
If the file is not a complete HTML document (doesn’t have an `<html>` element in it), soupault inserts it into the content container element of the template. If it is a complete page, then it goes straight to the next step.

The new HTML tree is then passed to widgets—HTML rewriting modules that manipulate it in different ways: include other files or outputs of external programs into specific elements,
create breadcrumbs for your page, they may delete unwanted elements too.

Processed pages are then written to disk, into a directory structure that mirrors your source directory structure.

Here is a simplified flowchart:

<img src="/images/soupault_flowchart.png" alt="soupault flowchart">

## Basic configuration

Very few soupault settings are fixed, and most can be changed in the configuration file. This is the settings from the default config that `soupault --init` generates:

<pre> <code class="language-toml" id="default-config"> </code> </pre>

Note that if you create a `soupault.conf` file before running `soupault --init`, it will not overwrite that file. 

In this document, whenever a specific site or build dir has to be mentioned, we’ll use default values.

If you misspell an option, soupault will notify you about it and try to suggest a correction.

Note that config values are typed and wrong value type has the same effect as missing option. All boolean values must be `true` or `false` (without quotes),
all integer values must not have quotes around numbers, and all strings must be in single or double quotes.

### Custom directory layouts

If you are using soupault as an HTML processor, or using it as a part of a CI pipeline, typical website generator approach with a single “project directory” may not be optimal.

You can override the location of the config using an environment variable `SOUPAULT_CONFIG`.
You can also override the locations of the source and destination directories with `--site-dir` and `--build-dir` options.

Thus it’s possible to run soupault without a dedicated project directory at all:

```
SOUPAULT_CONFIG="mysite.conf" soupault --site-dir some-input-dir --build-dir some-other-dir
```

## Page processing

### Page templates

In soupault’s terminology, a page template is simply an HTML file without content—an empty page. Soupault does not use a template processor for assembling pages,
instead it injects the content into the element tree. This way any empty HTML page can serve as a soupault ‘theme’

This is the default configuration:

```toml
[settings]
  default_template_file = "templates/main.html"
  default_content_selector = "body"
  default_content_action = "append_child"
```

It means that when soupault processes a page, it first loads and parses the HTML from `templates/main.html`, then parses a page, processes it,
and inserts the result in the `<body>` element of the template, after the last existing child element.

The `default_content_selector` option can be any valid CSS3 selector. The `default_content_action` can be an valid content insertion <term>action</term>.

This is the minimal template good for `default_content_selector = "body"`:

```html
<html>
  <body>
    <!-- content goes here -->
  </body>
</html>
```

### Additional templates

It’s possible to use multiple templates. However, note that additional templates *must* be limited to specific pages with using a <term>limiting option</term>!

You also cannot omit the default template. This is because there is no reliable way to sort templates and content selector by "specificity" that would satisfy every
user’s needs. Without an explicit default template to use for pages that didn’t match any of the custom templates, soupault would have to guess,
but software should never guess, so it requires an explicit default template.

Thus a config that uses custom templates will look like this:

```toml
[settings]
  default_template_file = "templates/main.html"
  default_content_selector = "body"

[templates.funny-template]
  file = "templates/funny-template.html"
  content_selector = "div#fun-content"
  content_action = "prepend_child"
  section = "fun/"
```

### Page files

With default config, soupault will look for page files in `site/`.

#### Page file extensions

Files in the <term>site directory</term> can be treated as pages or assets, depending on their extension.
The `page_file_extensions` option defines which files are treated as pages. This is the default:

```toml
[settings]
  page_file_extensions = ["html", "htm", "md", "rst", "adoc"]
```

Page files are parsed as HTML, processed, and written to the <term>build directory</term>. Asset files are copied to the build directory unchanged.

### Page preprocessors

Soupault has no built-in support for formats other than HTML. Instead, it allows you to specify external preprocessor programs to convert other formats to HTML.

A preprocessor program *must* take a page file as an argument and *must* write generated HTML to standard output.

For example, this configuration will make soupault preprocess Markdown files with [cmark](https://github.com/commonmark/cmark).

```toml
[preprocessors]
  md = "cmark --unsafe --smart"
```

Preprocessor commands are executed in the <term>system shell</term>, so it’s fine to use relative paths and specify command arguments. Page file name is appended to the command string.
For example, with the above config, when soupault processes `site/about.md`, it will run `cmark --unsafe --smart site/about.md` and read the standard output of that process.

### Partial and complete pages

Soupault allows you to have pages with a unique, non-templated layout even in generator mode.
If a page has an `<html>` element in it, it’s assumed to be a complete page.

Complete pages are exempt from templating, they are only parsed and processed by widgets.

If a page doesn’t have an `<html>` element in it, its content is inserted in a page template first.

Note that the selector used to check for ‘completeness’ is a configurable option:

```
[settings]
  complete_page_selector = "html"
```

### Clean URLs

Soupault uses clean URLs by default. If you add a page to `site/`, for example, `site/about.html`, it will turn into `build/about/index.html` so that it can be accessed as `https://mysite.example.com/about`.

Index files are simply copied to the target directory.

* `site/index.html` → `build/index.html`
* `site/about.html` → `build/about/index.html`
* `site/papers/theorems-for-free.html` → `build/papers/theorems-for-free/index.html`

Note: having a page named `foo.html` and a section directory named `foo/` results in undefined behaviour when clean URLs are on. Don’t do that to avoid unpredictable results.

This is what soupault will make from a source directory, when clean URLs are enabled:

```shell-session
$ tree site/
site/
├── about.html
├── cv.html
└── index.html

$ tree build/
build/
├── about
│   └── index.html
├── cv
│   └── index.html
└── index.html
```

#### Disabling clean URLs

If you’ve had a website for a long time and there are links to your page that will break if you change the URLs, you can make soupault mirror your site directory structure exactly and preserve original file names.

Just add `clean_urls = false` to the `[settings]` section of your `soupault.conf` file.

```
[settings]
  clean_urls = false
```

### Soupault as an HTML processor

If you want to use soupault with an existing website and don’t want the template functionality, you can switch it from a website generator mode to an HTML processor more where it doesn’t use a template
and doesn’t require the default_template to exist.

Recommended settings for the preprocessor mode:

```
[settings]
  generator_mode = false
  clean_urls = false
```

### Page processing order

By default, soupault may process content pages in any order. However, you can tell it to process certain pages before everything else
using the `process_pages_first` option (available since 4.0.0).

```toml
[settings]
  process_pages_first = ["foo.html", "bar.md"]
```

This is useful when processing a page produces some important [persistent data](#plugin-persistent-data), or you are experimenting
with some setup and want to have the build fail as early as possible, or be able to terminate it after processing
just the pages you are interested in.

## Metadata extraction and rendering

Soupault can extract metadata from pages using CSS selectors, similar to what web scrapers are doing. This is more flexible than “front matter”,
and allows you to automatically generate index pages for existing websites, without having to edit their pages.

What you do with extracted metadata is up to you. You can simply export it to JSON for further processing, like generating an RSS/Atom feed,
or creating taxonomy pages with an external script. You can also tell soupault to generate HTML from the index data. You can also combine both approaches.

Metadata extraction is disabled by default. You need to enable it first:

```toml
[index]
  index = true
```

### Index settings

These are the basic settings:

```toml
[index]
  # Whether to extract metadata and generate indices or not
  # Default is false, set to true to enable
  index = false

  # Which index field to use as a sorting key.
  # There is no default because there’s no built-in content model: it’s up to you.
  # sort_by =

  # By default entries are sorted in descending order.
  # This means if you sort by date, newest entries come first.
  sort_descending = true

  # There are three supported ways to sort entries.
  #
  # In the "calendar" mode, soupault will try to parse field values as dates
  # according to the index_date_formats option (see below).
  #
  # In the "numeric" mode, it will try to parse fields as integers.
  #
  # In the "lexicographic" mode it will simply compare field values as strings.
  #
  # The default is "calendar"
  sort_type = "calendar"

  # Date formats for calendar sorting
  # Default %F means YYYY-MM-DD
  # Most of the classic UNIX date format specifiers are supported
  # see https://man7.org/linux/man-pages/man1/date.1.html for example.
  index_date_formats = ["%F"]

  # By default, soupault will require valid values for "calendar" and "numeric" sorting
  # If a value is invalid, it’s assumed to be "less" than any valid value.
  # Two invalid values are compared lexicographically as strings.
  #
  # However, you can make if fail the build if it encounters invalid values using this option:
  strict_sort = false

  # extract_after_widgets = []
```

### Index fields

Soupault doesn’t have a built-in ‘content model’. Instead, it allows you to define what to extract from pages,
in the spirit of [microformats](http://microformats.org/).

This is the configuration for this very site:

```toml
# Metadata extracted from pages, using CSS selectors to find elements to extract data from
[index.fields]

[index.fields.title]
  selector = ["h1#post-title", "h1"]

[index.fields.date]
  selector = ["time#post-date", "time"]
  extract_attribute = "datetime"
  fallback_to_content = true

[index.fields.excerpt]
  selector = ["p#post-excerpt", "p"]

[index.fields.reading_time]
  selector = "span#reading-time"
```

The `selector` field is either a single CSS selector or a list of selectors that define what to extract
from the page. Here, `selector = ["p#post-excerpt", "p"]` means “use `p#post-excerpt` for the excerpt,
but if there’s no such element, just use the first paragraph”.

By default, soupault will extract only the first element, but you can change that with `select_all = true`.

You can also set the default value with `default` option (only for fields without `select_all = true`).

As you can see from the `date` field definition, it’s possible to make soupault extract an attribute
rather than content. The `fallback_to_content` option defines what soupault will do if an element has
no such attribute. With `fallback_to_content = true` it will extract the element content instead,
while if it’s false, it will leave the field undefined.

### Built-in index fields

Soupault provides technical metadata of the page as built-in fields.

<dl>
  <dt>url</dt>
  <dd>Absolute page URL path, like /papers/simple-imperative-polymorphism (or /papers/simple-imperative-polymorphism.html, if clean URLs are disabled)</dd>
  <dt>nav_path</dt>
  <dd>A list of strings that represents the logical section path, e.g. for <code>site/pictures/cats/grumpy.html</code> it will be <code>["pictures", "cats"]</code>.</dd> 
  <dt>page_file</dt>
  <dd>Original page file path.</dd>
</dl>

### Index views

Soupault can insert HTML rendered from site metadata into the site index pages. By default those are pages named `index.*`.

Note that you cannot insert an index into an arbitrary page, and you cannot extract any metadata
from an index page.

The way index data is rendered is defined by “index views”. You can have any number of views.

Which view is used is determined by the `index_selector` option. It’s possible to use multiple views on the same page,
e.g. if you want to display lists of posts grouped by date and by author.

#### Ways to control index rendering

There are three options that can define view rendering:

* `index_item_template` — a <term>jingoo</term> template for an individual item, applied to each index data entry.
* `index_template` — a jingoo template for the entire index.
* `index_processor` — external script that receives index data (in JSON) to stdin and write HTML to stdout.
* `file` or `lua_source` — path to a Lua index processor, or inline Lua code, respectively.

#### Index item template

The simplest way to render an index is to configure `index_item_template`:

```toml
[index.views.blog]
  index_selector = "#blog-index"
  index_item_template = """
    <h2><a href="{{url}}">{{title}}</a></h2>
    <p><strong>Last update:</strong> {{date}}.</p>
    <p><strong>Reading time:</strong> {{reading_time}}.</p>
    <p>{{excerpt}}</p>
    <a href="{{url}}">Read more</a>
  """
```

#### Index template

If you want more control, you can supply a complete template instead. The list of entries will be in the `entries` variable.
This is the equivalent of `index_item_template`:

```toml
[index.views.blog]
  index_selector = "#blog-index"
  index_template = """
    {% for e in entries %}
    <h2><a href="{{url}}">{{title}}</a></h2>
    <p><strong>Last update:</strong> {{date}}.</p>
    <p><strong>Reading time:</strong> {{reading_time}}.</p>
    <p>{{excerpt}}</p>
    <a href="{{url}}">Read more</a>
    {% endfor %}
  """
```

#### External index processor

If you have a favorite programming language or a favorite template processor and want to handle site index rendering with it,
you can call an external program with `index_processor = /path/to/script`. The value is actually a shell command,
so you can also specify arguments.

Soupault will send a JSON representation of the site index data to the script’s stdin and expects HTML source in the stdout.

The index data format is the same as what you get when [exporting site index to JSON](#exporting-metadata-to-json).
Use the `index.dump_json` option and inspect the output to get familiar with that format.

#### Lua index processor

Finally, if you want total control over the process, you can write an index processor in Lua. The most important advantage
of Lua index processors is that they can generate new pages and inject them in the processing queue.

For example, here’s a reimplementation of the built-in `index_template` behavior in Lua, but with a twist:
it also creates a clone of the index page.

```toml
[index.views.blog]
  index_selector = "#blog-index"
  index_template = """
    {% for e in entries %}
    <h2><a href="{{url}}">{{title}}</a></h2>
    <p><strong>Last update:</strong> {{date}}.</p>
    <p><strong>Reading time:</strong> {{reading_time}}.</p>
    <p>{{excerpt}}</p>
    <a href="{{url}}">Read more</a>
    {% endfor %}
  """

  lua_source = '''
    -- Render entries on the page
    env = {}
    env["entries"] = site_index
    rendered_entries = HTML.parse(String.render_template(config["index_template"], env))
    container = HTML.select_one(page, config["index_selector"])
    HTML.append_child(container, rendered_entries)

    -- Make a clone of the blog index page and add it to the generated page list.
    -- Soupault will extract the `pages` variable from the Lua environment
    -- when this script finishes.
    pages = {}
    pages[1] = {}
    pages[1]["page_file"] = Sys.join_path(Sys.dirname(page_file), "index_clone.html")
    pages[1]["page_content"] = HTML.pretty_print(page)
  '''
```

As you can see, generated pages are stored in the `pages` environment. When an index processor finishes, soupault
extracts that variable from its environment and adds generated pages to the page processing queue.

The `pages` variable must be a table, and its items must be tables with `page_file` and `page_content` fields.

The `page_file` field is the file path where the page _would have been at if it was hand-written_.
Most of the time you will want to generate it with `Sys.join_path(Sys.dirname(page_file), "page_name.html")`
to make it appear in the same directory as the index page being processed, but there are no restrictions:
you can use any path and place the generated page in any section.

The `page_content` must be a _string representation_ of the page, that you can make with `HTML.to_string` or `HTML.pretty_print` functions.
This is because generated pages are treated the same as pages that actually exist on disk, and need to be parsed.

Soupault will automatically prevent autogenerated pages from generating more pages so there shouldn’t be any infinite loops
or fork bombs coming from this functionality.

### Index view options

By default, soupault will render an index of the current section, e.g. `site/blog/index.html` page will display an index of all pages in the
`site/blog/` directory.

If you want to display an index of a different section, or present the same index in different ways, you can add <term>limiting options</term>
to the view, like this:

```toml
[index.views.blog-summary]
  section = "blog/"
  index_processor = "scripts/blog-summary.py"
```

Since soupault 4.0.0, you can also specify index sorting options on a per-view basis:

```toml
[index.views.list-of-all-pages]
  sort_by = "title"
  sort_type = "lexicographic"
  sort_descending = false
  strict_sort = false
```

### Interaction with widgets

Soupault first inserts rendered index data, then runs widgets. This is to allow widgets to modify HTML generated by index processors.

Metadata extraction happens as early as possible. By default, it happens before any widgets have run, to avoid adverse interaction with widgets.
However, if you want to extract something from output of a widget, you can tell soupault which widgets to run before extracting metadata.

Suppose you want metadata extraction to happen only after widgets `foo` and `bar` have run. You can do it with this config:

```toml
[index]
  extract_after_widgets = ["foo", "bar"]
```

Note that it doesn’t mean that soupault will schedule widgets `foo` and `bar` to run before everything else. It doesn’t mean that
soupault will not schedule any other widgets to run before metadata extraction happens. It only means that metadata extraction
will happen immediately after the last of `foo` and `bar` widgets have run.

Thus, if you have a setup where some widgets produce metadata you want extracted (*producers*) and other widgets that modify the
rendered index (*consumers*) you may need to specify all *producers* as dependencies for *consumers* to ensure correct ordering.

For example, if you want a widget `prettify-blog-index` to run only after `add-tags` and `add-reading-time` have run,
this is the only way to guarantee it:

```toml
[index]
  extract_after_widgets = ["add-tags", "add-reading-time"]
  ...

[widgets.prettify-blog-index]
  after = ["add-tags", "add-reading-time"]
  ...
```

### Treating index pages as normal pages

Since soupault can transform normal pages to clean URLs by itself, normally it’s best to keep a logical site structure: directory = section, file = page, and leave creation of clean URLs to the software.

However, sometimes creating a degenerate section by hand is a sensible thing to do. One use case is bundling a page with its assets.
Suppose you are making a page with a lot of photos, and those photos aren’t going to be used by any other page.
In that case, placing those photos in a shared asset directory will only make it harder to remember or find what pages they are used by, and will make all links to those images longer.
Storing them in a directory with the page offers the easiest mental model. 

Using the `force_indexing_path_regex` option in the `[index]` table, you can make soupault treat some pages as normal pages even though their files are named `index.*`.
This can be helpful if you only have a few such pages, or they all are within a single directory.

If you want to be able to mark any directory as a "leaf" (hand-made clean URL), there’s another way: a `leaf_file` option to the `[index]` table.
Suppose you set `leaf_file = ".leaf"`. In that case, when soupault finds a directory that has files named `index.html` and `.leaf`, it treats `index.html` as a normal page and extracts metadata from it.

There’s no default value for the `leaf_file option`, you need to set it explicitly if you want it.

### Making index data available to every page

By default, soupault first extracts metadata from content pages, then uses it for processing index pages.
That is fine most of the time, but what if you want to write a plugin to display a global site-wide navigation sidebar
on every page?

One option would be to [export the site index to JSON](#exporting-metadata-to-json), generate the sidebar from it,
then run soupault again and have your plugin load that generated file. That’s workable, but not very convenient.

Since soupault 4.0.0, a two-pass workflow is a built-in feature that you can enable with the new `index.index_first` option.

```toml
[index]
  index_first = true
```

When it’s true, soupault will make a first pass to do the bare minimum of work to extract the site metadata: read pages,
run widgets set to run before index extraction, and extract the data. It will not run every widget, render anything,
or write pages to disk during that first pass.

Then it will make a second pass to generate actual pages as usual, except the `index_entry` variable will contain the complete
site index even for plugins running on content pages.

### Exporting metadata to JSON

If built-in functionality is not enough, you can export the site index data to a JSON file
and process it with external scripts.

JSON export is disabled by default an needs to be enabled explicitly:

```toml
[index]
  dump_json = "path/to/file.json"
```

This way you can use a TeX-like workflow:

1. Run soupault so that index file is created.
2. Run your custom index generator and save generated taxonomy pages to site/.
3. Run soupault one more time to have them included in the build.

To save time and avoid useless operations, you can run `soupault --index-only`.
With that option, soupault will stop after extracting the metadata and exporting it to JSON.
It will run widgets that index extraction depends on (that is, those specified in `extract_after_widgets`),
but will not run the rest of the widgets, nor will it copy assets or generate pages.

After soupault 4.0.0 introduced the `index_first` option and ability to generate new pages
from Lua index processors, this approach is much less necessary than it used to be,
but still remains an option.

## Widgets

Soupault has built-in widgets for deleting specific HTML elements, including files into pages,
setting page title and more. 

### Widget behaviour

Widgets that require a selector option first check if there’s an element matching that selector in the page.
If there’s no such element, they do nothing, since they wouldn’t have a place to insert their output anyway.

Thus, the simplest way to ensure a widget doesn’t run on a particular page is to make sure that page doesn’t
have its target element.

If a page has more than one element matching the same selector, the first element is used as widget’s target.

### Widget configuration

Widget configuration is stored in the `[widgets]` table. The TOML syntax for nested tables is `[table.subtable]`, therefore, you will have entries like `[widgets.foo]`, `[widgets.bar]` and so on.

Widget subtable names are purely informational and have no effect, widget type is determined by the `widget` option.
Therefore, if you want to use a hypothetical frobnicator widget, your entry will look like:

```toml
[widgets.frobnicate]
  widget = "frobnicator"
  selector = "div#frob"
```

It may seem confusing and redundant, but it allows you to use more than one widget of the same type.

```toml
[widgets.insert-header]
  widget = "include"
  file = "templates/header.html"
  selector = "div#header"

[widgets.insert-footer]
  widget = "include"
  file = "templates/footer.html"
  selector = "div#footer"
```

### Choosing where to insert the output

By default, widget output is inserted after the last child of its target element.

If you are modifying existing pages or just want more control and flexibility, you can specify the position explicitly using an <term>action</term> option.

For example, you can insert a header file before the first element in the page `<body>`:

```toml
[widgets.insert-header]
  widget = "include"
  file = "templates/header.html"
  selector = "body"
  action = "prepend_child"
```

Or insert a table of contents before the first `<h1>` element (it a page has it):

```toml
[widgets.table-of-contents]
  widget = "toc"
  selector = "h1"
  action = "insert_before"
```

You can find the complete list of valid actions in the <term name="action">glossary</term>.

### Limiting widgets to pages or sections

If the widget target comes from the page content rather than the template, you can simply not include any elements matching its selector option.

Otherwise, you can explicitly set a widget to run or not run on specific pages or sections.

All options from this section can take either a single string, or a list of strings.

#### Limiting to pages or sections

There are page and section options that allow you to specify exact paths to specific pages or sections. Paths are relative to your site directory.

The page option limits a widget to an exact page file, while the section option applies a widget to all files in a subdirectory.

```toml
[widgets.site-news]
  # only on site/index.html and site/news.html
  page = ["index.html", "news.html"]

  widget = "include"
  file = "includes/site-news.html"
  selector = "div#news"

[widgets.cat-picture]
  # only on site/cats/*
  section = "cats"

  # Implicit default
  include_subsections = false

  widget = "insert_html"
  html = "<img src=\"/images/lolcat_cookie.gif\" />"
  selector = "#catpic"
```

Note that by default the `section` option applies _only_ to the directory itself. That is, if you have `section = "poems"` in a widget,
it will apply to `poems/georgia.html`, but not to `poems/soupault/georgia.html`.

If you want a widget to apply to a directory and its subdirectories, add `include_subsections = true`.

#### Excluding sections or pages

It’s also possible to explicitly exclude pages or sections.

```toml
[widgets.toc]
  # Don’t add a TOC to the main page
  exclude_page = "index.html"
  ...

[widgets.evil-analytics]
  exclude_section = "privacy"
  ...
```

#### Using regular expressions

When nothing else helps, `path_regex` and `exclude_path_regex` options may solve your problem. They take a Perl-compatible regular expression (not a glob).

```toml
[widgets.toc]
  # Don’t add a TOC to any section index page
  exclude_path_regex = '^(.*)/index\.html$'
  ...

[widgets.cat-picture]
  path_regex = 'cats/'
```

### Widget processing order

The order of widgets in your config file doesn’t determine their processing order. By default, soupault assumes that widgets are independent and can be processed in arbitrary order.
In future versions they may even be processed in parallel, who knows.

This can be an issue if one widget relies on output from another. In that case, you can order widgets explicitly with the after parameter.
It can be a single widget (`after = "my-widget"`) or a list of widgets (`after = ["some-widget", "another-widget"]`).

Here is an example. Suppose in the template there’s a `<div id="breadcrumbs">` where breadcrumbs are inserted by the `add-breadcrumbs` widget.
Since there may not be breadcrumbs if the page is not deep enough, that `<div>` may be left empty, and that’s not _neat_. We can remove empty breadcrumb containers
with a `delete_element` widget, but we need to make sure it only runs after breadcrumbs widget has run.

```toml
## Breadcrumbs
[widgets.add-breadcrumbs]
  widget = "breadcrumbs"
  selector = "#breadcrumbs"
  ...

## Remove div#breadcrumbs if the breadcrumbs widget left it empty
[widgets.cleanup-breadcrumbs]
  widget = "delete_element"
  selector = "#breadcrumbs"
  only_if_empty = true

  # Important!
  after = "add-breadcrumbs"
  ...
```

<h3 id="build-profiles">Limiting widgets to “build profiles”</h3>

Sometimes you may want to enable certain widgets only for some builds. For example, include analytics scripts only in production builds. It can be done with “build profiles”.

For example, this way you can only include `includes/analytics.html` file in your pages when the build profile is set to `live`:

```toml
[widgets.analytics]
  profile = "live"
  widget = "include"
  file = "includes/analytics.html"
  selector = "body"
```

Soupault will only process that widget if you run `soupault --profile live`. If you run `soupault --profile dev`, or run it without the `--profile` option, it will ignore that widget.

Since soupault 2.7.0, it’s possible to specify more than one build profile. For example, if you run `soupault --profile foo --profile bar`, it will enable both `foo` and `bar` profiles
and their associated widgets.

### Disabling widgets

Since soupault 2.7.0, it’s possible to disable a widget by adding `disabled = true` to its config.

## Built-in widgets

###  File and output inclusion

These widgets include something into your page: a file, a snippet, or output of an external program.

<h4 id="include-widget">include</h4>

The include widget simply reads a file and inserts its content into some element.

The following configuration will insert the content of `templates/header.html` file into an element with `id="header"` and the content of `templates/footer.html` into an element with `id="footer"`.

```toml
[widgets.header]
  widget = "include"
  file = "templates/header.html"
  selector = "#header"

[widgets.footer]
  widget = "include"
  file = "templates/footer.html"
  selector = "#footer"
```

This widget provides a parse option that controls whether the file is parsed or included as a text node. Use `parse = false` if you want to include a file verbatim, with HTML special characters escaped.

Note: you can specify multiple selectors, like `selector = ["div#footer", "footer", "body"]`.
In that case soupault will first try to insert the content in a `<div id="footer">` if a page has one,
the try `<footer>`, and if neither is found, just insert in the page `<body>`.

#### insert_html

If you only want to insert a small HTML snippet, you can use this widget instead of `include`.

```toml
[widgets.tracking-script]
  widget = "insert_html"
  html = '<script src="/scripts/evil-analytics.js"> </script>'
  selector = "head"
  parse = true
```

<h4 id="exec-widget">exec</h4>

The exec widget executes an external program and includes its output into an element. The program is executed in the <term>system shell</term>,
so you can write a complete command with arguments in the command option. Like the include widget, it has a `parse` option that includes the output verbatim if set to false.

Simple example: page generation timestamp.

```toml
[widgets.generated-on]
  widget = "exec"
  selector = "#generated-on"
  command = "date -R"
  parse = true
```

<h4 id="preprocess-element-widget">preprocess_element</h4>

This widget processes element content with an external program and includes its output back in the page.

Element content is sent to program’s `stdin`, so it can be used with any program designed to work as a pipe. HTML entities are expanded, so if you have an `&gt;` or an `&amp;` in your page, the program gets a `>` or `&`.

By default it assumes that the program output is HTML and runs it through an HTML parser. If you want to include its output as text (with HTML special characters escaped), you should specify `parse = false`.

For example, this is how you can run the content of `<pre>` elements through `cat -n` to automatically add line numbers:

```toml
[widgets.line-numbers]
  widget = "preprocess_element"
  selector = "pre"
  command = "cat -n"
  parse = false
```

You can pass element metadata to the program for better control.
The tag name is passed in the `TAG_NAME` environment variable, and all attributes are passed in environment variables prefixed with `ATTR`: `ATTR_ID`, `ATTR_CLASS`, `ATTR_SRC`…

For example, [highlight](http://www.andre-simon.de/), a popular syntax highlighting tool, has a language syntax option, e.g. `--syntax=python`.
If your elements that contain source code samples have language specified in a class (like `<pre class="language-python">`), you can extract the language from the `ATTR_CLASS` variable like this:

```toml
# Runs the content of <* class="language-*"> elements through a syntax highlighter
[widgets.highlight]
  widget = "preprocess_element"
  selector = '*[class^="language-"]'
  command = 'highlight -O html -f --syntax=$(echo $ATTR_CLASS | sed -e "s/language-//")'
```

Like all widgets, this widget supports the [action](#choosing-where-to-insert-the-output) option.
The default is `action = "replace_content"`, but using different actions you can insert a rendered version of the content alongside the original.
For example, insert an inline SVG version of every [Graphviz](https://graphviz.org/) graph next to the source, and then highlight the source:

```toml
[widgets.graphviz-svg]
  widget = 'preprocess_element'
  selector = 'pre.language-graphviz'
  command = 'dot -Tsvg'
  action = 'insert_after'

[widgets.highlight]
  after = "graphviz-svg"
  widget = "preprocess_element"
  selector = '*[class^="language-"]'
  command = 'highlight -O html -f --syntax=$(echo $ATTR_CLASS | sed -e "s/language-//")'
```

The result will look like this:

<img src="/images/graphviz_sample.png">

Note: this widget supports multiple selectors, e.g. `selector = ["pre", "code"]`.

#### Environment variables

External programs executed by `exec` and `preprocess_element` widgets get a few useful environment variables:

<dl>
  <dt>PAGE_FILE</dt>
  <dd>Path to the page source file, relative to the current working directory (e.g. site/index.html).</dd>
  <dt>TARGET_DIR</dt>
  <dd>The directory where the rendered page will be saved.</dd>
</dl>

This is how you can include page’s own source into a page, on a UNIX-like system:

```toml
[widgets.page-source]
  widget = "exec"
  selector = "#page-source"
  parse = false
  command = "cat $PAGE_FILE"
```

If you store your pages in git, you can get a page timestamp from the git log with a similar method (note that it’s not a very fast operation for long commit histories):

```toml
[widgets.last-modified]
  widget = "exec"
  selector = "#git-timestamp"
  command = "git log -n 1 --pretty=format:%ad --date=format:%Y-%m-%d -- $PAGE_FILE"
```

The `PAGE_FILE` variable can be used in many different ways, for example, you can use it to fetch the page author and modification date from a revision control system like git or mercurial.

The `TARGET_DIR` variable is useful for scripts that modify or create page assets.
For example, this snippet will create PNG images from Graphviz graphs inside `<pre class="graphviz-png">` elements and replace those pre’s with relative links to images.

```toml
[widgets.graphviz-png]
  widget = 'preprocess_element'
  selector = '.graphviz-png'
  command = 'dot -Tpng > $TARGET_DIR/graph_$ATTR_ID.png && echo \<img src="graph_$ATTR_ID.png"\>'
  action = 'replace_element'
```

#### External program behavior

One thing to note when writing or choosing programs to use with `preprocess_element` is that
soupault will not interactively exchange lines with the external program. It will first send the input _at once_
and close the child process' `stdin` to signal the end of input, then read the output from the program.

Thus your program should have the following structure:

```
input = read_until_eof(stdin);
result = do_things(input);
write(result, stdout)
```

For example, a trivial echo script in Python:

```python
import sys

input = sys.stdin.read()
print(input)
```

Attempting to wait for soupault to read your program’s output before it finishes reading soupault’s input
may cause a deadlock and hang the build process.
There’s no plan to make communication with the child process asynchronous (that would require quite some trade-offs),
so be careful to first read the input until the end, then write the output back.

### Content manipulation

<h4 id="title-widget">title</h4>

This widget sets the page `<title>` based on the content on another element. For example, if you have a page with `<h1>About me</h1>`,
quite likely you want it to have `<title>About me — J. Random Hacker’s homepage</title>`. With this widget you can avoid doing it by hand.

If a page has a _non-empty_ `<title>` element, this widget doesn’t touch it.

Example:

```toml
[widgets.page-title]
  widget = "title"
  selector = "h1"
  default = "My Website"
  append = " on My Website"
  prepend = "Page named "

  # Insert a <title> element if a page doesn’t have one
  force = false

  # Keep the existing <title> if it exists and isn’t empty
  keep = false
```

If `selector` is not specified, it uses the first `<h1>` as the title source element by default.

The `selector` option can be a list. For example, `selector = ["h1", "h2", "#title"]` means “use the first `<h1>` if the page has it, else use `<h2>`, else use anything with `id="title"`, else use default”.

Optional `prepend` and `append` parameters allow you to insert some text before and after the title.

If there is no element matching the `selector` in the page, it will use the `default`. In that case `prepend` and `append` options are ignored.

By default this widget skips pages that don’t have a `<title>` element. You can override this with `force = true`, then it will create missing `<title>` elements.

<h4 id="footnotes-widget">footnotes</h4>

The footnotes widget finds all elements matching a selector, moves them to a designated footnotes container, and replaces them with numbered links<fn>As if anyone doesn’t know what footnotes look like.</fn>.
As usual, the container element can be anywhere in the page—you can have footnotes at the top if you feel like it.

```toml
[widgets.footnotes]
  widget = "footnotes"

  # Required: Where to move the footnotes
  selector = "#footnotes"

  # Required: What elements to consider footnotes
  footnote_selector = ".footnote"

  # Optional: Element to wrap footnotes in, default is <p>
  footnote_template = "<p> </p>"

  # Optional: Element to wrap the footnote number in, default is <sup>
  ref_template = "<sup> </sup>"

  # Optional: Class for footnote links, default is none
  footnote_link_class = "footnote"

  # Optional: do not create links back to original locations
  back_links = true

  # Prepends some text to the footnote id
  link_id_prepend = ""

  # Appends some text to the back link id
  back_link_id_append = ""
```

The `footnote_selector` option can be a list, in that case all elements matching any of those selectors will be considered footnotes.

By default, the number in front of a footnote is a hyperlink back to the original location. You can disable it and make footnotes one way links with `back_links = false`.

You can create a custom “namespace” for footnotes and reference links using `link_id_prepend` and `back_link_id_append` options. This makes it easier to use custom styling for those elements.

```toml
link_id_prepend = "footnote-"
back_link_id_append = "-ref"
```

<h4 id="toc-widget">toc</h4>

The toc widget generates a table of contents for your page.

Table of contents is generated from heading tags from `<h1>` to `<h6>`.

Here is a sample ToC configuration:

```toml
[widgets.table-of-contents]
  widget = "toc"

  # Required: where to insert the ToC
  selector = "#generated-toc"

  # Optional: exclude headings that match certain CSS selectors from the ToC
  # ignore_heading_selectors = []

  # Optional: minimum and maximum levels, defaults are 1 and 6 respectively
  min_level = 2
  max_level = 6

  # Optional: use <ol> instead of <ul> for ToC lists
  # Default is false
  numbered_list = false

  # Optional: Class for the ToC list element, default is none
  toc_list_class = "toc"

  # Optional: append the heading level to the ToC list class
  # In this example list for level 2 would be "toc-2"
  toc_class_levels = false

  # Optional: Insert "link to this section" links next to headings
  heading_links = true

  # Optional: text for the section links
  # Default is "#"
  heading_link_text = "→ "

  # Optional: class for the section links
  # Default is none
  heading_link_class = "here"

  # Optional: insert the section link after the header text rather than before
  # Default is false
  heading_links_append = false

  # Maximum level for headings to create section links for. Can be greater than max_level
  # Implicitly defaults to max_level
  # max_heading_link_level = 

  # Optional: use header text slugs for anchors
  # Default is false
  use_heading_slug = true

  # Only replace non-whitespace characters when generating heading ids
  soft_slug = false

  # Force heading ids to lowercase
  slug_force_lowercase = true

  # You can redefine the whole slugification process using these options
  slug_regex = '[^a-zA-Z0-9\-]'
  slug_replacement_string = "-"

  # Optional: use unchanged header text for anchors
  # Default is false
  use_heading_text = false

  # Place nested lists inside a <li> rather than next to it
  valid_html = false

  # Exclude headings that match certain selectors from the ToC
  ignore_heading_selectors = [".notoc"]
```

##### Heading anchor options

For the table of contents to work, every heading needs a unique `id` attribute that can be used as an anchor.

If a heading has an `id` attribute, it will be used for the anchor. If it doesn’t, soupault has to generate one.

By default, if a heading has no `id`, soupault will generate a unique numeric identifier for it.
This is safe, but not very good for readers (links are non-indicative) and for people who want to share direct links to sections (they will change if you add more sections).

If you want to find a balance between readability, permanence, and ease of maintenance, there are a few ways you can do it and the choice is yours.

The `use_heading_slug = true` option converts the heading text to a valid HTML identifier.
Right now, however, it’s very aggressive and replaces everything other than ASCII letters and digits with hyphens.
This is obviously a no go for non-ASCII languages, that is, pretty much all languages in the world. It may be implemented more sensibly in the future.

The `use_heading_text = true` option uses unmodified heading text for the id, with whitespace and all. This is against the rules of HTML, but seems to work well in practice.

Note that `use_heading_slug` and `use_heading_text` do not enforce uniqueness.

All in all, for best link permanence you should give every heading a unique id by hand, and for best readability you may want to go with `use_heading_text = true`.

<h4 id="breadcrumbs-widget">breadcrumbs</h4>

The breadcrumbs widget generates breadcrumbs for the page.

The only required parameter is `selector`, the rest is optional.

Example:

```toml
[widgets.breadcrumbs]
  widget = "breadcrumbs"

  selector = "#breadcrumbs"
  prepend = ".. / "
  append = " /"
  between = " / "
  breadcrumb_template = '<a href="{{url}}">{{name}}</a>'
  min_depth = 1
```

The `breadcrumb_template` is a <term>jingoo</term> template string. The only variables in its environment are `url` and `name`.

The `min_depth` option sets the minimum nesting depth where breadcrumbs appear. That’s the length of the logical <term>navigation path</term> rather than directory path.

There is a fixup that decrements the path for section index pages, that is, pages named `index.*` by default, or whatever is specified in the `index_page` option.
Their navigation path is considered one level shorter than any other page in the section, when clean URLs are used. This is to prevent section index pages from having links to themselves.

* `site/index.html` → 0
* `site/foo/index.html` → 0 (sic!)
* `site/foo/bar.html` → 1

### HTML manipulation

#### delete_element

The opposite of `insert_html`. Deletes an element that matches a selector. It can be useful in two situations:

Another widget may leave an element empty and you want to clean it up.
Your pages are generated with another tool and it inserts something you don’t want.

```toml
# Who reads footers anyway?
[widgets.delete_footer]
  widget = "delete_element"
  selector = "#footer"
```

You can limit it to deleting only empty elements with `only_if_empty = true`. Element is considered empty if there’s nothing but whitespace inside it.

It’s possible to delete only the first element matching a selector by adding `delete_all = false` to its config.

#### wrap

The `wrap` widget wraps an element or elements into a "wrapper snippet". For example, this configuration will transform the `<main>` element
of every page into `<div class="main-wrapper"> <main /> </div>`.

```toml
[widgets.wrap-main]
  widget = "wrap"
  wrapper = """ <div class="main-wrapper"> """
  #wrapper_selector = "div.main-wrapper"
  selector = "main"
  wrap_all = true
```

By default it will wrap every element that matches the `selector`, but you can make it wrap only the first one with `wrap_all = false`.

##### Wrapper selectors

If there are multiple HTML elements in the wrapper snippet, it’s impossible to automatically decide where to insert the content.
However, if there’s only one element, then asking the user to specify where to insert is redundant and annoying.
Soupault solves it with a `wrapper_selector` parameter.

If your wrapper snippet has only one element, like `<div class="main-wrapper">`, then you can safely omit the `wrapper_selector` option.

Soupault will check the element count in the wrapper snippet. Iff it has exactly one element, then it just inserts the content into it.
If not, it checks whether a `wrapper_selector` is specified.

If you don’t specify it, you will get an error like this:

```
[ERROR] Could not process page site/reference-manual.md: the wrapper has more then one child element but the wrapper selector is not specified
```

Example: wrap all `<article>` elements in `<div class="article-outer"> <div class="article-wrapper" /> </div>`.

```toml
[widgets.wrap-articles]
  widget = "wrap"
  wrapper = """ <div class="article-outer"> <div class="article-wrapper">  </div> </div> """
  wrapper_selector = "div.article-wrapper"
  selector = "article"
  wrap_all = true
```

If the snippet does not have an element matching the `wrapper_selector`, the build will fail. If there are multiple elements that match the selector,
then soupault will pick the first one.

#### relative_links

The `relative_links` widget adjusts internal links to account for their depth in the directory tree
to allow hosting the website in any location on the web server.

This is helpful if you want to use a tilde URL for your website, like `https://example.com/~jrandomhacker`,
or host generated pages in a subdirectory of your main site.

Suppose you have this in your `templates/main.html`:
`<img src="/header.png">`. Then in `about/index.html` that element will be rewritten as `<img src="../header.png">`; in `books/magnetic-fields/index.html`
it will be `<img src="../../header.png">` and so on.

Default configuration:

```toml
[widgets.relativize]
  widget = "relative_links"
  check_file = false
  exclude_target_regex = '^((([a-zA-Z0-9]+):)|#|\.|//)'
```

The default regex is meant to exclude links that are either:

* External links with a URI schema (`(([a-zA-Z0-9]+):)`).
* Links to anchors within the same page (`#`, like `#top`).
* Hand-made relative links (`\.`, like `./about`).
* Protocol-relative URLs (`//`, like `//example.com`).

If you want to narrow the scope down, you can use the `only_target_regex` option instead.
For example, with `only_target_regex = '^/[a-zA-Z0-9]'`, it will only rewrite links like `/style.css`.

The `check_file` option is helpful is you have pages with unmarked relative links, e.g. there’s `about/index.html`
with `<img src="selfie.jpg">` in it, and also `about/selfie.jpg` file. Arguably, it would be a good idea to use
`<img src="./selfie.jpg">` to make it explicit where the file is, but it may be impractical to modify all old pages
just to be able to use this widget.

In that case you can set `check_file = true` and this widget will rewrite such links only if there is no such file
in the directory with the page.

#### absolute_links

This widget is prepends a prefix to every internal link. A polar opposite of the `relative-links` widget.

Similar to the `site URL` option in other static site generators, except it applies to all relative links
in all pages, not only to links generated by soupault itself.

Sample configuration:

```toml
[widgets.absolutize]
  widget = "absolute_links"
  prefix = "https://example.com/~jrandomhacker"
```

A prefix can be simply a directory, a URI schema or a host address is not required.

This widget supports all options of the [`relative_links`](#relative_links) widget.


## Plugins

Since version 1.2, soupault can be extended with Lua plugins.

The supported language is Lua 2.5, not modern Lua 5.x. That means no closures and no for loops in particular.
Here's a copy of the [Lua 2.5 reference manual](https://github.com/lindig/lua-ml/blob/master/doc/lua-2.5-refman.pdf).

On the other hand, soupault supports some things still impossible in the "real" PUC-Rio Lua implementation,
like [ordered iteration](#Table.iter_ordered) and iterating over table with non-consecutive numeric keys.

Plugins are treated like widgets and configured the same way.

You can find ready to use plugins in the [Plugins](/plugins) section on this site.

###  Installing plugins

#### Plugin discovery

By default, soupault looks for plugins in the `plugins/` directory. Suppose you want to use the [Site URL](/plugins/#site-url) plugin. To use that plugin, save it to `plugins/site-url.lua`.

Then a widget named `site-url` will automatically become available. The `site_url` option from the widget config will be accessible to the plugin as `config["site_url"]`.

```toml
[widgets.absolute-urls]
  widget = "site-url"
  site_url = "https://www.example.com"
```

You can specify multiple plugin directories using the `plugin_dirs` option under `[settings]`:

```toml
[settings]
  plugin_dirs = ["plugins", "/usr/share/soupault/plugins"]
```

If a file with the same name is found in multiple directories, soupault will use the file from the first directory in the list.

You can also disable plugin discovery and load all plugins explicitly.

```toml
[settings]
  plugin_discovery = false
```

#### Explicit plugin loading

You can always load plugins explicitly, whether plugin discovery is enabled or not. This can be useful if you want to:

* load a plugin from an unusual directory
* give the plugin widget your own name
* replace a built-in widget with a plugin

Suppose you want the widget of `site-url.lua` to be named `absolute-links`. Add this snippet to `soupault.conf`:

```toml
[plugins.absolute-links]
  file = "plugins/site-url.lua"
```

It will register the plugin as a widget named `absolute-links`.

Then you can use it like any other widget. Plugin subtable name becomes the name of the widget, in our case `absolute-links`.

```toml
[widgets.make-urls-absolute]
  widget = "absolute-links"
  site_url = "https://www.example.com"
```

Alternatively, you can add inline Lua plugins to your config using the `lua_source` option:

```toml
[plugins.trivial-plugin]
  lua_source = 'Plugin.exit("this plugin cannot do much")'
```

If you want to write your own plugins, read on.

### Plugin example

Here’s the source of that Site URL plugin that converts relative links to absolute URLs by prepending a site URL to them:

```lua
-- Converts relative links to absolute URLs
-- e.g. "/about" -> "https://www.example.com/about"

-- Get the URL from the widget config
site_url = config["site_url"]

if not Regex.match(site_url, "(.*)/$") then
  site_url = site_url .. "/"
end

links = HTML.select(page, "a")

-- Lua array indices start from 1
local index = 1
while links[index] do
  link = links[index]
  href = HTML.get_attribute(link, "href")
  if href then
    -- Check if URL schema is present
    if not Regex.match(href, "^([a-zA-Z0-9]+):") then
      -- Remove leading slashes
      href = Regex.replace(href, "^/*", "")
      href = site_url .. href
      HTML.set_attribute(link, "href", href)
    end
  end
  index = index + 1
end
```

In short:

* Widget options can be retrieved from the `config` table.
* The element tree of the page is in the `page` variable. You can think of it as an equivalent of `document` in JavaScript.
* `HTML.select()` function is like `document.querySelectorAll` in JS.
* The `HTML` module provides an API somewhat similar to the DOM API in browsers, though it’s procedural rather than object-oriented.

### Plugin environment

Plugins have access to the following global variables:

<dl>
  <dt>page</dt>
  <dd>The page element tree that can be manipulated with functions from the HTML module.</dd>
  <dt>page_file</dt>
  <dd>Page file path, e.g. site/index.html</dd>
  <dt>target_dir</dt>
  <dd>The directory where the page file will be saved, e.g. build/about/.</dd> 
  <dt>nav_path</dt>
  <dd>A list of strings representing the logical <term>navigation path</term>. For example, for site/foo/bar/quux.html it’s <code>["foo", "bar"]</code>.</dd>
  <dt>page_url</dt>
  <dd>Relative page URL, e.g. /articles or /articles/index.html, depending on the <code>clean_urls</code> setting.</dd>
  <dt>config</dt>
  <dd>A table with widget config options.</dd>
  <dt>soupault_config</dt>
  <dd>The global soupault config (deserialized contents of <code>soupault.conf</code>).</dd>
  <dt>site_index</dt>
  <dd>Site index data structure.</dd>
  <dt>site_dir, build_dir</dt>
  <dd>Convenience variables for the corresponding config options.</dd>
  <dt>persistent_data</dt>
  <dd>A table for values supposed to be persistent between different plugin runs (since 3.2.0).</dd>
</dl>

<h4 id="plugin-persistent-data">Persistent data</h4>

All of these variables _except for `persistent_data`_ are injected into the interpreter environment every time a plugin is executed.
If you modify their values, it will only affect the instance of the plugin that is currently running. When soupault finishes processing the current page
and moves on to a new page, the plugin will start in a clean environment.

The `persistent_data` variable is an exception. On soupault startup, its value is set to an empty table.
When a plugin finishes running, soupault will retrieve it from the Lua interpreter state and pass it to the next plugin run.
This can be used to avoid running some expensive calculations more than once, or for gathering data from all pages.

### Plugin API

<module name="HTML">

##### Document parsing, creation, and formatting

###### <function>HTML.parse(string)</function>

Example: `h = HTML.parse("<p>hello world<p>")`

Parses a string into an HTML element tree.

Note that this function never signals any parse errors. Just like web browsers,
it will try to make some sense even out of the most patently invalid HTML
and correct errors as much as it can.

For best results, make sure that your HTML is valid, since invalid HTML
may silently produce unexpected behavior.

###### <function>HTML.create_document()</function>

Creates an empty HTML element tree root.

Example: `doc = HTML.create_document()`

###### <function>HTML.clone_document(html)</function>

Creates a full copy of an HTML document element tree.

###### <function>HTML.to_string(html)</function>

Converts an HTML element tree to HTML source, without adding any whitespace.

###### <function>HTML.pretty_print(html)</function>

Converts an HTML element tree to HTML source and adds whitespace for readability.

##### Element creation and destructuring

###### <function>HTML.create_text(string)</function>

Example: `h = HTML.create_text("hello world")`

Creates a text node that can be inserted into the page just like element nodes.
This function automatically escapes all HTML special characters inside the string. 

###### <function>HTML.create_element(tag, text)</function>

Example: `h = HTML.create_element("p", "hello world")`

Creates an HTML element node. The text argument can be `nil`,
so you can safely omit it and write something like
`h = HTML.create_element("hr")`.

###### <function>HTML.inner_html(html)</function>

Example: `h = HTML.inner_html(HTML.select(page, "body"))`

Returns element content as a string.

###### <function>HTML.strip_tags(html)</function>

Example: `h = HTML.strip_tags(HTML.select(page, "body"))`

Returns element content as a string, with all HTML tags removed.

##### Element tree queries

###### <function>HTML.select(html, selector)</function>

Example: `links = HTML.select(page, "a")`

Returns a list of elements that match `selector`.
The `html` argument can be either a document or an element node.

###### <function>HTML.select_one(html, selector)</function>

Example: `content_div = HTML.select(page, "div#content")`

Returns the first element that matches `selector`, or `nil` if none are found.

###### <function>HTML.select_any_of(html, selectors)</function>

Example: `link_or_pic = HTML.select_any_of(page, {"a", "img"})`

Returns the first element that matches any of specified selectors.

###### <function>HTML.select_all_of(html, selectors)</function>

Example: `links_and_pics = HTML.select_all_of(page, {"a", "img"})`

Returns all elements that match any of specified selectors.

##### Checking if elements would match selectors

###### <function>HTML.matches_selector(document, elem, selector)</function>

Example: `HTML.matches_selector(page, (HTML.select_one(page, "body")), "body")`

Checks if an element node matches given selector.

The `elem` value must be an element node retrieved from an `document` with a function from the `HTML.select_*` family.

The reason you need to give that function both parent document and child element values is that
otherwise composite selectors like `div > p` wouldn’t work.

###### <function>HTML.matches_any_of_selectors(document, elem, selectors)</function>

Like `HTML.matches_selector`, but allows checking against a list of selectors
and returns true if any of them would match.

##### Access to surrounding elements

###### <function>HTML.parent(elem)</function>

Returns element’s parent.

Example: if there’s an element that has a `<blink>` in it, insert a warning just before that element.

```lua
blink_elem = HTML.select_one(page, "blink")
if elem then
  parent = HTML.parent(blink_elem)
  warning = HTML.create_element("p", "Warning: blink element ahead!")
  HTML.insert_before(parent, warning)
end
```

###### <function>HTML.children(elem)</function>
###### <function>HTML.ancestors(elem)</function>
###### <function>HTML.descendants(elem)</function>
###### <function>HTML.siblings(elem)</function>

Example: add `class="silly-class"` to every element inside the page `<body>`.

```lua
body = HTML.select_one(page, "body")
children = HTML.children(body)

function add_silly_class(e)
  if HTML.is_element(children[i]) then
    HTML.add_class(children[i], "silly-class")
  end
end

Table.iter_values(add_silly_class, children)
```

###### <function>HTML.child_count(elem)</function>

Returns the number of element’s children (handy for checking if it has any).

##### Tag and attribute manipulation

###### <function>HTML.is_element</function>

Web browsers provide a narrower API than general purpose HTML parsers. In the JavaScript DOM API, `element.children` provides access to all _child elements_ of an element.

However, in the HTML parse tree, the picture is more complex. Text nodes are also child nodes—browsers just filter those out because JavaScript code rarely has a need to do anything with text nodes.

Consider this HTML: `<p>This is a <em>great</em> paragraph</p>`. How many children does the `<p>` element have? In fact, three: `text("This is a ")`, `element("em", "great")`, `text(" paragraph")`.

The goal of soupault is to allow modifying HTML pages in any imaginable way, so it cannot ignore this complexity.
Many operations like `HTML.add_class` still make no sense for text nodes, so there has to be a way to check if something is an element or not.

That’s where `HTML.is_element` comes in handy.

###### <function>HTML.get_tag_name(html_element)</function>

Returns the tag name of an element.

Example: 

```lua
link_or_pic = HTML.select_any_of(page, {"a", "img"})
tag_name = HTML.get_tag_name(link_of_pic)
```

###### <function>HTML.set_tag_name(html_element)</function>

Changes the tag name of an element.

Example: ”modernize” `<blink>` elements by converting them to `<span class="blink">`.

```lua
blinks = HTML.select(page, "blink")

local i = 1
while blinks[i] do
  elem = blinks[i]
  HTML.set_tag_name(elem, "span")
  HTML.add_class(elem, "blink")

  i = i + 1
end
```

###### <function>HTML.get_attribute(html_element, attribute)</function>

Example: `href = HTML.get_attribute(link, "href")`

Returns the value of an element attribute. The first argument must be an element reference produced by `HTML.select_one` or another function.

If the attribute is missing, it returns `nil`. If the attribute is present but its value is empty (like in `<elem attr="">` or `<elem attr>`), it returns an empty string.
In Lua, both empty strings and `nil` are false for the purpose of `if value then … end`, so if you want to check for presence of an attribute regardless of its value, you should explicitly check for `nil`.

###### <function>HTML.set_attribute(html_element, attribute, value)</function>

Example: `HTML.set_attribute(content_div, "id", "content")`

Sets an attribute value.

###### <function>HTML.delete_attribute(html_element, attribute)</function>

Example: `HTML.delete_attribute(content_div, "id")`

Removes an attribute.

###### <function>HTML.classes(html_element)</function>

If an element has `class` attribute, returns a list (i.e. a number-indexed table) of its classes.

###### <function>HTML.add_class(html_element, class_name)</function>

Example: `HTML.add_class(p, "centered")`

Adds a new class. If an element has no classes, adds a `class` attribute in the process.

###### <function>HTML.has_class(html_element, class_name)</function>

Returns true is an element has given class.

###### <function>HTML.remove_class(html_element, class_name)</function>

Example: `HTML.remove_class(p, "centered")`

###### <function>HTML.list_attributes(html_element)</function>

Returns a list (i.e. a number-indexed table) with names of all attributes of an element.

###### <function>HTML.clear_attributes(html_element)</function>

Removes all attributes from an element.

##### Element tree modification

###### <function>HTML.append_root(parent, child)</function>

Adds a child node at the end of an HTML document element tree.

###### <function>HTML.append_child(parent, child)</function>
###### <function>HTML.prepend_child(parent, child)</function>

These functions insert the `child` element after the last or before the first child element of the `parent`.

Example: `HTML.append_child(page, HTML.create_element("br"))`

###### <function>HTML.insert_before(old, new)</function>
###### <function>HTML.insert_after(old, new)</function>

Insert the `new` element right before or after the `old` element.
The `old` value must be an element reference obtained with `HTML.select`/`HTML.select_one`.

Example:

```lua
-- Insert HTML5 <header> and <footer> elements
-- before and after <main>

main = HTML.select_one(page, "main")

header = HTML.create_element("header", "This is a header")
footer = HTML.create_element("footer", "This is a footer")

HTML.insert_before(main, header)
HTML.insert_after(main, footer)
```

###### <function>HTML.replace_content(parent, child)</function>

Deletes all existing children of the `parent` element and inserts the `child` element in their place.

###### <function>HTML.delete(element)</function>

Example: `HTML.delete(HTML.select_one(page, "h1"))`

Deletes an element from the page.

###### <function>HTML.delete_content(element)</function>

Deletes all children of an element (but leaves the element itself in place).

###### <function>HTML.clone_content(html_element)</function>

Creates a new HTML element tree object from the content of an element.

Useful for duplicating an element elsewhere in the page.
Since `HTML.select` and friends return _references_ to elements within the `page` tree.
To create a new element _value_ that can be independently modified, you need to clone an element
using this function.

##### Convenience functions

###### <function>HTML.unwrap(element)</function>

Removes the element and inserts its former children in its place.

###### <function>HTML.get_heading_level(element)</function>

For elements whose tag name matches `<h[1-9]>` pattern, returns the heading level.

Returns zero for elements whose tag name doesn’t look like a heading and for values that aren’t HTML elements.

###### <function>HTML.get_headings_tree(element)</function>

Returns a table that represents the tree of HTML document headings in a format like this:

```
[
  {
    "heading": ...,
    "children": [
      {"heading": ..., "children": []}
    ]
  },
  {"heading": ..., "children": []}
]
```

Values of `heading` fields are HTML element references. Perfect for those who want to implement their own ToC generator.

##### Behaviour

If an element tree access function cannot find any elements (e.g. there are no elements that match a selector), it returns `nil`.

If a function that expects an HTML element receives `nil`, it immediately returns `nil`,
so you don’t need to check for `nil` at every step and can safely chain calls to those functions<fn id="maybe-monad">If it sounds like a Maybe monad to you, internally it is.</fn>.

</module>

<module name="Regex">
Regular expressions used by this module are mostly Perl-compatible. However, capturing groups and back references are not supported.

##### <function>Regex.match(string, regex)</function>

Example: `Regex.match("/foo/bar", "^/")`

Checks if a string matches a regex.


##### <function>Regex.find_all(string, regex)</function>

Example: `matches = Regex.find_all("/foo/bar", "([a-z]+)")`

Returns a list of substrings matching a regex.

##### <function>Regex.replace(string, regex, string)</function>

Example: `s = Regex.replace("/foo/bar", "^/", "")`

Replaces the first matching substring. It returns a new string and doesn’t modify the original.

##### <function>Regex.replace_all(string, regex, string)</function>

Example: `Regex.replace_all("/foo/bar", "/", "")`

Replaces every matching substring. It returns a new string and doesn’t modify the original.

##### <function>Regex.split(string, regex)</function>

Example: `substrings = Regex.split("foo/bar", "/")`

Splits a string at a separator.

</module>

<module name="String">

##### <function>String.length(string)</function>

Returns string length, in UTF-8 characters.

That is, `String.length("строка")` is 6; and `String.length("日本語")` is 3.

For strings that contain invalid Unicode characters, it behaves like `String.length_ascii()`
and measures their length in bytes instead.

##### <function>String.length_ascii(string)</function>

Returns the count of bytes in the string. That is, `String.length("строка")` is 12
and `String.length("日本語")` is 9.

##### <function>String.trim(string)</function>

Example: `String.trim(" my string ")` produces `"my string"`

Removes leading and trailing whitespace from the string.

##### <function>String.truncate(string, length)</function>

Returns the first `length` characters of the string, counting in UTF-8 characters.

For strings that contain invalid Unicode characters, it behaves like `String.truncate_ascii`
and returns the first `length` _bytes_ instead.

##### <function>String.truncate_ascii(string, length)</function>

Returns the first `length` bytes of the string.

##### <function>String.slugify_soft(string)</function>

Replaces all whitespace in the string with hyphens to make it a valid HTML id.

##### <function>String.slugify_ascii(string)</function>

Example: `String.slugify_ascii("My Heading")` produces `"my-heading"`

Replaces all characters other than English letters and digits with hyphens, exactly like the ToC widget.

##### <function>String.truncate(string, length)</function>

Truncates a string to a given length.

Example: `String.truncate("foobar", 3)` produces `"foo"`.

##### <function>String.to_number(string)</function>

Example: `String.to_number("2.7")` produces `2.7` (float).

Converts strings to numbers. Returns `nil` is a string isn’t a valid representation of a number.

##### <function>String.join(separator, list)</function>

Concatenates a list of strings.

Example: `String.join(" ", {"hello", "world"})`.

##### <function>String.render_template(template_string, env)</function>

Renders data using a <term>jingoo</term> template.

Example:

```lua
env = {}
env["greeting"] = "hello"
env["addressee"] = "world"
s = String.render_template("{{greeting}} {{addressee}}", env)
```

##### <function>String.base64_encode</function>

Encodes a string in Base64.

##### <function>String.base64_decode</function>

Decodes Base64 data.

</module>

<module name="Sys">

##### <function>Sys.read_file(path)</function>

Example: `Sys.read_file("site/index.html")`

Reads a file into a string. The path is relative to the working directory.

##### <function>Sys.write_file(file_path, data)</function>

Writes data to a file. If a file doesn’t exist, it will be created.
If a file already exists, it will be overwritten.

##### <function>Sys.delete_file(path)</function>

Deletes a file.

##### <function>Sys.delete_recursive(path)</function>

Deletes a file or a directory recursively.

##### <function>Sys.get_file_size(file_path)</function>

Returns file size in bytes. Returns `nil` if it cannot read the file
(whether because it doesn’t exist or due to permission errors).

##### <function>Sys.file_exists(file_path)</function>

Checks if a file exists.

##### <function>Sys.is_file(file_path)</function>

Checks if a path is a regular file (not a directory). Returns `nil` if the file path does not exist at all.

##### <function>Sys.get_file_modification_date(file_path)

Returns the UNIX timestamp of the moment when the file was last modified.

##### <function>Sys.is_dir(file_path)</function>

Checks if a path is a directory. Returns `nil` if the file path does not exist at all.

##### <function>Sys.mkdir(path)</function>

Creates a directory. If a path is several directories deep,
and some are missing, creates them as needed (like `mkdir -p`).

##### <function>Sys.list_dir(path)</function>

Lists all files (normal files and directories), if `path` is a directory.

If `path` points to a file rather than a directory, fails with an error.
Always check the path with `Sys.is_dir` beforehand!

##### <function>Sys.get_extension(file_path)</function>

Returns the file extension, if it has one. For files without an extension it returns an empty string.
For files with multiple extensions like `.tar.bz2`, returns the last extension.

Examples:

* `"cat.jpg" → "jpg"`
* `"/bin/bash" → ""`
* `"soupault.tar.gz" → "gz"`

##### <function>Sys.get_extensions(file_path)</function>

Returns a list with all extensions of the file, or an empty list if the file has no extensions.

* `"/bin/bash" → {}`
* `"cat.jpg → {"jpg"}`
* `"soupault.tar.gz" → {"tar", "gz"}`

##### <function>Sys.has_extension(file_path, extension)</function>

Check if the file at `file_path` has `extension`.

For example, `Sys.has_extension("file.tar.gz", "tar")` is true,
and `Sys.has_extension("file.tar.gz", "gz")` is also true.

##### <function>Sys.basename(file_path)</function>

Returns the base name of a path (its file name part), e.g. `"/usr/local/bin/soupault" → "soupault"`.

##### <function>Sys.dirname(file_path)</function>

Returns the directory name of a path, e.g. `"/usr/local/bin/soupault" → "/usr/local/bin"`.


##### <function>Sys.join_path(left, right)</function>

Joins two file paths, using a correct, OS-specific separator.
E.g. `Sys.join_path("directory", "file")` will produce `directory/file` on UNIX, but `directory\file` on Windows.

**Note:** This function **will not** replace existing separators in its arguments.

You also **should not** use this function for concatenating _URLs_, at least not when using soupault on Windows.

##### <function>Sys.run_program(command)</function>
##### <function>Sys.run_program_get_exit_code(command)</function>

Executes given command in the <term>system shell</term>.
Returns 1 (sic!) on success, `nil` on failure, so that `if Sys.run_program(...)` statements work as expected.

The output of the command is ignored. If command fails, its stderr is logged.

Example: create a silly file in the directory where generated page will be stored.

```lua
res = Sys.run_program(format("echo \"Kilroy was here\" > %s/graffiti", target_dir))
if not res then
  Log.warning("Damn, busted")
end
```

The intended use case for it is creating and processing assets, e.g. converting images to different formats.

There’s also `Sys.run_program_get_exit_code` that does the same, but returns the raw exit code (0 on success).

##### <function>Sys.get_program_output(command)</function>

Executes a command in the system shell and returns its output.

If the command fails, it returns `nil`. The stderr is shown in the execution log, but there’s no way a plugin can access its stderr or the exit code.

Example: getting the last modification date of a page from git.

```lua
git_command = "git log -n 1 --pretty=format:%ad --date=format:%Y-%m-%d -- " .. page_file
timestamp = Sys.get_program_output(git_command)

if not timestamp then
  timestamp = "1970-01-01"
end
```

##### <function>Sys.random(max)</function>

Example: `Sys.ranrom(1000)`

Generates a random number from 0 to `max`.

##### <function>Sys.is_unix()</function>

Returns true on UNIX-like systems (Linux, Mac OS, BSDs), false otherwise.

##### <function>Sys.is_windows()</function>

Returns true on Microsoft Windows, false otherwise.

</module>

<module name="Plugin">
Provides functions for communicating with the plugin runner code.

##### <function>Plugin.fail(message)</function>

Example: `Plugin.fail("Error occured")`

Stops plugin execution immediately and signals an error. Errors raised this way are treated as widget processing errors by soupault, for the purpose of the `strict` option.

##### <function>Plugin.exit(message)</function>

Example: `Plugin.exit("Nothing to do"`), `Plugin.exit()`

Stops plugin execution immediately. The message is optional. This kind of termination is not considered an error by soupault.

##### <function>Plugin.require_version(version_string)</function>

Example: `Plugin.require_version("1.8.0")`

Stops plugin execution if soupault is older than the required version.
You can use a full version like `1.9.0` or a short version like `1.9`. This function was introduced in 1.8, so plugins that use it will fail to work in 1.7 and older. 

##### <function>Plugin.soupault_version()</function>

Returns soupault version string (e.g. `"2.2.0"`).

</module>

<module name="Log">

##### <function>Log.debug(message)</function>

Displayed with a `[DEBUG]` prefix when `debug` under `[settings]` is `true`.

##### <function>Log.info(message)</function>

Displayed with an `[INFO]` prefix if `verbose` or `debug` is true.

##### <function>Log.warning(message)</function>

##### <function>Log.error(message)</function>

These levels are always on and cannot be silenced.

</module>

<module name="JSON">

Provides JSON parsing and printing functions.

##### <function>JSON.from_string(string)</function>

Parses a JSON string and returns a table. Fails plugin execution if `string` isn’t syntactically correct JSON data.

##### <function>JSON.unsafe_from_string(string)</function>

Same as `JSON.from_string`, but returns `nil` on parse errors. Parse error message is logged (warning level).

Note that there are valid JSON strings that parse to `nil` (e.g. `"null"`), so `nil` doesn’t always mean a parse error.

##### <function>JSON.to_string(value)</function>

Converts a Lua value to JSON. The value doesn’t have to be a table, any value will work.

It produces minified JSON.

##### <function>JSON.pretty_print(value)</function>

Same as `JSON.to_string` but produces human-readable, indented JSON.

</module>

<module name="TOML">

Provides TOML parsing functions. This module doesn’t provide TOML <em>printing</em>
because TOML has a richer type system than Lua, and thus parsing it into a Lua table
erases a lot of type information. For debugging purposes, you can use `JSON.pretty_print` instead.

##### <function>TOML.from_string(string)</function>

Parses a TOML string and returns a table. Fails plugin execution if `string` isn’t a syntactically correct TOML document.

##### <function>TOML.unsafe_from_string(string)</function>

Same as `TOML.from_string`, but returns `nil` on parse errors. Parse error message is logged (warning level).

</module>

<module name="YAML">

Provides YAML parsing functions. Doesn’t provide any printing functions as of now.
For debugging purposes, you can use `JSON.pretty_print` instead.

##### <function>YAML.from_string(string)</function>

Parses a YAML string and returns a table. Fails plugin execution if `string` isn’t a syntactically correct TOML document.

##### <function>YAML.unsafe_from_string(string)</function>

Same as `YAML.from_string`, but returns `nil` on parse errors. Parse error message is logged (warning level).

</module>

<module name="Date">

##### <function>Date.now_timestamp()</function>

Returns a UNIX timestamp (seconds passed since 1970-01-01 00:00 UTC).

##### <function>Date.now_format(fmt)</function>

Returns as a string representation of the current datetime in UTC.

Example: `Date.now_format("%Y-%m-%d %H:%M")`

##### <function>Date.to_timestamp(date_string, input_formats)</function>

Converts a datetime string to a UNIX timestamp, using a list of allowed datetime formats.

Returns `nil` if none of the formats match the datetime string.

Example: `Date.to_timestamp("2006-08-16", {"%Y-%m-%d"})`

##### <function>Date.reformat(date_string, input_formats, output_format)</function>

Parses and reformats a datetime string.

Example: `Date.reformat("2007-06-23", {"%Y-%m-%d", "%d.%m.%Y"}, "%Y/%d/%m")`

</module>

<module name="Table">

##### <function>Table.has_key(table, key)</function>

Returns `nil` if and only if `table` does not have a field `key`. 

Why is this function needed? There are two possible reasons why `if my_table["some_key"] then` may not be true:

* `my_table` does not have a field named `some_key`.
* `my_table` has a field `some_key` but its truth value is false (e.g. `""` or `0`).

This functions tells you for certain.

##### <function>Table.get_key_default(table, key, default_value)</function>

Returns `table[key]` if the table has that key, otherwise returns the `default_value`.

##### <function>Table.keys(table)</function>

Returns a list of all keys found in `table`.

##### <function>Table.has_value(table, value)</function>

Returns true if any of the keys in the table is associated with `value`.

##### <function>Table.iter(func, table)</function>

Executes a function `func(key, value)` for every item in a table, in an arbitrary order.

Example:

```lua
my_table = {}
my_table["foo"] = 0
my_table["bar"] = "quux"
my_table["baz"] = {1,2}

function show_pair(k, v)
  Log.debug(format("Key: %s, value: %s", k, JSON.to_string(v)))
end

Table.iter(show_pair, my_table)
```

##### <function>Table.iter_values(func, table)</function>

Executes a function `func(value)` for every `(key, value)` pair in a table.
Handy for iterating over tables where keys don’t have any real meaning.

##### <function>Table.iter_ordered(func, table)</function>

##### <function>Table.iter_values_ordered(func, table)</function>

Like `Table.iter` and `Table.iter_values`, but respect the ordering of keys.

These functions first get a list of all keys in a table, then sort it (in ascending order), and then
loop through that list. See the following pseudo-code for the basic idea:

```
def iter_ordered(func, tbl):
  keys = get_table_keys(tbl)
  keys = sort(keys)
  for k in keys:
    f(tbl[k])
```

Comparing keys of different type is undefined behavior. As of now, it will not cause an error, but will result
in arbitrary ordering.

##### <function>Table.fold(func, table, initial_value)</function>

[Folds](https://en.wikipedia.org/wiki/Fold_%28higher-order_function%29) a table using a `func(key, value, accumulator)` function.

Since tables are not ordered collections, the question whether it’s a left or right fold is meaningless:
you should make sure that your operation is commutative.

##### <function>Table.fold_values(func, table, initial_value)</function>

Folds a table using a `func(value, accumulator)` function.

##### <function>Table.apply(func, table)</function>

Applies `func(key, value)` to every table item, in place. That is, executes `table[key] = func(key, value)` for every key.

Can be seen as an imperative equivalent of [map](https://en.wikipedia.org/wiki/Map_(higher-order_function)).

Since assigning `nil` to a field is equivalent to deleting that field from a table, this function can be used as an in-place filter too.

##### <function>Table.apply_to_values(func, table)</function>

Much like `Table.apply`, but takes a unary function `func(value)` and applies it to every value in the table.

##### <function>Table.find_values(func, table)</function>

Takes a table and a function `func(v)`, and returns a list of values for which `func(v)` is not `nil`.

Does not modify the table.

##### <function>Table.take(table, count)</function>

Remove the first `count` items from the table and return them as a list.

##### <function>Table.chunks(table, size)</function>

Splits the table into a list of chunks of up to `size` items.

</module>

<module name="Value">

Contains functions for working with Lua values in ways Lua never intended.

##### <function>Value.is_nil(value)</function>

Returns true if `value` is `nil`.

##### <function>Value.is_int(value)</function>

Returns true if `value` is an integer number.

##### <function>Value.is_float(value)</function>

Returns true if `value` is a number. Integers are considered a subset of floats,
so it returns true for integers.

##### <function>Value.is_string(value)</function>

Returns true if `value` is a string.

##### <function>Value.is_table(value)</function>

Returns true if `value` is a table.

##### <function>Value.is_list(value)</function>

Returns true if `value` is a table whose every key is an integer number.

</module>

## Page processing hooks

Page processing hooks allow Lua code to run between processing steps of replace them.

They have access to the same API functions as plugins, but their execution environments
are somewhat different and depend on specific hook.

Hooks are configured in the `hooks` table. The following hooks are supported as of soupault 4.0.0:
`pre-parse`, `pre-process`, `post-index`, `render`, `save`.

Like widget subtables, hook subtables can contain arbitrary options.

There can be only one hook of each type.

Hook source code can be given inline using `lua_source` option or loaded from a file
using the `file` option, just like with plugins.
There is no automatic discovery for hooks, they must always be configured explicitly.

Like widgets, hooks can be limited to a subset of pages using any <term>limiting option</term>.

<h3 id="hooks-pre-parse">Pre-parse</h3>

The `pre-parse` hook runs on the page source before it’s parsed into an HTML element tree.

It has the following variables in its environment:

* `page_source` — the page text.
* `page_file` — path to the page source file.
* `config` (aka `hook_config`) — the hook config table.
* `soupault_config` — the complete soupault config.
* `force` — true when soupault is called with `--force` option, plugins are free to interpret it.
* `site_dir` — the value from `settings.site_dir` or the `--site-dir` option if present.

For example, this website uses a pre-parse hook to globally replace the `$SOUPAULT_RELEASE$` string
with the latest soupault release version from custom options.

```toml
[hooks.pre-parse]
  lua_source = '''
    soupault_release = soupault_config["custom_options"]["latest_soupault_version"]
    Log.debug("running pre-parse hook")
    page_source = Regex.replace_all(page_source, "\\$SOUPAULT_RELEASE\\$", soupault_release)
  '''
```

<h3 id="hooks-pre-process">Pre-process</h3>

The `pre-process` hook runs after the page is parsed, but before any widgets or index extraction have run.

It has the following variables in its environment:

* `page` — the element tree of the page.
* `page_file` — path to the page source file.
* `target_file` — full path to the output file for the generated page.
* `target_dir` — path to the generated page output directory.
* `config` (aka `hook_config`) — the hook config table.
* `soupault_config` — the complete soupault config.
* `force` — true when soupault is called with `--force` option, plugins are free to interpret it.
* `site_dir` — the value from `settings.site_dir` or the `--site-dir` option if present.
* `build_dir` — the output directory from `settings.build_dir` or the `--build-dir` option if present.

Soupault takes back the following variables:

* `page`
* `target_file`
* `target_dir`

This means you can adjust not only the element tree of the page, but also change the output path for it.

For example, here’s a rudimentary implementation of a "multilingual site" with a single non-default
language:

```toml
[hooks.pre-process]
  lang_extension = "fr"

  lua_source = '''
    lang_extension = config["lang_extension"]
    if Sys.has_extension(page_file, lang_extension) then
      -- Remove the language extension from the path, wherever it is,
      -- e.g. "build/test.fr/index.html" → "build/test/index.html"
      target_file = Regex.replace(target_file, "\\." .. lang_extension, "")

      -- Extract the directory part for further mangling
      target_dir = Sys.dirname(target_file)  

      -- Get the part without the build dir,
      -- e.g. "build/test/index.html" → "test/index.html"
      target_dir_end = Sys.basename(target_dir)

      -- Add the language prefix to the dir,
      -- e.g. "build/" → "build/fr/"
      target_dir_start = Sys.join_path(build_dir, lang_extension)

      -- Join it all together into "build/fr/test/index.html"
      target_dir = Sys.join_path(target_dir_start, target_dir_end)
      target_file = Sys.join_path(target_dir, Sys.basename(target_file))
    end
  '''
```

<h3 id="hooks-post-index">Post-index</h3>

The `post-index` hook runs after index extraction and can modify index fields.

It has the following variables in its environment:

* `index_fields` — a table with page’s index entry.
* `page` — the element tree of the page.
* `page_url` — page URL relative to the site root.
* `page_file` — path to the page source file.
* `target_file` — full path to the output file for the generated page.
* `target_dir` — path to the generated page output directory.
* `config` (aka `hook_config`) — the hook config table.
* `soupault_config` — the complete soupault config.
* `force` — true when soupault is called with `--force` option, plugins are free to interpret it.
* `site_dir` — the value from `settings.site_dir` or the `--site-dir` option if present.
* `build_dir` — the output directory from `settings.build_dir` or the `--build-dir` option if present.

The following variables are taken back by soupault:

* `index_fields`
* `page`

For example, if you store post tags like `<tags>foo, bar, baz</tags>`, you can convert tag strings to lists
using this hook:

```toml
[hooks.post-index]
  lua_source = '''
     -- Split tags strings like "foo, bar" into lists
     -- to make life easier for the Atom plugin and the indexer
     if Value.is_string(index_fields["tags"]) then
       tags = Regex.split(index_fields["tags"], ",")
       Table.apply_to_values(String.trim, tags)
     index_fields["tags"] = tags
    end
  '''
```

<h3 id="hooks-render">Render</h3>

The `render` hook, if present, runs _instead of_ the built-in page rendering functionality.

It has the following variables in its environment:

* `index_fields` — a table with page’s index entry.
* `page` — the element tree of the page.
* `page_url` — page URL relative to the site root.
* `page_file` — path to the page source file.
* `target_file` — full path to the output file for the generated page.
* `target_dir` — path to the generated page output directory.
* `config` (aka `hook_config`) — the hook config table.
* `soupault_config` — the complete soupault config.
* `force` — true when soupault is called with `--force` option, plugins are free to interpret it.
* `site_dir` — the value from `settings.site_dir` or the `--site-dir` option if present.
* `build_dir` — the output directory from `settings.build_dir` or the `--build-dir` option if present.

Soupault takes back the following variables:

* `page_source` — string representation of the page element tree.

For example, this is how you simply pretty-print the page:

```toml
[hooks.render]
  page_source = HTML.pretty_print(page)
```

<h3 id="hooks-save">Save</h3>

The `save` hook runs _instead of_ the build-in generated page file output functionality.

It has the following variables in its environment:

* `page_source` — rendered HTML.
* `page_url` — page URL relative to the site root.
* `page_file` — path to the page source file.
* `target_file` — full path to the output file for the generated page.
* `target_dir` — path to the generated page output directory.
* `config` (aka `hook_config`) — the hook config table.
* `soupault_config` — the complete soupault config.
* `force` — true when soupault is called with `--force` option, plugins are free to interpret it.
* `site_dir` — the value from `settings.site_dir` or the `--site-dir` option if present.
* `build_dir` — the output directory from `settings.build_dir` or the `--build-dir` option if present.

For a trivial example, here’s how to just write the HTML to the default output file:

```toml
[hooks.save]
  lua_source = '''
    Sys.write_file(page_source, target_file)
  '''
```


## Glossary

<hr>

<glossary>
  <definition name="system shell">
    <code>/bin/sh</code> on UNIX, <code>cmd.exe</code> on Microsoft Windows.
  </definition>
  <definition name="site directory">
    The directory where page and asset source files are stored. By default it’s <code>site/</code>.
    You can change it with <code>site_dir</code> option under <code>[settings]</code>.
  </definition>
  <definition name="navigation path">
    Logical navigation path for the page. For example, for <code>site/papers/programming/goto-considered-harmful.html</code>
    it’s <code>[papers, programming]</code>.
  </definition>
  <definition name="limiting option">
    Many configuration items like widgets and index views can be limited to specific pages. Using <code>page, section, path_regex</code> options
    you can enable something only for some pages. Using <code>exclude_page, exclude_section, exclude_path_regex</code> options, you can enable
    something for all pages except some. You can also combine those options. All those options take a single string or a list of strings.
    Examples: <code>page = ["foo.html", "bar.html"]</code>, <code>section = "blog/"</code>, <code>exclude_path_regex = '^(.*)/index\.html$'</code>.
    <br>
    Please note that by default the <code>section</code> option applies <em>only</em> to the directory itself. That is, if you have <code>section = "poems"</code> in a widget,
    it will apply to <code>poems/georgia.html</code>, but not to <code>poems/soupault/georgia.html</code>.
    <br>
    If you want a widget to apply to a directory and its subdirectories, add <code>include_subsections = true</code>.
  </definition>
  <definition name="action">
    Action defines what to do with the content. In inclusion widgets (<code>include</code>, <code>insert_html</code>, <code>exec</code>, <code>preprocess_element</code>)
    it’s defined by the <code>action</code> option,  in <code>[settings]</code> it’s <code>default_content_action</code>, and in custom templates it’s <code>content_action</code>.
    <br>
    Its possible values are: <code>prepend_child</code>, <code>append_child</code>, <code>insert_before</code>, <code>insert_after</code>,
    <code>replace_content</code>, <code>replace_element</code>.
  </definition>
  <definition name="jingoo">
    A logic-aware template processor with syntax and capabilities similar to Jinja2. You can find the details in its
    <a href="http://tategakibunko.github.io/jingoo/templates/templates.en.html">documentation</a>.
  </definition>
  <!-- If we get to use these definitions, we’ll know the development has gone too far. -->
  <definition name="CHIM">The secret syllable of royalty.</definition>
  <definition name="AASR">Ancient and Accepted Scottish Rite.</definition>
  <definition name="tao">The tao that can be told is not the true Tao.</definition>
</glossary>

<hr>

<div id="footnotes"> </div>

</div> <!-- refman-main -->
</div> <!-- refman -->
