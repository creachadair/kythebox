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
volumes_must_exist "$cache" "$volume"

# Build the image with all the tools Kythe needs.
echo "
-- Building and tagging image: $imagetag ..." 1>&2
readonly dir="$(dirname "$0")"
(cd "$dir" ; \
 docker build -t "$buildtag" -f image/Dockerfile.bazelbox image && \
 docker build -t "$imagetag" \
	--build-arg HOMEDIR="$mountpoint" \
	--build-arg CACHEDIR="$cachemount" \
	-f image/Dockerfile.kythebox image)
