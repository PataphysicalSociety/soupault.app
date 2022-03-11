<h1 id="post-title">Soupault 3.2.0 release: persistent variables for plugins, checking for selector matches, and more</h1>

<p>Date: <time id="post-date">2021-10-23</time> </p>

<p id="post-excerpt">
Soupault 3.2.0, is available for download from <a href="https://files.baturin.org/software/soupault/3.2.0">my own server</a>
and from <a href="https://github.com/dmbaturin/soupault/releases/tag/3.2.0">GitHub releases</a>.
It features variables that are persistent between plugin runs, new functions for checking whether an HTML element matches
a CSS selector, and some bug fixes.
</p>

## New features

### Persistent variables

Historically, plugins would run from a clean state on every page. All [built-in variables](/reference-manual/#plugin-environment)
would be injected into the Lua interpreter environment every time a plugin ran. When plugin code finished running,
all variables it created or modified would be destroyed.

Most of the time, that’s a good thing since it prevents _unintended_ action at a distance. However, it also makes certain
use cases impossible.

For example, consider the [reading time](/plugins/#reading-time) plugin. It can calculate the estimated reading time for a page
based on its word count and insert it into the page. What if you want to calculate the total reading time of all pages on your site though?

You could exploit the fact that soupault processes all "content" pages before it starts processing index pages,
so you could be sure that by the time it gets to index pages, the total content reading time is already calculated.

So you could make it sum up the reading times of all pages in an accumulator variable, then make it insert it into a certain
element, e.g. `span#reading-time`. Then add `<span id="total-reading-time">` to your `site/index.html` and show the visitors
how much is there to read.

That is, if you had a way to keep the accumulator variable value. Well, now you do have a way to do that: the new
`persistent_data` built-in variable.

When soupault loads a plugin, it creates an empty Lua table. When a plugin runs, it injects that table into plugin’s environment
as a global variable named `persistent_data`.
When that plugin finishes running, soupault extracts the value of that global and stores it until the next plugin run.

Thus you can easily stash data for later use now. You can use that to either avoid running expensive operations more than once,
or to gather data from multiple pages.

For example, you could add this to the end of the `reading-time.lua` plugin to show the total reading time in the site build log:

```lua
if not persistent_data["time_total"] then
    persistent_data["time_total"] = reading_time
else
    persistent_data["time_total"] = persistent_data["time_total"] + reading_time
end

Log.info("Reading time total: " .. persistent_data["time_total"])
```

### Checking if elements match selectors

Most of the time, `HTML.select` and friends is all you need to find HTML elements you want to process.
However, sometimes you may want to select elements and then decide what exactly to do with each of them
depending on its attributes.

For example, soupault 3.1.0 added `ignore_heading_selectors` option for the [ToC widget](/reference-manual/#toc-widget)
that allows excluding some headings from the ToC. If you want to add a heading to the page but don’t want it in its ToC,
you can add `ignore_headings_selectors = [".notoc"]` in your `soupault.toml` and then add something like
`<h1 class="notoc">This heading will not be in the ToC</h1>` to your page.

Now plugin writers can implement similar logic in their own code using the new [HTML.matches_selector](/reference-manual/#HTML.matches_selector)
and [HTML.matches_any_of_selectors](/reference-manual/#HTML.matches_any_of_selectors) functions.

### Specifying minimum soupault version in the config

Websites whose source is open to community contributions sometimes have a problem with those contributors trying to build them with
wrong build tool versions and getting errors.

To let people with outdated soupault versions receive an unambiguous error message, you can add the minimum supported version to your config:

```toml
[settings]
  soupault_version = "3.2.0"
```

Then if anyone tries to run an older version on that config, soupault will show a message about minimum supported version and exit.

## Bug fixes

Soupault now correctly quotes page file paths before passing them to [page preprocessors](/reference-manual/#page-preprocessors),
so page names with spaces and other special characters are processed correctly now.
