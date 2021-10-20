#
# Name:    Dockerfile
# Purpose: Build a developer image of Kythe.
# Author:  M. J. Fromberger <michael.j.fromberger@gmail.com>
#
# See also: https://kythe.io/
#

FROM ubuntu:latest AS build
#
# Install the external dependencies of Kythe.
# See: https://kythe.io/getting-started/
#
# Additions: arcanist, cmake, golint, jq, make, patch, python, sudo, zip
#            g++ # for builds in Bazel
#
# Go is described as a requirement, but Bazel pulls in a Go toolchain on its
# own so you can do without it. Similarly jq is not required to build, but is
# very helpful for munging output data from the tools.
#
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install \
	--no-install-recommends --no-install-suggests -qq -y \
	tzdata arcanist  asciidoc asciidoctor bison flex git golint graphviz \
	clang-8 gcc g++ jq libncurses-dev make openjdk-8-jdk parallel patch \
	python source-highlight sudo wget unzip uuid-dev zip
COPY --from=golang:1.17 /usr/local/go /usr/local/go

FROM build AS kythe
#
# The container is expected to map volume kythe-dev-repo to $HOMEDIR so that
# results are persisted.
#
# To update the repo, attach to the container and run "git pull" normally.
#
ARG HOMEDIR=/home/kythedev
ARG CACHEDIR=/home/kythedev/buildcache

# Set up an unprivileged user to run builds.
RUN groupadd -g 501 kythedev && \
    useradd -r -m -u 501 -g kythedev kythedev && \
    echo 'kythedev ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
ENV GOBIN="/tools/go/bin"
ENV PATH="/tools/go/bin:/usr/local/go/bin:${PATH}"
RUN mkdir -p "$GOBIN" && \
    go get github.com/bazelbuild/bazelisk && \
    ln -s bazelisk "$GOBIN/bazel"

# If you want man pages and other niceties in your image, uncomment this.
# Be aware, however, that this will make the image much larger.
#
#RUN apt-get update && \
#    yes | unminimize && \
#    apt-get install --no-install-recommends -y man-db

USER    kythedev:kythedev
ENV     CC=/usr/bin/clang-8
VOLUME  $HOMEDIR $CACHEDIR
WORKDIR "$HOMEDIR"/kythe
CMD     ["/bin/bash"]
