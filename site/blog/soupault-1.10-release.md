<h1 id="post-title">Soupault 1.10.0 release</h1>

<p>Date: <time id="post-date">2020-03-25</time> </p>

<p id="post-excerpt">
Soupault 1.10.0 is available for <a href="https://files.baturin.org/software/soupault/1.10.0/">download</a>
or installation from the <a href="https://opam.ocaml.org">opam</a> repository.
It's not a very big release, but there are some bug fixes and improvements I'd like to make available to the users
before starting to work on big internal changes. New features you will find in this release include
automatic plugin discovery, correct handling of files without extensions, and new plugin functions.
</p>

## Verifying release integrity

Starting from the 1.9.0 release, soupault uses <a href="https://jedisct1.github.io/minisign/">minisign</a> rather than PGP for release signing.
If you are new to signify/minisign, you should read
<a href="https://www.openbsd.org/papers/bsdcan-signify.html">signify: Securing OpenBSD From Us To You</a> paper by Ted Unangst.
There's much less overhead compared to PGP, and the keys are much shorter due to less metadata embedded in them and use of
newer elliptic curve algorithms.

You can verify the releases using this key: `RWRfW+gkhk/+iA7dOUtTio6G6KeJCiAEp4Zfozw7eqv2shN90+5z20Cy`.

For example:

```
minisign -Vm soupault-1.10.0-win32.zip -P RWRfW+gkhk/+iA7dOUtTio6G6KeJCiAEp4Zfozw7eqv2shN90+5z20Cy
```

If you have any doubts about the authenticity of the key, feel free to contact me directly.

## Bug fixes

### Files without extensions

I've accidentally discovered that if you place a file without an extension in the site directory,
soupault crashes with an unhandled exception. Since files without extensions are quite rare on the web
(UNIX executables are usually distributed in tarballs rather than naked), this problem remained
undiscovered for a while, which made it an even more embarassing find.

The cause was in an unexpected inconsistency
in the [FileUtils](https://sylvain.le-gall.net/ocaml-fileutils.html) library API:
the `FilePath.get_extension` raises an exception when a file has no extension,
while all other similar functions return an empty string in that case. I'll work
with the maintainer to see if it can be fixes in the upstream, but for now I've added
a workaround and such files are handled correctly.

If you want special handling for those files, e.g. you want to ignore them, then
something like `ignore_extensions = ['']` _should_ work. Let me know if you run into any problems.

## New features

### Plugin discovery

In a [mailing list discussion](https://lists.sr.ht/~dmbaturin/soupault/%3C20200302072937.uy23fekfi2sseye3%40ideepad.localdomain%3E),
[Thomas Letan](https://soap.coffee/~lthms/) suggested plugin auto-discovery feature.

Indeed, in previous versions, installing plugins was harder than it _could_ be, since you'd have to
configure plugin loading by hand, like:

```toml
[plugins.my-plugin]
  file = "plugins/my-plugin.lua"
```

Now, if your config refers to a widget that is not a built-in and is not associated with an explicitly loaded plugin,
soupault will try to find `my-plugin.lua` in plugin directories.

The default configuration of that feature is:

```toml
  plugin_discovery = true
  plugin_dirs = ["plugins"]
```

Suppose you have this configuration:

```toml
[widgets.some-cool-widget]
  widget = "my-plugin"
```

Then if `plugin_discovery` is `true`, it will try to find a file named `my-plugin.lua` in `plugins/`.

You can specify multiple directories, e.g. `plugin_dirs = ['plugins', '/usr/share/soupault/plugins']`.
Note that you _cannot_ use `~` or environment variables there, so `plugin_dirs = ['~/.local/share/soupault/plugins']` will *not* work.


### New plugin functions

With `HTML.get_tag_name` function, you can get the name of an element. It was a rather unfortunate omission.

Soupault doesn't support commas in selectors, like in `div, span`, so working with multiple selectors wasn't easy. With `HTML.select_any_of` and `HTML.select_all_of`
you can select the first match or all matching elements using a list of selectors. For example, `HTML.select_any_of(page, {'blink', 'marquue'})`
will select the first `<blink>` or `<marquee>` element from the page, while `HTML.select_all_of(page, {'blink', 'marquue'})` will select all those elements.

### &ldquo;Monadic&rdquo; HTML interface

All element tree access functions from the `HTML` module, like `HTML.select`, could return either an HTML element or a `nil`.
However, none of them would accept a `nil` for an argument, which meant you'd have to check for nil at every step to avoid errors.

Now they behave similar to what OCaml or Haskell users would call a maybe/option monad. That is, if you give those functions a `nil`,
they instantly return a `nil`, while if you give them valid data, they do something to that data.

```lua
HTML.select(nil, "p") = nil
HTML.select(page, "p") = <element list>
```

This way, you still can check for `nil` where appropriate, or you can just chain calls like `HTML.delete_element(HTML.select_one(page, "body"))`
and those chains will automatically stop on the first `nil` rather than cause a runtime error.

### OS checks

Since plugins can run external programs now, they may need OS-specific workaround, e.g. different command names on UNIX and Windows.
Now you can check where your plugin is running with `Sys.is_unix ()` and `Sys.is_windows ()`.

## New JSON index data field

There's now `page_file` field in the JSON index dump. It contains the original page file path.

## Future plans

The first thing I have to admit is that the codebase got a bit messy over time. It also contains some anti-optimizations
such as not caching even easily cacheable things (e.g. reading the same files over and over again). If you pick a fast language,
you can get away with such things and still be reasonably fast, but the code can be made cleaner and faster.

Another thing is the TOML library. [To.ml](http://mackwic.github.io/To.ml/) isn't bad, but it's designed with an assumption
that the user knows what to look for. It's true for config files with a fixed set of options, but it quickly becomes a headache
if you add plugin support and need to pass chunks of the config to plugins, with arbitrary options or arbitrary types.

I'm going to stop and write a new TOML reading library that will make reading and handling arbitrary data easy,
so that plugins can take options of any types, rather than just strings.

Thus, there may be a slowdown in soupault development. Or there may not be, time will tell. If I come up with something
useful or community members submit pull requests, I'll make new releases based on the current codebase, while working
on the internal improvements in separate branches.
