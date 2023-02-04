<h1 id="post-title">Soupault 4.4.0 release and a review of cache implementations in static site generators</h1>

<p>Date: <time id="post-date">2023-02-04</time> </p>

<p id="post-excerpt">
Soupault 4.4.0 is available for download from <a href="https://files.baturin.org/software/soupault/4.4.0">my own server</a>
and from <a href="https://github.com/PataphysicalSociety/soupault/releases/tag/4.4.0">GitHub releases</a>.
Its major change is the implementation of caching for the outputs of page preprocessors
and <code>preprocess_element</code> widgets that can make repeated builds several times faster
for sites that call external tools a lot. Somewhat unusually for a release post,
I included a detailed description of the implementation and comparison with other SSGs,
so this post may also help other SSG developers.
</p>

<div id="generated-toc"> </div>

Everyone knows that the two hard problems in computing are cache invalidation and naming things.
Soupault already has a perfect name: it confuses people who are not familiar with French orthography
and threatens to overshadow the person it was named after (<wikipedia>Philippe Soupault</wikipedia>) in search results.

Now it's time to solve the caching problem as well. 

## Cache configuration

This is the implicit default configuration:

```toml
[settings]
  caching = false
  cache_dir = ".soupault-cache"
```

By the way, did you know that you can view the default config with `soupault --show-default-config`
and the current effective config (your settings plus defaults) with `soupault --show-effective-config`?

Anyway, to enable caching, you just need to change it to `caching = true`. You can also optionally change
the cache directory name/path.

The only other thing to know is that you can force cache invalidation and eviction by running `soupault --force`.

The implementation aims to invalidate and evict outdated cache entries automatically
so you should not need to use `--force` any often (read on for details).
However, if you change the `[preprocessors]` config section or any of your `preprocess_element` widgets,
you may want to run `soupault --force` to ensure that old data doesn't persist.

I considered automatically invalidating the cache on _any_ config changes but decided against it
because _most_ changes don't affect the cache, and it could defeat the purpose of caching.
There are also situations when the cache becomes invalid for reasons undetectable from within soupault
— for example, when you update an external tool and the new version produces a different output.

## What is cached and how fast is it

Right now soupault only caches outputs of [page preprocessors](/reference-manual/#page-preprocessors) and commands executed by
[preprocess_element](/reference-manual/#preprocess-element-widget) widgets.

The reason is that execution of external programs is the biggest bottleneck. Soupault itself is very reasonably fast —
its startup time is close to zero because it's a native executable, and its page processing speed is decent as well.
Bringing external tools to the build process, however, can slow it down considerably, even if those tools themselves are fast,
simply due to the cost of spawning subprocesses.

This website uses [pandoc](https://pandoc.org/) for Markdown to HTML conversion
and [highlight](/tips-and-tricks/static-rendering/#syntax-highlighting) for syntax highlighting.
On my laptop, it takes about 5 seconds to build with `--force` but a warm build only takes 0.7-1.0 seconds.

So, if you are calling external tools a lot, caching can make repeated builds 5x faster.
If you only use external page preprocessors to convert your pages to HTML, you can still get a significant speed-up.
However, if you aren't calling any external tools, caching will not bring any improvement, which is why it's disabled by default.

Note that there's no caching for [asset processors](/reference-manual/#asset-processing), at least for now.
The reason is that asset processor commands, in the current design, are opaque to soupault — the user specifies
a complete command template, and soupault just executes it. Page preprocessor commands must output generated HTML to stdout
for soupault to read since it's going to parse it and process it further, and it controls the output paths of generated pages.
Asset processors can't use that approach since soupault has no way to know what the output file name should be (one example
when the asset processor changes the file extension, like a Sass compiler),
and it also needs to support commands with fragile option syntax that makes it impossible to just glue the output file to the end.

If you have any ideas on how to redesign the asset processor configuration to accomodate caching, please share!

There also isn't a caching API for Lua plugins yet. I may add it in the future, but I'd like to hear from people
how they want to use it first.

Now let's talk about the implementation, the problems it tries to avoid, and how exactly it avoids them.

## Implementation

### Requirements

There are a few things one would expect from a single-node<fn id="coherence">Distributed systems also need to consider cache coherence,
but for an SSG running on a single machine, it is not a concern.</fn> caching mechanism implementation. Let's define them in the most general words:

* Cache _invalidation_ — don't use cached values if computing them from scratch would produce a different result.
* Cache _eviction_ — don't keep outdated or irrelevant values in the cache.
* Cache _efficiency_ — don't compute values from scratch if they were already computed and cached.

Depending on the use case and implementation, all three concerns can be completely separate issues. If you are using a cache to memoize
computation results, invalidation can be trivial, but eviction can be tricky.

For example, consider caching the results of converting Markdown to HTML. Let's assume that our cache is a key-value store
and that to cache a result we calculate a hash sum from the original Markdown string and use it as a key.

```
md_hash = hash_sum(markdown)

if md_hash in cache:
  return cache[md_hash]
else:
   html = markdown_to_html(markdown)
   cache[md_hash] =  html
   return html
```

This approach has a built-in _invalidation_ protocol: whenever the content of a Markdown file changes,
that code will never return cached HTML for any older version of the same file due to a different hash sum.
However, it will not _evict_ the old cached HTML. In fact, it doesn't even have a way
to check if any existing cached values were generated from older versions of the same Markdown or from anything else.
Such a cache will keep getting bloated with irrelevant values until the user clears it,
or until an eviction mechanism kicks in.

I surveyed a few SSGs to see how they implement caching and learn from them. Zola and Hugo don't use a persistent cache
even though AsciiDoctor/pandoc calls in Hugo and built-in Sass compilation in both of them could benefit from it.
Jekyll supports caching and has exactly that cache eviction problem — let's examine it in practice.

### Caching in Jekyll

Jekyll provides a [cache API](https://jekyllrb.com/tutorials/cache-api/) that it uses internally and exposes to plugins.
Every module (built-in or plugin) initializes or opens its own cache (`Jekyll::Cache.new(name)`) and can associate
cached objects with unique keys. There is also a method for [deleting cache entries](https://jekyllrb.com/tutorials/cache-api/#deletekey)
and, presumably, every well-behaved module is supposed to clean up irrelevant values.

However, a well-behaved module is nearly impossible to write in most cases, since
there is no way to know which entries belong to older versions of the same object.

For a test, I created a post with "The Magic Words are Squeamish Ossifrage" sentence, then edited it repeatedly (by adding exclamation marks to that sentence),
ran `jekyll build`, and searched the cache for that source text. Here's the outcome after three edits:

```
$ grep -r Ossifrage .jekyll-cache/
.jekyll-cache/Jekyll/Cache/Jekyll--Converters--Markdown/10/1fbff82f1701e23c82cf3dd53d435b1586b65c249e8f0bb3844ce8d645aed6I"6<p>The Magic Words are Squeamish Ossifrage!!</p>
.jekyll-cache/Jekyll/Cache/Jekyll--Converters--Markdown/10/fa7831ccacad5a1f4afb3c38af2d18c318685c28a54da41362442e384bd147I"4<p>The Magic Words are Squeamish Ossifrage</p>
.jekyll-cache/Jekyll/Cache/Jekyll--Converters--Markdown/12/5ed3fb22033f02ae899621822c60fe598d24165b3e0f1b31d560ca6016b386I"5<p>The Magic Words are Squeamish Ossifrage!</p>
.jekyll-cache/Jekyll/Cache/Jekyll--Converters--Markdown/a6/f26adf7cc7af436c9373c688f395b908f159643e58955d599f1f9aae8ea825I"6<p>The Magic Words are Squeamish Ossifrage!!</p>
.jekyll-cache/Jekyll/Cache/Jekyll--Converters--Markdown/1e/07e88191bc43de567f94227b5ebfc047e8a38c1096a0d66a2cd6e75e51f4e0I"5<p>The Magic Words are Squeamish Ossifrage!</p>
.jekyll-cache/Jekyll/Cache/Jekyll--Converters--Markdown/54/f8d3efe72f7f6e0cbd9a914456b98c2bf2fa63345316e43c09cdc1c8c0359bI"4<p>The Magic Words are Squeamish Ossifrage</p>
```
As you can see, old versions remain in the cache forever. Even if you remove the post, its old cached versions will remain there as well.
Sure, with modern storage devices, it's going to take a very long time for that cache size to become a problem for the user.
Still, if you have a website with frequently edited pages, the cache directory will soon contain more useless data than useful
and can easily become larger than the website source.

### Caching in soupault

The default name for the cache directory is  `.soupault-cache`. That's the only inspiration I took from Jekyll: that name format makes it obvious
what created that directory, and how it's used.

However, its internal organization is completely different. Here's a peek at the cache from this website:

```
$ tree -a ./.soupault-cache/
./.soupault-cache/
└── site
    ├── 1-to-2.html
    │   └── .page_source_hash
    ├── blog
    │   ├── automation.html
    │   │   ├── ba6c0a894c03ed382428e6e3362bbf247ec25d808cfd9e2bf6c952a130052739_c9f347b76ff1773ad090c1eb402b0a843934fe438c49e106a41224748e32d30b
    │   │   └── .page_source_hash
    │   ├── blogs-and-section-indices.html
    │   │   ├── ba6c0a894c03ed382428e6e3362bbf247ec25d808cfd9e2bf6c952a130052739_39047315829786bbbab7fc717f467edbad11b6237041976f6d2ff85514148a58
    │   │   ├── ba6c0a894c03ed382428e6e3362bbf247ec25d808cfd9e2bf6c952a130052739_6dd6a03f3c6fcceba61a6074349e6b1c9bf0e3a65f22db4ac416866935e5339a
    │   │   ├── ba6c0a894c03ed382428e6e3362bbf247ec25d808cfd9e2bf6c952a130052739_7672bd2b41e7debb7c7671e5ffa2535573fdb74ac1d950623dbc84a783a520b0
    │   │   ├── ba6c0a894c03ed382428e6e3362bbf247ec25d808cfd9e2bf6c952a130052739_a4d37cff9432794476092154ca3555415bd061e59817a8e54c1b1cb4e3d3e3d2
    │   │   ├── ba6c0a894c03ed382428e6e3362bbf247ec25d808cfd9e2bf6c952a130052739_c66232854f8b2d8b6a3d9a954ed94d4377535e9944ca5c0e74fa33b039e88b66
    │   │   └── .page_source_hash
...
```

First, I opted out of the "prefix tree" approach that many tools use for a reason that escapes me.
If anyone knows why Jekyll, ccache, and many other projects create a subdirectory for each one-byte prefix
and use paths like `10/1fbff82f1701e23c82cf3dd53d435b1586b65c249e8f0bb3844ce8d645aed6I`, please let me know.<fn id="prefix-tree">My only
guess is that in some old filesystems the limit on the number of files in a directory was low enough to be a concern,
and splitting the cache into multiple subdirectories was a way to lower the risk of reaching that limit.</fn>

Second, notice that the cache directory isn't flat. For every page in `site/`, there's a _subdirectory_ with a matching name
in the cache directory. That is my way of keeping track of the origin of cached objects.

The `.page_source_hash` file contains the hash sum of the page source. When soupault starts processing a page,
it calculates its source hash sum and compares it to that file. If they differ, it means the page source has changed
and any cached objects for that page are no longer valid. Its cache directory is removed and re-created
with a new hash file.

For the record, the hash function I chose is [BLAKE2](https://en.wikipedia.org/wiki/BLAKE_(hash_function)).
It's one of the fastest hash functions around, although, frankly, for the purpose of cached object names,
any hash function that isn't intentionally slow would work just as well.

Now, notice that cached object file names consist of two components separated by an underscore.
The first component is the hash sum of the source, and the second one is the hash of a unique identifier — currently,
the command that was used to process that data.

For example, suppose that a page at `site/about.md` contains the text "Under **construction**!" and you have this
in your config:

```toml
[preprocessors]
  md = "cmark --unsafe --smart"
```

To cache that preprocessor output, soupault will first create a directory named `.soupault-cache/site/about.md/`.
Then it will calculate `Blake2S("Under **construction**!") = 6be9eb7a3ac1095bf6d287addc05907053080fc56f9f0d14d13736a493207496`
to uniquely identify that piece of content. Then it will calculate `Blake2S("cmark --unsafe --smart") = f75029d4ccca3c350ee11374fafe4e0de3e4227fe034e3e987da973908536870`
to associate the cached object with the command that was used to produce it.
The cached object file thus will be `.soupault-cache/site/about.md/6be9eb7..._f75029d...`.
Finally, it will do an equivalent of `echo "Under **construction**!" | cmark --unsafe --smart`
and save the result (`<p>Under <strong>construction</strong>!</p>`) to that file.

Now every time soupault wants to know what's the output of `cmark --unsafe --smart` for string `"Under **construction**!"`
when it processes `site/about.md`, it can calculate hash sums and check if a file exists in the cache.
Embedding the hashes of both the content and the command ensures that soupault will not try to look for a wrong file.

The disadvantage is that if there are multiple pages where the same content is processed with the same command,
those objects will be duplicated since cached objects are restricted to a single page.
That is the price to pay for the fully automated eviction of outdated objects.

Another disadvantage is that it makes exposing a caching API to Lua plugins more complicated,
which is why I want to hear from people how they plan to use it and what they want the API to look like.
If you have any ideas for plugins that use caching, let me know!

## Future plans

Caching was the last big thing on my roadmap for soupault. Frankly, it feels somewhat strange that
the side project that has occupied a significant share of my free time since I started it
in June 2019 is now effectively complete. I'm sure there will be new plugin functions to add
and other small improvements to make, and maybe some bugs will be discovered
but I don't have any big plans in mind.

There is an upcoming project to modernize the Lua-ML interpreter to support features
from modern Lua rather than its current antiquated Lua 2.5. However, even now,
ironically, it has a few things better than the "real" (PUC-Rio) Lua — for example,
[Table.iter()](/reference-manual/#Table.iter) and friends correctly handle
number-indexed tables with indexing gaps.

I also have a vague idea of mechanism to allow writing Lua hooks for custom actions.
Hypothetically, when the user adds a script to `actions/new-page.lua`,
soupault picks it up and exposes it as `soupault --action new-page`.
However, there are many questions about possible designs for that feature.
For example, should it read its parameters from standard input or,
should it take custom command-line options instead?
If you'd be interested in something like that, please let me know.
