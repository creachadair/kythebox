#!/bin/bash
#
# Name:    setup.sh
# Purpose: Set up volumes for a Kythe developer container.
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
#   - Initializes the volumes with a fresh checkout of the Kythe repository.
#

set -e -o pipefail

. "$(dirname $0)/config.sh"

# Create and set up the volumes, if necessary. Do the cache volume first so we
# can mount it into the init container to get the permissions set up.
if volume_exists "$cache"
then
    echo "-- Volume $cache already exists [OK]" 1>&2
else
    echo "-- Creating cache volume $cache ..." 1>&2
    docker volume create "$cache"
fi

if volume_exists "$volume"
then
    echo "-- Volume $volume already exists [OK]" 1>&2
else
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
fi
