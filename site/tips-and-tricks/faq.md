# FAQ

<div id="generated-toc"> </div>

<h2 id="basics">Basics</h2>

<h3 id="other-ssgs">How does soupault compare to other static site generators?</h3>

Like Hugo or Zola, soupault is available as a single self-contained executable (~17MB),
so it's trivial to install and upgrade, and will not break easily.

Like Jekyll or Nikola, it's extensible with a scripting language
and allows plugins to redefine its built-in features.

Unlike any other SSG, it works on the HTML element tree level. This means that it:

* supports any format that can be converted to HTML;
* features like [ToC](/reference-manual/#toc-widget) work consistently across all formats;
* it offers unique capabilities such as piping HTML element content through an external program.

For details, check out the [comparison table](/tips-and-tricks/comparison/).

<h3 id="page-format-support">What markup languages/Markdown flavors does soupault support?</h3>

The only built-in supported format is HTML. However, you can automatically import
pages in any format if you install and configure a [convertor](/reference-manual/#page-preprocessors) for it.

For example, if you want `*.md` files to be processed with [Pandoc](https://pandoc.org) in CommonMark mode:

```toml
[preprocessors]
  md = 'pandoc -f commonmark+smart -t html'
```

You can specify as many preprocessors as you want.

<h3 id="processor-mode">Do I need to change my website to start using soupault?</h3>

Not necessarily. With many other website generators, you need to create a theme/template in their
own format to start using them. However, soupault can work also as an HTML processor for existing
websites, so it's much easier to give it a try.

<h3 id="html-processor">Is soupault just an HTML processor?</h3>

No. It has an HTML (post-)processor mode and some projects use it as such because it's pretty much the only
tool that can do that.

However, it can also do what all other SSGs do: assemble pages, extract metadata from them,
and render that metadata on index pages. That's not counting its ability to also manipulate pages
in completely arbitrary ways that other SSGs do not support.

<h3 id="blog-aware">Is soupault &ldquo;blog-aware&rdquo;?</h3>

Soupault does not have a built-in content model. Instead, it allows you to define your own.
You can make a blog, a wiki, or anything else you want.

If you want to quickly start a blog with soupault, you can use the [soupault-blog](https://github.com/PataphysicalSociety/soupault-blog) application.
It comes with a blog content model and relevant plugins (post reading time, Atom feeds...) ready to use.

<h3 id="performance">Is soupault fast?</h3>

It's subjective, but here are some tests made on my 8th gen Intel NUC machine: i5-8259U, SSD, Fedora 35, NVMe SSD.
<fn id="build-time">Those figures are for "warm" builds (pages [cached in RAM](https://linuxatemyram.com/)),
but the initial build takes maybe a couple of ms longer. For machines with magnetic drives reading pages from disk may take longer.</fn>

Assembling 1000 HTML pages (~4kbytes) each takes ~2s (with `verbose = true`) or ~1.6s (with progress logging disabled).

If you add an external Markdown preprocessor (I tested with `cmark --smart --unsafe`), it takes ~3.5s in the verbose mode
or ~3.2s with logging disabled.

All in all, the UNIX-way approach with delegating some processing steps to external programs does have its cost,
but for all but the largest websites it's not going to be a problem.

<h3 id="themes">Are there themes?</h3>

The problem with typical SSG/CMS "themes" is that they aren't really themes—most often they contain
a mix of formatting, styling, and _logic_. Essentially, they are _applications_ written on top of a _framework_.

One reason why many SSG frameworks rely heavily on theme catalogs is that writing a working website from scratch
is not trivial. The reason for that is heavy use of templates that are by definition a mix of presentation and logic.

Working at the HTML element tree level allows soupault to decouple the logic from presentation to a much greater extent,
so it needs themes less.

However, there are some ready to use blueprints, such as blog..

<h3 id="template-processor">Does soupault use a template processor?</h3>

Soupault does not use a template processor for assembling pages from a "theme" and a content file.
That is done by inserting the content into an element specified by a CSS selector.

However, it does have a built-in template processor ([jingoo](https://github.com/tategakibunko/jingoo)) and
one of the options for rendering the site index is to supply a template. You can also call template rendering
[from Lua plugin code](/reference-manual/#String.render_template).

<h3 id="shortcodes">Are the shortcodes?</h3>

No. Instead, soupault allows you to write "fake" HTML elements and make them real via HTML transformation plugins.

It can be as simple as translating `<wikipedia lang="en">HTML</wikipedia>` to `<a href="https://en.wikipedia.org/wiki/HTML>HTML</a>`
or much more complex, e.g. you can create hyperlinked glossaries. See examples in the [Augmented HTML](/plugins/#augmented-html)
plugin catalog category.

<h2 id="usage">Using soupault</h2>

<h3 id="project-setup">How to set up a basic project</h3>

Run `soupault --init` in an empty directory. It will create the following directory structure and files:

```
.
├── site
│   └── index.html
├── soupault.toml
└── templates
    └── main.html
```

The `site/` directory is where your page content files go. The `templates/main.html` file is
the page template. The`soupault.toml` file is the configuration file for soupault, in the TOML format.

If you run `soupault` in that directory, it will build your website and place generated pages in
the `build/` directory. You can then deploy your website with any tool of your choice, like
`neocities push`, rsync, or anything else.

<h3 id="no-project-dir">Do I need to keep everything in one directory?</h3>

No. It makes things easier, but it's not required. By default, soupault will look for `soupault.toml`
in the current working directory and read it. From there it will take the `site_dir` and `build_dir`
options. You can use absolute paths for those options.

You can also override the locations of the config file
and the source/output directories from the command line. A UNIX example of overriding everything at once:

```
SOUPAULT_CONFIG="/tmp/mysite.conf" soupault --site-dir ~/mysite --build-dir ~/public_html
```

On Windows, there's no easy way to set an environment variable for a command like that,
so you can use an option instead (since 4.2.0):

```
soupault --config A:\mysite.cfg --site-dir B:\mysite --build-dir C:\inetpub\wwwroot\
```

The `--site-dir` and `--build-dir` options work the same on all platforms.

<h3 id="assets">How to add assets (pictures, CSS...)</h3>

You can just drop files in the `site/` directory together with pages. Files with extensions
matching the `settings.page_file_extensions` option are considered pages and processed, by default that's
`["html", "htm", "md", "rst", "adoc"]`. All other files are just copied to the `build/`
directory unchanged.

<h3 id="sections">How to create a site section?</h3>

Just create a subdirectory in `site/`. Every subdirectory automatically becomes a section,
e.g. `site/pictures/cats.html` becomes `build/pictures/cats/index.html` if clean URLs
are enabled, or `build/pictures/cats.html` if they are disabled.

They can be nested as deep as you want, there is no depth limit. However, section index pages is your responsibility,
so if you want `https://example.com/pictures` to work, you should also add `site/pictures/index.html`.

Soupault can be configured to generate a list of all pages in a section, but there still must be a section index page,
whether you are maintaining a list of pages in the section by hand or using a script to generate it.

<h3 id="clean-urls">How to disable clean URLs?</h3>

Soupault uses "clean URLs" by default. This means a page like `site/about.html`
turns into `build/about/index.html`, so that on a deployed website it can be accessed as
`http://example.com/about`.

For a new website, the choice between `/about/` and `/about.html` is purely aesthetic,
but for people who already have a website and want to switch to managing it with soupault, it can be a real
show-stopper since it can break all their links. For this reason, soupault has a `settings.clean_urls`
option. Use `clean_urls = false` if you want to disable them.

With `clean_urls = false`, soupault preserves file names exactly, e.g. `site/about.htm`
becomes `build/about.htm`, and `site/projects/soupault.html` becomes
`build/projects/soupault.html`.

<h3 id="content-selector">Where the page content goes?</h3>

When soupault builds your website, it takes the empty page template from `templates/main.html`,
reads content from files in `site/` such as `site/about.html`, and inserts it in the template.

By default, it will insert the page content into the `<body>` element of the page template.
However, you can insert page content into any element using the `settings.default_content_selector` option.

Suppose you want your page content to go to `<div id="content">`. Then add that div
to `templates/main.html`, find that option in `soupault.toml`,
and set `settings.default_content_selector = "div#content"`.
</p>

<h3 id="unique-layout">How to create a page with unique layout?</h3>

Using a template saves time and allows easily changing the website layout. However, what if you want to make a page
with a unique layout different from the template?

Soupault decides whether to use a template or not by checking if a page file has an `<html>` element in it.
It it does not have it, then the file is considered a page body and inserted in the template. If it does, then it's considered
a complete page and only processed by widgets/plugins.

So, to make a unique page, just make it a complete HTML document.

<h3 id="set-title">How to automatically set page title?</h3>

A website where every page has the same `<title>` is a sad sight.
Soupault can set the page title from an element of your choice. This is the config
for this page, that takes the title from an element with `id="title"`.
In this page it's a `<h1>`, but it could be anything.

```toml
[widgets.page-title]
  widget = "title"
  selector = "#title"
  default = "soupault"
  append = " &mdash; soupault"
```

<h3 id="toc">How to add a table of contents?</h3>

Soupault can automatically generate tables of contents from heading tags.
This is the config for this very page:

```toml
[widgets.table-of-contents]
  widget = "toc"
  selector = "#generated-toc"

  min_level = 2

  toc_list_class = "toc"
  toc_class_levels = false

  numbered_list = true

  heading_links = true
  heading_link_text = "→ "
  heading_link_class = "here"

  use_heading_slug = true
```

Remember to add a `<div id="generated-toc">` to `templates/main.html`
if you want a ToC in every page, or just to pages where you want it.

<h3 id="footnotes">How to add footnotes?</h3>

If you like footnotes, you can add them to your pages easily. This is the config for this website:

```toml
[widgets.footnotes]
  widget = "footnotes"
  selector = "div#footnotes"
  footnote_selector = ".footnote"
  footnote_link_class = "footnote"
  back_links = true
  link_id_prepend = "footnote-"
  back_link_id_append = "-ref"
```

It assumes that there's a `<div id="footnotes">` in the page.
If you forget to include it in the page, footnotes will not appear.

It considers elements with `class="footnote"` footnotes and moves them
to that div. The `back_links` option creates links back from footnotes
to their original locations, you can set it to `false` if you only want forward links.

<h2 id="security">Security</h2>

<h3 id="untrusted-data">Is it safe to run soupault on untrusted data?</h3>

No, it isn't safe.

Soupault allows executing system commands from the config and from plugins,
so you should exercise caution if you want to run soupault on anything you didn't write.
You should either run it sandboxed or thoroughly inspect the config and plugins
to make sure they aren't doing anything malicious.

<h3 id="safe-mode">Is there a safe mode?</h3>

No, there isn't.

A "safe mode" that disallows execution of external commands would limit soupault's usefulness,
because being able to bring external tools to its workflows is one of the main design points.

Trying to guess what is safe and what is not also is very error-prone
and can give a false sense of security. If you want to run soupault on untrusted data,
use your operating system's isolation capabilities (virtual machines or containers).

<h2 id="edge-cases">Edge cases</h2>

<h3 id="page-section-collision">What happens if you have a directory and a page with the same name?</h3>

Don't do it. It's undefined behaviour and anything may happen.

Currently, if you have clean URLs enabled and there are both `site/test.html`
and `site/test/index.html`, then the latter will be used. But it just happens to be this way now
and may change any time, so don't count on it.

<h3 id="plugin-and-builtin-name-collision">What happens if I load a plugin with the same name as a built-in widget?</h3>

The plugin wins. You also get a log message that clarifies that.

This is an intentional choice, so that people can replace built-in functionality with plugins if they want to.

<hr>
<div id="footnotes"> </div>

