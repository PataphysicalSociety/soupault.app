# Deployment

<div id="generated-toc"> </div>

Soupault generates static sites, so you can host generated pages anywhere.
The simplest option is to build your site on your own computer and copy generated
pages to the server.

It may not be the _easiest_ option though: you cannot edit your site from a device
that doesn’t have a soupault build setup, and you need to remember to rebuild and update
the site whenever you make an edit.

The good news is that soupault is easy to integrate into an automated CI setup.
Since it comes as a statically linked executable, you only need to download
and unpack the archive.

## Getting soupault

Since most of the hosting and CI services offer build hosts with preinstalled soupault yet,
you’ll need to download it as a part of your website build process.

Since the Linux version of soupault is a statically linked executable, you can run it on any Linux-based build host without any trouble.

The primary location for soupault downloads is [files.baturin.org/software/soupault/](https://files.baturin.org/software/soupault/).

However, for a CI process, you may rather want to use a CDN’d link. For this reason I mirror releases to [GitHub](https://github.com/dmbaturin/soupault/releases).
Examples below use GitHub links.

## Netlify

[Netlify](https://netlify.com) is a popular static site hosting platform
that has a built-in continuous integration service.

One disadvantage is that as of early 2021, Netlify only provides an Ubuntu 16/Xenial [build image](https://github.com/netlify/build-image).
Worse yet, they do not give you root permissions in the container, so you _cannot install packages from APT repositories_.
So, if you want to use external programs in your workflow, Netlify’s built-in CI isn’t for you.

**Warning**: if you are using external CI for your Netlify sites, make sure to go to “Site settings”, “Build & deploy”,
and tick the “Stop builds” option there. Otherwise Netlify will try ‘building’ your site with its built-in process
even if you don’t have `netlify.toml` in your repository, which will produce an empty website.
Thus, if you don’t disable those builds by hand, then a) your website will be emptied when a deploy is triggered
and will stay empty until the external CI job completes b) if the external CI job fails, the website will remain empty forever.
Make sure to “Stop builds” to prevent that.

If everything you need can be installed without root permissions, then their built-in CI service can be very nice to use though.
On the plus side, Netlify allows rather free-form build scripts and doesn’t make you write fragile YAML files.

First you need a build script.

```bash
#!/bin/sh

SOUPAULT_VERSION="3.0.0"

wget https://github.com/dmbaturin/soupault/releases/download/$SOUPAULT_VERSION/soupault-$SOUPAULT_VERSION-linux-x86_64.tar.gz
if [ $? != 0 ]; then
    echo "Error: failed to download soupault."
    exit 1
fi

tar xvf soupault-$SOUPAULT_VERSION-linux-x86_64.tar.gz

./soupault-$SOUPAULT_VERSION-linux-x86_64/soupault
```

Then you need to tell the builder what script to run and which directory to publish.
This is specified in the `netlify.toml` file.

```toml
[build]
  publish = "build/"
  command = "./netlify.sh"
```

You can also deploy a website from my [sample repo](https://app.netlify.com/start/deploy?repository=dmbaturin/soupault-sample-blog) in one click.

## GitHub Actions

GitHub Actions is Microsoft GitHub’s built-in CI service.

Advantages:

* For GitHub users: tight integration with the rest of GitHub.
* Good selection of build images, newer GNU/Linux distro versions.

I use it for building this site and the [OCaml book](https://ocamlbook.org) and deploying it to Netlify,
so you can use its [build script](https://github.com/dmbaturin/ocaml-book/blob/master/.github/workflows/main.yml) as a basis for your own.

The build part in `.github/workflows/main.yml` boils down to this:

```yaml
jobs:
  build:
    # The type of runner that the job will run on
    runs-on: ubuntu-latest

    # Steps represent a sequence of tasks that will be executed as part of the job
    steps:
    # Checks-out your repository under $GITHUB_WORKSPACE, so your job can access it
    - uses: actions/checkout@v2

    - name: Install soupault
      env:
        SOUPAULT_VERSION: 3.0.0
      run: |
        echo Downloading and unpacking soupault
        wget https://github.com/dmbaturin/soupault/releases/download/$SOUPAULT_VERSION/soupault-$SOUPAULT_VERSION-linux-x86_64.tar.gz
        tar xvf soupault-$SOUPAULT_VERSION-linux-x86_64.tar.gz
        sudo mv -v ./soupault-$SOUPAULT_VERSION-linux-x86_64/soupault /usr/bin/

    - name: Build the site
      run: |
        soupault

    # Your deployment steps here
```

## Sourcehut + NixOS 

Sourcehut’s [builds.sr.ht](https://man.sr.ht/builds.sr.ht/) can offer a quick Soupault environment via [NixOS](https://nixos.org/). 

In your project directory, create a build configuration

```shell-session
$ touch .build.yml
```

The simplest configuration 

```yaml
image: nixos/unstable # at the time of writing, soupault only available in unstable 
packages:
  - nixos.soupault
  # … any additional dependencies (e.g. preprocessors)
  # - nixos.asciidoctor
environment:
  repo_name: "$YOUR_SOURCEHUT_REPOSITORY_NAME"
tasks:
  - build: |
    cd "$repo_name"
    soupault
  # add other tasks such as deployment via `curl`
```
