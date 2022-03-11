## Official binary builds

The simplest way to start using soupault is to download a prebuilt executable. Just unpack the archive and you are ready to go.

<dl>
  <dt>Linux (x86-64)<fn id="linux-musl">Before you have a chance to interject for a moment,
      I&apos;ll say that it&apos;s linked statically with <a href="https://www.musl-libc.org/">musl</a>, so it will work on any Linux-based OS,
      not only GNU/Linux.</span></dt>
  <dd><soupault-release platform="linux-x86_64" />
  <dt>Microsoft Windows (64-bit)</dt>
  <dd><soupault-release platform="win64" /></dd>
  <dt>macOS</dt>
  <dd><soupault-release platform="macos-x86_64" /></dd>
</dl>

If you want CDNed links for your [CI scripts](/tips-and-tricks/deployment/), you can use [GitHub releases](https://github.com/dmbaturin/soupault/releases) mirror links.

### Verifying digital signatures

You can verify digital signatures using this signify/minisign public key:

```
RWRfW+gkhk/+iA7dOUtTio6G6KeJCiAEp4Zfozw7eqv2shN90+5z20Cy
```

Soupault uses [minisign](https://jedisct1.github.io/minisign/) for release signing. To learn about its advantages
over GPG, read [signify: Securing OpenBSD From Us To You](https://www.openbsd.org/papers/bsdcan-signify.html).

One obvious advantage is that you don't need to import the key anywhere, you can pass it as a command line argument:

```
minisign -Vm soupault-$SOUPAULT_RELEASE$-win32.zip -P RWRfW+gkhk/+iA7dOUtTio6G6KeJCiAEp4Zfozw7eqv2shN90+5z20Cy
```

## Package repositories

### OPAM

Soupault is written in [OCaml](https://ocaml.org) and is available from the [OPAM](https://opam.ocaml.org) repository.

If you already have OCaml and OPAM installed, you can easily install with this command:

```
opam install soupault
```

### Nix

Soupault is available in [nixpkgs](https://search.nixos.org/packages?channel=unstable&show=soupault&type=packages&query=soupault)
(as of September 2021, only in unstable).

Nix packaging is maintained by [toastal](https://toast.al/).

## Building from source

Soupault is free software published under the [MIT license](https://mit-license.org/). You can build it from source for any
platform supported by the OCaml programming language.

The source code is available from these git repositories:

* [GitHub](https://github.com/dmbaturin/soupault) (primary location)
* [Codeberg](https://codeberg.org/dmbaturin/soupault) (read-write mirror)

To build the latest source, you will need the OCaml compiler (4.08 or later) and the OPAM package manager.

```shell-session
$ git clone <url>
$ cd soupault
$ opam pin add .

```

<hr>
<div id="footnotes"> </div>
