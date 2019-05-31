#!/bin/bash
#
# Usage    start.sh [attach]
# Purpose: Run a Kythe developer container from a prebuilt image.
#
# Copyright (C) 2019 Michael J. Fromberger. All Rights Reserved.
#
# This script assumes you have docker installed and have run setup.sh.
#

set -e -o pipefail

. "$(dirname $0)/config.sh"

if [[ "$(docker ps --filter=name="$container" -a -q)" = '' ]] ; then
    docker run -d --name="$container" -it \
	   --mount source="$volume",target="$mountpoint" \
	   --mount source="$cache",target="$cachemount" \
	   "$imagetag":latest
else
    docker restart "$container"
fi

if [[ "$1" = "attach" ]] ; then
    docker attach "$container"
else
    echo "
-- Container $container is ready to use. Run:

$ docker attach $container" 1>&2
fi
