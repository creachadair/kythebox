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
#   - Creates a separate volume to cache build outputs.
#
#   - Builds and tags an image that contains all the build tools and external
#     dependencies needed to build Kythe with Bazel.
#
#   - (Re)starts a container on the image.
#

set -e -o pipefail

# -- begin configuration --

# The name of the volumes to create to hold the Kythe repository.
# We keep a separate volume for the build cache to avoid expensive rebuilds
# particularly for LLVM.
readonly volume=kythe-dev-homedir
readonly cache=kythe-dev-cache

# The URL of the Kythe repository, for "git clone".
readonly repo='https://github.com/kythe/kythe.git'

# The path where the home volume should be mounted.
readonly mountpoint=/home/kythedev

# The path where the cache volume should be mounted.
readonly cachemount="$mountpoint"/buildcache

# The tag to apply to the build image.
readonly imagetag=kythedev

# The name of the container created to update modules.
readonly container=kythe-dev

# -- end configuration --

# Create and set up the volumes, if necessary. Do the cache volume first so we
# can mount it into the init container to get the permissions set up.
if [[ "$(docker volume ls --format={{.Name}} --filter=name=$cache)" = "" ]]
then
    echo "-- Creating cache volume $cache ..." 1>&2
    docker volume create "$cache"
else
    echo "-- Volume $cache already exists [OK]" 1>&2
fi

if [[ "$(docker volume ls --format={{.Name}} --filter=name=$volume)" = "" ]]
then
    echo "-- Creating and populating home volume $volume ..." 1>&2
    tmp="$(mktemp -d)"
    trap "rm -rf -- '$tmp'" EXIT
    kvi=kythe-volume-init

    echo " >> Cloning $repo ..." 1>&2
    git clone "$repo" "$tmp/kythe"

    # Instruct Bazel to use the cache volume as a disk cache.
    # See https://docs.bazel.build/versions/master/remote-caching.html
    echo " >> Pointing build cache to $cachemount ..." 1>&2
    echo "build --disk_cache=$cachemount" \
	 > "$tmp/bazelrc"
    echo "build --experimental_guard_against_concurrent_changes" \
	 >> "$tmp/bazelrc"

    echo " >> Installing repo into volume $volume ..." 1>&2
    docker volume create "$volume"
    docker run -d --name=$kvi -it \
	   --mount source="$volume",target="$mountpoint" \
	   --mount source="$cache",target="$cachemount" \
	   busybox sh
    docker cp "$tmp/kythe" "$kvi":"$mountpoint"
    docker cp "$tmp/bazelrc" "$kvi":"$mountpoint/.bazelrc"
    docker exec $kvi mkdir -p "$mountpoint"/go/{src,pkg,bin}
    docker exec $kvi chown -R 501:501 "$mountpoint"
    docker stop $kvi
    docker rm $kvi
else
    echo "-- Volume $volume already exists [OK]" 1>&2
fi

# Build the image with all the tools Kythe needs. Tag the build image
# separately so that it will persist in the local cache; this can be safely
# manually removed to save storage.
echo "
-- Building and tagging image: $imagetag ..." 1>&2
readonly dir="$(dirname "$0")"
(cd "$dir" ; \
 docker build --target=build -t "$imagetag"-build image ; \
 docker build -t "$imagetag" \
	--build-arg HOMEDIR="$mountpoint" \
	--build-arg CACHEDIR="$cachemount" \
	image)

# Start or restart a container with a shell in this image.
if [[ "$(docker ps --filter=name="$container" -a -q)" = '' ]] ; then
    docker run -d --name="$container" -it \
	   --mount source="$volume",target="$mountpoint" \
	   --mount source="$cache",target="$cachemount" \
	   "$imagetag":latest
else
    docker restart "$container"
fi

echo "
-- Container $container is ready to use.

$ docker attach $container" 1>&2
