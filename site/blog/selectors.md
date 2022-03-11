<h1 id="post-title">Using selectors</h1>

<span>Date: <time id="post-date">2019-11-13</time> </span>

<p id="post-excerpt">
Soupault turns the traditional HTML processor workflow upside down: instead of inserting a placeholder like <code>{{header}}</code>
or <code>{{content}}</code> in your page, you point it at a specific element in your page using CSS selectors. That’s what allows
it to work with unmodified websites and find elements regardless of their exact location in the page.
It also saves you learning time since everyone who ever wrote a CSS stylesheet already knows the basic selector syntax.
However, there are less well-known features of the CSS standard that may help you find elements with better precision—let’s take a closer look at them.
</p>

## The basics

The concept of a selector came from CSS. Every CSS rule consists of a selector that defines what elements it applies to, and
a list of declarations that define the style for those elements.

In a rule like `body { max-width: 1000px; }`, `body` is a _selector_, and `{ max-width: 1000px; }` is a _declaration block_.

Since then it became something of an unofficial “HTML query” standard. It may be less expressive and powerful than XQuery/XPath,
but every webmaster already knows it, and it’s good enough for most practical cases.

It was adopted by client-side JavaScript libraries like jQuery and eventually
by the [DOM API standard](https://www.w3.org/TR/selectors-api/) itself. Instead of using a whole family of functions like
`getElementById`, `getElementsByClassName` etc. you now can use a single `document.querySelector` function for all those tasks.
For example, extract the first paragraph with `document.querySelector("p")` or all elements with `class="myclass"` with `document.querySelectorAll(".myclass")`.

Web browsers are not the only programs that can read HTML though, and selectors have been used by web scraping libraries like BeautifulSoup
and automated testing tools like Selenium for a long time as well.

Soupault uses the same approach. It uses a fast and fully-functional HTML parsing library named [lambdasoup](https://aantron.github.io/lambdasoup)
that supports almost every kind of selectors CSS3 has to offer. 

## Selector options in soupault

The first place where a selector is used is the `content_selector` option in settings. It’s very relevant in the website generator mode:
if a page is not a complete HTML document (i.e. doesn’t have an `<html>` element in it), that page is inserted into the template.

That option defines where exactly in the template it will be inserted. By default it’s appended to the document body element:

```toml
[settings]
  content_selector = 'body'
```

Then almost every widget has a `selector` option. For some widgets it’s their source element, for others it’s the target. The meaning can usually be
inferred from context. For example, the `title` widget that sets the page title always inserts its output in the `<title>` element, so the
`selector` option defines the element it takes the title _from_. For `insert_html` or `include` it defines the target element where they insert
their output. If in doubt, consult the reference manual.

Selectors are also used by the site index generator, to extract data from pages. A very simple ‘blog’ can be made from an existing site by using
the first `<h1>` for the post title and the first `<p>` for the excerpt, for example.

Last but not least, the Lua plugin API provides `HTML.select` and `HTML.select_all` function that take a selector as an argument.

## What doesn’t work?

If you are well familiar with CSS selector syntax already, you are likely wondering how complete the implementation is.

One thing that doesn’t work but I hope will work some day is comma-separated selectors. You cannot do something like `selector = 'h1, h2, h3'`.
Some widgets allow lists of selectors to work around it. For example, this is how you can set the page title to the first `<h1>` if page has it,
or to the `<h2>` if there’s no `<h1>`:

```toml
[widgets.set-title]
  widget = 'title'
  selector = ['h1', 'h2']
```

Not all widgets support it as of 1.5, but I’m planning to improve it in the next releases.

Another thing that doesn’t work and cannot work is selectors that imply a user interface or layout. Pseudo-classes like `:visited`
or `:hover` can only work in an interactive web browser.

## Attribute selectors

Many pages already have elements with `class` or `id` attributes used for CSS styling. It’s easy to reuse them as targets for soupault’s widgets.

The id selector will find any element with a certain id. For example, if you have a `<div id="footer">` in your page and want to insert a footer file in that div,
you can do it like this:

```toml
[widgets.footer]
  widget = 'include'
  selector = '#footer"
  file = 'templates/footer.html'
```

You can make it more specific by changing it to `div#footer`.

If you are using a `<div class="footer">` for that, it’s also easy to do. Just use `selector = "div.footer"` instead.

What’s somewhat less known is that you can query arbitrary attributes. For example, the `#footer` selector is really a shortcut for 
`selector = 'div[id="footer"]'`. The real power of that extended syntax is that it’s not limited to exact matching.

You can use a variety of comparison operators there. For example, `selector = 'div[id^="some"]'` will match any element whose
id begins with `some`, like `<div id="some-div">` or `<div id="some-block">`. The full list can be found in the
[W3C standard](https://drafts.csswg.org/selectors-3/#attribute-selectors).

## Element selectors

HTML5 introduced a bunch of elements like `<header>`, `<footer>`, `<nav`>, `<main>`, `<aside>` and some others to better reflect a typical page structure.
If you like that approach and want your footer to be inserted in the `<footer>` element, then it’s even easier.

The simplest possible selector is a tag name, like `selector = 'footer'`.

```toml
[widgets.footer]
  widget = 'include'
  selector = 'footer"
  file = 'templates/footer.html'
```

If you are working with existing pages, you may find descendent and child selectors useful. This is how you can set the page title
to the first `<h1>` found _inside_ a `<div id="content">`:

```toml
[widget.set-title]
  widget = 'title'
  selector = 'div#content h1'
```

If you want to find the first immediate child (i.e. not contained inside an intermediate element), you can use `div#content > h1`
selector instead.

## Matching element content

Apart from standard CSS syntax, there’s also a non-standard `:contains()` pseudo-class. It once was in the CSS standard [draft](https://www.w3.org/TR/2001/CR-css3-selectors-20011113/#content-selectors).
but never made it to the standard. However, when working with existing pages, it can be especially useful as a last resort.

This is how you can append “[Carthage must be destroyed](https://en.wikipedia.org/wiki/Carthago_delenda_est)” to any paragraph that mentions Carthage:

```toml
[widgets.cato-the-elder]
  widget = "insert_html"
  selector = 'p:contains("Carthage")'
  html = ' Carthage must be destroyed.'
```

Note that comparison is case-sensitive.

## Conclusion

A combination of a right selector and an appropriate `action` option should allow you to insert or extract what you want
with a good precision. There’s clearly still room for improvement, but I hope even now you can start automating
tasks you find annoying without having to modify your pages just to do that.
