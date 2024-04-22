<h1 id="post-title">Soupault 4.10.0 release</h1>

<p>Date: <time id="post-date">2024-04-22</time> </p>

<p id="post-excerpt">
Soupault 4.10.0 is available for download from <a href="https://files.baturin.org/software/soupault/4.10.0">my own server</a>
and from <a href="https://github.com/PataphysicalSociety/soupault/releases/tag/4.10.0">GitHub releases</a>.
It fixes the <code>complete_page_selector</code> option that unfortunately was broken in recent releases.
It also fixes a few bugs with TOML parsing that affected Windows users and adds a new option to the <code>delete_element</code>
widget that allows deleting elements only if they don't have certain children inside.
</p>

## New features

### Deleting only elements that do not have certain children

The `delete_element` widget has a new option: `when_no_child`.

For example, suppose you have footnotes container in your template that looks like this:
`<div id="footnotes"> <hr class="footnotes-separator"> </div>`. If a page has footnotes,
it would contain something like `<p class="footnote">...`. If not, it would only have the `<hr>` element in it.

Deleting it from pages that don't have any footnotes cannot be done with `only_if_empty`
because the container has that auxilliary element in it.

However, with the new option you can make the widget delete the container
only if nothing inside it matches the selector of actual footnotes.

```toml
[widgets.clean-up-footnote-containers]
  after = "footnotes"
  widget = "delete_element"
  selector = "div#footnotes"
  when_no_child = "p.footnote"
```

## Bug fixes

* Complete HTML pages work correctly in generator mode again (report by Auguste Baum)
* Config files with multiline strings and Windows newlines (CRLF) no longer cause parse errors
  (report by Bohdan Kolesnikov)
* Configs that consist of a single comment line followed by EOF no longer cause parse errors
  (found thanks to the TOML test suite v1.4.0)
