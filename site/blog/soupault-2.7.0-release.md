<h1 id="post-title">Soupault 2.7.0 release</h1>

<p>Date: <time id="post-date">2021-05-12</time> </p>

<p id="post-excerpt">
Soupault 2.7.0, is available for download from <a href="https://files.baturin.org/software/soupault/2.7.0">my own server</a>
and from <a href="https://github.com/dmbaturin/soupault/releases/tag/2.7.0">GitHub releases</a>.
It adds a new <code>wrap</code> widget, ability to disable any widget in the config, and support for multiple build profiles.
</p>

## The `wrap` widget

The new `wrap` widget allows wrapping certain elements in an HTML snippet. This may be useful to avoid additional templates,
or to fix up something in a legacy page.

For example, this configuration will wrap the `<main>` element of a page in a `<div class="main-wrapper">`.

```toml
[widgets.wrap-main]
  widget = "wrap"
  wrapper = """ <div class="main-wrapper"> </div>"""
  selector = "main"
```

How about wrappers that have nested elements? Since there's no way to automatically decide which exact element
to insert the target in, you'll need to specify the `wrapper_selector` option in that case.

```toml
[widgets.wrap-multiple]
  widget = "wrap"
  wrapper = """
  <div class="text-3xl"> 
    <div class="font-bold"> 
      <div class="text-red-200" id="innermost-div">
  """
  selector = "#wrap-me-up"
  wrapper_selector = "#innermost-div"
```

Thanks to JP Lew and Anton Bachin for input and testing this feature.

## Multiple build profiles

Originally, you could only specify one build profile using `soupault --profile someprofile`. However, this can be quite limiting.
Sometimes you may want to enable different sets of widgets independently.

Suppose you have this config:

```toml
[widgets.foo]
  ...
  profile = "live"

[widgets.bar]
  ...
  profile = "debug"
```

Now you can make both widgets run by calling `soupault --profile live --profile debug`, in addition to being able to run them independently.

## Disabling widgets

Now it's possible to disable any widget by adding `disabled = true` to its config. This is much easier than commenting out an entire widget.
