<h1 id="post-title">Soupault 4.3.0 release</h1>

<p>Date: <time id="post-date">2022-10-24</time> </p>

## Overview

<p id="post-excerpt">
Soupault 4.3.0 is available for download from <a href="https://files.baturin.org/software/soupault/4.3.0">my own server</a>
and from <a href="https://github.com/PataphysicalSociety/soupault/releases/tag/4.3.0">GitHub releases</a>.
It adds a few more Lua plugin functions and fixes a few minor bugs.
</p>

## New features and improvements

### New Lua plugin functions

* `String.starts_with(str, prefix)`
* `Sys.split_path(path_str)` for splitting native file paths (uses `/` on UNIX-like systems, `\` on Windows).
* `Sys.split_path_unix` (aka `Sys.split_path_url`) for splitting paths using the `/`-convention regardless of the OS (safe for URLs).

## Bug fixes

* `--help` message about the `--config` option now correctly mentions that it takes a path.
* Removed a useless log message about build profiles when no profiles are specified (i.e., `--profile` option is not given).
* Improved error reporting in certain unlikely situations (mainly internal errors).
* When index entry comparison failure fails due to bad field values, offending entries are logged in JSON to simplify debugging.
* Corrected a mistake in option spell checking logic that could sometimes lead to useless suggestions.
