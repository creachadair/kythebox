# Building Kythe with Docker

This repository contains instructions for assembling a working developer
installation of the [Kythe](https://kythe.io/) project in a docker container.

**Basic usage:**

```shell
$ git clone https://github.com/creachadair/kythebox.git
$ ./kythebox/setup.sh
# ... a long time passes ...
$ docker attach kythe-dev
```

The `setup.sh` script:

-  Creates a volume to serve as the running user's home directory and populates
   it with a fresh checkout of Kythe from GitHub.

-  Builds and tags an image that contains all the build tools and external
   dependencies needed to build Kythe with Bazel.

-  (Re)starts a container and verifies that modules are up to date.

It should not be necessary to edit the script, but there are some configuration
variables at the top which you can modify if you wish.

After the script runs there will be a container named `kythe-dev` that you can
attach to and run builds. You enter the container as an unprivileged user but
can use `sudo` to become root for installation purposes.  Note, however, that
changes you make outside `$HOME` will disappear when the image is removed -- if
you want a more expressive toolchain you'll need to edit the
[Dockerfile](image/Dockerfile).
