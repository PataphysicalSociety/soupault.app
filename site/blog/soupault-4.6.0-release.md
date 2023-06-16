<h1 id="post-title">Soupault 4.6.0 release</h1>

<p>Date: <time id="post-date">2023-06-16</time> </p>

<p id="post-excerpt">
Soupault 4.6.0 is available for download from <a href="https://files.baturin.org/software/soupault/4.6.0">my own server</a>
and from <a href="https://github.com/PataphysicalSociety/soupault/releases/tag/4.6.0">GitHub releases</a>.
It improves error reporting for configs with duplicate option names and adds a bunch of useful plugin API functions.
</p>

## New features and improvements

### New plugin API functions

* `Sys.getenv(name, default_value)` function (`default_value` is optional).
* `String.ends_with(string, suffix)`.
* `String.is_valid_utf8(string)` and `String.is_valid_ascii(string)` functions.
* `Table.length(table)` — returns the number of items in a table.
* `Table.for_all(func, table)` — checks if boolean function `func` is true for all items in a table.
* `Table.for_any(func, table)` — checks if boolean function `func` is true for at least one item in a table.
* `Table.is_empty(t)` — returns true if `t` has no items in it.
* `Table.copy(t)` — returns a copy of the table `t`.
* `HTML.is_empty(e)` — returns true if `e` has zero child nodes.
* `HTML.is_root(e)` — returns true if `e` has no parent node.
* `HTML.is_document(e)` — returns true if `e` is a soup (document) node rather than an element or a text.
* `Value.is_html(v)` — returns true is `v` is an HTML document or node.

## Bug fixes

* Fixed an unhandled OTOML exception when loading configs with duplicate key names (such issues generate proper parse errors now).
