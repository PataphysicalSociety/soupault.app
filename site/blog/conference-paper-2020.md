<h1 id="post-title">Imaginary conference paper</h1>

<p>Date: <time id="post-date">2020-08-26</time> </p>

<p id="post-excerpt">
I was planning to give a talk about Soupault at an online conference, but the conference ended up completely cancelled, so the paper I wrote for it ended up unused.
If you know of an upcoming conference that may be interested in it, let me know. Otherwise, it can remain a good introduction to the project I suppose.
</p>

Soupault is a static website generator that rejects the classic CMS-like architecture and uses ideas of client-side DOM APIs and microformats to manipulate static HTML files and extract metadata from them.
It is extensible with external programs and Lua plugins despite being available as a statically linked executable, and can be configured to adapt to existing workflows.

Static websites generators are growing in popularity and in numbers. The  [staticgen.com](https://staticgen.com/) directory alone lists about 1250 projects. However, their typical architecture has a few unsolved problems.

Soupault sets out to explore new architecture ideas and fulfill the following goals:

* Support HTML as a first-class citizen.
* Be able to adapt to user’s workflow rather than force the user to adapt.
* Provide an upgrade path for authors of hand-written websites.
* Combine stability of a statically linked file with support for plugins.

Soupault is written in [OCaml](https://ocaml.org) and distributed under the MIT license. Official binaries are available for Linux, Microsoft Windows, and macOS.

## Classic static website generator architecture

Most SSG projects still use an architecture codified by Jekyll back in 2006. Exploration of new ideas is relatively rare and the main difference between most projects is their implementation language, built-in feature set, and choice of template processors and input formats.

In effect, Jekyll's architecture is an “eagerly evaluated CMS”. The techniques it employs are those of the web backend: HTML is generated from an intentionally limited input format (usually Markdown) with a template processor.

Markdown, reStructuredText, AsciiDoc and other formats focus on formatting and don't provide a general way to attach metadata to the document. Website generators usually work around this issue with “front matter”, (machine-readable headers that precede Markdown data), template processor “shortcodes”, but sometimes even that is not enough, and people turn to using an HTML parser from plugins or just adding client-side JavaScript code.

Another problem with the classic approach is that extensibility and resistance to software rot are mutually exclusive problems. Projects written in interpreted languages generally support plugins written in the same language, but may break without maintenance if their dependencies make incompatible changes. Some projects like Hugo (written in Go) and Zola (written in Rust) provide static binaries, but their only extensibility mechanism is a Turing-complete template processor.

Finally, for the user, there's a problem of commitment. Despite architectural similarities, switching between different generators is a non-trivial task and the user may need to adapt both their theme and the “front matter” of every page.

## Automatic HTML rewriting as an alternative to templates

Automatic manipulation of HTML data has always been common—ever since web browsers first implemented a DOM API. However, it was rarely, if ever used for generating static HTML files rather than for making client-side web applications. HTML parsing libraries like BeautifulSoup existed for a long time but were mostly used for web scraping.

Soupault uses the [lambdasoup](https://github.com/aantron/lambdasoup) library that is especially well-suited for automatic rewriting. This allows any HTML page to serve as a ‘theme’, the user specifies where to insert the page content with a CSS selector like `div#content` or `main`.

Page content files are also in HTML, which allows arbitrary metadata in the spirit of [microformats](http://microformats.org). This allows features like LaTeX-like footnote elements whose content is moved to a new parent element and replaced with a link.

Additionally, plugins can take ‘fake’ HTML elements and generate valid HTML from them, which serves as an alternative for template shortcodes.

## Extensibility

Soupault is written in OCaml, which compiles to machine code, and its official binaries are statically linked. It provides two distinct extensibility mechanisms.

The first mechanism is ability to execute external programs and pipe entire page files or HTML element content through them. This way the user can store their pages in any format they have a preprocessor for, and process individual HTML elements with external tools, e.g. pipe `<pre>` elements through a syntax highlighter of their choice.

The second mechanism is Lua scripts. Soupault uses [Lua-ML](https://github.com/lindig/lua-ml), a Lua implementation written in OCaml that provides a type-safe way to extend its runtime library. The plugin API is conceptually similar to the DOM API of web browsers and allows the user to modify the element tree in arbitrary ways.

## Metadata extraction

Additionally, soupault allows extracting metadata from HTML files, which eliminates a need for front matter. The user can create custom fields declaratively, using CSS selectors.

Extracted metadata can be rendered into a site index, a blog feed, or anything user wants. It can also be exported to JSON for processing by external scripts.

## Conclusion

Whether ideas of soupault will catch on remains to be seen. However, it  already provides unique functions that no other project offers. Besides, it can work in an HTML processor mode so users can experiment with it and use it in addition to their current website generator, rather than instead of it.
