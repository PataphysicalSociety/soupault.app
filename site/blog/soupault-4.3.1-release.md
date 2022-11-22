<h1 id="post-title">Soupault 4.3.1 maintenance release</h1>

<p>Date: <time id="post-date">2022-11-22</time> </p>

<p id="post-excerpt">
Soupault 4.3.1 is available for download from <a href="https://files.baturin.org/software/soupault/4.3.1">my own server</a>
and from <a href="https://github.com/PataphysicalSociety/soupault/releases/tag/4.3.1">GitHub releases</a>.
It's a very small release that fixes a couple of bugs in the relative links widget.
</p>

There were two separate but somewhat related bugs in the [relative links widget](/reference-manual/#relative-links).
Thanks to Lulu, whose use of that widget is much more advanced than my own, I was able to identify and fix them.

They have to do with pages and files located at the same level as the current page.
The most common use of that widget from its inception was correcting links to shared resources such as CSS
in pages generated from a template. Suppose your `templates/main.html` has `<link rel="stylesheet" href="style.css">`.
Now suppose you host your website on `https://example.edu/alumni/jrandomahacker` so writing `href="/style.css"` is not an option
because that would refer to `example.edu/style.css`, not to `example.edu/alumni/jrandomhacker/style.css`.

The solution is to use relative link instead: in `/index.html`, `href="style.css"` works, but in `about/index.html`
you set it to `../style.css`; in `projects/soupault/index.html` it's `../../style.css` and so on.

Now, that part — adding a `../` for every nesting level — always worked as intended. What I didn't realize was broken
was adding a `./` to links to the current level. Worse yet, soupault tried to be smart and only relativize links
to files that didn't actually exist in the build directory already. That led to non-deterministic outputs:
some links would not be relativized in warm builds when those files did exist, but were relativized in cold builds
(when those files did not exist yet).

Now pages and files at the same level are always relativized with a `./`, so it should work as expected.

## What's next?

This release is very small, but there are bigger plans for the future! The next big thing is support for caching,
although it will take a while to implement properly.
