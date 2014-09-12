#! /bin/bash

# Copyright (c) 2014 Sandstorm Development Group, Inc. and contributors
# Licensed under the MIT License:
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

# This script gathers all of the binaries and libraries needed to run Meteor,
# but which aren't part of a normal Meteor bundle.
#
# We pull Node.js from the Meteor tools installation.
#
# We build a custom MongoDB binary using a special fork of Mongo which creates
# much smaller databases. This is necessary because Mongo by default
# pre-allocates many megabytes of space, but Sandstorm app instances should be
# individual documents and therefore small. (It would be nice to replace Mongo
# entirely with an in-process database; maybe based on Meteor's own
# "minimongo"...)
#
# We pull any needed libraries straight from the local system.

set -euo pipefail

mkdir -p tmp

copyDep() {
  # Copies a file from the system into the chroot.
  
  local FILE=$1
  local DST=bundle"${FILE/#\/usr\/local/\/usr}"
  
  if [ -e "$DST" ]; then
    # already copied
    :
  elif [[ "$FILE" == /etc/* ]]; then
    # We'll want to copy configuration (e.g. for DNS) from the host at runtime.
    if [ -f "$FILE" ]; then
      echo "$FILE" >> tmp/etc.list
    fi
  elif [ -h "$FILE" ]; then
    # Symbolic link.
    # We copy over the target, and recreate the link.
    # Currently we denormalize the link because I'm not sure how to follow
    # one link at a time in bash (since readlink without -f gives a relative
    # path and I'm not sure how to interpret that against the link's path).
    # I'm sure there's a way, but whatever...
    mkdir -p $(dirname "$DST")
    local LINK=$(readlink -f "$FILE")
    ln -sf "${LINK/#\/usr\/local/\/usr}" "$DST"
    copyDep "$LINK"
  elif [ -d "$FILE" ]; then
    # Directory.  Make it, but don't copy contents; we'll do that later.
    mkdir -p "$DST"
  elif [ -f "$FILE" ]; then
    # Regular file.  Copy it over.
    mkdir -p $(dirname "$DST")
    cp "$FILE" "$DST"
  fi
}

copyDeps() {
  # Reads filenames on stdin and copies them into the chroot.

  while read FILE; do
    copyDep "$FILE"
  done
}

rm -rf bundle
mkdir bundle
METEOR_WAREHOUSE_DIR="${METEOR_WAREHOUSE_DIR:-$HOME/.meteor}"
METEOR_DEV_BUNDLE=$(dirname $(readlink -f "$METEOR_WAREHOUSE_DIR/meteor"))/dev_bundle

cp start.js bundle/start.js

# Copy over key binaries.
mkdir -p bundle/bin
cp mongo/mongod bundle/bin/niscud
cp $METEOR_DEV_BUNDLE/bin/node bundle/bin

# Binaries copied from Meteor aren't writable by default.
chmod u+w bundle/bin/*

# Copy over all necessary shared libraries.
(ldd bundle/bin/* $(find bundle -name '*.node') || true) | grep -o '[[:space:]]/[^ ]*' | copyDeps

# Mongo wants these localization files.
mkdir -p bundle/usr/lib
cp -r /usr/lib/locale bundle/usr/lib
mkdir -p bundle/usr/share/locale
cp /usr/share/locale/locale.alias bundle/usr/share/locale

# Make bundle smaller by stripping stuff.
strip bundle/bin/*
find bundle -name '*.so' | xargs strip

rm -rf meteor-spk.deps
mv bundle meteor-spk.deps

