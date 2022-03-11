# Getting started: HTML processor

<div id="generated-toc"> </div>

One feature that sets soupault apart from other website generators is that the
&ldquo;generator&rdquo; part is optional.
You can use it as an HTML processor for existing websites, without modifying any single page.

In this guide we’ll set up soupault to add some meta tags to every page, set the `<title>`
to the first heading, and insert tables of contents.

It assumes that you already have a static website, either handwritten or generated with another tool.

If you don’t have soupault on your machine yet, you should <a href="/install">install</a> it.
The `soupault` (`soupault.exe` on Windows) executable is standalone and has no dependencies,
so you only need to copy it somewhere to ‘install’ it.

## Create a basic config

First you should create a directory for your project. For example:

```shell-session
$ mkdir mysite
```

Soupault’s workflow is defined in a single configuration file, `soupault.conf`.
It’s a file in the <a href="https://toml.io">TOML</a> format.

For the start, we’ll write a basic config for running soupault as an HTML processor:

```toml
[settings]
  strict = false
  verbose = true

  generator_mode = false

  clean_urls = false

  build_dir = "build"
  site_dir = "site"

  doctype = "<!DOCTYPE html>"

  page_file_extensions = ["htm", "html"]
```

Save that file to `mysite/soupault.conf`.

The `generator_mode = false` option tells soupault not to look for or use a page template.

With `clean_urls = false` we tell soupault to preserve file paths exactly, e.g.
`site/about.html` will become `build/about.html`. 

If you want to automatically convert your site to use clean URLs along the way, you can use `clean_urls = true` instead.
Then `site/about.html` will become `build/about/index.html` and so on.

The `page_file_extensions = ["htm", "html"]` option from our config tells soupault
to treat files with extensions `.htm` and `.html` as pages (parse, process, and output).
All other files will be simply copied unchanged.


### Configuring the source directory

The `site_dir` options tell soupault where to look for page source files.
In our config, we have `site_dir = "site"`, which means you should copy your pages to `mysite/site` to have them processed.

However, if you already have a directory with your site somewhere, you can simply point soupault to it:

For example:

```toml
[settings]
  site_dir = '/home/jrandomhacker/homepage'
```

Or, on Windows:

```toml
[settings]
  site_dir = 'C:\Users\jrandomhacker\homepage'
```

Note that soupault never modifies anything in the `site_dir`, so it’s a safe thing to do.

### Run	soupault

Now you can run soupault:

```shell-session
$ cd mysite
$ soupault
```

We’ve set `build_dir = "build"` in the config, so it will create a `mysite/build` directory
and output processed pages to it. Just like with `site_dir`, you can set `build_dir` to an arbitrary
directory, even outside the project directory.

There’s no built-in web server in soupault, but you can use any web server you like for preview,
for example the `http.server` module that comes with Python:

```
python3 -m http.server --directory build
```

The output will be more or less exact copy of your source dir. Soupault will set the doctype of the pages
to `<!DOCTYPE html>` as per the `doctype` option. It will also 

## Configure widgets

General purpose text preprocessors usually work by looking for special directives in files, like
`#include "myfile.html"` or `<a href="{{site_url}}">Home</a>` and replacing them with something else. The downsides of that approach
are that a) you have to modify the page to have it processed b) generated content is in a fixed place.

That is _not_ how soupault works. Parsing HTML into an element tree allows it to see the page structure
and modify pages regardless of their exact layout. However, it also requires a different approach
to telling it what to do with the pages.

Instead of template variables and filters, soupault provides a set of HTML transformation modules. Some are low level and simple,
like `insert_html` and `include`. Other modules have more logic in them, like `toc` and `footnotes`.
To identify the source and target elements for transformation, they use CSS selectors.

If you are familiar with DOM manipulation in JavaScript, it’s the same concept as `document.querySelector(".myclass")`.
You can use any CSS selectors, like `h1` (first `<h1>` element), `div#content` (`<div id="content">`),
`.footnote` (any element with `class="footnote"`), or `div#content p` (first paragraph inside `<div id="content">`).

HTML transformation modules are called &ldquo;widgets&rdquo;, for lack of a better word.
They are configured in the `[widgets]` table of the config file. TOML uses a dot as a table
name separator, so options for a widget named `set-title` will be in `[widgets.set-title]`.

Here’s an example of a config with two widgets:

```toml
[settings]
  strict = false
  verbose = true

  generator_mode = false

  clean_urls = false

  build_dir = "build"
  site_dir = "site"

  doctype = "<!DOCTYPE html>"

  page_file_extensions = ["htm", "html"]

[widgets.set-title]
  selector = "h1"
  default = "My website"

[widgets.generator-meta]
  widget = 'insert_html'
  selector = 'head'
  html = '<meta name="generator" content="soupault">'
```

Now let’s see how to automatically enhance a website with some widgets:

### Setting the page title

In a lot of websites, page title is the same as its first heading. You can easily automate
it using the `title` widget. It takes the content from the element you specify in its `selector` option
and inserts it in the page `<title>`.

```toml
[widgets.set-title]
  widget = "title"
  selector = "h1"
  default = "My website"
```

Some widgets allow you to specify more than one selector, and `title` is one of those:

```toml
[widgets.set-title]
  widget = "title"
  selector = ["h1", "h2"]
  default = "My website"
```

With this config it will check if the page has an `<h1>` element, and use its content for the title.
If there is no such element, it will try `<h2>` instead. If all else fails, it will set the title to
`My website`.

### Adding a meta tag

The reason widget name and type are separate things is that you may want to have multiple
widgets of the same type.

For example, suppose you want to add two `<meta>` tags to the `<head>` of each page,
one to tell mobile browsers to behave like every sensible browser should, the other
to tell everyone you are using soupault.

You can do it with the `insert_html` widget. It has a `selector` option that defines
where the content is inserted, and `html` option for the HTML snippet to insert.

You can combine both meta tags in one snippet and it will work, but it may be better
to use two independent widgets for that:

```toml
[widgets.viewport-meta]
  widget = 'insert_html'
  selector = 'head'
  html = '<meta name="viewport" content="width=device-width, initial-scale=1">'

[widgets.generator-meta]
  widget = 'insert_html'
  selector = 'head'
  html = '<meta name="generator" content="soupault">'

```

Meta tags always go to the page `<head>`, so naturally we use `selector = "head"`.

By default, soupault inserts new content after the last child in the 

So if your source page looked like:
```html
<head>
  <style>h1 { color: red; }</style>
</head>
```

after processing it will look like:
```html
<head>
  <style>h1 { color: red; }</style>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="generator" content="soupault">
</head>
```

The order of the meta tags can be different, but they will come after the `<style>` tag that originally was there.

What if you want the generator tag to always come after the viewport tag? That is possible. In soupault, widgets
form a _pipeline_. Output of one widget can be used as input for another. Or you can just schedule their execution
order for aesthetic reasons, nothing wrong with it:

```toml
[widgets.viewport-meta]
  widget = 'insert_html'
  selector = 'head'
  html = '<meta name="viewport" content="width=device-width, initial-scale=1">'

[widgets.generator-meta]
  widget = 'insert_html'
  selector = 'head'
  html = '<meta name="generator" content="soupault">'
  # Run after viewport-meta
  after = "viewport-meta"
```

### Including a file and choosing where to insert it

Now, support you want to add a header to every page, and you want to keep it in a separate file. For example:

```
echo "Please read: a personal appeal from the webmaster" > header.html
```

Suppose you want the header to come before the first element of the page `<body>`. You can do it with an `include` widget like this:

```toml
[widgets.alleged-header]
  widget = 'include'
  selector = 'body'
  file = 'header.html'
```

However, since soupault inserts new content after the last element, this config will create a _footer_ rather than a _header_.

You can specify where to insert it using the `action` option. Its default value is `append_child`, but you can choose any of
`prepend_child`, `append_child`, `insert_before`, `insert_after`, `replace_element`, `replace_content`.

For inserting before the first element, you will need `prepend_child`:

```toml
[widgets.header]
  widget = 'include'
  selector = 'body'
  file = 'header.html'
  action = 'prepend_child'
```

### Adding a ToC

Soupault can generate tables of contents from your page headings, as you can see from this website.
That widget has a large number of <a href="/reference-manual/#toc-widget">configurable options</a>
with (hopefully) sensible defaults.

It’s a good idea to add a container with a unique id to every page where you want a ToC,
and point the widget to it. For example, add a `<div id="generated-toc">` to those pages,
and set up the widget like:

```
[widgets.toc]
  widget = "toc"
  selector = "div#generated-toc"
```

However, if you know you have an `<h1>` element in every page where you want a ToC,
you can take advantage of the `insert_before` action and tell soupault to insert
it right before the first `<h1>`:

```toml
[widgets.toc]
  widget = "toc"
  selector = "h1"
  action = "insert_before"
```

### Where to go from here

There are many other things you can do, for example, create lists of pages in a section or a blog
feed, add footnotes, breadcrumbs, and more. You can also extend soupault with <a href="/plugins">Lua plugins</a>.
Read the <a href="/reference-manual">reference manual</a> for details.
