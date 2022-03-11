<h1 id="post-title">Soupault 2.0.0 release</h1>

<p>Date: <time id="post-date">2020-09-20</time> </p>

<p id="post-excerpt">
Soupault 2.0.0 is <a href="https://files.baturin.org/software/soupault/2.0.0">available for download</a>.
I believe it’s now stable enough for a public release. Its config format is incompatible with earlier 1.x.x releases,
which is why the major version number has increased. I understand that config format change is quite a hassle for users,
so I made a <a href="/1-to-2/">convertor</a>. If you run into any bugs or difficulties converting, let me know!
</p>

You may want to read the [previous post](/blog/soupault-2.0.0-beta1-release/) for a detailed discussion of breaking changes and migration.
In this post I’ll focus on new features—many of them are made possible by those breaking changes.

## The convertor

To simplify migration for existing users, I wrote a convertor that you can find at [1-to-2](/1-to-2/).
It’s a pure client-side JS application and your config is never sent anywhere over the network.

Its only downside is that it cannot preserve your original comments and formatting. If you have a nice hand-written config,
you may not want to lose it, so I made the convertor output a detailed log of its actions that you can use as a guidance
for converting configs by hand.

## Site metadata extraction and rendering

### Index fields

If you haven’t used the indexing feature yet, this may need some explanation. Soupault doesn’t use “front matter”,
instead it extracts metadata from HTML itself, in the spirit of microformats. Thus it needs a mapping of CSS selectors
to field names.

First versions that supported metadata extraction had a fixed content model: `title, date, author, excerpt`.
Then it became clear that it’s not enough and I added [custom fields](/reference-manual-v1/#custom-index-fields).
The irony is that custom fields were immediately more flexible than the built-in ones: for example, you could use
them to extract an element attribute rather than content.

Since built-in fields were configured with options like `index_title_selector`, there was no obvious path to
giving them the same flexibility. There was also no way for the user to rename built-in fields, or override them
with custom fields.

Now there’s no built-in content model anymore, and thus no separation between built-in and custom index fields.

You can easily re-create the old content model with this configuration:

```toml
[index]
    index = true
    sort_by = "date"
    sort_descending = true

[index.fields]
  date = { selector = "time", extract_attribute = "datetime", fallback_to_content = true }

  author = { selector = "#author" }

  excerpt = { selector = "p" }

  title = { selector = "h1" }
```

The convertor will also do that for you.

### Built-in template processor

The built-in template processor is now [Jingoo](https://github.com/tategakibunko/jingoo) rather than Mustache.
Jingoo’s syntax and capabilities are similar to that of Jinja2, so it’s now possible to render site index
data in non-trivial ways without resorting to external scripts.

Jingoo syntax is almost a strict superset of Mustache, with one exception: it neither uses nor supports triple braces.
Thus, your old `index_item_template` options will work if you replace every `{{{var}}}` instance with `{{var}}`.
The convertor also takes care of it.

The old `index_item_template` option applies the template to every index entry individually. Since Mustache doesn’t
have real loops or conditions, that wouldn’t be any useful. Jingoo is a different story though.

Now thers’s a new `index_template` option that allows you to give the entire index data to a template at once.

Here’s the index view that produces the [code](https://baturin.org/code/) page of my website where entries are grouped by category
(taken from elements like `<span id="category">OCaml</span>`).

```toml
[index.views.topical]
  index_selector = "#topical-index"
  index_template = """
    {# Collect unique categories from the list #}

    {# Variables outside of namespaces are immutable,
       thus we create a "state" namespace so that we can modify
       the list of categories #}
    {% set state = namespace(categories = []) %}

    {% for e in entries %}
      {% if not (e.category in state.categories) %}
        {% set state.categories = [e.category] + state.categories %}
      {% endif %}
    {% endfor %}

    {% set state.categories = sort(state.categories) %}

    {# Now render a list of entries from each category we’ve found #}
    {% for c in state.categories %}
      <h2>{{c}}</h2>
      <ul class=\"nav\">
        {% for e in entries %}
          {% if e.category == c %}
            <li><a href="{{e.url}}">{{e.title}}</a></li>
          {% endif %}
        {% endfor %}
      </ul>
    {% endfor %}
  """
```

Of course, the `index_processor` option isn’t going anywhere either. You will always be able to just pass JSON-encoded
site metadata to an external program and take HTML back from it.

### Decoupled metadata gathering and rendering

Soupault now collects metadata from "normal" pages and then runs index rendering on index pages (all pages named `index.*`, or whatever you set the `index_file` option to).
This means every index page has access to the complete site index, not only to the index of its own section.

This opens new opportunities, such as displaying an index of the same section in different ways.
For example, [Hristos](https://hristos.lol/) used it to display a simplified list of recent blog entries on his front page, while on [/blog](https://hristos.lol/blog/) he displays a detailed blog feed.

## New Lua plugin functions

### Using the template processor from Lua plugins

It would be unfair to keep the new template processor to myself. 
You can use it in your Lua plugins as well, via `String.render_template(template_string, env_table)`.
 
Note that index metadata is also available to Lua plugins now , as a `site_index` global variable. Thus you can completely
take over the index rendering process if you want to. 

### JSON serialization and file output

You can serialize Lua values to JSON using `JSON.to_string` and `JSON.pretty_print` functions.

It’s also possible to write a string to a file with `Sys.write_file` (if anyone wants overwrite/append and binary/mode switches, that’s doable, just let me know).

## Multiple page templates

It’s now possible to use different page templates for different sections/pages. In soupault’s terminology, a "page template" is simply a HTML pages without content
where content is inserted, using a CSS selector query to find the element where to inser it.

```toml
[settings]
  default_template_file = "templates/main.html"
  default_content_selector = "body"

[templates.funny-template]
  file = "templates/funny-template.html"
  content_selector = "div#fun-content"
  section = "fun/"
```

## New widget options

The `breadcrumb_template` option of the [breadcrumbs widget](/reference-manual/#breadcrumbs-widget) is now a Jingoo template as well.
This means you can use filters to fine-tune their rendering, like `breadcrumb_template = """<a class="nav" href="{{url}}">{{name|replace("_", " ")}}</a>"""`.
Thanks to [Tyrone](https://tyrone.zone/) for the idea!

The ToC widget now supports a `min_headings` option, e.g. `min_headings = 5` will make the ToC appear only in pages with five or more heading tags.

## Closing words

I’m grateful to everyone who tested the new features of 2.0.0 and confirmed that they work,
including [lthms](https://soap.coffee/~lthms/) and Tyrone.

Special thanks to [Hristos](hristos.lol/) who not only tested new features, but exposed himself
to the new config format before it was stabilized and then helped find and fix bugs in the automated convertor.

My work on soupault doesn’t stop here of course, and I’m prepared to make maintenance releases
if anyone finds a bug we missed. I’m also ready to answer any questions about migrating from 1.x.

What to expect in the future? One thing I hope to make happen is a parallel implementation using the multicore OCaml runtime
I successfully built simple parallel programs with multicore OCaml and I already reworked soupault to make it parallelizable
by replacing a normal fold with a parallel version, but I haven’t tried to make these developments work together yet.
There are many small improvements to make too, so stay tuned for updates.

