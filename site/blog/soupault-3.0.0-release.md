<h1 id="post-title">Soupault 3.0.0 release</h1>

<p>Date: <time id="post-date">2021-07-19</time> </p>

<p id="post-excerpt">
Soupault 3.0.0, is available for download from <a href="https://files.baturin.org/software/soupault/3.0.0">my own server</a>
and from <a href="https://github.com/dmbaturin/soupault/releases/tag/3.0.0">GitHub releases</a>.
It uses a new, fully standard-compliant TOML parsing library, and also adds new features, such as colored log headers,
Lua plugin functions for loading TOML and YAML data, and a more precise selector for the title widget.
The 3.0.0 version shouldn’t scare you: the breaking change is that the old library used to allow certain invalid
TOML syntax while the new one does not, so you are unlikely to be affected and if you are, it’s an easy fix—but technically
it’s still a breaking change and must be marked as such.
</p>

## Colored log messages

On UNIX-like systems, log levels are now colored: debug is blue, info is green, warning is yellow, and error is red.
On Windows, color is disabled because most Windows terminals still don’t support it.

If you prefer monochrome outputs, you can disable it using `NO_COLOR=` environment variable.

```
NO_COLOR=1 soupault
```

It’s only the presence of the `NO_COLOR` variable that matters, its value is ignored, so you can set it to any value.
You can read about the `NO_COLOR` standard initiative at [no-color.org](https://no-color.org).

## The new TOML library

The old TOML library had multiple issues, but it was also the only TOML library for OCaml—most people in the OCaml community
prefer S-expressions for configuration files (which have their advantages, but TOML is much more familiar for the target audience).
For a long time I put up with its shortcomings, but I had a plan to make a really good TOML library for a long time,
and this summer the plan finally came to frutition: I released [OTOML](https://opam.ocaml.org/packages/otoml/)
and migrated soupault to it.

It took a lot of effort to make it fully compliant with the TOML spec, but now it passes all tests in the 
[test suite](https://github.com/BurntSushi/toml-test) and also provides a very flexible pretty-printer.

Why is this release soupault 3.0.0 rather than 2.9.0 then? Well, the problem is that the old library
used to allow certain configs that weren’t actually valid TOML documents. If your config was valid TOML,
then you have nothing to worry about.

However, if you used line breaks inside inline tables, then your config will not load anymore. Here’s an example:

```toml
# Invalid TOML!
[index.fields]
  title = {
    selector = "h1"
  }
```

To make it work again, simply remove the line breaks:

```toml
[index.fields]
  title = {selector = "h1"}
```

Or convert it to a non-inline table:

```toml
[index.fields.title]
  selector = "h1"
```

I wish the TOML standard _did_ allow line breaks inside inline tables (after all, it allows them in arrays),
and I hope TOML 1.1 (or 2.0...) will allow them, but until then, it’s better to stick with the standard
so that soupault configs can be manipulated by other TOML tools (formatters etc.).

There may be more such cases. The OTOML library provides friendly parse error messages for many conditions,
so I hope even if you run into issues, they will be easy to fix. If not, don’t hesitate to contact me about it.

One advantage of the new library is that options in `soupault --show-effective-config` are now guaranteed to come
in the same order as in your `soupault.toml/`soupault.conf`. This way it’s much easier to diff them,
either visually or with diff tools.

## TOML and YAML parsing functions

I wanted to make it possible to load TOML files from Lua for a long time.
[JSON parsing](/reference-manual/#JSON) is sufficient in most cases, but TOML is much more human-friendly.
If it’s easy to read external data from plugins, it opens up many possibilities that were mostly provided
only by JavaScript frameworks before that. The reason I haven’t done it earlier is that I didn’t want
to expose potential plugin writers to a _bad_ TOML library.

Now that’s not an issue anymore. And while I was at it, I added YAML support, too, since people may already
have YAML data they may want to migrate to soupault.

The functions follow the same pattern as JSON ones:

```
TOML.from_string()
TOML.from_string_unsafe()

YAML.from_string()
YAML.from_string_unsafe()
```

The `unsafe` versions will return a `nil` if the data is invalid, while the ‘normal’ versions will raise
a plugin error in that case.

## Future plans

Now that the TOML library replacement is done, I’m going to work on the long-promised system of hooks.
My plan to make it flexible enough to allow Lua code to take over virtually any stage, so that
it will be possible to do pagination, reimplement front matter to import pages from other SSGs without changes
and more. Stay tuned!

## Soupault’s second anniversary!

Soupault 1.0.0 release was made two years ago. Not every side project gets to celebrate its second anniversary,
and I’m glad it’s useful for other people.

I’d like to say special thanks to:

* Hristos N. Triantafillou, Thomas Letan, Anton Bachin, toastal, Aoirthoir An Broc, and everyone who contributed to soupault and helped to test it over these two years.
* The [OCaml](https://ocaml.org) compiler team and developers of the libraries soupault depends on<fn>Even the authors of To.ml, the TOML library I had to replace—it still provided me with TOML parsing at least. ;)</fn>. Without a fast, expressive, and type-safe language and such a great HTML manipulation library as [lambdasoup](https://github.com/aantron/lambdasoup), this project wouldn’t be possible.
* The now-defunct bakery that, unbestknown to them, provided fuel for initial development.



<hr>
<div id="footnotes"> </div>
