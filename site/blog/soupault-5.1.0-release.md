<h1 id="post-title">Soupault 5.1.0 release</h1>

<p>Date: <time id="post-date">2025-06-17</time> </p>

<p id="post-excerpt">
Soupault 5.1.0 is available for download from <a href="https://files.baturin.org/software/soupault/5.1.0">my own server</a>
and from <a href="https://github.com/PataphysicalSociety/soupault/releases/tag/5.1.0">GitHub releases</a>.
It reintroduces the global data in a safer way, adds functions for string case conversion, and also adds an option
to strip tags from individual index fields.
</p>

## Behavior changes

Index extraction is now enabled by default in generator mode and always still disabled in the HTML (post-)processor mode,
so the old `index.index = <true|false>` option has no effect now. I'll leave it for compatibility with older releases
for the forseeable future, not to break anyone's configs.

## New features

### Global data is back

In soupault 5.0.0, I removed support for the `global_data` variable shared between all Lua code.
That thing would be a nightmare for the future multi-threaded page processing support,
since all plugins that wanted to use it would have to acquire a lock.

However, people started asking me to get it back, and I realized that the real problem
is not the _existence_ of global data but its _mutability_.

The use case that people use it for in practice is usually like this: the [`startup`](#hooks-startup) hook
loads some data from an external file, then widgets use it, to avoid reading the same files and loading the same data
for every page.

For example, a statically generated online store website can load the product catalog from a CSV or a TOML file,
then use it when generating product pages.

Now support for sharing global data is back, in a way that will not mess with parallelism and concurrency:

* The startup hook can add new values to a table called `global_data`.
* Soupault retrieves it from the hook environment and stores it internally.
* All Lua code can access values from there using a new function: `Plugin.get_global_data(key)`.

That way, only the startup hook (that runs only once, on soupault startup) can write to the global data,
and all other code can read it but has no way to modify it.
I believe this covers the case that people actually want to use global data for.

### Widgets can safely create asset files in all directories

Soupault intentionally processes asset files and puts them in their target directories
before it starts processing pages — so that widgets that run on pages can access or modify those asset files.

For example, it was already possible to write a plugin that creates smaller preview versions of
images used in a page. Look in the element tree for `<img>` and friends, run a tool like GraphicsMagic
on the file, then rewrite the `src` attribute to point at the preview and wrap it in a hyperlink to the original.

However, I missed one possible use case: creating _new_ asset files.
It was hindered by the fact that target if the intended target directory didn't exist when soupault started processing a page,
it would only create that directory before writing the page file.
That means such plugins would have to check if that directory already existed before trying to create files.

Target directories for page files are now guaranteed to exist when soupault starts processing widgets,
so that widgets can create new asset files in any page directories, without having to check if they exist and create them.

### It's now possible to strip HTML tags from individual index fields

Soupault already had an undocumented option for stripping HTML tags from _all_ index fields: `index.strip_tags`).
Undocumented as in I simply forgot to document it... not intentionally undocumented.

Then a new user asked me if there was a way to strip tags from field.
I found the undocumented option but realized that people may want to strip tags only from _some_ fields.

Now there's a simple way to specify that behavior for individual fields:

```toml
[index]
  # By default soupault keeps HTML tags in index fields,
  # suppose we want to strip them by default
  strip_tags = true

[index.fields.excerpt]
  selector = ["p.excerpt", "p"]

  # But want to keep them in post exerpts
  strip_tags = false
```

# Other improvements

* `site_index` and `index_entry` variables are now available in the template environment of the `element_template` widget.

### New Lua API functions

There are now functions for case conversion. They only affect the case of ASCII characters,
Unicode characters are ignored because handling their case requires knowing their language.

* `String.lowercase_ascii(string)`
* `String.uppercase_ascii(string)`
* `String.capitalize_ascii(string)`
* `String.uncapitalize_ascii(string)`



