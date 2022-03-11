<h1 id="post-title">Soupault 1.12.0 release</h1>

<p>Date: <time id="post-date">2020-05-31</time> </p>

<p id="post-excerpt">
Soupault 1.12 release is available for [download](https://files.baturin.org/software/soupault/1.12.0/).
It’s a pretty small release, with just two essential changes. I haven’t had much time last month so big things from the roadmap
aren’t there yet. What is there is better reporting of missing/misspelt widget dependencies and a way to properly
loop through node’s children.
</p>

## Better reporting of missing widget dependencies

As you know, soupault allows you to sequence page processing widgets explicitly using the `after=` option.
This way you can use the output of one widget as an input for another.

Now debugging bad dependencies got easier. In older versions if you mistyped a widget name,
it would tell you the offending name, but not which widget depends on it.

Now it gives you a full list of widgets with missing dependencies so you immediately know
where to look.

Suppose you have this config:

```toml
[widgets.good-widget]
  after = "fake-widget"

[widgets.better-widgets]
  after = ["very-fake-widget", "fakest-widget-ever"]
```

Assuming there’s no `[widgets.fake-widget]` etc. in your config, you’ll get this error:

```
[ERROR] Found dependencies on non-existent widgets
Widget "good-widget" depends on non-existent widgets: fake-widget
Widget "better-widget" depends on non-existent widgets: very-fake-widget, fakest-widget-ver
```

There are no spelling suggestions for this case yet, but it’s doable, so if you think it would be usedul,
let me know.

## Handling of HTML element tree children

The plugin API is mostly intuitive for people familiar with DOM manipulation in JavaScript,
even if function names are different. However, there are some subtle differences.
One issue discovered by Aoirthoir An Broc was in handling of the values returned by
`HTML.children` function.

Web browsers don’t provide a general HTML parsing API and only give you an already parsed page.
The DOM API also assumes you are working exclusively with elements, and treats element text as
something non-existent—you can only access the entire content of an element with `e.innerHTML`.

For example, from an HTML parser’s point of view, `<p>This is a <em>great</em> <strong>paragraph</em></p>` node has _four_ children:
`text("This is a ")`, `element("<em>", "great")`, `text(" ")`,  `element("<strong>", "paragraph"`.
Browsers hide this bit of complexity from you, which is justified for their use case.

Soupault aims to allow completely arbitrary HTML manipulation, so it cannot avoid this complexity.
A side effect is that not every output of `HTML.children` is suitable for `HTML.set_attribute` and similar functions:
how can you add an attribute to a node that isn’t an element?

Earlier versions had one bug and one shortcoming related to this. The bug was that it would disallow using
any output of `HTML.children/ancestors/descendants/...` with element-only functions like `HTML.add_class`.
The shortcoming was that there was no way to check if something is an HTML element.

Now the bug is fixed, and there’s a new `HTML.is_element` function for checking if something is an element.

This is how you can add  `class="my-class"` to every element in the page `<body>`:

```lua
children = HTML.chilndren(HTML.select(page, "body"))

local index = 1
while children[index] do
  node = children[index]

  if HTML.is_element(node) then
    HTML.add_class(node, "my-class")
  end

  index = index + 1
end
```

In the future there may be new functions for getting only _element_ children,
of filtering functions. If you have any ideas for the plugin API, let me know!
