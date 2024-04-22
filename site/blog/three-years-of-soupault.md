<h1 id="post-title">Three years of soupault</h1>

<p>Date: <time id="post-date">2022-07-15</time> </p>

<p id="post-excerpt">
Three years ago, on 2019-07-15, I released the first public beta of soupault.
There is no anniversary release this time, so I'm just using it to look back
and reflect on the project history. There will be a release, of course,
but not right now.
</p>

Previous two years there were anniversary releases and I didn't have to hold
anything back to match that date because releases were almost monthly anyway,
unless other committments prevented me from working on soupault.
This is the first time I have no _small_ improvements to make right now.

Big improvements I want to make currently lie outside of soupault:
the [Lua-ML](https://github.com/lindig/lua-ml) interpreter needs a refresh to make debugging easier
and to make it concurrency-safe. It requires a complete rewrite of its lexer
and big changes to the AST, but we'll get there, I promise. It just takes time and effort.

Generally, I think application developers should be a driving force of the ecosystem
rather than just passive users. When I wanted to be able to make widgets
run in specific order, I released a [topological sorting library](https://github.com/dmbaturin/ocaml-tsort)
so that everyone could also easily sort dependencies.<fn id="tsort">There are very good generic graph manipulation
libraries already, but they require converting user input to their internal graph type
and are not designed to handle faulty inputs, so they are not very easy to use
for sorting dependency graphs where dependencies can be cyclic or outright missing.</fn>
When I got tired of design issues and standard non-compliance of the old TOML library,
I made [OTOML](https://github.com/dmbaturin/otoml) and a few other projects already adopted it.
I helped resurrect [odate](https://github.com/hhugo/odate), took over the maintenance
of Lua-ML, and contributed to quite a few libraries I use in soupault.
Soupault would be impractical to make without the work of other people in the ecosystem,
so I believe it's my duty to contribute back.

Besides, if software that you want to use doesn't yet exist, why wait for anyone else to make it?
Soupault itself started its life as a response to my own needs. My own [website](https://baturin.org)
was powered by a bunch of custom scripts, while the blog was separate and powered by [Pelican](https://blog.getpelican.com/).
At some point I started looking for a solution that could replace and unify both, and I also wanted to get rid of all client-side JavaScript
but quickly realized that a static website generator I wanted to use didn't exist at that time.

Some of my requirements could be called frivolous, but they are indicative of deeper issues.
For example, I want web pages to have _good_ tables of contents if they have lots of headings.
I want to be able to write footnotes
_inside_ the paragraphs rather than separately. Offline tools (LaTeX) could do that,
MediaWiki can do that, so why can't I do that in a static website?

My old website used a JavaScript-based ToC script. It could reliably read all page headings
and insert the generated ToC into any place in the page. That's easy if you can manipulate the element tree of a page.
But if you are generating a complete page from a content file in Markdown and a template (an HTML file with template
processor placeholders in it), there are _two_ different kinds of headings in your page now:
those that come from the template and those that come from the content file.
You can also only insert the ToC in the part of the page that comes from the template.
And since Markdown headings can only encode the heading level, there's no way to give
your headings permanent anchors to facilitate deep links to page sections,
while in HTML you could write `<h2 id="some-section">Some section</h2>`.
If you include HTML headings in a Markdown file, they will be insivible to most SSGs
because ToC is a feature of their Markdown parsers and they ignore non-Markdown syntax.

Maybe you can do that if it uses an extended variant of Markdown, or a different, more flexible markup language.
However, then you will typically be locked into that SSG forever because most of them only support a specific
set of input formats and don't let you add new ones. Hugo is an especially weird example:
it has two built-in Markdown libraries with slightly different feature sets.
It also relies on external helpers for AsciiDoc and reStructuredText,
but doesn't allow the user to pass any options to them or add new helpers.
Needless to say, ToC generation functionality in Hugo is vastly different for every format.

Ability to generate a page ToC as good as that old JavaScript could became my litmus test.
I kept looking for SSGs and plugins that could do that, and eventually found one Jekyll plugin
that was as good. However, when I looked into its source code, I realized it does that by
loading an HTML parser library, parsing the generated page, and manipulating its element tree.

That was the moment when I realized that popular SSGs are using a wrong abstraction.
HTML is the language of the web, it's expressive and machine-modifiable,
even if sometimes annoying to write for humans. Treating it as an opaque format limits
what a static site generator can do. I set out to make a tool where HTML would be
a first-class citizen. All other formats (Markdown, AsciiDoc, RST...) would be converted
to HTML immediately after loading and all real functionality would work at the HTML level
so that it can work the same for all input formats.

However, not all HTML parsing libraries are equally useful for that task.
That Jekyll plugin that used the Nikogiri HTML parser had serious performance
problems. BeautifulSoup for Python3 is quite fast, but its functionality for
element tree _manipulation_ is very limited—it's a web scraping library first of all.

Everyone knows that I'm a huge fan of the OCaml programming language,
but I'm not advocating it for every use case. I wanted the new SSG to be extensible,
so I was considering Python or JS, but alas—none of HTML parsers I found for those languages
were sufficiently fast and sufficiently good at element tree modification.

[Lambda Soup](https://github.com/aantron/lambdasoup), an OCaml library, met both requirements.
In fact, when it comes to rewriting element trees, in some areas it's even better than
the DOM API of web browsers—at least it can see deeper into HTML than they can.
So I decided to write it in OCaml and focus on extensibility mechanisms
other than loading plugins written in the same language.<fn id="plugins">OCaml supports dynamic linking,
so loading plugins is possible, but compiling and distributing native code plugins
would be a nightmare for plugin authors and users alike.</fn>

That's how I came up with the idea to allow the user to call arbitrary anything-to-HTML convertors
depending on page source file extensions and then with the idea of widgets for injecting external helper outputs
into pages and piping HTML element content through external programs.

Finally, I realized that I could add a scripting language interpreter,
and roughly at that time, someone brought my attention to the then-unmaintained Lua-ML project.
Even if it only supports outdated Lua 2.5, it still represents the future of embedded interpreters
I believe: it integrates with the type and module system of the host language
and provides type safety guarantees that an interpreter written in C never will.
It also avoids having two different GCs in the same process and doesn't need to
spend time passing values between the host program and the interpreter, since its Lua values
are just boxed OCaml values.

And there it was: an SSG that is easy to distribute and never breaks (since it's a single statically-linked
binary) but also extensible in multiple ways.

It's also completely alien to the users of currently popular SSGs.
That's the irony of accidentally making something genuinely novel: unlike a "Jekyll, but in OCaml",
it's very hard to explain. Perhaps that's why it's yet to gain any momentum.

Still, there are people who instantly get it when they see it, and that makes me think
that I did make a tool that will make the future of static websites better—that future
just isn't evenly distributed yet.
