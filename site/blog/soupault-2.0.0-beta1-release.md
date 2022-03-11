<h1 id="post-title">Soupault 2.0.0-beta1 release</h1>

<p>Date: <time id="post-date">2020-08-24</time> </p>

<p id="post-excerpt">
Soupault 2.0.0-beta1 is <a href="https://files.baturin.org/software/soupault/2.0.0-beta1/">available for download</a>.
People familiar with <a href="https://semver.org">semantic versioning</a> likely have a bad feeling already.
Yes, it means what you think it means: there are breaking changes that make soupault 2.0.0 incompatible with older releases.
Those changes are necessary to fix old design mistakes and make some useful improvements. I made an effort to simplify the migration
as much as possible. Please read this post carefully before upgrading.
</p>

First of all, I’d like to say thanks to every community member! Originally I thought soupault is likely to remain a single user project,
but it attracted some creative and passionate people who gave valuable feedback, contributed to the code, and used it in ways I never thought
were possible. I’m happy to see that it became a useful tool for other people and that the community is growing, even if slowly for now.
I’m also happy that, after a year of development, most of the architectural decisions still hold up quite well. 

However, there are some mistakes in the configuration format design that block some paths forward. Sadly, there’s no way to fix them without
breaking compatibility, and even deprecation is hard or impossible. I believe it’s better to make all those changes at once so that we all can
migrate and forget. Creeping incompatibility is way worse than a big migration, as of me.

So, to the point: soupault 2.0.0 makes incompatible changes to the config syntax _only_. The plugin API remains compatible, so old plugins
will continue to work. It’s only the config that you need to update. You can do it by hand or use an automated migration tool.

If you have any problems migrating to 2.0.0, don’t hesitate to ask! One of the reasons I went for the big change is that at this point
the community is small enough that, if needed, I can help everyone personally.

## New features

So, why even bother upgrading if you need to adjust the config by hand?

* Index metadata is now available to Lua plugins, as a `site_index` global variable.
* New plugin functions: `Sys.get_file_size`, `String.render_template`.
* The ToC widget now supports `min_headings` option, e.g. `min_headings = 5` will make the ToC appear only in pages with five or more heading tags.
* It’s now possible to use advanced options with all index fields.
* It’s now possible to specify a different content selector for custom page templates.
* It’s also possible to present the _complete_ site index in different ways on different pages.

The inner workings of the index metadata collection were completely reworked. Now soupault first collects data from every non-index page,
and only then renders index pages. This means _every_ index page has access to the complete index. For example, [Hristos](https://staging.hristos.lol/)
used it to display a simplified list of recent blog entries on his front page, while on [/blog](https://staging.hristos.lol/blog/) he displays
a detailed blog feed.

An additional advantage of this approach is that it will make parallel processing possible. It’s not there yet, but once multicore OCaml runtime
is ready, soupault can be made parallel simply by replacing the normal `fold` with a parallel version.

## Config format changes

I say again: soupault 2.0 config format is incompatible with 1.x and you will need to convert your old configs. First of all, invalid options are now treated as errors
rather than warnings, so at least you will notice obsolete options sooner than later.

### 1 to 2 config convertor

To make migration as simple as possible, I made an [automatic convertor](/1-to-2). It’s a pure client-side JavaScript application, so there are
no privacy or availability concerns there. Just paste your config and get an updated version.

The only problem with it is that it doesn’t preserve original formatting or comments. I couldn’t find a TOML parser capable of doing that.
Instead, I made the convertor output a detailed log of what it’s doing, so that you can replicate its actions by hand.

If you find any issues with the convertor, let me know!

Or, if you prefer to convert the config entirely by hand, or just want to know the details of incompatible changes, read on.

### The settings section

The `default_template` option was renamed to `default_template_file`. This is because there are `template` options in different places
that take a template _string_ rather than a file path.

The `content_selector` option is now `default_content_selector`. This is because custom templates can have their own `content_selector`
options now.

### The index section

#### Index fields

The following fields have been *removed*: `index_date_selector`, `index_author_selector`, `index_title_selector`, `index_excerpt_selector`.
In effect, the built-in content model is gone.

The `[index.custom_fields]` was renamed to `[index.fields]`, because there are no built-in fields anymore.

Why? Over time, custom fields became much more flexible and got new options like `extract_attribute` and `default_value`.
However, built-in fields were still limited to just a selector option and nothing else. 

You can replicate the old defaults with this:

```toml
[index.fields]
  author = { selector = "#author" }

  date = { selector = "time" }

  excerpt = { selector = "p" }

  title = { selector = "h1" }
```

#### Index views

The following options were *removed*: `use_default_view`, `index_item_template`, `index_processor`. There is no default view anymore.

Old versions automatically sorted index entires by the built-in `date` field. Now there is no built-in `date` field, but it’s possible
to sort the index by _any_ field you define.

Thus, the `newest_entries_first` option was renamed to `sort_descending`. Since it’s possible to sort by a field that logically isn’t a date,
the old name would be misleading.

How do you specify which field to sort by? With a `sort_by` option, of course.

## New template processor: from Mustache to Jingoo

For some tasks, a template processor is really the best tool. People sometimes use them even in client-site JavaScript code.

To make it possible to render the side index without resorting to an external script, I originally added an `index_item_template`
option that took a [Mustache](https://mustache.github.io/) template. Mustache is logic-less, which makes it simple and lighweight,
but also limits what you can do.

Sometimes complete lack of conditionals or filters is way too limiting. Not long ago, [Tyrone](https://tyrone.zone/) asked me if it’s possible to replace
underscores and hyphens in breadcrumbs with spaces so that `my-projects` directory name is rendered `my projects`.
That would be trivial if the `breadcrumb_template` option was a template for a logic-aware processor: `{{name | replace("_", " ") | capitalize}}`.
Sadly, it’s not, and the only way to do it is to make your own breadcrumbs implementation in Lua.

Same goes for rendering index data. All my sites used Python scripts for rendering it because the built-ins were too limited. Ability to use an external
script is an essential part of soupault’s architecture and it’s not going anywhere. However, when an external script is involved, it’s no longer a
&ldquo;no moving parts&rdquo; setup, so this decision should better be reserved for cases when you need something truly unusual.

So, soupault now uses [Jingoo](https://github.com/tategakibunko/jingoo) for the `index_item_template` option in index views, and for
the `breadcrumb_template` option of the breadcrumbs widget.

The only incompatibility with Mustache is that Jingoo doesn’t support triple brace syntax (`{{{them}}}`). In Mustache triple brace means
“don’t escape HTML”, but Jingoo doesn’t escape HTML by default, so it doesn’t need that feature to begin with. It treats
triple braces as a syntax error, so you’ll need to replace it with a double brace everywhere.

The `breadcrumb_template` option needs to be changed complete by hand. The new default is `<a href={{url}}>{{name}}</a>`.

The template processor functionality is also available to Lua plugins, through the `String.render_template(template_string, env_table)` function.

## Please test it!

The beta needs as much testing as it can get. Please test it with your sites and let me know if you find any issues!
