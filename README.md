# Tool for packaging Meteor apps for Sandstorm.io

[Sandstorm](https://sandstorm.io) is a platform for personal clouds that makes
installing apps to your personal server as easy as installing apps to your
phone.

[Meteor](https://meteor.com) is a revolutionary web app framework. Sandstorm's
own UI is built using Meteor, and Meteor is also a great way to build Sandstorm
apps.

This package provides a tool, `meteor-spk`, which wraps Sandstorm's normal
`spk` tool as well as Meteor's tools in order to easily package Meteor apps
to run on Sandstorm.

## Installing the tool

### Prerequisites

Currently, this tool only works on Linux. We may port to Mac OSX in the future.

You must install Sandstorm locally in order to get the `spk` tool. The easiest
way to do that is:

    curl https://install.sandstorm.io | bash

### Installing `meteor-spk` from binaries

1. Download and unpack
   [the binary distribution](https://dl.sandstorm.io/meteor-spk-0.1.5.tar.xz),
   e.g.:

        mkdir -p ~/projects/meteor-spk
        cd ~/projects/meteor-spk
        curl https://dl.sandstorm.io/meteor-spk-0.1.5.tar.xz | tar Jxf -
        cd meteor-spk-0.1.5

2. Add the directory to your `$PATH`, or symlink the `meteor-spk` script into
   a directory in your `$PATH`, e.g.:

        ln -s $PWD/meteor-spk ~/bin

## Packaging your app

To package your existing Meteor app, do the following:

1. Run `meteor-spk init` in your app's source tree.
2. Open the generated file `sandstorm-pkgdef.capnp` in a text editor. Read
   the comments and fill in as appropriate. In particular you will probably
   want to change the "new instance" action title.
3. (optional) Run `meteor-spk dev` to run your app in dev mode. For this to
   work, you must be running a local Sandstorm server and your user account
   must be a member of the server's group. The tool will connect to that
   server and temporarily make your app available for testing. When done
   testing, use ctrl+C in the terminal to stop.
4. Run `meteor-spk pack example.spk` to create a Sandstorm package file called
   `example.spk`. WARNING: You may want to place this file outside of your
   source directory as otherwise Meteor will think it is part of the app
   and will include it in the app bundle. This means if you repeatedly run
   this command your package will keep including itself and become enormous.
5. You can upload your `spk` to a Sandstorm server using the "Upload App"
   button in the Sandstorm UI.

## Tips

* As of version 0.1.5, `meteor-spk` uses Mongo 3.0. Mongo 2.x does not work
  well for Sandstorm apps as it pre-allocates far too much disk space
  expecting a large database; Mongo 3.x mostly avoids preallocation. The
  differences should be invisible to your app. Note that apps built with
  previous versions of `meteor-spk` can upgrade safely -- old grains will
  automatically be migrated to Mongo 3 format on their first run.
* If your app uses accounts, add the package
  [`kenton:accounts-sandstorm`](https://github.com/sandstorm-io/meteor-accounts-sandstorm)
  to integrate with Sandstorm's login system. (See also
  [`jacksingleton:accounts-sandstorm-dev`](https://atmospherejs.com/jacksingleton/accounts-sandstorm-dev)
  to fake Sandstorm user info during development, so that you can use Meteor's auto-refreshing
  dev mode outside of Sandstorm.)
* That said, there is often no need for accounts because instances of your app
  are already private, viewable only to the owner and people with whom they
  explicitly shared it. You might as well give all of these users full access,
  and rely on Sandstorm for protection.
* If your app is document-oriented, you should design it to host only a single
  document. Users can create multiple instances of your app if they
  want multiple documents. In fact, it's better that way, because then the
  instances can be independently shared.
* All of this means that it's often OK to leave `autopublish` and `insecure`
  on! If all users have full access anyway, and the data set is limited to
  one document, then there's no problem.

## Developing `meteor-spk`

### Installing `meteor-spk` from source

1. Check out this github repository. Note that you must use the `--recursive`
   flag to ensure that submodules are cloned as well:

        git clone --recursive https://github.com/sandstorm-io/meteor-spk.git

2. Run `make`.
3. Add the directory to your `$PATH`, or symlink the `meteor-spk` script into
   a directory in your `$PATH`, e.g.:

        ln -s $PWD/meteor-spk ~/bin
