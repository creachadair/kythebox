# Building Kythe with Docker

This repository contains instructions for assembling a working developer
installation of the [Kythe](https://kythe.io/) project in a docker container.

**Basic usage:**

```shell
$ git clone https://github.com/creachadair/kythebox.git
$ ./kythebox/setup.sh
$ ./kythebox/start.sh attach
```

The `setup.sh` script creates a persistent read-write volume to serve as the
user's home directory, and populates it with a fresh checkout of Kythe from
GitHub at HEAD on the `master` branch. Local changes to the working copy will
be preserved here.

It also creates a separate persistent read-write volume to cache build outputs.
This speeds up rebuilds, particularly for expensive toolchains like LLVM.  This
volume can safely be purged at any time. A Bazel configuration is set up to
point to this volume as a `--disk_cache`.

The `build.sh` script is used to build the container image from scratch.  The
resulting image is unfortunately quite large, so it is not obvious whether you
are better off using `docker pull` or building it yourself. Nevertheless, I
will try to keep a reasonably up-to-date tag of `creachadair/kythedev` on
dockerhub.

The `start.sh` script simply starts or restarts a container named `kythe-dev`
using the image described above. After this script runs you can attach to the
container (it will do this for you, if you add `attach`) and run builds. You
begin as an unprivileged user in the container but you can use `sudo` to become
root for installation purposes.

Note that any changes you make outside `$HOME` will disappear when the image is
removed. If you want a more expressive toolchain you'll need to install it
manually and update the tag, e.g.

```shell
host $ docker attach kythe-dev
cont % sudo apt-get update ; sudo apt-get install -y tmux
host $ docker commit kythe-dev creachadair/kythedev:latest
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

    You can do this _without_ modifying the image.  If you build cache is
	pooched and needs replacement, you can do the same for `kythe-dev-cache`.


 -  If you need to add items to the image, edit the
	[Dockerfile](image/Dockerfile) and rerun `build.sh` to rebuild the image:

    ```shell
    docker stop kythe-dev ; docker rm kythe-dev
    ./kythebox/build.sh
    ```
