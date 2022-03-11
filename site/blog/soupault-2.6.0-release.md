<h1 id="post-title">Soupault 2.6.0 release</h1>

<p>Date: <time id="post-date">2021-04-15</time> </p>

<p id="post-excerpt">
Soupault 2.6.0, is available for download from <a href="https://files.baturin.org/software/soupault/2.6.0">my own server</a>
and from <a href="https://github.com/dmbaturin/soupault/releases/tag/2.6.0">GitHub releases</a>.
It’s a relatively small release with a few bug fixes and one new feature: configurable index entry sorting method.
</p>

## Bug fixes

* Removed a dependency on the [stringext](https://github.com/rgrinberg/stringext) library that is no longer necessary.
* Fixed empty page output in a situation when the config has `generator_mode = false` and `keep_doctype = false`, and the page lacks an `<HTML>` element (#27).
* Malformed dates no longer cause soupault to crash (that could happen due to incomplete exception handling).

## Configurable entry sorting

Originally, soupault assumed that the index entry sort key field is some kind of a date. You could configure supported date formats using the
`index_date_formats` option, and it would attempt to parse every value as a date, or resorted to lexicographic comparison if parsing failed.

A lot of websites with auto-generated index pages are blogs, so that assumption wasn’t terribly unreasonable. However, it still was a rather
inflexible design.

Now there’s a new option: `sort_type` that can have three values: `calendar` (the default), `numeric`, and `lexicographic`.

The `calendar` mode matches the old behaviour: it tries to parse a field value as a date according to supported `index_date_formats`.
Invalid values are considered "older" than any valid values. Between themselves, invalid values are compared lexicographically.

In the `numeric` mode, soupault will try to parse values as integer numbers. Invalid values are considered "less" than any valid values.
This is useful in cases when you want to order pages or sections by "weight".

In the `lexicographic` mode, soupault will simply compare values as strings.

There’s also a new `strict_sort` option. If it’s set to `true`, then soupault will log an error and terminate if it finds a value
that cannot be parsed.

Example:

```toml
[index]
  sort_type = "numeric"
  strict_sort = true
```

## Acknowledgements

Thanks for testing and suggestions to Anton Bachin and Javier Chávarri who now use soupault in the documentation workflows for [Dream](https://aantron.github.io/dream/)
and [Melange](https://jchavarri.github.io/melange-docs/) respectively.
