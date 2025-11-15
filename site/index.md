Soupault (_soup-oh_) is a static website generator/framework that works with HTML element trees
and can automatically manipulate them. It can be described as a robotic webmaster
that can edit HTML pages according to your rules, but doesn't get tired of editing them.

You can use soupault for making blogs and other types of websites, pretty much like any other SSGs
(Jekyll, Hugo, Eleventy, etc.). However, you can also use it as a post-processor
for existing websites — a use case other tools don't support.

Soupault is highly-configurable, extensible, and designed to give you complete control
over your website generation process.

If you are already familiar with other static site generators, check out the
[comparison with Hugo, Zola, and Jekyll](/tips-and-tricks/comparison/).
You may also want to read the [FAQ](/tips-and-tricks/faq/).

<h2 id="quick-start">Quick start</h2>

Soupault is very simple to [install](/install/): if you are on Linux (x86-64), macOS, or Microsoft Windows,
you can just download an executable.

If you are starting a blog or an online book, you can grab a ready-to-use [blueprint](/blueprints/).

If you want to make a custom setup, read a guide to get a feel of soupault's workflow:

* [Create a blog setup from scratch](/tips-and-tricks/quickstart/).
* [Use soupault as a post-processor for an existing website](/tips-and-tricks/getting-started-html-processor/).

<h2 id="why-soupault">Why soupault?</h2>

Soupault is not like other static site generators — it works on the HTML element tree level.
Most SSGs treat HTML as an opaque format that can be generated with templates but cannot be read or manipulated.

Soupault treats HTML as a first-class format and that enables many use cases and features that are impossible for other SSGs.

### Store pages in any format

Soupault works with HTML element trees, so you can store your pages in any format
that can be converted to HTML — all features will work the same no matter what the source format was.

There's built-in Markdown support, but you can also configure HTML conversion commands for different file extensions
and soupault will call them automatically when it loads your pages.

Whatever formats and tools you want to use, you can easily do it. Want to use [cmark](https://github.com/commonmark/cmark) for Markdown,
[pandoc](https://pandoc.org) for reStructuredText, and [Asciidoctor](https://asciidoctor.org/) for AsciiDoc? That's simple:

```toml
[preprocessors]
  md = `cmark --unsafe --smart`
  rst = `pandoc -f rst -t html`
  adoc = `asciidoctor --embedded -o -`
```

Or you can write HTML pages by hand if you prefer.

### Bring any external tools to your workflow and remove unnecessary client-side JavaScript

A lot of time people add non-interactive client-side JavaScript to compensate for missing features
in their SSGs. Soupault helps you keep your pages lighter by pre-rendering HTML with external
tools at build time instead.

In the simplest case, you can include the output of an external program in your page,
in any location identifiable with a CSS selector.

```toml
[widgets.page-generation-date]
  widget = "exec"
  command = "date -R"
  selector = "datetime#generated-on"
```

But you can also _pipe_ element content through an external program and insert the output back.
Run code examples through your favorite syntax highlighter, automatically check if they compile — there are many possibilities.

This is how this website highlights source code in `<pre>` and `<code>` tags
with Andre Simon's [highlight](http://www.andre-simon.de/doku/highlight/en/highlight.php):

```toml
# Runs the content of <* class="language-*"> elements through a syntax highlighter
[widgets.highlight]
  widget = "preprocess_element"
  selector = '*[class^="language-"]'
  command = 'highlight -O html -f --syntax=$(echo $ATTR_CLASS | sed -e "s/language-//")'
```

With additional scripts you can do much more, for example, [render math with KaTeX at build time](/tips-and-tricks/static-rendering/#mathematics).

### Extract page metadata from HTML, no front matter needed

Most static site generators make you write metadata in the "front matter", but soupault allows you to extract
it right from HTML instead.

You can define a mapping of CSS selectors to metadata fields. This is how you can add a list of all pages to your
main page, using the first heading tag (either `<h1>`, `<h2>`, or `<h3>`, whichever is present) of the page as its title:

```toml
[index]
  index = true

[index.fields]
  title = { selector = ["h1", "h2", "h3"] }

[index.views.page-list]
  page = "index.html"
  index_selector = "main"

  index_template = '''
    <h2>All pages</h2>
    <ul class="page-list">
    {% for e in entries %}
      <li><a href="{{e.url}}">{{e.title}}</a></li> 
    {% endfor %}
  '''
```

### Take advantage of HTML as a first-class format

Soupault's DOM manipulation is as powerful as client-side JavaScript (without interactivity, of course),
but the result is a static page.

With built-in features, you can automatically create [two-way footnotes](/reference-manual/#footnotes-widget),
use a [highly-configurable ToC](/reference-manual/#toc-widget), or [add a URL prefix to every link](/reference-manual/#absolute-links).
Most importantly, those features are available regardless of the original page format: whether the HTML was hand-written
or produced by a converter, they will work the same.

With [Lua plugins](/plugins/) you can do much more than that. You can transform existing HTML,
or create a <abbr title="Domain-Specific Language">DSL</abbr> from "fake" elements and convert them to real HTML,
e.g. create a [hyperlinked glossary](/plugins/#hyperlinked-glossary).

The [plugin API](/reference-manual/#plugin-api) offers many possibilities, from adding and deleting HTML elements
to executing external programs, loading data from JSON/YAML/TOML, and more.

### Built to last

Soupault is available as a statically-linked executable with no dependencies. You can stick with the same version
for years if it works for you. Or you can download every new version, try it out, and easily revert back
if you run into any issues.

<h2 id="name">Why it's named soupault?</h2>

Soupault is named after <wikipedia>Philippe Soupault</wikipedia>, a French dadaist and surrealist writer,
because it's based on the <github project="aantron/lambdasoup">lambdasoup</github> library.

Its development is sponsored by the [College of 'Pataphysics](http://www.college-de-pataphysique.org/) and the
[IHHF](https://hobbyhorsefederation.com/) (the International [Hobbyhorse](https://en.wikipedia.org/wiki/Hobby_horsing) Federation).<fn id="sponsors">Not really.</fn>

<h2 id="graphics">Graphics</h2>

Soupault logo is a stick horse. It's a reference to the meeting where Philippe Soupault et al. chose a name for their movement by opening a dictionary
at a random word and landed on <q>dada (n.), a colloquial for a stick horse</q>, which is why they named it "dadaism".

<img src="/images/soupault_logo.svg" width="128" height="128"/>
<img src="/images/powered_by_soupault_88x31.png" />

If you are using soupault for your site or want to raise awareness of it, feel free to put a button there.

<h2 id="maintainer">Who's behind it?</h2>

So far just me, [Daniil Baturin](https://baturin.org), but everyone is welcome to send a patch/pull request or a suggestion.
It has grown out of the bunch of ad hoc scripts that used to power my own website, and then I thought I can as well make it usable
for everyone who finds other generators too annoying or too limiting.

Feel free to contact me for [support](/support/).
