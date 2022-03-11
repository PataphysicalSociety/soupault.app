# FAQ

<div id="generated-toc"> </div>

<h3 id="other-ssgs">How does soupault compare to other static site generators?</h3>

Like Hugo or Zola, soupault is available as a single self-contained executable (~17MB),
so it’s trivial to install and upgrade, and will not break easily.

Like Jekyll or Nikola, it’s extensible with a scripting language
and allows plugins to redefine its built-in features.

Unlike any other SSG, it works on the HTML element tree level. This means that it:

* supports any format that can be converted to HTML;
* its features like [ToC](/reference-manual/#toc-widget) work consistently across all formats;
* it offers unique capabilities such as piping HTML element content through an external program.

<h3 id="page-format-support">What markup languages/Markdown flavors does soupault support?</h3>

The only built-in supported format is HTML. However, you can automatically import
pages in any format if you install and configure a [convertor](/reference-manual/#page-preprocessors) for it.

For example, if you want `*.md` files to be processed with [Pandoc](https://pandoc.org) in CommonMark mode:

```toml
[preprocessors]
  md = 'pandoc -f commonmark+smart -t html'
```

You can specify as many preprocessors as you want.

<h3 id="html-processor">Is soupault just an HTML processor?</h3>

No. It has an HTML (post-)processor mode and some projects use it as such because it’s pretty much the only
tool that can do that.

However, it can also do what all other SSGs do: assemble pages, extract metadata from them,
and render that metadata on index pages. That’s not counting its ability to also manipulate pages
in completely arbitrary ways that other SSGs do not support.

<h3 id="blog-aware">Is soupault &ldquo;blog-aware&rdquo;?</h3>

Soupault does not have a built-in content model. Instead, it allows you to define your own.
You can make a blog, a wiki, or anything else you want.

If you want to quickly start a blog with soupault, you can use the [soupault-blog](https://github.com/PataphysicalSociety/soupault-blog) application.
It comes with a blog content model and relevant plugins (post reading time, Atom feeds...) ready to use.

<h3 id="performance">Is soupault fast?</h3>

It’s subjective, but here are some tests made on my 8th gen Intel NUC machine: i5-8259U, SSD, Fedora 35, NVMe SSD.
<fn id="build-time">Those figures are for ‘warm’ builds (pages [cached in RAM](https://linuxatemyram.com/)),
but the initial build takes maybe a couple of ms longer. For machines with magnetic drives reading pages from disk may take longer.</fn>

Assembling 1000 HTML pages (~4kbytes) each takes ~2s (with `verbose = true`) or ~1.6s (with progress logging disabled).

If you add an external Markdown preprocessor (I tested with `cmark --smart --unsafe`), it takes ~3.5s in the verbose mode
or ~3.2s with logging disabled.

All in all, the UNIX-way approach with delegating some processing steps to external programs does have its cost,
but for all but the largest websites it’s not going to be a problem.

<h3 id="themes">Are there themes?</h3>

The problem with typical SSG/CMS ‘themes’ is that they aren’t really themes—most often they contain
a mix of formatting, styling, and _logic_. Essentially, they are _applications_ written on top of a _framework_.

One reason why many SSG frameworks rely heavily on theme catalogs is that writing a working website from scratch
is not trivial. The reason for that is heavy use of templates that are by definition a mix of presentation and logic.

Working at the HTML element tree level allows soupault to decouple the logic from presentation to a much greater extent,
so it needs themes less.

However, there are some ready to use blueprints, such as blog..

<h3 id="template-processor">Does soupault use a template processor?</h3>

Soupault does not use a template processor for assembling pages from a ‘theme’ and a content file.
That is done by inserting the content into an element specified by a CSS selector.

However, it does have a built-in template processor ([jingoo](https://github.com/tategakibunko/jingoo)) and
one of the options for rendering the site index is to supply a template. You can also call template rendering
from Lua plugin code.

<h3 id="shortcodes">Are the shortcodes?</h3>

No. Instead, soupault allows you to write ‘fake’ HTML elements and make them real via HTML transformation plugins.

It can be as simple as translating `<wikipedia lang="en">HTML</wikipedia>` to `<a href="https://en.wikipedia.org/wiki/HTML>HTML</a>`
or much more complex, e.g. you can create hyperlinked glossaries. See examples in the [Augmented HTML](/plugins/#augmented-html)
plugin catalog category.

<hr>
<div id="footnotes"> </div>
