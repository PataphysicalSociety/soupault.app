<h1 id="post-title">Tables of contents</h1>

<div id="generated-toc"> </div>

<span>Date: <time id="post-date">2019-11-07</time> </span>

For a long document, table of contents is an essential navigation aid. Maintaining it by hand is a very
tedious task though. Soupault makes it very easy to do—just add a few lines to `soupault.conf`,
and it will create a table of contents from your page headings. However, there's more to it:
it allows easily linking to document sections and provides multiple styling options.

<p id="post-excerpt">
ToC functionality in static site generators is often far from great, and people are turning to hacks
like <a href="https://gist.github.com/skyzyx/a796d66f6a124f057f3374eff0b3f99a">parsing</a> generated HTML with regular expressions,
<a href="https://github.com/dafi/jekyll-toc-generator">adding an HTML parser</a> to a template-based workflow,
and even creating <a href="https://github.com/helmbold/tocfix">external tools</a> to fix buggy output. I'm clearly not the only
one who wants good tables of contents, so I set out to make it as close to perfect as possible. My understanding of perfect here is
robust and configurable. Let's how it works and how to setup it.
</p>

So, what's good about it? First, it handles missing levels gracefully. If you have something like `h2 h1 h3 h2` in your page,
the ToC will look somewhat odd, but it will be complete and functional.

Second, since it's generated from the HTML element tree, after preprocessing steps (if any), it will work the same regardless of the page source format.
If the tool you use for converting Markdown/reStructuredText/AsciiDoc etc. can emit HTML with headings,
the ToC widget will work with them. In some generators, it only works for one format but not another, or even for one Markdown flavor but not another.
There are no such limitations in soupault, so you don't need to worry about it.

Third, you have pretty good control over its look and behaviour and can style the ToC itself and &ldquo;link to this section&rdquo;
elements as you please.

Last but not least, it preserves HTML _inside_ headers, so something like `<h2>Properties of e<sup>x</sup></h2>` will produce a correct
ToC link like <a href="#">Properties of e<sup>x</sup></a>.

This is the ToC config for this website:

```toml
[widgets.table-of-contents]
  widget = "toc"
  selector = "#generated-toc"

  min_level = 2

  toc_list_class = "toc"

  numbered_list = false

  heading_links = true
  heading_link_text = "→ "
  heading_link_class = "here"

  use_heading_slug = true
```

Let's see what it all means and what else is possible.

The best place to see the ToC in action is the <a href="/reference-manual">reference manual</a>.

## Simple example

The simplest possible config is:

```toml
[widgets.toc]
  widget = 'toc'
  selector = 'body'
  action = 'prepend_child'
```

It will insert a ToC in every page that has headings, just before the first element you have in `<body>`.

Myself I don't want it in every page, so I use `selector = '#generated-toc'`. This way soupault only inserts
it in pages that have an element with `id="generated-toc"`. I add a `<div id="generated-toc"> </div>` to pages
where I want it, and all other pages are automatically excluded.

## Basic settings

First, you get a choice between numbered and unnumbered lists (i.e. `<ol>` vs `<ul>`.
It's controlled by the `numbered_list` option that can be `true` or `false` (the default is `false`).

Second, you get to choose the minimum heading level to include in the ToC. The default is 1 (`<h1>`),
but if you are using `<h1>` for your page titles like I do, you'll likely want to exclude it.
Not a problem, just use `min_level = 2` or greater.

## Styling the ToC

First, you get a choice between numbered and unnumbered lists (i.e. `<ol>` vs `<ul>`.
It's controlled by the `numbered_list` option that can be `true` or `false` (the default is `false`).

Then you can set the class for the topmost list element with `toc_list_class` option, e.g. `toc_list_class = "toc"`.

But that's not all. You can also make it use a different class for each level if you add `toc_class_levels = true`.

Suppose you setup it like this:

```toml
[widgets.toc]
  widget = "toc"
  selector = "body"
  numbered_list = false
  toc_list_class = "toc"
  toc_class_levels = true
```

Then your generated HTML will look like:

```html
<ul class="toc-1">
  <li> <a href="#chapter-1">Chapter 1</a> </li>
  <ul class="toc-2">
    <li> <a href="#section-1">Section 1</a> </li>
    <ul class="toc-3">
      <li> <a href="#subsection-1">Subsection 1</a> </li>
    </ul>
 </ul>
</ul>
```

so you can style different levels independently.

## Section links

For technical documentation or any long, structured document like a novel,
it's nice to be able to link directly to a specific document section, like
<a href="/reference-manual/#widgets-toc">/reference-manual/#widgets-toc</a>.

Soupault will create a link for every heading if you add `heading_links = true` to the config.

The default link text is `#`. I chose it because it's safe for any character encoding, relatively popular,
and invokes an association with the HTML anchor syntax. I don't like it though, so I use
`heading_link_text = "→ "` instead. Note that in the current version you cannot put HTML inside
that text (it can be made to work, so if you want that ability, let me know).

You can style those links though. I give them `here` class with `heading_link_class = "here"`.
My CSS for `a.here` is very simple, it just removes the underline, but with CSS features like `:before` and `:after`
you can modify them like you want.

Also, if you want those links to appear after the heading, rather then before it like on this site, you can use `heading_links_append = false`.

Finally, you get to choose what's used for the anchor. With `use_heading_text = true` soupault will not &ldquo;slugify&rdquo; the headings
and just use the unchanged heading text. In the current version, it's the only option for non-ASCII languages, since slugification removes
everything that isn't alphanumeric characters. Slugifying unicode is a complicated subject, but if you have ideas how to do it best, please share.
