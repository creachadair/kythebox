# This file is sourced by the other scripts in this directory.
# It does not do anything on its own.

# -- begin configuration --

# The name of the volumes to create to hold the Kythe repository.
# We keep a separate volume for the build cache to avoid expensive rebuilds
# particularly for LLVM.
readonly volume=kythe-dev-homedir
readonly cache=kythe-dev-cache

# The URL of the Kythe repository, for "git clone".
# If you want to test unmerged changes, you may want to replace this with the
# URL of your own fork.
readonly repo='https://github.com/kythe/kythe.git'

# The path where the home volume should be mounted.
readonly mountpoint=/home/kythedev

# The path where the cache volume should be mounted.
readonly cachemount="$mountpoint"/buildcache

# The tag to apply to the build image.
readonly imagetag=creachadair/kythedev

# The name of the container to create or restart.
readonly container=kythe-dev

# -- end configuration --

volume_exists() {
    [[ "$(docker volume ls --format={{.Name}} --filter=name=${1:?missing volume})" != "" ]]
}