#!/bin/bash
#
# Name:    build.sh
# Purpose: Build a Docker image for Kythe development.
#
# Copyright (C) 2019 Michael J. Fromberger. All Rights Reserved.
#
# This script assumes you have docker installed on your machine. When invoked,
# this script builds and tags an image that contains all the build tools and
# external dependencies needed to build Kythe with Bazel.
#

set -e -o pipefail

. "$(dirname $0)/config.sh"

# Create and set up the volumes, if necessary. Do the cache volume first so we
# can mount it into the init container to get the permissions set up.
if ! volume_exists "$cache"
then
    echo "Cache volume not found: Please run 'setup.sh' first." 2>&1
    exit 1
fi
if ! volume_exists "$volume"
then
    echo "Home volume not found: PLease run 'setup.sh' first." 2>&1
    exit 1
fi

# Build the image with all the tools Kythe needs.
echo "
-- Building and tagging image: $imagetag ..." 1>&2
readonly dir="$(dirname "$0")"
(cd "$dir" ; \
 docker build -t "$imagetag" \
	--build-arg HOMEDIR="$mountpoint" \
	--build-arg CACHEDIR="$cachemount" \
	image)
