<h1 id="post-title">Soupault 1.8.0 release, with improved plugin support</h1>

<p>Date: <time id="post-date">2020-01-17</time> </p>

<p id="post-excerpt">
Soupault 1.8.0 is available for <a href="/#downloads">download</a>. This release is focused on improving
plugin support. First big improvement is that Lua plugin execution errors are treated exactly like all
other errors: in strict mode, they fail the build. There’s also a bunch of new plugin functions.
</p>

Now to the improvements…

## Plugin execution error handling

In older versions, Lua syntax errors and runtime errors were logged, but they could not
stop the build even in strict mode. That was a limitation of [Lua-ML](https://github.com/lindig/lua-ml/),
so I had to fix it there.

Now plugin errors correctly fail the build.

## `TARGET_DIR` environment variable

One possible use of plugins and executable called with the `preprocess_element` widget is processing existing assets
or creating new ones.

For example, it’s quite easy to resize images to their `width` and `height` attributes, create PNG versions of
Graphviz graphs, or run chunks of the page through a text to speech program.

However, one thing was overlooked in 1.7.0: there was no easy way to see where the page file will be stored
and create correct relative links. Directory structure varies depending on the `clean_urls` option,
so you’d have to put all generated files in a single directory and use absolute paths.

Now there is: programs called from `preprocess_element` and `exec` widgets can access it via `TARGET_DIR`
environment variable, and Lua plugins got a `target_dir` global.

Now you can easily store processed/generated assets together with pages:

```
[widgets.graphviz-png]
  widget = 'preprocess_element'
  selector = '.graphviz-png'
  command = 'dot -Tpng > $TARGET_DIR/graph_$ATTR_ID.png && echo \<img src="graph_$ATTR_ID.png"\>'
  action = 'replace_element'
```

For example, when this widget runs on `site/articles/dijkstra.html` and encounters `<pre class="graphviz-png" id="sample">`,
it will save the PNG version to `build/articles/dijkstra/graph_sample.png` if clean URLs are on, or to
`build/articles/graph_sample.png` if not. In both cases relative `src` will work as expected. 

## Build profiles

Sometimes you may want to enable certain widgets only for some builds. For example, include analytics
scripts only in production builds.

Now it’s easy to do. Add a `profile` option to your widget:

```
[widgets.analytics]
  profile = "live"
  widget = "include"
  file = "includes/analytics.html"
  selector = "body"
```

Then soupault will only process that widget if you run `soupault --profile live`. If you run
`soupault --profile dev`, or just `soupault`, it will ignore that widget.

## Specifying minimum supported version in plugins

It can be frustrating to see a plugin fail mysteriously and then find out it simply wants a newer version.

Now it’s easy to specify minimum supported version:

```
Plugin.require_version("42.0.0")
```

If soupault version is less than `42.0.0`, the build will fail like this:

```
[ERROR] Could not process page site/index.html: Plugin requires soupault 42.0.0 or newer, current version is 1.8.0
```

You can specify either a full version like `1.8.0`, but you can also write `1.8` and it’s assumed to mean `1.8.0`.

There is no way to specify _maximum_ supported version, but if I make any incompatible change to soupault,
I will add a function for that.

Plugins that use `Plugin.require_version` will obviously fail to work with versions older than 1.8.8 because
they didn’t have that function. For this reason you should only use it in new plugins that rely on functions
introduced in 1.8.0 or later.

## New plugin functions

Most of these are not really new, but rather internal functions now available to plugins.

<dl>
  <dt><code>Sys.random(max)</code></dt>
  <dd>Generates a random integer number from 0 to <code>max</code>. Example: `Sys.random(100)`. Numbers are not cryptographically secure.</dd>
  <dt><code>Sys.get_program_output(command)</code></dt>
  <dd>Executes a command in the system shell (<code>/bin/sh</code> on UNIX, <code>cmd.exe</code> on Windows) and returns its output. Execution errors are logged to stderr.</dd>
  <dt><code>Log.debug(message)</code></dt>
  <dd>If <code>settings.debug</code> is true, shows a message in the build log. Otherwise does nothing.</dd>
  <dt><code>HTML.replace_element</code> and <code>HTML.delete_element</code></dt>
  <dd>Aliases for <code>HTML.replace</code> and <code>HTML.delete</code> added for consistency.</dd>
  <dt><code>String.trim(string)</code></dt>
  <dd>Removes extra spaces from a string.</dd>
  <dt><code>String.slugify_ascii(string)</code></dt>
  <dd>Removes all characters other than English letters and digits from a string and replaces them with hyphens.</dd>
</dl>
