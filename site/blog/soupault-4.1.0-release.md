<h1 id="post-title">Soupault 4.1.0: asset processors, post-save hook, and more</h1>

<p>Date: <time id="post-date">2022-08-19</time> </p>

## Overview

<p id="post-excerpt">
Soupault 4.1.0 is available for download from <a href="https://files.baturin.org/software/soupault/4.1.0">my own server</a>
and from <a href="https://github.com/PataphysicalSociety/soupault/releases/tag/4.1.0">GitHub releases</a>.
It continues the extensibility improvement trend of 4.0.0 and adds two new mechanisms: <code>post-save</code> hooks
and asset processors. Additionally, release archives now include a changelog file.
</p>

## Post-save hooks

Some people want to run generated HTML through external programs, like HTML minifiers. That was already possible
in 4.0.0 thanks to the `save` hook, but the user would also need to write logic for writing pages to disk,
since the intended purpose of that hook is to give the user a chance to modify the output
before it's saved to disk or implement custom logic for writing output files.

If one want _just_ post-processing, that's extra effort. Now there's a new [`post-save`](/reference-manual/#hooks-post-save) hook that
runs _after_ the page file is written.

## Asset processors

A few people asked about support for asset pipelines for soupault. The system of hooks that I added in 4.0.0
greatly improved _page_ processing flexibility, but did nothing to improve asset handling,
since non-page files are handled outside of the page processing workflow.

Before this release, all soupault would do with non-page files was to copy them over to the build directory.
Any preprocessing had to be done outside of soupault as a separate build step.

Now there's a mechanism very similar to page preprocessors, but for assets. However, its design is noticeable
more complex. Page preprocessors are expected to send generated HTML to stdout, so they have only one mandatory argument —
the input file. No matter how (un)ergonomic and (in)flexible program's command-line options are, it's always possible
to structure a command string so that an input file path can be just appended to it.

Asset processors, however, require at least two arguments for input and output files.
With pages, there's no output file name problem because soupault manages generated page names itself,
but asset file names are on the user and soupault has no way to know what the output name should be.

Worse yet, a lot of time input and output file _extensions_ also need to be different.
If one references `styles/main.css` in a page template but the source file is `site/styles/main.sass`,
a Sass compiler command needs `build/styles/main.css` as its output argument<fn>Some tools allow the user
to specify an output directory, but many don't, and there may be a need to change the output file name
in any case.</fn>

That is why asset processor strings are [Jingoo](http://tategakibunko.github.io/jingoo/templates/templates.en.html) templates that offer a few built-in variables
so that you can assemble complete commands.

Here's a simple example: running all `*.png` files through [pngcrush](https://pmt.sourceforge.io/pngcrush/) — a popular PNG optimizer.

```toml
[asset_processors]
  png = "pngcrush {{source_file_path}} {{target_dir}}/{{source_file_name}}"

```

There are following variables in the template environment:

* `source_file_path` — full path to the source files (like `site/pictures/cat.png`).
* `source_file_name` — name of the input file without the directory part (like `cat.png`).
* `source_file_base_name` — name of the input file without extensions (like `cat`).
* `target_dir` — output directory path.

It may not be the best solution. The name of the `source_file_base_name` variable can be confusing
due to a collision with "basename vs. dirname" terminology where "basename" means a file name
without a directory path.

Perhaps it's better to add a Jingoo filter like `{{source_file_name | strip_extensions}}`.
Let me know what you think.

## Plugin API

* `Sys.get_program_output` now supports an optional input argument for sending data to program's stdin (`Sys.get_program_output("cat", "hello world")`).
* New `Sys.strip_extensions` function for removing extensions from file names.

## Misc

Release archives now include a brief changelog to make it easier to see what's new
if one receives a new version on floppy drives over an underground sneakernet.
It's also helpful for creating distro packages that are expected to include a changelog.
