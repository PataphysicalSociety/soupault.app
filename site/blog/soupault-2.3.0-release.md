<h1 id="post-title">Soupault 2.3.0 release</h1>

<p>Date: <time id="post-date">2020-12-18</time> </p>

<p id="post-excerpt">
Soupault 2.3.0, a winter holidays release, is <a href="https://files.baturin.org/software/soupault/2.3.0">available for download</a>.
The main highlight is a bunch of new plugin functions for dealing with files and Base64 data.
There’s also a bug fix related to the <code>profile</code> option and a couple of behaviour improvements.
Also, the macOS target is now named <code>macos-x86_64</code> to reflect the existence of macOS on ARM64.
There are no prebuilt binaries for it, so if you’ve got an ARM64 Mac, you’ll need to build from source
or rely on its x86 compatibility layer.
</p>

## Bug fixes

The `profile` option for widgets works as expected again. It was broken between 2.0.0 and 2.3.0 due to my mistake.
I forgot to add that option to the list of valid options when I first added it,
but since until 2.0.0 invalid widget options were merely warnings, it wasn’t so noticeable.

I wasn’t actively using that option for a while, so I when I made invalid options hard errors in 2.0.0,
I didn’t notice. Then [Hristos](https://hristos.lol) tried it and found that it blows up in 2.2.0.
Shame on me. Well, at least it was a simple fix.

## Behaviour changes

One thing is that TOML type errors now include expected and actual type for ease of debugging, like "expected a string but found a table".

Another change is that soupault now copies asset files before processing pages.
For example, if you have `site/cats/serious_cat.jpg` and `site/cats/index.html`, then it will create `build/cats/serious_cat.jpg` first.

The reason for this change is to allow plugins to modify asset files.
Plugins run when a page is processed, so if assets are copied after generating pages, then plugin output would end up overwritten.
Now "co-located" assets of a page are guaranteed to exist at the time when the page is processed.

## New features

The `insert_html` widget now supports `parse = false`, mainly for consistency with `include` and `preprocess_element`.

### New plugin functions

* `String.base64_encode` and `String.base64_decode`.
* `Sys.basename` and `Sys.dirname`.
* `Sys.get_extension` (e.g. `"hello.jpg" → "jpg"`).
* `Sys.file_exists`.
* `Sys.is_file` and `Sys.is_dir`. Both return `nil` if it does not exist.
* `Sys.run_program_get_exit_code`. Returns the exit code unlike `Sys.run_program`, 0 for success.
* `Sys.delete_file` and `Sys.delete_recursive`

## Future plans

After 1.5 years of development, it seems like soupault has reached certain maturity.
Ever since it shed some early days design mistakes in 2.0.0, most changes are small incremental improvements,
mostly new plugin functions.

The work will sure continue in 2021. The `profile` option showed a clear need for a test suite.
In the early days, this very site used every feature of soupault, so broken features were immediately obvious.
Now it’s no longer the case, so some unit tests and a test site that actually uses every configuration option
will be necessary to ensure that changes are safe. If you want to join this work, that’s more than welcome!

Another plan is the long-promised new TOML library. Since TOML is a _configuration_ file format for humans,
rather than a serialization format for machines, it really deserves a library that can produce nice parse errors at least.

For now, winter holidays is a perfect time to make website updates and overhauls we keep putting on hold all the year,
and I hope soupault 2.3.0 will help you with it.
