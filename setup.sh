#!/bin/bash
#
# Name:    setup.sh
# Purpose: Build and run a Kythe developer container.
#
# Copyright (C) 2018 Michael J. Fromberger. All Rights Reserved.
#
# This script assumes you have docker installed on your machine. When invoked,
# this script:
#
#   - Creates a volume to serve as the running user's home directory and
#     populates it with a fresh checkout of Kythe from GitHub.
#
#   - Builds and tags an image that contains all the build tools and external
#     dependencies needed to build Kythe with Bazel.
#
#   - (Re)starts a container and verifies that modules are up to date.
#

set -e -o pipefail

# -- begin configuration --

# The name of the volume to create to hold the Kythe repository.
readonly volume=kythe-dev-homedir

# The URL of the Kythe repository, for "git clone".
readonly repo='https://github.com/kythe/kythe.git'

# The path of the home directory on the container image where the volume should
# be mounted.
readonly mountpoint=/home/kythedev

# The tag to apply to the build image.
readonly tag=kythedev

# The name of the container created to update modules.
readonly container=kythe-dev

# -- end configuration --

# Create a volume and check out Kythe into it.
if [[ "$(docker volume ls --format={{.Name}} --filter=name=$volume)" = "" ]]
then
    echo "-- Creating and populating $volume ..." 1>&2
    tmp="$(mktemp -d)"
    trap "rm -rf -- '$tmp'" EXIT
    kvi=kythe-volume-init

    echo " >> Cloning $repo ..." 1>&2
    git clone "$repo" "$tmp/kythe"

    echo " >> Installing repo into volume $volume ..." 1>&2
    docker volume create "$volume"
    docker run -d --name=$kvi -it \
	   --mount source="$volume",target="$mountpoint" \
	   busybox sh
    docker cp "$tmp/kythe" "$kvi":"$mountpoint"
    docker exec $kvi mkdir -p "$mountpoint"/go/{src,pkg,bin}
    docker exec $kvi chown -R 501:501 "$mountpoint"
    docker stop $kvi
    docker rm $kvi
else
    echo "-- Volume $volume already exists [OK]" 1>&2
fi

# Build the image with all the tools Kythe needs.
echo "
-- Building and tagging image: $tag ..." 1>&2
readonly dir="$(dirname "$0")"
(cd "$dir" ; \
 docker build -t "$tag" --build-arg HOMEDIR="$mountpoint" image)

# Do the expensive initial build of LLVM.
if [[ "$(docker ps --filter=name="$container" -a -q)" = '' ]] ; then
    docker run -d --name="$container" -it \
	   --mount source="$volume",target="$mountpoint" \
	   "$tag":latest /bin/bash
else
    docker restart "$container"
fi
echo "
-- Updating modules ..." 1>&2
docker exec "$container" ./tools/modules/update.sh

echo "
-- Container $container is ready to use.

$ docker attach kythe-dev" 1>&2
