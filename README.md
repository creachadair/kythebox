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

-  Creates a separate volume to hold the LLVM installation. This reduces the
   frequency with which you need to rebuild LLVM, which takes forever.

-  Builds and tags an image that contains all the build tools and external
   dependencies needed to build Kythe with Bazel.

-  (Re)starts a container and verifies that modules are up to date, which has
   the effect of populating the LLVM volume.

The script takes no arguments, and it should not be necessary to edit anything,
but there are some configuration variables at the top which you can modify if
you wish.

After the script runs there will be a container named `kythe-dev` that you can
attach to and run builds. You enter the container as an unprivileged user but
can use `sudo` to become root for installation purposes.

Note, however, that any changes you make outside `$HOME` will disappear when
the image is removed -- if you want a more expressive toolchain you'll need to
edit the [Dockerfile](image/Dockerfile).

## Maintenance

 -  If your home volume is befouled and needs replacement, remove the
    `kythe-dev` container (and any others that are using it), and rerun
    `setup.sh` to recreate the volume:

    ```shell
    docker volume rm kythe-dev-homedir
    ./kythebox/setup.sh
    ```

    You can do this _without_ modifying the image or rebuilding LLVM.  If your
	LLVM volume is pooched and needs replacement, you can do the same for
	`kythe-dev-llvm`.  In that case you _will_ have to wait for LLFM to
	rebuild, however.

 -  If you need to add items to the image, edit the
	[Dockerfile](image/Dockerfile) and rerun `setup.sh` to rebuild the image:

    ```shell
    docker stop kythe-dev ; docker rm kythe-dev
    ./kythebox/setup.sh
    ```

    This will not make you rebuild LLVM.  Thank heaven for small favours.
