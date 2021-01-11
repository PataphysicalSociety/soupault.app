#!/bin/sh

# Install required external tools

brew install highlight

# Get soupault

SOUPAULT_VERSION="2.3.0"

if [ -z "${SOUPAULT_VERSION}" ]; then
    echo "Error: soupault version is undefined, cannot decide what to download"
    exit 1
fi

echo "Downloading and unpacking soupault"
wget https://github.com/dmbaturin/soupault/releases/download/$SOUPAULT_VERSION/soupault-$SOUPAULT_VERSION-linux-x86_64.tar.gz
if [ $? != 0 ]; then
    echo "Error: failed to download soupault."
    exit 1
fi

tar xvf soupault-$SOUPAULT_VERSION-linux-x86_64.tar.gz
mv ./soupault-$SOUPAULT_VERSION-linux-x86_64/soupault soupault

# Build

SOUPAULT=./soupault-$SOUPAULT_VERSION-linux-x86_64/soupault make all

