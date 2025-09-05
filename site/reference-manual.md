<div id="refman">

<div id="refman-sidebar">
  <div id="generated-toc"> </div>
</div>
<div id="refman-main">

# Reference manual

This manual applies to soupault $SOUPAULT_RELEASE.
Earlier versions may not support some of the features described here and may have different configuration syntax.

If you are running soupault older than $SOUPAULT_RELEASE, consider upgrading to the latest version.

## Installation

### Binary release packages

Soupault is distributed as a single, self-contained executable, so installing it from a binary release package it trivial.

You can download it from [files.baturin.org/software/soupault](https://files.baturin.org/software/soupault) or from [GitHub releases](https://github.com/PataphysicalSociety/soupault/releases).
Prebuilt executables are available for Linux (x86-64 and Aarch64, statically linked), macOS (x86-64), and Microsoft Windows (64-bit).

Just unpack the archive and copy the executable to a target directory.

Prebuilt executables are compiled with debug symbols. It makes them a couple of megabytes larger than they could be, but you can get better error messages if something goes wrong.
If you encounter an internal error, you can run `soupault --debug` to enable detailed logging and exception traces.

###  Building from source

Soupault is written in the [OCaml](https://ocaml.org) programming language, so you will need the OCaml toolchain
to build it. The best way to install the toolchain and build dependencies is to use [opam](https://ocaml.org/docs/installing-ocaml),
the OCaml package manager.

Since version 1.6, soupault is available from the [opam](https://opam.ocaml.org) repository. If you already have opam installed, you can install it with `opam install soupault`.

If you want the latest development version, the git repository is at [github.com/PataphysicalSociety/soupault](https://github.com/PataphysicalSociety/soupault).
There is also a Codeberg mirror at [codeberg.org/PataphysicalSociety/soupault](https://codeberg.org/PataphysicalSociety/soupault).

#### Building static executables for Linux

Official soupault executables for Linux are statically linked so that they can work on any distro.
That is achieved by linking them with [musl](http://musl.libc.org/) rather than GNU libc,
because GNU libc is not designed to produce truly statically linked binaries (even when compiled with `-static`,
executables linked with GNU libc may try to dynamically load shared libraries).

OCaml uses GNU libc on Linux by default,
so to replicate official releases, you need to create an opam switch with musl and static linking enabled.

Suppose you want to build soupault with OCaml 5.2.0 (the latest as of October 2024). You will need the following commands:

```
# Install dependencies, for Fedora (or recent RHEL/CentOS Stream):
sudo dnf install musl-gcc musl-libc-static

# Install dependencies, for Debian:
sudo apt install musl musl-dev musl-tools

# Create an OCaml installation that uses musl-based runtime
opam switch create 5.2.0-musl ocaml-variants.5.2.0+options ocaml-option-musl ocaml-option-static
opam switch 5.2.0-musl
```

Then use the `static` dune profile for your build command:

```
dune build --profile=static
```

###  Using soupault on Windows

Windows is a supported platform and soupault includes some fixups to account for the differences between UNIX-like systems and Windows.

This document makes a UNIX cultural assumption throughout, but most of the time the same configs will work on both systems. Some differences, however, require user intervention to resolve.

If a file path is only used by soupault itself, then the UNIX convention will work. For example, `file = 'templates/header.html'` and `file = 'templates\header.html'` are both valid options for the [`include`](#include-widget) widget when running soupault on Windows.

However, if a path is passed to an external program, then you must use the Windows convention with backslashes.
This applies, for example, to [page preprocessors](#page-preprocessors), the `command` option of the [`exec`](#exec-widget) widget, and [external index processors](#external-index-processor).

So, if you are on Windows, remember to adjust the paths if needed. For example:

```toml
[widgets.some-script]
  widget = 'exec'
  command = 'scripts\myscript.bat'
  selector = 'body'
```

Note that inside double quotes, the backslash is an escape character, so you should either use single quotes for such paths (`'scripts\myscript.bat'`) or use a double backslash (`"scripts\\myscript.bat"`).

#### ANSI colors

Since soupault 5.0.0, ANSI colors are enabled by default in the output. Windows Terminal supports them out of the box,
so if you are using Windows Terminal, logs should be more easily readable for you now.

If you are using an older built-in terminal for `cmd.exe` or PowerShell, you can either enable ANSI colors
in them in Windows settings or disable coloring in soupault using the `NO_COLOR` environment variable.

## Overview

Soupault has two distinct modes: the _website generator mode_ and the _HTML processor mode_.

In the website generator mode (the default), soupault takes a page "template" — an HTML file devoid of content, parses it into an element tree,
and locates the content container element inside it (defined by the `settings.default_content_selector` option).

By default, the content container is `<body>`, but you can use any selector, for example: `div#content` (a `<div id="content">` element),
`article` (the HTML5 `<article>` element), `#post` (any element with `id="post"`) or any other valid CSS selector.

Then it traverses your site directory where page source files are stored (by default, `site`), takes a page file, and parses it into an HTML element tree too.
If the file is not a complete HTML document (doesn not have an `<html>` element in it), soupault inserts it into the content container element of the template.
If it is a complete page, then it goes straight to the next step.

The new HTML tree is then passed to widgets — HTML rewriting modules that manipulate it in different ways.
Widgets can be built-in or can be implemented by plugins.

Soupault may also [extract metadata from the website](#metadata-extraction-and-rendering), if that feature is enabled.
Unlike most static site generators, soupault doesn't use front matter and doesn't have a built-in content model,
but allows you to extract metadata from HTML itself and map content model fields to CSS selectors.
It can then render that metadata using a template, a Lua plugin, or an external helper.

Processed pages are then written to disk, into a directory structure that normally mirrors your source directory structure,
although you can also tell it to use a different path, using the [pre-process hook](#hooks-pre-process).

## Basic configuration

Very few soupault settings are fixed, and most can be changed in the configuration file.

These are the settings from the default config that `soupault --init` generates.

<pre> <code class="language-toml" id="default-config"> </code> </pre>

Note that if you create a `soupault.toml` file before running `soupault --init`, it will not overwrite that file.

In this document, whenever a specific site or build dir has to be mentioned, we will use their default values: `site_dir` and `build_dir`.

If you misspell an option, soupault will notify you about it and try to suggest a correction.

Soupault attempts to convert value types in a manner similar to many dynamically typed programming languages
like Perl and UNIX shells. For example, `settings.debug = true` and `settings.debug = 1` will both work.

### Logging options

By default, soupault will only log warnings and errors. However, its philosophy is that the user should be able to get as much insight into the build process as possible.

It provides two settings for controlling the log level: `settings.verbose` and `settings.debug`. By default, both are false.

```toml
[settings]
    verbose = false
    debug = false
```

It is also possible to control the log level from the command line, by running `soupault --verbose` or `soupault --debug`.

With `verbose = true`, soupault logs detailed build progress: what pages are being processed, what widgets run on them, and so on.

With `debug = true`, it will also include the details of what it's doing: it will tell why it's not running certain widgets,
display the input and output of external commands, etc.

### HTML output options

By default, soupault pretty-prints HTML in an attempt to make it more readable. If you want to keep the original formatting,
you can disable pretty-printing:

```toml
[settings]
    pretty_print_html = false
```

Soupault will also keep the original document type declaration, if it's present. If it's not, it will automatically
add the HTML5 docype (`<!DOCTYPE html>`). However, you can change that: for example, force the HTML 4.01 doctype
for all pages:

```toml
[settings]
    keep_doctype = false
    doctype = '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/strict.dtd">'
```

### Custom directory layouts

If you are using soupault as an HTML processor, or using it as a part of a CI pipeline, typical website generator approach with a single "project directory" may not be optimal.

You can override the location of the config using an environment variable `SOUPAULT_CONFIG`.
You can also override the locations of the source and destination directories with `--site-dir` and `--build-dir` options.

Thus it is possible to run soupault without a dedicated project directory at all:

```shell-session
$ SOUPAULT_CONFIG="mysite.toml" soupault --site-dir some-input-dir --build-dir some-other-dir
```

Since 4.2.0, it is also possible to specify the config location using a command line option (`--config`) instead of an environment variable.
That is especially useful on Windows, where there is no easy way to set an environment variable
for a single command invocation:

```shell-session
C:\> soupault --config mysite.toml --site-dir some-input-dir --build-dir some-other-dir
```

### Ignoring files and directories

If you want to ignore certain paths inside the site directory (e.g., exclude auxilliary directories created by third-party tools),
you can use either `settings.ignore_directories` option to exclude a list of directories with all their subdirectories,
or use `settings.ignore_path_regexes` to ignore arbitraty patterns.
Those options are not mutually exclusive and you can use them both at the same time:

```toml
[settings]
  # Ignore specific directories
  ignore_directories = ["images", "videos"]

  # Ignore all directories that start with a dot, like ".hidden"
  ignore_path_regexes = ["^\.(.*)"]
```

You can also ignore all files with certain extensions.

```toml
[settings]
  # Ignore draft files like foo.html.draft
  ignore_extensions = ["draft"]
```

### Caching

Starting from 4.4.0, soupault supports caching the output of [page preprocessors](#page-preprocessors)
and commands called by [preprocess_element](#preprocess-element-widget) widgets.

If you use external preprocessors extensively, it can make repeated builds a few times faster.

This is the implicit default configuration:

```toml
[settings]
  # Enable caching
  caching = true

  # Optionally, change the cache directory
  # The default is `.soupault-cache`
  cache_directory = ".soupault-cache"
```

Since soupault 4.5.0, you can also completely disable caching even if it is enabled in the config:
if you run `soupault --no-caching`, it will not attempt to create the cache directory
or cache any outputs.

Soupault creates a subdirectory in the cache for each page to associate cached objects with their sources.
When a page source file changes, its sub-cache is automatically invalidated and cleared,
so in most cases you do not need to worry about stale cache
or about the cache directory getting bloated with unused data.

However, there are situations when the cache can become stale in ways that soupault will not detect automatically:

* When you change the `[preprocessors]` section or a `preprocess_element` widget config.
* When you update external tools and their new versions produce different outputs.

In those cases, you can force cache invalidation and eviction by running `soupault --force`.
With that option, soupault will delete the cache directory and build everything from scratch.

Note that [asset processor](#asset-processing) outputs are not cached.
That is because asset processor output file name is controlled by the user (or the command), not by soupault.

Future versions may extend that configuration syntax to allow asset caching.
For now, if you need an advanced asset pipeline, you may want to use an external tool instead.

## Asset processing

By default, soupault simply copies non-page files unchanged. However, it is possible to run them through external tools instead,
such as image optimizers, Sass/Less/etc. compilers, and similar tools.

Example: running all `*.png` files through [pngcrush](https://pmt.sourceforge.io/pngcrush/) — a popular PNG optimizer.

```toml
[asset_processors]
  png = "pngcrush {{source_file_path}} {{target_dir}}/{{source_file_name}}"

```

The value is a <term>Jingoo</term> template. There are following variables in the template environment:

* `source_file_path` — full path to the source files (like `site/pictures/cat.png`).
* `source_file_name` — name of the input file without the directory part (like `cat.png`).
* `source_file_base_name` — name of the input file without extensions (like `cat`).
* `target_dir` — output directory path.

## Character encoding

By default, soupault assumes that all pages are stored in <wikipedia>UTF-8</wikipedia>.
However, if your website uses a different encoding and you have reasons to keep it that way,
you can specify the encoding explicitly.

```toml
[settings]
  page_character_encoding = 'utf-8'
```

The following encodings are supported: `ascii`, `iso-8859-1`, `windows-1251`, `windows-1252`, `utf-8`,
`utf-16`, `utf-16le`, `utf-16be`, `utf-32le`, `utf-32be`, and `ebcdic`.
You can write those options in either upper or lower case (e.g., `UTF-16LE`, `UTF-16le`, and `utf-16le`
are equally acceptable).

## Page processing

### Page templates

In soupault's terminology, a page template is simply an HTML file without content — an empty page. Soupault does not use a template processor for assembling pages,
instead it injects the content into the element tree. This way any empty HTML page can serve as a soupault "theme".

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

It i possible to use multiple templates. However, note that additional templates *must* be limited to specific pagesusing a <term>limiting option</term>!

You also cannot omit the default template. This is because there is no reliable way to sort templates and content selectors by "specificity".

Without an explicit default template, soupault would have to guess what template to use for pages that do not match any of the custom templates, and there is no way to guess it in a way that would satisfy every user's needs.

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

With default settings, soupault will look for page files in `site/`.

Files in the <term>site directory</term> can be treated as pages or assets, depending on their extension.

Asset files are copied to the build directory unchanged or processed using [asset processors](#asset-processing).

Page files are converted to HTML if needed, parsed into element trees, processed,
and written to the <term>build directory</term>.

### Page file extensions

The `page_file_extensions` option defines which files are treated as pages. This is the default setting:

```toml
[settings]
  page_file_extensions = ["html", "htm"]
```

By default, pages are assumed to be HTML files that can be parsed directly into element trees.
However, you can also store pages in different formats and tell soupault how to convert them to HTML
before parding.

### Built-in Markdown support

Since 5.0.0, soupault includes a built-in Markdown processor. It's based on [Cmarkit](https://erratique.ch/software/cmarkit)
and implements [CommonMark](https://spec.commonmark.org/)
and some [common extensions](https://erratique.ch/software/cmarkit/doc/Cmarkit/index.html#extensions).

The default config generated by `soupault --init` now enables built-in Markdown support for all `*.md` files:

```toml
[settings]
  markdown_extensions = ["md"]
```

However, if `settings.markdown_extensions` is not in the config or is set to an empty list,
then built-in Markdown processing is disabled. That is to allow the user to choose whether to use
the built-in implementation or an external [page preprocessor](#page-preprocessors) of their choice.

Extensions from that list are implicitly added to `settings.page_file_extensions`,
so you do not have to add them to that list by hand.

It is also possible to import pages in any format using page preprocessors.

### Page preprocessors

Soupault allows you to specify external preprocessor programs to convert other formats to HTML,
so you can bring your own Markdown processor (e.g., pandoc) if you want to
or store pages in completely arbitrary formats, as long as there's a convertor to HTML for it
(reStructuredText, AsciiDoc, LaTeX via latex2html — your imagination is the limit).

A preprocessor program *must* take a page file as an argument and *must* write generated HTML to standard output.

For example, this configuration will make soupault preprocess Markdown files with [cmark](https://github.com/commonmark/cmark).

```toml
[preprocessors]
  md = "cmark --unsafe --smart"
```

**NOTE:** Since soupault 5.0.0, files with extensions that have page preprocessors associated with them
are automatically considered page files. You no longer have to add them to `settings.page_file_extensions`
by hand — they will be added to that list implicitly (and you can see that in `soupault --show-effective-config`).

Preprocessor commands are executed in the <term>system shell</term>, so it is fine to use relative paths and specify command arguments. Page file name is appended to the command string.
For example, with the above config, when soupault processes `site/about.md`, it will run `cmark --unsafe --smart site/about.md` and read the standard output of that process.

**NOTE:** if a page has an extension listed in `settings.markdown_extensions`, soupault will immediately process it
with the built-in Markdown implementation and will *not* try to find a preprocessor for it.
If you want to an external processor for some other Markdown flavor, use different extensions for them.

### Partial and complete pages

Soupault allows you to have pages with a unique, non-templated layout even in generator mode.
If a page has an `<html>` element in it, it is assumed to be a complete page.

Complete pages are exempt from templating, they are only parsed and processed by widgets.

If a page does not have an `<html>` element in it, its content is inserted in a page template first.

Note that the selector used to check for "completeness" is a configurable option:

```toml
[settings]
  complete_page_selector = "html"
```

### Clean URLs

Soupault uses <wikipedia>clean URLs</wikipedia> by default. If you add a page to `site/`, for example, `site/about.html`, it will turn into `build/about/index.html` so that it can be accessed as `https://mysite.example.com/about`.

Index files are simply copied to the target directory.

* `site/index.html` → `build/index.html`
* `site/about.html` → `build/about/index.html`
* `site/papers/theorems-for-free.html` → `build/papers/theorems-for-free/index.html`

Note: if you add a page file `foo.html` and a section directory named `foo/`, soupault makes no guarantees about its conflict resolution behavior. Just do not do that.

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

If you have had a website for a long time and there are links to your pages that will break if you change the URLs, you can make soupault mirror your site directory structure exactly and preserve original file names.

Just add `clean_urls = false` to the `[settings]` section of your `soupault.conf` file.

```toml
[settings]
  clean_urls = false
```

### Soupault as an HTML processor

By default, soupault assumes that you want to assemble pages from content files and HTML templates.
However, you can also use it as a post-processor for existing HTML pages, whether handwritten or generated by other tools.

Technically, you don't need to do anything special to use soupault this way because it always checks
if a file is a [complete HTML page](/#partial-and-complete-pages) and skips the templating step if it is.
The only problem is that you'd still have to provide a template file that would never actually be used.

If you don't want to use the templating functionality for any pages, you can set `settings.generator_mode = false`.
In that case, soupault will switch to the post-processor mode where it assumes that all pages are complete pages
and doesn't require the `default_template` option.

Recommended settings for the HTML processor mode:

```toml
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

Soupault can extract metadata from pages using CSS selectors, similar to what web scrapers are doing. This is more flexible than "front matter",
and allows you to automatically generate index pages for existing websites, without having to edit their pages.

What you do with extracted metadata is up to you. You can simply export it to JSON for further processing, like generating an RSS/Atom feed,
or creating taxonomy pages with an external script. Or you can tell soupault to generate HTML from the index data. You can also combine both approaches.

Metadata extraction is always enabled in the webgenerator mode but disabled in the HTML processor mode.
### Index settings

These are the basic settings and their default values:

```toml
[index]
  # Which index field to use as a sorting key.
  # There is no default because there’s no built-in content model: it’s up to you.
  # sort_by =

  # By default entries are sorted in descending order.
  # This means if you sort by date, newest entries come first.
  sort_descending = true

  # There are three supported ways to sort entries.
  #
  # In the "calendar" mode, soupault will try to parse field values as dates
  # according to the date_formats option (see below).
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
  date_formats = ["%F"]

  # By default, soupault will require valid values for "calendar" and "numeric" sorting
  # If a value is invalid, it’s assumed to be "less" than any valid value.
  # Two invalid values are compared lexicographically as strings.
  #
  # However, you can make if fail the build if it encounters invalid values using this option:
  strict_sort = false

  # Whether to always strip HTML tags from field data
  # You can also enable that for individual fields.
  # The default is false.
  strip_tags = false

  # If you want widget outputs to serve as index data inputs,
  # you can schedule those widgets to run before metadata extraction.
  # extract_after_widgets = []
```

### Index fields

Soupault does not have a built-in "content model". Instead, it allows you to define what to extract from pages,
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

The "selector" field is either a single CSS selector or a list of selectors that define what to extract
from the page. Here, `selector = ["p#post-excerpt", "p"]` means "use `p#post-excerpt` for the excerpt,
but if there’s no such element, just use the first paragraph".

By default, soupault will extract only the first element, but you can change that with `select_all = true`.

You can also set the default value with `default` option (only for fields without `select_all = true`).

As you can see from the `date` field definition, it is possible to make soupault extract an attribute of an element
rather than its content. The `fallback_to_content` option defines what soupault will do if an element has
no such attribute. With `fallback_to_content = true` it will extract the element content instead.
If it is false, it will leave the field undefined.

It is also possible to strip HTML tags from specific fields by setting `strip_tags = true` in the field configuration.

### Built-in index fields

Soupault provides technical metadata of the page in these built-in fields:

<dl>
  <dt>url</dt>
  <dd>Absolute page URL path, like <code>/papers/simple-imperative-polymorphism</code> (or <code>/papers/simple-imperative-polymorphism.html</code>, if clean URLs are disabled)</dd>
  <dt>nav_path</dt>
  <dd>A list of strings that represents the logical section path. E.g., for <code>site/pictures/cats/grumpy.html</code> it will be <code>["pictures", "cats"]</code>.</dd> 
  <dt>page_file</dt>
  <dd>Page source file path (like <code>site/about.md</code>).</dd>
</dl>

### Index views

Soupault can insert HTML rendered from site metadata into the site index pages. By default those are pages named `index.*`.

The way index data is rendered is defined by "index views". You can have any number of views.

Which view is used is determined by the `index_selector` option. It’s possible to use multiple views on the same page,
e.g. if you want to display lists of posts grouped by date and by author.

#### Ways to control index rendering

There are four ways to render index data:

* `index_item_template` — a <term>jingoo</term> template for an individual item, applied to each index data entry.
* `index_template` — a jingoo template for the entire index (get a list of entries and iterate through it yourself).
* `index_processor` — path to an external script that receives index data (in JSON) from stdin and writes HTML to stdout.
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
    <h2><a href="{{e.url}}">{{e.title}}</a></h2>
    <p><strong>Last update:</strong> {{e.date}}.</p>
    <p><strong>Reading time:</strong> {{e.reading_time}}.</p>
    <p>{{e.excerpt}}</p>
    <a href="{{e.url}}">Read more</a>
    {% endfor %}
  """
```

#### External index processor

If you have a favorite programming language or a favorite template processor and want to handle site index rendering with it,
you can call an external program with `index_processor = /path/to/script`. The value is actually a shell command,
so you can also specify arguments.

Soupault will send a JSON representation of the site index data to the script's stdin and expects HTML source in the stdout.

The index data format is the same as what you get when [exporting site index to JSON](#exporting-metadata-to-json).
Use the `index.dump_json` option and inspect the output to get familiar with that format.

#### Lua index processor

Finally, if you want total control over the process, you can write an index processor in Lua. The most important advantage
of Lua index processors is that they can generate new pages and inject them in the processing queue.

For example, here is a reimplementation of the built-in `index_template` behavior in Lua, but with a twist:
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

As you can see, generated pages are stored in the `pages` variable. When an index processor finishes, soupault
extracts that variable from its environment and adds generated pages to the page processing queue.

The `pages` variable must be a table, and its items must be tables with `page_file` and `page_content` fields.

The `page_file` field is the file path where the page _would have been if it was hand-written_.
Most of the time you will want to generate it with `Sys.join_path(Sys.dirname(page_file), "page_name.html")`
to make it appear in the same directory as the index page being processed, but there are no restrictions:
you can use any path and place the generated page in any section.

The `page_content` must be a _string representation_ of the page, that you can make with `HTML.to_string` or `HTML.pretty_print` functions.
This is because generated pages are treated exactly like pages that actually exist on disk, and need to be parsed.

Soupault will automatically prevent autogenerated pages from generating more pages so this functionality is unlikely to cause infinite loops or fork bombs.

### Index view options

By default, soupault will render an index of the current section, e.g., `site/blog/index.html` page will display an index of all pages in the
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

Since 4.7.0, it is possible to limit the number of displayed items with.

```toml
[index.views.main-page-news]
  # Display up to ten entries on the main page
  max_items = 10
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

### Treating index pages as normal pages

Since soupault can transform normal pages to clean URLs by itself, normally it is best to keep a logical site structure: directory = section, file = page, and leave creation of clean URLs to the software.

However, sometimes creating a degenerate section by hand is a sensible thing to do. One use case is bundling a page with its assets.
Suppose you are making a page with a lot of photos, and those photos are not going to be used by any other page.
In that case, placing those photos in a shared asset directory will only make it harder to remember or find what pages they are used by, and will make all links to those images longer.
Storing them in a directory with the page offers the easiest mental model.

Using the `force_indexing_path_regex` option in the `[index]` table, you can make soupault treat some pages as normal pages even though their files are named `index.*`.
This can be helpful if you only have a few such pages, or they all follow a predictable pattern that you can match with a regex.

If you want to be able to mark any directory as a "leaf" (hand-made clean URL), there is another way: the `index.leaf_file` option.
Suppose you set `leaf_file = ".leaf"`. In that case, when soupault finds a directory that has files named `index.html` and `.leaf`, it treats `index.html` as a normal page and extracts metadata from it.

There is no default value for the `leaf_file`, you need to set it explicitly if you want it.

### Exporting metadata to JSON

You can export the site index data to a JSON file and process it with external scripts —
for example, to generate a feed.

JSON export is disabled by default and needs to be enabled explicitly:

```toml
[index]
  dump_json = "path/to/file.json"
```

## Widgets

Soupault has built-in widgets for deleting specific HTML elements, including files into pages,
setting page title and more. 

### Widget behaviour

Widgets that require a selector option first check if there’s an element matching that selector in the page.
If there is no such element, they do nothing, since they would not have a place to insert their output anyway.

Thus, the simplest way to ensure a widget does not run on a particular page is to make sure that page does not
have its target element.

If a page has more than one element matching the same selector, the first element is used as widget's target.

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

It is also possible to explicitly exclude pages or sections.

```toml
[widgets.toc]
  # Don’t add a TOC to the main page
  exclude_page = "index.html"
  # ...

[widgets.evil-analytics]
  exclude_section = "privacy"
  # ...
```

#### Using regular expressions

When nothing else helps, `path_regex` and `exclude_path_regex` options may solve your problem. They take a Perl-compatible regular expression (not a glob).

```toml
[widgets.toc]
  # Don’t add a TOC to any section index page
  exclude_path_regex = '^(.*)/index\.html$'
  # ...

[widgets.cat-picture]
  path_regex = 'cats/'
```

### Widget processing order

The order of widgets in your config file does not determine their processing order. By default, soupault assumes that widgets are independent and can be processed in arbitrary order.
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
  # ...

## Remove div#breadcrumbs if the breadcrumbs widget left it empty
[widgets.cleanup-breadcrumbs]
  widget = "delete_element"
  selector = "#breadcrumbs"
  only_if_empty = true

  # Important!
  after = "add-breadcrumbs"
  # ...
```

<h3 id="build-profiles">Limiting widgets to build profiles</h3>

Sometimes you may want to enable certain widgets only for some builds. For example, include analytics scripts only in production builds. It can be done with build profiles.

For example, this way you can only include `includes/analytics.html` file in your pages when the build profile is set to `live`:

```toml
[widgets.analytics]
  profile = "live"
  widget = "include"
  file = "includes/analytics.html"
  selector = "body"
```

Soupault will only process that widget if you run `soupault --profile live`. If you run `soupault --profile dev`, or run it without the `--profile` option, it will ignore that widget.

Since soupault 2.7.0, it is possible to specify more than one build profile. For example, if you run `soupault --profile foo --profile bar`, it will enable both `foo` and `bar` profiles
and their associated widgets.

### Disabling widgets

Since soupault 2.7.0, it is possible to disable a widget by adding `disabled = true` to its config.

## Built-in widgets

###  File and output inclusion

These widgets include something into your page: a file, a snippet, or output of an external program.

<h4 id="inclusion-widget-parse-options">HTML parsing options</h4>

All widgets in this family can either parse the received data as HTML and include it in the element tree,
or simply include it as text.

The default behavior is to parse it. If you want to include the data as text, set the `parse` option to `false`.

```toml
parse = false
```

You can also specify an _HTML parsing context_. In most cases that is not necessary — soupault can infer the context.
But in rare cases, you may need to specify it to prevent the HTML parser from attempting to correct the HTML.
For example, a fragment that starts with `<link rel="stylesheet" href="...">` is not valid for an HTML `<body>`,
and the parser may mangle it to make it valid. If you want to include a fragment in the `<head>`,
that behavior would be wrong.

You can prevent that by telling soupault what tag your fragment is for:

```toml
parse = true
html_context = "head"
```

You can technically specify any tag name in that option, although only a few have a real effect,
such as `body`, `head`, `table`, or `math`.

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

  # There're no HTML tags in the output of `date -R`
  # so there's no reason to parse it as HTML
  parse = false

  # Set to "unix" or "windows" if you want the widget
  # to run only on specific operating systems
  # os_family = 
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

  # Prevent the widget from mangling preformatted text
  parse = false

  # Set to "unix" or "windows" if you want the widget
  # to run only on specific operating systems
  # os_family = 
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

This is how you can include page's own source into a page, on a UNIX-like system:

```toml
[widgets.page-source]
  widget = "exec"
  selector = "#page-source"
  parse = false
  command = "cat $PAGE_FILE"
```

If you store your pages in git, you can get a page timestamp from the git log with a similar method (note that it is not a very fast operation for long commit histories):

```toml
[widgets.last-modified]
  widget = "exec"
  selector = "#git-timestamp"
  command = "git log -n 1 --pretty=format:%ad --date=format:%Y-%m-%d -- $PAGE_FILE"
```

The `PAGE_FILE` variable can be used in many different ways, for example, you can use it to fetch the page author and modification date from a revision control system like git or mercurial.

The `TARGET_DIR` variable is useful for scripts that modify or create page assets.
For example, this snippet will create PNG images from Graphviz graphs inside `<pre class="graphviz-png">` elements and replace those `<pre>`'s with relative links to images.

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

Attempting to wait for soupault to read your program's output before it finishes reading soupault's input
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

The `selector` option can be a list. For example, `selector = ["h1", "h2", "#title"]` means 'use the first `<h1>` if the page has it, else use `<h2>`, else use anything with `id="title"`, else use default'.

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

By default, the number in front of a footnote is a hyperlink back to the original location. You can disable it and make footnotes one-way links with `back_links = false`.

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

If a heading has an `id` attribute, it will be used for the anchor. If it does not, soupault has to generate one.

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

* Another widget may leave an element empty and you want to clean it up.
* Your pages are generated with another tool and it inserts something you don't want.

```toml
# Who reads footers anyway?
[widgets.delete_footer]
  widget = "delete_element"
  selector = "#footer"
```

You can limit it to deleting only empty elements with `only_if_empty = true`. Element is considered empty if there’s nothing but whitespace inside it.

It is also possible to only delete elements that do not have certain children. For example, suppose you have a footnotes container
in the template and you want to delete it on pages where it doesn't contain any actual footnotes.
You can do it with something like `when_no_child = "p.footnote"`.

```toml
[widgets.delete_unused_footnotes_containers]
  widget = "delete_element"
  selector = "div#footnotes"
  when_no_child = "p.footnote"
```

By default, this widget removes all matching elements. It is possible to delete only the first matching element by setting `delete_all = false`.

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

If there are multiple HTML elements in the wrapper snippet, it is impossible to automatically decide where to insert the content.
However, if there is only one element, then asking the user to specify where to insert is redundant and annoying.
Soupault solves it with a `wrapper_selector` parameter.

If your wrapper snippet has only one element, like `<div class="main-wrapper">`, then you can safely omit the `wrapper_selector` option.

Soupault will check the element count in the wrapper snippet. If it has exactly one element, then it just inserts the content into it.
If not, it checks whether a `wrapper_selector` is specified.

If you do not specify it, you will get an error like this:

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

If the snippet does not have an element matching the `wrapper_selector`, the build will fail. If there are multiple elements that match the selector, then soupault will pick the first one.

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

The `check_file` option is helpful is you have pages with unmarked relative links. Suppose there is `about/index.html`
with `<img src="selfie.jpg">` in it, and also `about/selfie.jpg` file. Arguably, it would be a good idea to use
`<img src="./selfie.jpg">` to make it explicit where the file is, but it may be impractical to modify all old pages
just to be able to use this widget.

In that case you can set `check_file = true` and this widget will rewrite such links only if there is no such file
in the directory with the page.

#### element_template

This widget takes a template, renders it using data from an HTML element, and replaces the element
with the rendered template.

Its goal is to simplify creating "shortcodes". For example, suppose you want to add a shortcut
for embedding YouTube videos. You can add the following configuration:

```toml
[widgets.youtube-embed]
  widget = "element_template"
  selector = "youtube"
  template = '''
    {# Enable iframe border by default, if not given #}
    {% if not border %}
      {% set border = 1 %}
    {% endif %}

    <div class="youtube-video" style="position: relative; width: 100%; height: 0; padding-bottom: 56.25%;">
      <iframe src="https://www.youtube.com/embed/{{content}}"
        style="position: absolute; top: 0; left: 0; width: 100%; height: 100%;"
        title="{{title}}"
        frameborder="{{border}}" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
        allowfullscreen>
      </iframe>
    </div>
  '''
```

Now, suppose you want to embed "Sintel" by Blender Foundation in your page.
You only need to write `<youtube title="Sintel">eRsGyueVLvQ</youtube>` and it will be translated
to an actual YouTube embed.

In the case above, the template environment will be:

```json
{
  "title": "Sintel",
  "content": "eRsGyueVLvQ"
}
```

All element attributes are added to the environment, and the inner HTML is placed in a variable named `content`.

If you want to use an attribute called `content`, you can redefine the name of the variable that stores
element content using the `content_key` option.

Since soupault 5.1.0, this widget provides `site_index` and `index_entry` variables to templates.

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

You can find a selection of useful plugins in the [Plugins](/plugins) section on this site.

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
  <dt>target_file</dt>
  <dd>Path to the output file, relative to the current working directory.</dd>
  <dt>nav_path</dt>
  <dd>A list of strings representing the logical <term>navigation path</term>. For example, for site/foo/bar/quux.html it’s <code>["foo", "bar"]</code>.</dd>
  <dt>page_url</dt>
  <dd>Relative page URL, e.g. /articles or /articles/index.html, depending on the <code>clean_urls</code> setting.</dd>
  <dt>config</dt>
  <dd>A table with widget config options.</dd>
  <dt>soupault_config</dt>
  <dd>The global soupault config (deserialized contents of <code>soupault.toml</code>).</dd>
  <dt>site_index</dt>
  <dd>Site index data structure.</dd>
  <dt>index_entry</dt>
  <dd>The index entry of the current page.</dd>
  <dt>site_dir, build_dir</dt>
  <dd>Convenience variables for the corresponding config options.</dd>
</dl>

<h4 id="plugin-persistent-data">Persistent data</h4>

All of these variables are injected into the interpreter environment every time a plugin is executed.
If you modify their values, it will only affect the instance of the plugin that is currently running. When soupault finishes processing the current page
and moves on to a new page, the plugin will start in a clean environment.

### Plugin API

<module name="HTML">

##### Parsing and rendering

###### <function>HTML.parse(string)</function>

Example: `h = HTML.parse("<p>hello world<p>")`

Parses a string into an HTML element tree.

Note that this function never signals any parse errors. Just like web browsers,
it will try to make some sense even of the most patently invalid HTML
and correct errors as much as it can.

For best results, make sure that your HTML is valid, since invalid HTML
may silently produce unexpected behavior.

###### <function>HTML.to_string(html)</function>

Converts an HTML element tree to HTML source, without adding any whitespace.

###### <function>HTML.pretty_print(html)</function>

Converts an HTML element tree to HTML source and adds whitespace for readability.

##### Node creation

###### <function>HTML.create_document()</function>

Creates an empty HTML element tree root.

Example: `doc = HTML.create_document()`

###### <function>HTML.create_element(tag, text)</function>

Example: `h = HTML.create_element("p", "hello world")`

Creates an HTML element node. The text argument can be `nil`,
so you can safely omit it and write something like
`h = HTML.create_element("hr")`.

###### <function>HTML.create_text(string)</function>

Example: `h = HTML.create_text("hello world")`

Creates a text node that can be inserted into an element tree just like element nodes.
This function automatically escapes all HTML special characters inside the string.

##### Node cloning

###### <function>HTML.clone_document(html)</function>

Creates a full copy of an HTML document element tree.

###### <function>HTML.clone_content(html_element)</function>

Creates a new HTML element tree object from the content of an element.

Useful for duplicating an element elsewhere in the page.
Since `HTML.select` and friends return _references_ to elements within the `page` tree.
To create a new element _value_ that can be independently modified, you need to clone an element
using this function.

##### Selection and selector match checking

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

The `elem` value must be an element node retrieved from an `document` with a function from the `HTML.select_*` fami>

The reason you need to give that function both parent document and child element values is that
composite selectors like `div > p` would not work otherwise.

###### <function>HTML.matches_any_of_selectors(document, elem, selectors)</function>

Like `HTML.matches_selector`, but allows checking against a list of selectors
and returns true if any of them would match.

##### Access to element tree surroundings

###### <function>HTML.parent(elem)</function>

Returns element's parent.

Example: if there is an element that has a `<blink>` in it, insert a warning just before that element.

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

function add_silly_class(elem)
  if HTML.is_element(elem) then
    HTML.add_class(elem, "silly-class")
  end
end

Table.iter_values(add_silly_class, children)
```

###### <function>HTML.child_count(elem)</function>

Returns the number of element's children (handy for checking if it has any).

###### <function>HTML.is_empty(elem)</function> (since 4.6.0)

Returns true is `elem` has no child nodes (a shortcut for `HTML.child_cound(elem) == 0`).

##### Node tests

###### <function>HTML.is_element(node)</function> (since 4.6.0)

Returns true if `node` is an HTML element node (selected from an element tree
or created with `HTML.create_element`.

###### <function>HTML.is_text(node)</function> (since 4.11.0)

Returns	true if	`node` is a text node.

###### <function>HTML.is_document(node)</function> (since 4.6.0)

Returns	true if	`node` is an HTML document node (created by parsing HTML or with `HTML.create_document`.

###### <function>HTML.is_root(node)</function> (since 4.6.0)

Returns true if `node` is an HTML document's root node.

##### Element property access and manipulation

###### <function>HTML.get_tag_name(html_element)</function>

Returns the tag name of an element.

Example:

```lua
link_or_pic = HTML.select_any_of(page, {"a", "img"})
tag_name = HTML.get_tag_name(link_of_pic)
```

###### <function>HTML.set_tag_name(html_element)</function>

Changes the tag name of an element.

Example: "modernize" `<blink>` elements by converting them to `<span class="blink">`.

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

Returns the value of an element attribute. The first argument must be an element reference produced by `HTML.select`.

If the attribute is missing, it returns `nil`.

###### <function>HTML.set_attribute(html_element, attribute, value)</function>

Example: `HTML.set_attribute(content_div, "id", "content")`

Sets attribute value.

###### <function>HTML.append_attribute(html_element, attribute, value)</function>

Appends a string to the value of an attribute.

For example, a crude reimplementation of `HTML.add_class`: `HTML.append_attribute(content_div, "class", " green-background")`

###### <function>HTML.delete_attribute(html_element, attribute)</function>

Example: `HTML.delete_attribute(content_div, "id")`

Removes an attribute from an element.

###### <function>HTML.list_attributes(html_element)</function>

Returns a list (i.e., a number-indexed table) with names of all attributes of an element.
For example, for `<div id="content" class="green-background">`
it would return `{"id", "class"}`.

###### <function>HTML.clear_attributes(html_element)</function>

Removes all attributes from an element.

###### <function>HTML.get_classes(html_element)</function>

If an element has `class` attribute, returns a list (i.e. a number-indexed table) of its classes.

###### <function>HTML.has_class(html_element, class_name)</function>

Returns true if an element has given class.

###### <function>HTML.add_class(html_element, class_name)</function>

Example: `HTML.add_class(p, "centered")`

Adds a new class. If an element has no classes, adds a `class` attribute in the process.

###### <function>HTML.remove_class(html_element, class_name)</function>

Example: `HTML.remove_class(p, "centered")`

###### <function>HTML.inner_html(html)</function>

Example: `h = HTML.inner_html(HTML.select(page, "body"))`

Returns element content as a string.

###### <function>HTML.inner_text(html)</function>

Similar to `HTML.inner_html` but strips all tags away and returns only the text.

###### <function>HTML.strip_tags(html)</function>

Example: `h = HTML.strip_tags(HTML.select(page, "body"))`

Returns element content as a string, with all HTML tags removed.

##### Element tree manipulation

###### <function>HTML.append_root(parent, child)</function>
###### <function>HTML.prepend_root(parent, child)</function> (since 4.5.0)

Adds a child node at the beginning or at the end of an HTML document element tree, respectively.

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

###### <function>HTML.replace(orig, new)</function> (legacy name)
###### <function>HTML.replace_element(orig, new)</function> (new name, recommended)

Deletes the `orig` element from the element tree where it belongs
and inserts the `new` element in its former place.

###### <function>HTML.replace_content(parent, child)</function>

Deletes all existing children of the `parent` element and inserts the `child` element in their place.

###### <function>HTML.delete(element)</function> (legacy name)
###### <function>HTML.delete_element(element)</function> (new name, recommended)

Example: `HTML.delete(HTML.select_one(page, "h1"))`

Deletes an element from an element tree.

###### <function>HTML.delete_content(element)</function>

Deletes all children of an element (but leaves the element itself in place).

###### <function>HTML.wrap(node, elem)</function> (since 4.7.0)

Wraps `node` in `elem`.

###### <function>HTML.unwrap(element)</function> (since 4.7.0)

Removes the element and inserts its former children in its place.
For example, `<div> <p>Test!</p> </div>` will remove the outer `<div>`
and leave just `<p>Test!</p>`.

###### <function>HTML.swap(l, r)</function>

Swaps two elements in an element tree.
Element nodes `l` and `r`, obviously, must belong to the same element tree.

##### Node tests

##### High-level convenience functions

###### <function>HTML.get_heading_level(element)</function>

For elements whose tag name matches `<h[1-9]>` pattern, returns the heading level.

Returns zero for elements whose tag name doesn't look like a heading and for values that aren't HTML elements.

###### <function>HTML.get_headings_tree(element)</function>

Returns a table that represents the tree of HTML document headings in a format like this:

```json
[
  {
    "heading": "...",
    "children": [
      {"heading": "...", "children": []}
    ]
  },
  {"heading": "...", "children": []}
]
```

Values of `heading` fields are HTML element references (not clones). Perfect for those who want to implement their own ToC generator.

##### Behaviour

If an element tree access function cannot find any elements (e.g. there are no elements that match a selector), it returns `nil`.

If a function that expects an HTML element receives `nil`, it immediately returns `nil`,
so you don’t need to check for `nil` at every step and can safely chain calls to those functions<fn id="maybe-monad">If it sounds like a Maybe monad to you, internally it is.</fn>.

</module>

<module name="Regex">
Regular expressions used by this module are mostly Perl-compatible. However, capturing groups and back references are not supported yet.

##### <function>Regex.match(string, regex)</function>

Example: `Regex.match("/foo/bar", "^/")`

Checks if a string matches a regex.

##### <function>Regex.find_all(string, regex)</function>

Example: `matches = Regex.find_all("/foo/bar", "([a-z]+)")`

Returns a list of substrings matching a regex.

##### <function>Regex.replace(string, regex, string)</function>

Example: `s = Regex.replace("/foo/bar", "^/", "")`

Replaces the first matching substring. It returns a new string and does not modify the original.

##### <function>Regex.replace_all(string, regex, string)</function>

Example: `Regex.replace_all("/foo/bar", "/", "")`

Replaces every matching substring. It returns a new string and doesn’t modify the original.

##### <function>Regex.split(string, regex)</function>

Example: `substrings = Regex.split("foo/bar", "/")`

Splits a string into a list of substrings.

</module>

<module name="String">

##### <function>String.is_valid_utf8(string)</function> (since 4.6.0)

Returns true if `string` is a valid UTF-8 encoded string, false otherwise.

##### <function>String.length(string)</function>

Returns the count of UTF-8 characters in a string.

That is, `String.length("строка")` is 6; and `String.length("日本語")` is 3.

For strings that contain invalid Unicode characters, it behaves like `String.length_ascii()`
and measures their length in bytes instead.

##### <function>String.length_ascii(string)</function>

Returns the count of bytes in the string. That is, `String.length("строка")` is 12
and `String.length("日本語")` is 6.

##### <function>String.trim(string)</function>

Example: `String.trim(" my string ")` produces `"my string"`

Removes leading and trailing whitespace from the string.

##### <function>String.truncate(string, length)</function>

Returns the first `length` characters of the string, counting in UTF-8 characters.

For strings that contain invalid Unicode characters, it behaves like `String.truncate_ascii`
and returns the first `length` _bytes_ instead.

Example: `String.truncate("foobar", 3)` produces `"foo"`.

##### <function>String.truncate_ascii(string, length)</function>

Returns the first `length` bytes of the string.

##### <function>String.slugify_soft(string)</function>

Replaces all whitespace in the string with hyphens to make it a valid HTML id.

##### <function>String.slugify_ascii(string)</function>

Example: `String.slugify_ascii("My Heading")` produces `"my-heading"`

Replaces all characters other than English letters and digits with hyphens, exactly like the ToC widget.

##### <function>String.to_number(string)</function>

Example: `String.to_number("2.7")` produces `2.7` (float).

Converts strings to numbers. Returns `nil` if a string isn’t a valid representation of a number.
You can use [`Value.is_nil`](#Value.is_nil) to check is actually `nil` or just a zero (e.g. from `String.to_number("0.0")`.

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

##### <function>String.base64_encode(string)</function>

Encodes a string in Base64.

##### <function>String.base64_decode(string)</function>

Decodes Base64 data.

##### <function>String.url_encode(string)</function>

Encodes a string using URL percent-encoding as per [RFC3986](https://datatracker.ietf.org/doc/html/rfc3986).

All characters except ASCII letters, hyphens, underscores, and tildes are replaced with
percent-encoded versions (e.g. space is `%20`).

You can also supply a list of characters to _exclude_ from encoding:
`String.url_encode(string, {"?", "&"})`.

##### <function>String.url_decode(string)</function>

Decodes percent-encoded URL strings.

##### <function>String.starts_with(string, prefix)</function> (since 4.3.0)

Checks is `string` starts with `prefix`.
For example, `String.starts_with("hello", "hell")` is true
and `String.starts_with("maintenance", "fun")` is false.

##### <function>String.ends_with(string, suffix)</function> (since 4.6.0)

Like `String.starts_with`, but checks if a string ends with given suffix.

##### <function>String.lowercase_ascii(string)</function>

Converts the case of ASCII characters in a string from upper to lower.

Unicode characters outside of the ASCII range are left unchanged.

##### <function>String.uppercase_ascii(string)</function>

Converts the case of ASCII characters in a string from lower to upper.

Unicode	characters outside of the ASCII	range are left unchanged.

##### <function>String.capitalize_ascii(string)</function>

Converts the case of the first character in a string from lower to upper

Unicode	characters outside of the ASCII	range are left unchanged.

##### <function>String.uncapitalize_ascii(string)</function>

Converts the case of the first character in a string from upper to lower.

Unicode characters outside of the ASCII range are left unchanged.

</module>

<module name="Sys">

##### <function>Sys.read_file(path)</function>

Example: `Sys.read_file("site/index.html")`

Reads a file and returns its content as a string.

If the path is relative, it is considered relative to the working directory of soupault.

##### <function>Sys.write_file(path, data)</function>

Writes data to a file. If the file at `path` doesn’t exist, it will be created.
If the file already exists, it will be overwritten.

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

Checks if a path is a regular file (not a directory). Returns `nil` if it's a directory or the path does not exist at all.

##### <function>Sys.get_file_modification_date(file_path)

Returns the UNIX timestamp of the moment when the file was last modified.

##### <function>Sys.is_dir(file_path)</function>

Checks if a path is a directory. Returns `nil` if it's a file or the file path does not exist at all.

##### <function>Sys.mkdir(path)</function>

Creates a directory. If the path is several directories deep,
and some are missing, creates them as needed (like `mkdir -p`).

##### <function>Sys.list_dir(path)</function>

Lists all files (normal files and directories), if `path` is a directory.

If `path` points to a file rather than a directory, fails with an error.
Always check the path with `Sys.is_dir` beforehand!

##### <function>Sys.get_extension(file_path)</function>

Returns the last extension of the file at `path`, if it has any extensions.
For files without any extensions it returns an empty string.
For files with multiple extensions like `.tar.bz2`, it returns the last extension.

Examples:

* `"cat.jpg" → "jpg"`
* `"/bin/bash" → ""`
* `"soupault.tar.gz" → "gz"`

##### <function>Sys.get_extensions(path)</function>

Returns the list of all extensions of the file, or an empty list if the file has no extensions.

* `"/bin/bash" → {}`
* `"cat.jpg → {"jpg"}`
* `"soupault.tar.gz" → {"tar", "gz"}`

##### <function>Sys.has_extension(path, extension)</function>

Check if the file at `path` has `extension` in its list of extensions.

For example, `Sys.has_extension("file.tar.gz", "tar")` is true,
and `Sys.has_extension("file.tar.gz", "gz")` is also true.

##### <function>Sys.strip_extensions(path)</function>

Removes all extensions from a file name. For example, the result of `Sys.strip_extensions("foo.png")` is `"foo"`.

##### <function>Sys.basename(file_path)</function>

Returns the base name of a path (its file name part), e.g. `"/usr/local/bin/soupault" → "soupault"`.

This function uses OS-specific separators for splitting paths, so it should not be used for URLs,
use `Sys.basename_unix` instead.

##### <function>Sys.basename_unix(file_path)</function>

Like `Sys.basename` but uses forward slashes as path separators on all OSes, so it's safe for splitting URLs.

##### <function>Sys.basename_url(file_path)</function>

An alias for `Sys.basename_unix`.

##### <function>Sys.dirname(file_path)</function>

Returns the directory name of a path, e.g. `"/usr/local/bin/soupault" → "/usr/local/bin"`.

This function uses OS-specific separators for splitting	paths, so it should not	be used	for URLs,
use `Sys.basename_unix`	instead.

##### <function>Sys.dirname_unix(file_path)</function>

Like `Sys.dirname` but uses forward slashes as path separators on all OSes, so it's safe for splitting URLs.

##### <function>Sys.dirname_url(file_path)</function>

An alias for `Sys.dirname_unix`.

##### <function>Sys.join_path(left, right)</function>

Joins two file paths, using the path separator specific to the OS where soupault is running.
E.g. `Sys.join_path("directory", "file")` will produce `directory/file` on UNIX, but `directory\file` on Windows.

**Note:** This function **will not** replace existing separators in its arguments.

You also **should not** use this function for concatenating _URLs_, at least not when using soupault on Windows.
If you want your code to be portable, always use `Sys.join_path_unix` for concatenating URLs. 

##### <function>Sys.join_path_unix(left, right)</function>
##### <function>Sys.join_url(left, right)</function> (since 4.0.0)

These two functions are just aliases for each other.

They join two file paths, using forward slash as separator.
E.g. `Sys.join_path_unix("directory", "file")` will always produce `directory/file`, no matter which OS soupault
is running on.

Since URLs use the UNIX path convention, you should always use these functions for joining parts of a URL.
`Sys.join_path` uses _OS-specific_ path separators, so on Windows it will use back slashes and produce a broken URL. 

**Note:** Just like `Sys.join_path`, this function **will not** replace existing separators in its arguments.
Make sure that if there are path separators in your string, they are all forward slashes.

##### <function>Sys.split_path(path_str)</function> (since 4.3.0)

Splits a path into its components using OS-specific separators.

##### <function>Sys.split_path_unix(path_str)</function> (since 4.3.0)
##### <function>Sys.split_path_url(path_str)</function> (since 4.3.0)

Splits a path into its components using forward slash separator convention (safe for URLs).

##### <function>Sys.run_program(command)</function>

Executes given command in the <term>system shell</term>.
Returns 1 (sic!) on success, `nil` on failure, so that `if Sys.run_program(...)` statements work as expected.

The output of the command is ignored. If command fails, its stderr is displayed as an error-level log message.

Example: create a silly file in the directory where the currently processed page will be stored.

```lua
res = Sys.run_program(format("echo \"Kilroy was here\" > %s/graffiti", target_dir))
if not res then
  Log.warning("Damn, busted")
end
```

The intended use case for it is creating and processing assets, e.g., converting images to different formats.

##### <function>Sys.run_program_get_exit_code(command)</function>

Like `Sys.run_program`, but returns the raw exit code value (0 on success).

##### <function>Sys.get_program_output(command, input)</function>

Executes a command in the <term>system shell</term> and returns its output.

**Note:** the `input` argument is optional. When present, it must be a string — its contents will be passed to the program through its `stdin`.

If the command fails, it returns `nil`. The stderr output is displayed as an error-level log message, but there’s no way a plugin can access its stderr or the exit code.

Example: getting the last modification date of the page from git.

```lua
git_command = "git log -n 1 --pretty=format:%ad --date=format:%Y-%m-%d -- " .. page_file
timestamp = Sys.get_program_output(git_command)

if not timestamp then
  timestamp = "1970-01-01"
end
```

##### <function>Sys.random(max)</function>

Example: `Sys.random(1000)`

Generates a random number from 0 to `max`.
The RNG is seeded at soupault startup time so numbers are not completely predictable,
but it is not cryptographically secure.

##### <function>Sys.is_unix()</function>

Returns true on UNIX-like systems (Linux, macOS, BSDs), false otherwise.

##### <function>Sys.is_windows()</function>

Returns true on Microsoft Windows, false otherwise.

##### <function>Sys.getenv(name, default_value)</function> (since 4.6.0)

Returns the value of an environment variable if it's set.

If `default_value` is given, it returns that value if the variable is not set. Otherwise returns `nil`.

</module>

<module name="Plugin">
Provides functions for communicating with the plugin runner code.

##### <function>Plugin.fail(message)</function>

Example: `Plugin.fail("Error occured")`

Stops plugin execution immediately and signals an error. Errors raised this way are treated as widget processing errors by soupault, for the purpose of the `settings.strict` option
(with `settings.strict = true`, it immediately stops the build process and terminates soupault with a non-zero exit code).

##### <function>Plugin.exit(message)</function>

Example: `Plugin.exit("Nothing to do"`), `Plugin.exit()`

Stops plugin execution immediately. The message is optional. This kind of termination is not considered an error by soupault.

##### <function>Plugin.require_version(version_string)</function> (since 1.7.0)

Example: `Plugin.require_version("1.8.0")`

Stops plugin execution if soupault is older than the required version.
You can use a full version like `1.9.0` or a short version like `1.9`. This function was introduced in 1.8, so plugins that use it will fail to work in 1.7 and older. 

##### <function>Plugin.soupault_version()</function>

Returns soupault version string (e.g., `"2.2.0"`).

##### <function>Plugin.get_global_data(key)</function>

Retrieves a value from the global data table that the [startup hook](#hooks-startup) may populate.

</module>

<module name="Log">

##### <function>Log.debug(message)</function>

Displayed with `[DEBUG]` prefix when `settings.debug` is `true`.

##### <function>Log.info(message)</function>

Displayed with `[INFO]` prefix if either `settings.verbose` or `settings.debug` is true.

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

Converts a Lua value to JSON. The value does not have to be a table, any value will work.

It produces minified JSON.

##### <function>JSON.pretty_print(value)</function>

Same as `JSON.to_string` but produces human-readable, indented JSON.

</module>

<module name="TOML"> (since 3.0.0)

Provides TOML parsing functions. This module does not provide TOML <em>printing</em>
because TOML has a richer type system than Lua, and thus parsing it into a Lua table
erases a lot of type information. For debugging purposes, you can use `JSON.pretty_print` instead.

##### <function>TOML.from_string(string)</function>

Parses a TOML string and returns a table. Fails plugin execution if `string` is not a syntactically correct TOML document.

##### <function>TOML.unsafe_from_string(string)</function>

Same as `TOML.from_string`, but returns `nil` on parse errors. Parse error message is logged (warning level).

</module>

<module name="YAML"> (since 3.0.0)

Provides YAML parsing functions. Does not provide any printing functions as of now.
For debugging purposes, you can use `JSON.pretty_print` instead.

##### <function>YAML.from_string(string)</function>

Parses a YAML string and returns a table. Fails plugin execution if `string` is not a syntactically correct YAML document.

##### <function>YAML.unsafe_from_string(string)</function>

Same as `YAML.from_string`, but returns `nil` on parse errors. Parse error message is logged (warning level).

</module>

<module name="CSV"> (since 4.7.0)

##### <function>CSV.from_string(str)</function>

Parses CSV data and returns it as a list (i.e., an integer-indexed table) of lists.

##### <function>CSV.unsafe_from_string(str)</function>

Like `CSV.from_string` but returns `nil` on errors instead or raising an exception.

##### <function>CSV.to_list_of_tables(csv_data)</function>

Converts CSV data returned by `CSV.from_string` into a list of string-indexed tables for easy rendering in templates.
The data variable must have at least two rows, the first row is assumed to be the header
and used for field names.

All rows must have the same number of columns. If a row is malformed, plugin execution fails with an error.
There is no unsafe equivalent of this function that would ignore row errors.

</module>

<module name="Date">

##### <function>Date.now_timestamp()</function>

Returns a UNIX timestamp (seconds passed since 1970-01-01 00:00 UTC).

##### <function>Date.now_format(fmt)</function>

Returns a string representation of the current datetime in UTC.

Example: `Date.now_format("%Y-%m-%d %H:%M")`

##### <function>Date.to_timestamp(date_string, input_formats)</function>

Converts a datetime string to a UNIX timestamp, using a list of allowed datetime formats.

Returns `nil` if none of the formats match the datetime string.

Example: `Date.to_timestamp("2006-08-16", {"%Y-%m-%d"})`

##### <function>Date.reformat(date_string, input_formats, output_format)</function>

Parses and reformats a datetime string.

Example: `Date.reformat("2007-06-23", {"%Y-%m-%d", "%d.%m.%Y"}, "%Y/%d/%m")`

</module>

<module name="Digest">

Provides functions for cryptographic hash sums. All these functions take a string
and return a hex digest.

##### <function>Digest.md5(str)</function>

Returns an MD5 digest of `str`.

##### <function>Digest.sha1(str)</function>

Returns	an SHA-1 digest of `str`.

##### <function>Digest.sha256(str)</function>

Returns an SHA-256 digest of `str`.

##### <function>Digest.sha512(str)</function>

Returns an SHA-512 digest of `str`.

##### <function>Digest.blake2s(str)</function>

Returns a BLAKE2-S digest of `str`.

##### <function>Digest.blake2b(str)</function>

Returns a BLAKE2-B digest of `str`.

</module>

<module name="Table">

##### <function>Table.has_key(table, key)</function>

Returns `nil` if `table` does not have a field `key`. 

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
Handy for iterating over tables where keys do not have any real meaning.

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

Since tables are not ordered collections, the question whether it is a left or right fold is meaningless:
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

##### <function>Table.for_all(func, table)</function> (since 4.6.0)

Checks if boolean function `func` is true for all items in a table.

##### <function>Table.for_any(func, table)</function> (since 4.6.0)

Checks if the boolean function `func` is true for at least one item in `table`.

##### <function>Table.take(table, count)</function>

Removes the first `count` items from `table` and return them as a list.

##### <function>Table.chunks(table, size)</function>

Splits `table` into a list of chunks of up to `size` items.

##### <function>Table.length(table)</function> (since 4.6.0)

Returns the table size (the number of items in it).

##### <function>Table.is_empty(table)</function> (since 4.6.0)

Returns true if `table` does not contain any items.

##### <function>Table.copy(table)</function> (since 4.6.0)

Returns a shallow copy of `table`.
If a value is mutable (like a string or a sub-table) and it is mutated in the original table,
that change will also be reflected in all copies.

Note: there is no deep copy functionality in Lua-ML or soupault's API yet.

##### <function>Table.sort(compare_func, table)</function> (since 5.0.0)

Sorts a table with numeric keys using a comparison function.

The function must return -1 (less than), 0 (equal), or 1 (greater than).

</module>

<module name="Value">

Contains functions for working with Lua values in ways that PUC-Rio's Lua design never intended.

##### <function>Value.repr(value)</function>

Returns a string representation of a Lua value for debug output.

As of soupault 4.0.0, it's fairly limited. For example,
tables just produce `"table"`. The main advantage is that it is safe to use with any values.
Lua's `str()` will fail for `nil`, tables etc. so it can't be used for logging values in debug prints.

For dumping the contents of tables, you may want to use [`JSON.pretty_print()`](#JSON.pretty_print) instead.

##### <function>Value.is_nil(value)</function>

Returns true if `value` is `nil`.

##### <function>Value.is_int(value)</function>

Returns true if `value` is an integer number.

##### <function>Value.is_float(value)</function>

Returns true if `value` is a number. Integers are considered a subset of floats,
so it returns true for integers as well.

##### <function>Value.is_string(value)</function>

Returns true if `value` is a string.

##### <function>Value.is_table(value)</function>

Returns true if `value` is a table.

##### <function>Value.is_list(value)</function>

Returns true if `value` is a table whose every key is an integer number.

##### <function>Value.is_html(value)</function> (since 4.6.0)

Returns true if `value` is an HTML element tree data structure (either a document or an element).

</module>

## Page processing hooks

Page processing hooks allow Lua code to run between processing steps of replace them.

They have access to the same API functions as plugins, but their execution environments
are somewhat different and vary between hooks.

Hooks are configured in the `hooks` table. The following hooks are supported as of soupault 4.9.0:
`startup`, `pre-parse`, `pre-process`, `post-index`, `render`, `save`, and `post-build`.

Two of those hooks are global: `startup` and `post-build` — they run before the build process is started
and when it's finished, respectively. All other hooks run for every page.

Like widget subtables, hook subtables can contain arbitrary options.

There can be only one hook of each type.

Hook source code can be given inline using `lua_source` option or loaded from a file
using the `file` option, just like with plugins.
There is no automatic discovery for hooks, they must always be configured explicitly.

Like widgets, hooks that run on every page can be limited to a subset of pages using any <term>limiting option</term>.
They can also be limited to [build profiles](#build-profiles).

<h3 id="hooks-startup">Startup</h3>

The `startup` hook runs once, on soupault startup, before any pages are processed.

It has the following variables in its environment:

* `config` (aka `hook_config`) — the hook config table.
* `soupault_config` — the complete soupault config.
* `force` — true when soupault is called with `--force` option, plugins are free to interpret it.
* `site_dir` — the value from `settings.site_dir` or the `--site-dir` option if present.

Soupault retrieves the following variables from this hook's environment:

* `global_data` — must be a table with string keys.
  Soupault makes data from it available to all Lua code via `Plugin.get_global_data(key)` function.

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

* `index_fields` — a table with page's index entry.
* `index_entry` — the complete index entry for the page (including internal variables and custom variables that hooks might have set).
* `site_index` — the complete site index.* `site_index` — the complete site index.
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

The `index_entry` variable is provided to give the hook access to auxilliary fields in a uniform way
but is not taken back by soupault — all its modifications are ignored (to prevent the hook from interfering with
those internal fields). If you want to inject new index entry fields, modify the `index_fields` variable.

<h3 id="hooks-render">Render</h3>

The `render` hook, if present, runs _instead of_ the built-in page rendering functionality.

It has the following variables in its environment:

* `index_entry` — the complete index entry for the page (including internal variables and custom variables that hooks might have set).
* `site_index` — the complete site index.* `site_index` — the complete site index.
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
  lua_source = '''
    page_source = soupault_config["settings"]["doctype"] .. "\n" .. HTML.pretty_print(page)
  '''
```

<h3 id="hooks-save">Save</h3>

The `save` hook runs _instead of_ the build-in generated page file output functionality.

It has the following variables in its environment:

* `index_entry` — the complete index entry for the page (including internal variables and custom variables that hooks might have set).
* `site_index` — the complete site index.* `site_index` — the complete site index.
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
    Sys.write_file(target_file, page_source)
  '''
```

<h3 id="hooks-post-build">Post-build</h3>

The `post-build` hook runs after all pages are processed and soupault is about to terminate.
It runs once rather than for every page, so it does not have page-specific variables in its environment
(like `page_file` or `target_file` — they only make sense for hooks that run on every page).

It has the following variables in its environment:

* `config` (aka `hook_config`) — the hook config table.
* `soupault_config` — the complete soupault config.
* `force` — true when soupault is called with `--force` option, plugins are free to interpret it.
* `site_dir` — the value from `settings.site_dir` or the `--site-dir` option if present.
* `build_dir` — the output directory from `settings.build_dir` or the `--build-dir` option if present.
* `site_index` — the complete site index.

Example:

```toml
[hooks.post-build]
  lua_source = '''
    Log.debug("Number of pages in the site index: " .. (Table.length(site_index)))
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
