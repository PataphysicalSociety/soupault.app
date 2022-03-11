# Plugins

<div id="generated-toc"> </div>

If you made a plugin and want it included in this directory, let me know!

## Installing plugins

The simplest way to install a plugin is to create a `plugins` directory inside your project directory
(next to `site`) and save a plugin file there. Since 1.10 release, soupault will automatically find them,
for example, `plugins/my-plugin.lua` will be registered as `my-plugin` widget.

However, if you want to load a plugin from an unusual directory, or you want to give its widget a different name,
you can also load it explicitly like this:

```toml
[plugins.my-cool-widget]
  file = "tmp/some-plugin.lua"
```

In this case `tmp/some-plugin.lua` will be registered as `my-cool-widget` widget.

## Generic

### Conditional HTML insertion

This plugin inserts an HTML snippet into the page iff that page has an element matching certain selector.

The key difference from the built-in `insert_html` widget is that it can check for one element,
but insert in another. The element to check for is defined by the `check_selector` option,
while the `selector` option defines the target element to insert the snippet in.

For example, if some content requires some JavaScript to interpret, you may want to insert that JavaScript only in pages
that actually need it. Of course, that JS usually has to go to the page `<head>`,
not inside the content element, and you don’t need it in _every_ element, so `insert_html`
doesn’t work well for this task.

One example is self-hosted [asciinema](https://asciinema.org) player. It’s smaller than a video
would be, but it’s still quite a chunk of JS and it’s better to insert it only in pages that have any `<asciinema-player>`
elements.

There are other possible uses of course. Here’s an example that adds a warning to your page if it has any `<blink>`
elements:

```toml
[widgets.blink-warning]
  widget = "insert-if"
  html = "<div><strong>Warning: blink elements are obsolete!</strong></div>"
  selector = "body"
  check_selector = "blink"
```

Download: [insert-if.lua](/files/plugins/insert-if.lua).

### Collapsible lists

Converts a list to a tree with collapsible/expansible nodes using HTML5 `<details>` element.

Configuration example:

```toml
[widgets.list-to-tree]
  widget = "collapsible-list"
  selector = ["ul.tree", "ol.tree"]
  collapsible_class = "collapsible"
```

It will convert `<li>` elements that have `<ul>` or `<ol>` elements nested inside them
to collapsible tree nodes. If `collapsible_class` option is given, that class will be
added to the affected `<li>` elements.

A live example this plugin’s output can be seen in the table of contents of the
[iproute2 manual](https://baturin.org/docs/iproute2/).

Download: <a href="/files/plugins/collapsible-list.lua">collapsible-list.lua</a>.

## Content

### Reading time

Calculates estimated reading time based on word count and inserts it into the page. Sample configuration
that counts words inside a `<div id="content">` and inserts the result in `<span id="reading-time">`:

```toml
[widgets.insert-reading-time]
  widget = "reading-time"
  selector = "span#reading-time"
  content_selector = "div#content"
```
Download: <a href="/files/plugins/reading-time.lua">reading-time.lua</a>.

### Escape HTML special characters

Writing _about_ HTML in HTML can be especially annoying since you have to replace all special characters (`<`, `>`, `&`) with
HTML entities. I always wished the `<pre>` tag content was treated as raw data, since we sadly gave up on XHTML and anyway.
With this plugin you can do it easily.


It converts the content of an element to its HTML source. E.g. `<pre class="raw-html"><p>hello world</p></pre>`
to `<pre class="raw-html">&lt;p&gt;hello world&lt;/p&gt;</pre>`.

```toml
[widgets.raw-html-in-pre]
  widget = "escape-html"
  selector = "pre.raw-html"
```
Download: <a href="/files/plugins/escape-html.lua">escape-html.lua</a>.

## Navigation

### Site URL

This plugin changes all relative links like `/about.html` to absolute like `https://www.example.com/about.html`.
It replaces the appropriate attribute (`href, src, data`) in `a, link, script, img, audio, video, embed, object` elements.
Sample configuration:

```toml
[widgets.set-site-url]
  widget = "site-url"
  site_url = "https://www.example.com"  
```
Download: <a href="/files/plugins/site-url.lua">site-url.lua</a>.

### Active link highlight

This plugin highlights the link to the current page/section in a navigation menu. You can see that the &ldquo;Plugins&rdquo; link
on this page is bold, it’s what this plugin does (it adds a `nav-active` class to that link).

It assumes that you are using relative links and that you keep all navigation links inside one element (like `<nav>`).
It may require some tweaking for your website. Sample configuration:

```toml
[widgets.nav-menu]
  widget = "include"
  file = "templates/menu.html"
  selector = "div#nav-menu"

[widgets.highlight-active-link]
  after = "nav-menu"
  widget = "section-link-highlight"
  selector = "div#nav-menu"
  active_link_class = "nav-active"
```

If you keep navigation menu in a separate file like I do, the `after = ` option is necessary for correct ordering,
otherwise the `highlight-active-link` widget may run before navigation links are actually available.

Download: <a href="/files/plugins/section-link-highlight.lua">section-link-highlight.lua</a>.

### Safe links

Allows you to add `rel` attributes to external links (those with a URL schema).
By default it adds `rel="nofollow noopener"`.

Sample configuration:
```toml
[widgets.make-links-safe]
  widget = "safe-links"
  attributes = "nofollow noopener noreferrer"
```

Download: <a href="/files/plugins/safe-links.lua">safe-links.lua</a>.

### Page source link

For people who store their site source in a public repository. This plugin inserts a link to the page source file
in the repository, by appending the page file path to a base URL (the `repo_base` option).

Written by <a href="https://hristos.lol/">Hristos N. Triantafillou</a>.
Sample configuration from his site:

```toml
[widgets.source-link]
  widget = "source-link"
  selector = "div#source-link"
  link_text = "Source link for this page"
  repo_base = "https://git.sr.ht/~hristoast/hristoast/tree/master/"
```

Download: <a href="/files/plugins/source-link.lua">source-link.lua</a>.

## Integrations with external tools

### git timestamp

Requires soupault 1.9 or newer.

Extracts page modification date from <a href="https://git-scm.com/">git</a> history and inserts it into the page.

It also allows you to override the automatic git timestamp with a manual revision date,
which is handy if you want to preserve the date of the last _essential_ modification
when you make typo fixes or formatting updates.

To do that, set the `manual_timestamp_selector` option, and if a page has an element
matching that selector, then its content (i.e. inner HTML) will be used for the timestamp.

The `timestamp_format` is the revision text as it appears in the page.
It’s a Lua format string, `%s` will be replaced with actual timestamp.

The `git_date_format` is an argument for the `--date` git option.
It defaults to "short" (YYYY-MM-DD).

Configuration example:

```toml
[widgets.last-modified]
  widget = "git-timestamp"
  timestamp_container_selector = "div#content"
  manual_timestamp_selector = "time#last-modified"
  timestamp_format = "Last modified on %s"
  git_date_format = "short"
```

Download: <a href="/files/plugins/git-timestamp.lua">git-timestamp.lua</a>.

## Augmented HTML

These plugins create &ldquo;fake&rdquo; HTML elements that are processed and replaced with
real HTML.

They serve the same purpose as &ldquo;shortcodes&rdquo; in other static site generators.

### File inclusion

For those who miss `{% include "path/to/file" %}` directives from template processors.
If you remember SSI, it’s also similar to `<!-- #include file="myfile.html" -->`.

This plugin adds a fake HTML element `<include>path/to/file</include>`.
For example:

```html
<include> includes/footer.html </include>
```

When it encounters this element, it reads the `includes/footer.html` file and replaces the include element with its content.

By default the file is parsed as HTML, but you can also include it as raw text with HTML special
characters escaped, using `<include raw>...</include>`.

You can specify either an absolute or a relative path. If a relative path is given,
it’s relative to the current directory where you run soupault.

Sample configuration:
```
[widgets.process-include-tags]
  widget = "inline-include"
```

Download: <a href="/files/plugins/inline-include.lua">inline-include.lua</a>.

### Quick links

Requires soupault 1.10 or newer.

Provides fake HTML elements for easily creating links to popular websites.

Supported elements:

* `<wikipedia lang="fr" page="Philippe Soupault">surrealist writer</wikipedia>` (result: <wikipedia lang="fr" page="Philippe Soupault">surrealist writer</wikipedia>)
* `<github project="dmbaturin/soupault">soupault</github>` (result: <github project="dmbaturin/soupault">soupault</github>)
* `<sourcehut project="dmbaturin/soupault">soupault</sourcehut>` (result: <sourcehut project="dmbaturin/soupault">soupault</sourcehut>)
* `<mastodon user="@dmbaturin@mastodon.social">me on mastodon</mastodon>` (result: <mastodon user="@dmbaturin@mastodon.social">me on mastodon</mastodon>).
* `<twitter user="dmbaturin">me on twitter</twitter>` (result: <twitter user="dmbaturin">me on twitter</twitter>)
* `<rfc number="1945">HTTP RFC</rfc>` (result: <rfc number="1945">HTTP RFC</rfc>).

All elements also support a short form where the content becomes the link data:
* `<wikipedia>Philippe Soupault</wikipedia>`
* `<github>dmbaturin/soupault</github>`
* `<sourcehut>dmbaturin/soupault</sourcehut>`
* `<mastodon>@dmbaturin@mastodon.social</mastodon>`
* `<twitter>@dmbaturin</twitter>` (@ is optional)
* `<rfc>RFC1945</rfc>` (automatically extracts 1945)

Social media link elements also support `me` attribute. For example, `<mastodon me user="@dmbaturin@mastodon.social">`
is translated to `<a rel="me" href="https://mastodon.social/@dmbaturin">`.

Sample configuration:

```toml
[widgets.convert-quick-links]
  widget = "quick-links"
  wikipedia_default_language = "fr"
```

Download: [quick-links.lua](/files/plugins/quick-links.lua)

### Hyperlinked glossary

Requires soupault 3.0.0 or newer.

Provides a way to make a hyperlinked glossary.

This plugin has no configurable options (as of now). You only need to enable it to run on your pages.

```toml
[widgets.make-glossary]
  widget = "glossary"
```

To make a glossary, first, define a `<glossary>` element with terms:

```html
<glossary>
  <definition name="sepulka">
    A prominent element of the civilization of Ardrites from the planet of Enteropia; see “sepuling”.
  </definition>
  <definition name="sepuling">
   An activity of Ardrites from the planet of Enteropia; see "sepulka".
  </definition>
</glossary>
```

Then you can refer to them like this: `<term>sepulka</term>` anywhere in the page.
Any `<term>` elements that have glossary definitions will be automatically converted to hyperlinks.
All other terms will be ignored. The glossary itself will be made into a `<dl>`.

You can see this plugin at work in the [reference manual](/reference-manual) page.

Download: [glossary.lua](/files/plugins/glossary.lua)

