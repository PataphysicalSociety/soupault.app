<h1 id="post-title">Soupault 5.0.0 release</h1>

<p>Date: <time id="post-date">2025-04-24</time> </p>

<p id="post-excerpt">
Soupault 5.0.0 is available for download from <a href="https://files.baturin.org/software/soupault/5.0.0">my own server</a>
and from <a href="https://github.com/PataphysicalSociety/soupault/releases/tag/5.0.0">GitHub releases</a>.
It brings built-in Markdown support (in addition to already existing external page preprocessors),
a new widget that can translate intermediate HTML elements to real HTML with a template, an option to limit
<code>exec</code> and </code>preprocess_element</code> widgets to either UNIX or Windows,
and a few new plugin functions.
This release also includes a lot of big feature reworks and configuration changes that remove many of the old limitations,
inconsistencies, and performance problems.
However, they may break some setups and require small adjustments to your configs or plugins,
so you should read this post carefully before upgrading.
</p>

The main motivation for this release is to revise and fix old design decisions that did not stand the test of time
and turned out misguided, suboptimal, or overly complicated. For example, the idea not to include built-in support
for Markdown or any other popular format now seems like a misplaced purity to me — that feature can easily exist
together with configurable page preprocessors.
Likewise, the idea to load and process pages sequentially to support processing arbitrarily large websites with
a limited amount of RAM made the implementation a lot more complex, for a very small benefit.
I hope that all the changes I made and the new features of this release will make soupault easier to adopt
and use — read on for details.

<div id="generated-toc"> </div>

## Removed features and incompatible changes

This release removes a few configuration options and features. I made a point to check if any known soupault users
used them and only removed features right away (without a deprecation warning) if I couldn't find
any use among websites with public source code repos, so I assume it will not break anyone's configs.

All those features were quite obscure or even undocumented. But if this release does break your config,
the migration path is straightforward.

Here's what's gone now:

* `index.index_first` is no longer a valid configuration option.
  If you used it, simply remove it from the config — index data is now always available to all pages
  (more on that later).
* `settings.process_pages_first` is no longer a valid option — there is no sequential page processing anymore,
  so the concept of "processing specific pages first" no longer applies.
  It should have no effect on any websites — just remove the option.
* There is no separate `post-save` hook anymore. If you used it, move the code to the `save` hook instead.
* There is no way to make the `post-index` hook tell soupault to stop processing a page anymore
  (previously that was possble to do by setting the undocumented `ingore_page` variable).
  The motivation for that feature was to give people a way to use a page purely as a data source,
  but you can do the same by loading a CSV/JSON/TOML/YAML file in your Lua plugin code instead.
* `persistent_data` and `global_data` variables are no longer available in the plugin environment.
  If you want to share data between different widgets, place it in the page or in the index entry.

## New features

### Built-in Markdown support

For a long time, soupault didn't include built-in support for any format other than HTML.
That was my reaction to the situation with already-existing SSGs where differences between
Markdown flavors and implementations could bite you at any moment if you tried
to migrate to a different SSG.

My response was to make HTML a first-class format and make all features like tables of contents,
footnotes, etc. work at the HTML level. That way, those feature worked the same whether you wrote
an HTML page by hand or converted it from some other format. However, few people want to write HTML by hand,
so I added a way to configure soupault to run an [external HTML converter](/reference-manual/#page-preprocessors)
on pages with certain extensions. That allowed people to store pages in absolutely any formats
and choose how exactly they wanted to handle their Markdown, reStructuredText, AsciiDoc, and other files.

However, executing an external program is an expensive operation, and it became a common performance complaint.
Moreover, from my survey of websites with public repositories, most of them use Markdown
and almost all that do use a CommonMark implementation.

To make life easier for those users (myself included), soupault now features a built-in Markdown processor.
It's based on [Cmarkit](https://erratique.ch/software/cmarkit)
and implements [CommonMark](https://spec.commonmark.org/)
and some [common extensions](https://erratique.ch/software/cmarkit/doc/Cmarkit/index.html#extensions).

The default config generated by	`soupault --init` now enables built-in Markdown	support	for all	`*.md` files:

```toml
[settings]
  markdown_extensions = ["md"]
```

However, if `settings.markdown_extensions` is not in the config or is set to an empty list,
then built-in Markdown processing is disabled. That is to allow	the user to choose whether to use
the built-in implementation or an external page preprocessor of their choice.
So if you are using an external preprocessor, your config will work exactly as before —
you don't need to do anything to disable built-in Markdown for existing setups.

If you want to switch from an external preprocessor to the built-in,
remove your Markdown extension (normally `md`) from `[preprocessors]`
and add it to `settings.markdown_extension`.

Extensions from that list are implicitly added to `settings.page_file_extensions`,
so you do not have to add them to that list by hand.

If there's demand for it and if suitable OCaml libraries exist, I may add built-in support for more formats in the future.
However, configurable page preprocessors are not going anywhere — they will always be a key feature
of soupault!

### `element_template` widget

A common theme in soupault plugins is to define an imaginary HTML element
and transform it to real HTML. That mechanism is much more flexible than classic shortcodes:
in the [augmented HTML category](/plugins/#augmented-html) there's a simple plugin
for replacing something like `<wikipedia lang="fr">HTML</wikipedia>` with `<a href="https://fr.wikipedia.org/wiki/HTML">HTML</a>`,
but also a DSL for a hyperlinked glossary — that would be impossible without the [Lua API for element tree manipulation](/reference-manual/#HTML). 

However, in many cases, all you need is to feed a bunch of keys and values to a template.
Now there's a new built-in widget that allows you to create a "shortcode" for those simple cases
without writing any Lua code.

The new widget is called `element_template`. It takes a template, renders it using data from an HTML element
(its attributes and content), and replaces the element with the rendered template.

For example, suppose you want to add a shortcut
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

If you want to use an attribute called `content`, you can redefine the name of the variable that stores the
element content using the `content_key` option.

## `os_family` option for `exec` and `preprocess_element` widgets

UNIX-like systems and Windows-like systems (let's not forget that [ReactOS](https://reactos.org) exists)
can have very different behavior of the same commands.

For example, the config from the sample site
included in soupault's source code tree has a widget that calls `date` to get the page generation timestamp.
On UNIX-like systems, that command produces something like `Wed Apr 23 10:21:53 PM UTC 2025` and exits.
However, on Windows that widget makes the build hang because Windows `date` shows the current date
_and asks the user to enter a new date_, so the command keeps waiting for an input that never comes
(to just show the current date, you need `date /T` — which would fail on UNIX because `/T` is not a valid
argument to the UNIX `date`).

For individual users that's usually not an issue — I've never heard of anyone running soupault
on more than one OS on the same website, so far at least.
But if you want to use system commands in reusable blueprints, that becomes a real problem.

Now [`exec`](/reference-manual/#exec-widget) and [`preprocess_element`](/reference-manual/#preprocess-element-widget) widgets
support `os_family` option that can be set to either `"unix"` or `"windows"`.

```toml
# If the system is Unix-like, run `date -R` and insert its output
# into the <span id="generated-on"> element
[widgets.generated-on_unix]
  widget = "exec"
  selector = "#generated-on"
  os_family = "unix"
  command = "date"

# If the system is Microsoft Windows (or a compatible),
# then use 'date /T' command for <span id="generated-on">
[widgets.generated-on_windows]
  widget = "exec"
  selector = "#generated-on"
  os_family = "windows"
  command = "date /T"
```

Why not a single boolean option `is_unix` or `is_windows`?
I'm not a big fan of ["stringly-typed"](https://en.wiktionary.org/wiki/stringly-typed) options,
but a boolean option will become problematic if anyone wants to add support
for an entirely different OS family (e.g., [OpenVMS](https://vmssoftware.com/) —
it now runs on x86 machines for real) or a granular check for Linux/FreeBSD/macOS/etc.

### New plugin functions

* `Table.sort(func, table)` — sorts a table with numeric indices using `func` for value comparison.
* `String.to_integer` — converts a string to an integer (returns `nil` if conversion fails).
* `String.to_float` — a clearer-named alias for `String.to_number`.

## Behavior changes

### Strict mode is now the only mode

Historically, soupault provided an option to ignore most page processing errors,
by setting `settings.strict = false` or running `soupault --strict false`.

However, that idea was probably always misguided, since none of the built-in errors are truly recoverable.
In fact, they all _should_ stop the build because
if soupault cannot save a page to disk, for example. that's certainly a big problem that shouldn't be ignored.
Same goes for widget configuration problems where they are missing required options or have incorrect options.

So, `settings.strict = false` has no effect now. If errors that would formerly be ignored occur,
they will fail the website build. I didn't remove that option from the config and the CLI because
many existing websites use it (not least because it was in the default config generated by `soupault --init`)
and I didn't want to break peoples' configs.
I added a deprecation warning but I will keep it there for at least a few releases, maybe even indefinitely.

### Site index is now available to all pages by default

The old `index.index_first` option doesn't exist anymore because there's no need for it — the entire site index
is now available to all pages by default.

But this change requires a compromise:

### Soupault can run out of memory while processing very large websites

Before this release, soupault was guaranteed to be able to process an arbitrarily large website, given enough time.

It was a unique feature of soupault.
Classic static site generators always loaded everything into memory so they always had that issue.

With soupault, processing websites of unlimited size was possible because it would load and process pages sequentially.
When I started working on soupault, the ability to process, say,
a static version of Wikipedia with limited RAM seemed like a cool feature to have,
and the compromises I had to make for that seemed acceptable. It could still generate index pages
for blogs and similar by splitting the list of pages into content and index (normally `index.*`) pages,
processing content pages and gathering the metadata from them, and then processing index pages
when the metadata of all content pages was available.

Then it turned out that there wasn't any demand for processing gigabytes-large websites — most websites,
static or dynamic, are quite small. It also turned out that there are many website features
that are only possible to implement if all pages have access to the entire site index.
For example, a fully-autogenerated site-wide navigation sidebar or "next-previous" navigation buttons.

Since soupault 4.0.0, there was a way to make the entire site index available
to all pages by setting [`index.index_first = true`](/blog/soupault-4.0.0-release/#accessing-the-index-entry-of-the-page-from-plugins),
but only at the cost of a huge performance hit — the build process would be almost two times slower,
since it worked by doing many steps of content processing page twice (first just enough work to extract metadata,
then full processing).

Now it loads all pages into RAM before processing. That makes it trivial to provide every page with index data,
_if_ the entire website fits in memory. If it doesn't, soupault will run out of memory and crash
or hang the machine, depending on the system settings.

I think this change is a net positive, but if you _are_ processing something as large as Wikipedia,
you will need to change your build workflow.

I don't think it's going to make anyone's workflow entirely infeasible.
When I started soupault in 2019, magnetic HDDs were still common and RAM was considerably more expensive.
Now you can rent a server with a _terabyte_ of memory (or even more) for $5-10/hour on demand from a cloud platform —
that would be very expensive to run non-stop,
but if you spawn it just to run a build and then shut it down, that's not too bad.
Or you can swap to an NVMe SSD — not as fast as RAM, but a lot faster than magnetic HDDs.

That change also makes it possible to implement "live rebuild" and an embedded web server in the future,
if anyone wants that functionality.

### `html_context_body = <true|false>"` option is replaced with a general `html_context = "<elementName>"`

Includion widgets used to support an option called `html_context_body`. When left unset or explicitly set to `true`,
it would make the HTML parser interpret HTML fragments as fragments to be placed in the `<body>` tag.
When set to `false`, those fragments would be interpreted as fragments for `<head>`.

This issue comes into play when you want to use tags that can appear only in `<head>` or in `<body>`.
For example, a `<link>` tag cannot appear in `<body>` and a reasonable parser should try to correct it by wrapping it into
`<head>` when it appears at the top of the document. But if you want to insert a CSS stylesheet link into your page,
that behavior is not reasonable at all.
So, I added a way to tell soupault if a fragment was meant for `<body>` or `<head>` to ensure that soupault
doesn't try to correct fragments that don't need to be corrected.

But a boolean option was too limiting. For example, `<tr>` and `<td>` cannot appear in `<body>` by themselves either.
They are only valid inside a `<table>`.
The HTML parser would react to a fragment that started with a `<tr>` tag by removing that tag,
to avoid creating a document with an ill-formed, standard-violating `<body>`.

Now the default behavior of all inclusion widgets is to infer the context. But if its inference is wrong,
you can force the context to anything you need: like `html_context = "head"`, or `"table"`, or "`"svg"`.

If you used the old `html_context_body` option, then:

* if it was `true`, use `html_context = "body"`;
* if it was `false`, use `html_context = "head"`.

### Files with extensions from `settings.markdown_extensions` and `[preprocessors]` are automatically considered page files

Before this release, soupault would treat a file as a page if (and only if) its extension was in
`settings.page_file_extensions`. If it was not there, it would treat the file as an asset
and either send it to an asset processor or copy it unchanged.

By default, that option was set to `["htm", "html", "md", "rst", "adoc"]` to cover the most commonly used formats.
However, if someone wanted to use, for example, write pages in LaTeX and use `latex2html` to convert them to HTML,
they would also need to add `"tex"` to that list — simply configuring a preprocessor for `*.tex` wouldn't suffice.

That default would also make soupault try to parse Markdown, reStructuredText, and AsciiDoc files as HTML
if there was no configured preprocessor for them — with predictably silly results.

Now there is no need to ever change that option by hand anymore: if an extension is in `settings.markdown_extensions`
or there's an entry for it in the `[preprocessors]` section, then every file with that extension
is automatically considered a page rather than an asset.

You can see that fact reflected in `soupault --show-effective-config`.

## Changes in soupault for Windows

### ANSI terminal colors for log messages are now enabled on Windows by default

Windows Terminal is now a built-in feature of Windows 11 and Windows Server 2025,
and it supports ANSI colors out of the box. It's also possible to enable colors
for the older cmd.exe and PowerShell terminals in all still-supported versions of Windows,
so I don't think it's justified to disable colors on Windows unconditionally.

If you don't like colors or use a terminal that doesn't support them,
you can always disable them by setting the [`NO_COLOR`](https://no-color.org/) environment variable.

### Executables are now built on Windows Server 2022

Older releases were built on Windows Server 2019, so this change _may_ make soupault 5.0.0
incompatible with some older Windows versions. That is not very likely because soupault
doesn't use any APIs specific to new Windows versions, but not impossible.

## Bug fixes

* Clean	URL in rendered	index views now	include	trailing slashes,
  which reduces the number of unncessessary redirects (GitHub issue #81).
  The old behavior can be restored with	`settings.clean_url_trailing_slash = false`.
* Lists	of selectors are now consistently supported in all built-in widgets (GitHub issue #77).
* If the `pre-process` hook modifies the path of a leaf	bundle,	
  its child asset paths	are adjusted accordingly (GitHub issue #63).
* `soupault --show-effective-config` now correctly updates values
  that are overridden by commmand line options or internal processes.

## What's next?

First, I have a plan to make widget config validation a separate step.
If there are errors, the build will fail before soupault gets to processing any pages.
If all the configs are alright, they will be cached in the widget environment,
to make the build slightly faster.

Second, this release has already laid the groundwork for parallel page processing.
That was blocked by two factors: first, soupault itself was hard-wired to process pages sequentially;
second, Lua-ML was not thread-safe and would blow up immediately when two threads tried to execute Lua code with it.
The first part is a non-issue now — the logic of soupault itself is now trivial to parallelize
by replacing a normal `fold` or `map` with a parallel version.
The second part still applies. I made a good progress on making Lua-ML thread-safe
but there are still odd errors that I need to debug, so it will take more time.

I also have a plan to make it possible to write custom actions.
E.g., a blog template could provide a `soupault new --title <title> ...` command,
that would invoke a plugin that would retrieve the options and generate a new post with a pre-populated header.

And the idea to integrate WASM plugins as an alternative to Lua still stands, although it's just an idea
and I haven't done any serious research in that area yet.
