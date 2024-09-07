<h1 id="post-title">Soupault 4.11.0 release</h1>

<p>Date: <time id="post-date">2024-09-06</time> </p>

<p id="post-excerpt">
Soupault 4.11.0 is available for download from <a href="https://files.baturin.org/software/soupault/4.11.0">my own server</a>
and from <a href="https://github.com/PataphysicalSociety/soupault/releases/tag/4.11.0">GitHub releases</a>.
It adds a plugin function for checking if HTML element tree nodes are tree nodes (<code>HTML.is_text()</code>),
and fixes and issue with <code>HTML.is_document()</code>. Also, thanks to a lambdasoup update,
now there is support for <code>:has()</code> selector in options that accept CSS selectors
and another bug fix: namespaces are now correctly preserved in attribute named.
</p>

## New features

* It's now possible to use `:has()` selector in options that accept CSS selectors (implemented in lambdasoup 1.1.0)

### New plugin API functions

* `HTML.is_text(e)` — checks if an HTML element tree node is a text node. Thanks to [Jayesh Bhoot](https://bhoot.dev/)

## Bug fixes

* `HTML.is_document(e)` now correctly returns true for values created with `HTML.parse()` and `HTML.create_document()`.
* Namespaces are now correctly preserved in HTML element attribute names (implemented in lambdasoup 1.1.1).
