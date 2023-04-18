<h1 id="post-title">Soupault 4.5.0 release</h1>

<p>Date: <time id="post-date">2023-04-17</time> </p>

<p id="post-excerpt">
Soupault 4.5.0 is available for download from <a href="https://files.baturin.org/software/soupault/4.5.0">my own server</a>
and from <a href="https://github.com/PataphysicalSociety/soupault/releases/tag/4.5.0">GitHub releases</a>.
It is a rather unremarkable release, with just a few small improvements and a trivial bug fix.
</p>

To be fair, the fact that it's so unremarkable and small is the main reason why it took me so long to build official binaries
and make a release. Well, there are more reasons. First, [Camomile](https://opam.ocaml.org/packages/camomile/), the Unicode string
library for OCaml that soupault uses, made a release with breaking changes, and I wanted to adjust to them to make the latest soupault
release buildable for everyone without dependency pinning and potential conflicts with other OPAM packages.

Then my Cygwin setup on the Windows VM got borked somehow and I had to redo it before I could build the Windows executable.
But now it's all done, and all binaries are available.

## New features and improvements

* `--no-caching` option allows the user to disable caching even if `settings.caching` is true in the config.
* [Plugin API] New `HTML.prepend_root(node, child)` function for inserting new nodes in HTML documents before all existing nodes.
* The name of the Lua index processor file and the index view that calls it are displayed in the logs now.
* Clearer breadcrumb template parse error message (mentions Jingoo now).

## Bug fixes

* `soupault --version` correctly prints a trailing newline again.

## Future plans

Now it's a really odd feeling — I can't think of anything I could add to soupault. All bigs plans from the roadmap,
like caching support, are already implemented.

Multi-core support depends on a refresh of the Lua-ML interpreter (which was written before any multi-core CPUs
were available and parallelism simply wasn't a concern). That refresh is planned and may even get support from INRIA
(fingers crossed!). However, since soupault is rather fast by itself, support for parallelism is unlikely to be a game-changer
for most websites — only the largest ones will see any significant build time reduction, especially when they also use caching.

An additional issue is support for persistent variables in plugins and index processors scripts. As off as it sounds, they may be compatible
with multi-core support _in practice_. Theoretically, they must always be locked and thus the code of a plugin that
saves anything in a persistent variable cannot run in more than one thread. However, since the order of page processing is not deterministic,
plugins don't actually have reasons to _read_ those variables _at arbitrary moments in time_.
It may be possible to design a persistent variable API so that they can only be updated when a plugin runs on content pages
and can only be read when it runs on index pages. Whether this is worthwhile or more trouble thant it's worth is debatable.

In any case, it's not an issue for the nearest months. For now soupault effectively goes to maintenance mode.
I will certainly respond to bug reports, and I'll be happy to receive feature requests and patches! I will also make small releases
if I think of any improvements.

However, I have no big plans at the moment and there is a chance that soupault is now effectively complete.
I've already been putting effort to make it friendly to long-term maintenance and I'm going to keep improving
the codebase to make it easy to maintain and contribute to — reorganize it for better structure,
document assumptions, improve comments for non-obvious logic and so on.
But otherwise soupault can already do everything I want it to do at the moment and I'll keep using it in
my current and future projects, so even if this is the last feature release, it's not a bad thing —
soupault is not abandoned, but rather complete, and we can all focus on building new cool sites with it
rather than on building soupault itself.
