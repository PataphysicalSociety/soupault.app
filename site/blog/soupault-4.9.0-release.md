<h1 id="post-title">Soupault 4.9.0 release</h1>

<p>Date: <time id="post-date">2024-03-20</time> </p>

<p id="post-excerpt">
Soupault 4.9.0 is available for download from <a href="https://files.baturin.org/software/soupault/4.9.0">my own server</a>
and from <a href="https://github.com/PataphysicalSociety/soupault/releases/tag/4.9.0">GitHub releases</a>.
It is a small release that includes Lua plugin API for cryprographic hash functions (MD5, SHA-1, SHA-256/512, and BLAKE2),
a couple of function aliases, and a new hook that runs before any pages are processed.
</p>

## New features and improvements

* New `startup` hook that runs before soupault processes any pages and can modify the `global_data` variable.

### New plugin API functions

New `Digest` module offers functions for calculating cryptographic hash sums of strings.
All those functions return hex digests.

* `Digest.md5(str)`
* `Digest.sha1(str)`
* `Digest.sha256(str)`
* `Digest.sha512(str)`
* `Digest.blake2s(str)`
* `Digest.blake2b(str)`

Other new functions:

* `Sys.basename_url(str)` and `Sys.dirname_url(str)` — aliases for `Sys.basename_unix` and `Sys.dirname_unix`, respectively.

