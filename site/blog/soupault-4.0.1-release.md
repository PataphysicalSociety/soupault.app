<h1 id="post-title">Soupault 4.0.1 maintenance release</h1>

<p>Date: <time id="post-date">2022-05-30</time> </p>

<p id="post-excerpt">
Soupault 4.0.1 is available for download from <a href="https://files.baturin.org/software/soupault/4.0.1">my own server</a>
and from <a href="https://github.com/PataphysicalSociety/soupault/releases/tag/4.0.1">GitHub releases</a>.
It's a small maintenance release that fixes two bugs: one introduced by the post-index hook implementation,
and another one in indexing withhout clean URLs.
</p>

## Correct URL field for pages when `clean_urls = false`

I have to admit I'm not using `clean_urls = false` in any of my own projects,
and I sometimes neglect to test new features with clean URLs disabled.
That's why I never noticed that the `url` index field was incorrect for
pages in that case. For example, `/site/foo.md` would produce `{"url": "/foo.md", ...}`
instead of expected `"/foo.html`.

Thanks to the report and testing from [laumann](https://github.com/laumann),
this oversight is fixed now.

## Soupault no longer crashes when a page produces a completely empty index entry

The hook system was a big change, and, unfortunately, it introduced at least one bug.
Soupault would crash when a page produced a completely empty index entry.

The reason for it was that index entry datastructure is first converted to a Lua value
so that a Lua script in the `post-index` hook can process it, then it's passed from Lua
back to the OCaml code.

The problem is that conversion to Lua is "lossy": there's no difference between lists
and dictionaries in Lua: everything is a table. Soupault uses a simple heuristic
to recover the original type: if there aren't any non-integer keys in a table,
it's considered a list.

However, for an empty Lua table that property is trivially true, so empty index entries
would come back as lists instead of dictionaries.
I anticipated that my code may be faulty and added a type check and an internal error
to make soupault fail if that check fails. However, I considered that situation so unlikely
that I didn't even think to log the received value.

That is, until [akavel](https://github.com/akavel) ran soupault 4.0.0 on a website with an empty page
and triggered the faulty assumption. Thanks to his report, I added a case to handle
the ambiguity and produce correct result.

## Soupault on OpenCollective

I also have to admit that with the huge 4.0.0 release, I completely forgot
that I set up an organization for soupault on [OpenCollective](https://opencollective.com/soupault).

If you want to support soupault development, you can sponsor it on OpenCollective now.

