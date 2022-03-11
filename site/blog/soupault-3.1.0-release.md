<h1 id="post-title">Soupault 3.1.0 release</h1>

<p>Date: <time id="post-date">2021-08-16</time> </p>

<p id="post-excerpt">
Soupault 3.1.0, is available for download from <a href="https://files.baturin.org/software/soupault/3.1.0">my own server</a>
and from <a href="https://github.com/dmbaturin/soupault/releases/tag/3.1.0">GitHub releases</a>.
It’s a small quality of life and bugfix release. It adds plugin functions for platform-independent UNIX/URL path manipulation,
and new functions for ordered iteration through tables.
The ToC widget now has an option to ignore headings that match certain selectors.
Finally, specifying a widget twice by accident in the <code>after</code> option no longer causes a false positive dependency cycle
detection.
</p>

## UNIX/URL path manipulation on all platforms

The URL path convention uses forward slashes as directory separators because Tim Burners-Lee used a UNIX cultural assumption.
Thus for UNIX-like system users, filesystem path and URL path is one and the same and the same functions can be used for manipulating them.

For Windows users, the situation is obviously different. The `Sys.join_path` function from the plugin API is correctly OS-dependent
and `Sys.join_path("foo", "bar")` returns `foo\bar` there, which is good for filesystem paths, but not URLs.

In a plugin a I made for my personal website lately I had to automatically generate URLs from directory and file parts,
and I realized that the current API won’t work for Windows users who will want to do that same.

So I went and added `Sys.join_path_unix`, `Sys.basename_unix`, and `Sys.dirname_unix`. These functions use the forward slash convention
regardless of the host OS so they are safe to use with URLs.

## Ordered iteration

Lua uses an "everything is an unordered hash table" approach. It’s a royal headache when order is required, to the point that I’m thinking
of writing a Scheme interpreter on the same principles as [Lua-ML](https://github.com/lindig/lua-ml).<fn>If you missed that story,
soupault uses an alternative Lua implementation that offers modular and type-safe integration with the host program
(unlike the PUC-Rio Lua, which offers neither), but implements an outdated Lua 2.5.</fn>

However, as long as soupault doesn’t support anything but Lua, we have to keep finding workarounds for those issues.

In Lua, "arrays" are hash tables indexed by numeric keys. Lua 2.5 doesn’t have `for`-loops so the "intended" way to iterate through an array
in a loop with a counter.

```lua
local n = 1
while tbl[n] do
  dothings(tbl[n])
  n = n + 1
end
```

The catch is that if there’s a hole in the keys, it will stop the iteration early. Funnily enough, it’s not a solved problem in the
modern Lua versions either!

```lua
Lua 5.4.3  Copyright (C) 1994-2021 Lua.org, PUC-Rio
> tbl = {}
> tbl[1] = "foo"
> tbl[2] = "bar"
> tbl[4] = "baz"
> for k, v in ipairs(tbl) do print(k, v) end
1	foo
2	bar
```

Soupault 3.1.0 now offers two new functions to alleviate that: `Table.iter_ordered` and `Table.iter_values_ordered`.
They work much like their [older counterparts](/reference-manual/#Table.iter), but sort the keys before iterating
through them.

Note that for tables with non-numeric and mixed numeric/non-numeric keys, the order may be arbitrary, but at least
it will actually iterate through every key.

## Ignoring certain heading selectors in the ToC

The ToC widget now has a new `ignore_heading_selectors` option. For example, `ignore_heading_selectors = [".notoc"]`
will exclude every heading with `class="notoc`.

This way you can more easily include purely technical headings without polluting your ToC with them.

## What’s next?

I hoped to implement the long-planned system of hooks this summer, but that plan clearly didn’t work out.
Implementing a fully 1.0.0-compliant TOML library took much more effort than I hoped,
and there have been too many other things to take care of. However, that idea is not abandoned
and I’ll get back to it as time allows. If you have any ideas for a hook system that would allow
plugins to take over any step, feel free to share them.

<hr>
<div id="footnotes"> </div>
