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
#   - Creates a separate volume to hold the LLVM installation. This reduces the
#     frequency with which you need to rebuild LLVM, which takes forever.
#
#   - Builds and tags an image that contains all the build tools and external
#     dependencies needed to build Kythe with Bazel.
#
#   - (Re)starts a container and verifies that modules are up to date, which
#     has the effect of populating the LLVM volume.
#

set -e -o pipefail

# -- begin configuration --

# The name of the volumes to create to hold the Kythe repository.
# We keep a separate volume for the LLVM installation to cut down on the need
# to rebuild it quite so often.
readonly volume=kythe-dev-homedir
readonly llvolume=kythe-dev-llvm

# The URL of the Kythe repository, for "git clone".
readonly repo='https://github.com/kythe/kythe.git'

# The path where the home volume should be mounted.
readonly mountpoint=/home/kythedev

# The path where the LLVM volume should be mounted.
readonly llmount="$mountpoint"/kythe/third_party/llvm

# The tag to apply to the build image.
readonly imagetag=kythedev

# The name of the container created to update modules.
readonly container=kythe-dev

# -- end configuration --

# Create and set up the volumes, if necessary. Do the LLVM volume first so we
# can mount it into the init container to get the permissions set up.
if [[ "$(docker volume ls --format={{.Name}} --filter=name=$llvolume)" = "" ]]
then
    echo "-- Creating LLVM volume $llvolume ..." 1>&2
    docker volume create "$llvolume"
else
    echo " >> Volume $llvolume already exists [OK]" 1>&2
fi

if [[ "$(docker volume ls --format={{.Name}} --filter=name=$volume)" = "" ]]
then
    echo "-- Creating and populating home volume $volume ..." 1>&2
    tmp="$(mktemp -d)"
    trap "rm -rf -- '$tmp'" EXIT
    kvi=kythe-volume-init

    echo " >> Cloning $repo ..." 1>&2
    git clone "$repo" "$tmp/kythe"

    echo " >> Installing repo into volume $volume ..." 1>&2
    docker volume create "$volume"
    docker run -d --name=$kvi -it \
	   --mount source="$volume",target="$mountpoint" \
	   --mount source="$llvolume",target="$llmount" \
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
-- Building and tagging image: $imagetag ..." 1>&2
readonly dir="$(dirname "$0")"
(cd "$dir" ; \
 docker build -t "$imagetag" \
	--build-arg HOMEDIR="$mountpoint" \
	--build-arg LLVMDIR="$llmount" \
	image)

# Do the expensive initial build of LLVM.
if [[ "$(docker ps --filter=name="$container" -a -q)" = '' ]] ; then
    docker run -d --name="$container" -it \
	   --mount source="$volume",target="$mountpoint" \
	   --mount source="$llvolume",target="$llmount" \
	   "$imagetag":latest /bin/bash
else
    docker restart "$container"
fi
echo "
-- Updating modules ..." 1>&2
docker exec "$container" ./tools/modules/update.sh

echo "
-- Container $container is ready to use.

$ docker attach $container" 1>&2
