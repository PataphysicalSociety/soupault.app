<h1 id="post-title">Soupault 1.9.0 release</h1>

<p>Date: <time id="post-date">2020-02-28</time> </p>

<p id="post-excerpt">
Soupault 1.9.0 is available for <a href="https://files.baturin.org/software/soupault/1.9.0/">download</a>
or installation from the <a href="https://opam.ocaml.org">opam</a> repository.
It now offers a <code>--index-only</code> option for people who want to extract site metadata to JSON
and stop at that. There are also multiple improvements in the plugin API and the <code>preprocess_element</code> widget support,
as well as bug fixes.
</p>

## Verifying release integrity

Since 1.9.0, soupault uses <a href="https://jedisct1.github.io/minisign/">minisign</a> rather than PGP for release signing.
If you are new to signify/minisign, you should read
<a href="https://www.openbsd.org/papers/bsdcan-signify.html">signify: Securing OpenBSD From Us To You</a> paper by Ted Unangst.
There’s much less overhead compared to PGP, and the keys are much shorter due to less metadata embedded in them and use of
newer elliptic curve algorithms.

You can verify the releases using this key: `RWRfW+gkhk/+iA7dOUtTio6G6KeJCiAEp4Zfozw7eqv2shN90+5z20Cy`.

For example:

```
minisign -Vm soupault-1.9.0-win32.zip -P RWRfW+gkhk/+iA7dOUtTio6G6KeJCiAEp4Zfozw7eqv2shN90+5z20Cy
```

If you have any doubts about the authenticity of the key, feel free to contact me directly.

## New features

### `--index-only`

There’s now a `--index-only` option that makes soupault stop at metadata extraction. It just dumps the index data
to a JSON file specified in the `dump_json` option, but doesn’t generate any pages.

It will run widgets that are supposed to run before the index extraction though, if you’ve configured the
`extract_after_widgets` option (the reading time plugin on this site is a good example of why this may be needed—that widget
must run before metadata extraction so that the reading time can appear in the blog index page).

There are two use cases for this. First, it may be useful for people who want to generate an index page or an RSS/Atom/JSONFeed
for a handwritten website. Second, it can be a step in a TeX-like workflow. Since soupault doesn’t create page files on principle,
the intended way to generate a blog archive or a list of all pages is to export the metadata to JSON and run it through
a script that makes pages, then run soupault again to assemble a complete website. With `--index-only`, you can make
that process faster.

### Limiting index extraction to some pages or sections

You already could <a href="/reference-manual/#limiting-widgets-to-pages-or-sections">limit</a> widgets to certain pages, sections, or path regular expressions.
Now you can <a href="/reference-manual/#limiting-index-extraction-to-pages-or-sections">do the same</a> for index extraction, if you want to index
just a `/blog` section for example.

Likewise, you can also limit index extraction to a specific build profile.

### Multiple selectors for `preprocess_element` widgets

It’s now possible to use a list of selectors with `preprocess_element` widgets, to avoid redundancy in the configs.

```
[widgets.syntax-highlight]
  widget = "preprocess_element"
  selector = ["code", "pre"]
  ...
```

### New plugin functions

It’s now possible to extend soupault with plugins, external programs, or 
<a href="https://tvtropes.org/pmwiki/pmwiki.php/Main/BreadEggsBreadedEggs">plugins that run external programs</a>.

Specifically, there are now `Sys.run_program` and `Sys.get_program_output` functions that you
can use in your plugins. It doesn’t add much more expressive power, but it can make some things easier.
For example, I use it in a <a href="/plugins/#git-timestamp">plugin</a> that takes a page modification date from git unless that page has a handwritten
timestamp in `<time id="last-modified">`.

There are also functions for easily accessing children, descendants, and siblings of an element, functions for deleting and cloning element content,
and a few more convenience functions.

### Bug fixes

The `title` widget correctly removes all HTML tags from the title string (if there are any). It also doesn’t add extra whitespace anymore.
Both fixes were made by <a href="https://soap.coffee/~lthms/">Thomas Letan</a>.

CSS selector syntax errors are now handled gracefully. That took a <a href="https://github.com/aantron/lambdasoup/pull/31">pull request</a>
to lambdasoup.
