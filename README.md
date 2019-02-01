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

-  Creates a persistent read-write volume to serve as the running user's home
   directory and populates it with a fresh checkout of Kythe from GitHub.
   Local changes to the working copy will be preserved here.

-  Creates a separate persistent read-write volume to cache build outputs.
   This speeds up rebuilds, particularly for expensive toolchains like LLVM.
   This volume can safely be purged at any time. A Bazel configuration is set
   up to point to this volume as a `--disk_cache`.

-  Builds and tags an image that contains all the build tools and external
   dependencies needed to build Kythe with Bazel.

-  (Re)starts a container on the image.

The script takes no arguments, and it should not be necessary to edit anything,
but there are some configuration variables at the top which you can modify if
you wish.

After the script runs there will be a container named `kythe-dev` that you can
attach to and run builds. You enter the container as an unprivileged user but
can use `sudo` to become root for installation purposes.

Note that any changes you make outside `$HOME` will disappear when the image is
removed. If you want a more expressive toolchain you'll need to install it
manually and update the tag, e.g.

```shell
host $ docker attach kythe-dev
cont % sudo apt-get update ; sudo apt-get install -y tmux
host $ docker commit kythe-dev kythedev:latest
```

or, just edit the [Dockerfile](image/Dockerfile).

## Maintenance

 -  If your home volume is befouled and needs replacement, remove the
    `kythe-dev` container (and any others that are using it), and rerun
    `setup.sh` to recreate the volume:

    ```shell
    docker volume rm kythe-dev-homedir
    ./kythebox/setup.sh
    ```

    You can do this _without_ modifying the image.  If your cache volume is
	pooched and needs replacement, you can do the same for `kythe-dev-cache`.


 -  If you need to add items to the image, edit the
	[Dockerfile](image/Dockerfile) and rerun `setup.sh` to rebuild the image:

    ```shell
    docker stop kythe-dev ; docker rm kythe-dev
    ./kythebox/setup.sh
    ```
