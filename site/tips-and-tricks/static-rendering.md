# Static rendering

<div id="generated-toc"> </div>

There are many reasons to avoid JavaScript. 
Plain HTML and CSS are good for pages [designed to last](https://jeffhuang.com/designed_to_last/).
Pages with less JS load faster and use less machine resources (still important for battery-powered devices).
They also require less bandwidth—many JS libraries are quite large.

On this page I collect howto guides for rendering different kinds of content to static HTML.

If you come up with some interesting ways to avoid JS, let me know!

## Syntax highlighting

For any website about programming and system administration, syntax highlighting is a great thing to have.
Many static site generators have built-in syntax highlighting. Most sites seem to use some form of static
highlighting now and few stick with JavaScript libraries for that. That makes me happy.

So, how about soupault? It doesn’t have built-in syntax highlighting, but the `preprocess_element` widget
allows you to pipe and element’s content through any program—including a highlighter of your choice.

Which highlighter to use? If I could only take one highlighter with me to a desert island, that would be
Andre Simon’s [highlight](http://www.andre-simon.de/doku/highlight/en/highlight.php).
Why would I need a highlighter on a desert island is another question. In any case, it’s fast,
cross-platform, and _very_ flexible.

Let’s see how to set up soupault to work with it.

### Obtaining a CSS theme

The highlight package comes with a whole bunch of ready to use themes.
You can list all installed themes with `highlight --list-scripts=theme`.

It has an option to inline all CSS. For example:

```shell-session
$ echo "<p>foo</p>" | highlight --style matrix --syntax=html -O html  -f --inline-css
<span style="color:#55ff55; font-weight:bold">&lt;p&gt;</span>foo<span style="color:#55ff55; font-weight:bold">&lt;/p&gt;</span>
```

As you can see, it’s quite messy. Besides, you will not be able to switch styles without rebuilding the whole site,
and the pages will be heavier than they could be. It’s better to use external CSS. But first we need to get that CSS.

Highlight’s theme is [abstract](http://www.andre-simon.de/doku/highlight/en/highlight.php#ch3_4). They have to be since
it supports multiple output formats, not only HTML.

Luckily it has an option to print the CSS of any theme. Pick a theme, e.g. `matrix`, and run:

```
highlight --style matrix --syntax=ocaml -O html --print-style --stdout
```

It will give you CSS that you can add to your stylesheets. Less than 20 lines, so it doesn’t even warrant its
own file.

### Configuring soupault

The `preprocess_element` widget sends the content of an element to an external program
and replaces that original content with the output of that program. It can also place
the output alongside the original element, but we won’t need that now.

We’ll need to run `highlight` with `-O html` to make it produce HTML, and with `-f`
(`--fragment`) to make it produce HTML fragments rather than complete documents.

We also need to tell it the language so that it knows which keywords to highlight.
The simplest way to encode it is a custom class.

What makes it a bit complicated is that you may not want to highlight every `<code>` or `<pre>` element.
Also, some tools, like Markdown converters, may add a prefix like `language-html`.

CSS3 selectors allow matching elements by prefix class. This is how we can match any element
with a class that start with `language-`: `'*[class^="language-"]'`.

But then we also need to give `highlight` its language part, unprefixed.
Since the `preprocess_element` widget runs commands in the system shell,
on UNIX we can easily remove the prefix with `sed`.

This is a real configuration from this website:

```toml
# Runs the content of <* class="language-*"> elements through a syntax highlighter
[widgets.highlight]
  after = "escape-html-in-pre"
  widget = "preprocess_element"
  selector = '*[class^="language-"]'
  command = 'highlight -O html -f --syntax=$(echo $ATTR_CLASS | sed -e "s/language-//")'
```

And it works nicely:

```toml
[settings]
  site_dir = "site"
```

I’m not sure what would be the best way to replicate this on Windows, but if you are doing it, let me know.

## Mathematics

Credit for this recipe goes to [Thomas Letan](https://soap.coffee/~lthms/cleopatra/soupault.html#org97bbcd3).

When it comes to mathematics, [LaTeX](https://www.latex-project.org) remains the de facto standard.
And when it comes to converting it to HTML, [KaTeX](https://katex.org) is one of the best libraries.

KaTeX is usually used as a client side JavaScript library. However, it doesn’t really need
a browser to work. If you have node.js and npm in your system, nothing prevents you from using it in an offline script.

### Wrapper script

First you need to install KaTeX, e.g. with `npm install katex` (that will install it to `node_modules` under your current directory).

Then create a script:

```js
var katex = require("katex");
var fs = require("fs");
var input = fs.readFileSync(0);
var displayMode = process.env.DISPLAY != undefined;

var html = katex.renderToString(String.raw`${input}`, {
    throwOnError : false,
    displayModed : displayMode
});

console.log(html)
```

Save it somewhere, e.g. to `scripts/katex.js`. Now it’s ready to be called.

### Configuring soupault

This configuration will allow you to use elements `<span class="inline-math">` for inline equations
and `<div class="display-math">` for equation blocks:

```toml
[widgets.inline-math]
  widget = "preprocess_element"
  selector = ".inline-math"
  command = "node scripts/katex.js"
  action = "replace_content"

[widgets.display-math]
  widget = "preprocess_element"
  selector = ".display-math"
  command = "DISPLAY=1 node scripts/katex.js"
  action = "replace_content"
```
