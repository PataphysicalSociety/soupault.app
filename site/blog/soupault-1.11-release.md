<h1 id="post-title">Soupault 1.11.0 release</h1>

<p>Date: <time id="post-date">2020-04-27</time> </p>

<p id="post-excerpt">
Soupault 1.11.0 is available for <a href="https://files.baturin.org/software/soupault/1.11.0/">download</a>.
It's not a very big release, but it adds some new features, including support for multiple page templates,
ability to extract attribute values as metadata, and new plugin API functions for working with element attributes.
</p>

As usual, you can verify releases with [minisign](https://jedisct1.github.io/minisign/), for example:

```
minisign -Vm soupault-1.11.0-win32.zip -P RWRfW+gkhk/+iA7dOUtTio6G6KeJCiAEp4Zfozw7eqv2shN90+5z20Cy
```

Initially I planned to focus on the next big release with reworked internals, but I've received some good suggestions
from the community, and I wanted to make those features available to everyone, so here we go.

Thanks to Aoirthoir An Broc, Jonah G, Hristos N. Triantafillou,	and Thomas Letan for feedback and testing!

## Multiple page templates

Historically, you could only have one page template. However, some people like to make sites
where pages in different sections look different. That's a cool thing to do, and the goal
of soupault is to save people time hand-editing HTML without stiffling their creativity.

Now you can specify multiple templates in addition to the default:

```toml
[templates.serious-template]
  file = "templates/serious.html"
  section = "serious-business"

[templates.fun-template]
  file = "templates/fun.html"
  path_regex = "(.*)/funny-(.*)"
```

You can use all the same page targeting options as you already could use in widgets and index settings:
`page, section, path_regex` and `exclude_page, exclude_section, exclude_path_regex`.

There is no way to specify content selector per-template yet, so they all will use the
`content_selector` option from `[settings]` for now. This limitation will be lifted
in later versions.

Also, it's your responsibility to make sure that templates are properly limited to specific pages.
If there is more than one template without any limiting options, it's undefined behaviour:
you can't rely on their order in the config.

## Extracting element attributes

Most of the time, meaningful data is found in the content of HTML elements, while their attributes
provide purely technical metadata. However, sometimes attributes are semantic.

For example, the `<time>` element allows storing the real date/time in the `datetime=` attribute
as in `<time datetime="1970-01-01T00:00Z">time immemorial</time>`.

Another exxample is the `<img>` element that has no content. If someone wants to include a
&ldquo;hero image&rdquo; of a post in the blog index, or create posts whose _only_ content
is an image (self-hosted Instagram?), they have to be able to access its `src` attribute.

In this release, it can be done—so far only for custom fields (not for builtins like `date_selector`).

```toml
[index.custom_fields]
  post_image = {
    selector = "img#post-image",
    extract_attribute = "src" 
  }

  post_date = {
    selector = "time#post-date",
    extract_attribute = "datetime"
  }
```

## New plugin functions

There was `HTML.set_attribute` function, but generally the plugin API for working with attributes
was lacking. You couldn't delete an existing attribute, or see what attributes an element has.
Now you can:

```lua
HTML.delete_attribute(elem, attr_name) -- deletes attribute
HTML.list_attributes(elem) -- lists names of all attributes an element has
HTML.clear_attributes(elem) -- deletes all attributes from an element
```

Another area where the API was not well thought out was `HTML.children` and friends.
Those functions worked by themselves, but they didn't play well with functions like
`HTML.set_attribute`.

The issue is that children of an HTML elements may be either other elements or text nodes.
Functions like `HTML.set_attribute` only works with elements, since text nodes obviously
can't have attributes. However, there was no way to check if a node is an element or text.
That way any attempt to modify every child/siblind/descendant of an element in a loop
would fail if it had bare text inside.

Now there's `HTML.is_element` function that is true for element nodes and false otherwise.
Thus you can check if it's safe to use element-only functions. For example, add a CSS class
to every child of the page `<body>`:

```lua
container = HTML.select_one(page, "body")
elems = HTML.children(container)
count = size(elems)

local n = 1
while (n <= count) do
  elem = elems[n]
  if HTML.is_element(elem) then
    HTML.add_class(elem, "some-silly-class")
  end

  n = n + 1
end
```

Last but not least, there's now `String.join(strings, separator)` for concatenating
a list of strings into a single string.
