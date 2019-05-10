#
# Name:    Dockerfile
# Purpose: Build a developer image of Kythe.
# Author:  M. J. Fromberger <michael@sourced.tech>
#
# See also: https://kythe.io/
#

FROM ubuntu:latest AS base
#
# If you want man pages and other niceties in your image, uncomment this.
# Be aware, however, that this will make the image much larger.
#
#RUN apt-get update && \
#    yes | unminimize && \
#    apt-get install --no-install-recommends -y man-db

FROM base AS bazel
#
# Install bazel from the bazel GitHub releases page.
#
# Ideally we would just take the latest release version of Bazel.
# Unfortunately, releases often ship breaking changes.  Kythe uses quite a lot
# of custom rules and macros to shim compatibility between the internal and
# eternal build environments, and Bazel regularly breaks language and API
# features those rules and macros use.
#
# So here we pin a specific release, which will occasionally need to be updated
# as Kythe updates its requirements (see the WORKSPACE file).
#
ARG BAZEL_VERSION=0.25.1
RUN apt-get update && \
    apt-get install --no-install-recommends -qy curl ca-certificates
RUN curl -L -o /tmp/bazel.deb \
	https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel_${BAZEL_VERSION}-linux-x86_64.deb && \
    apt install -qy /tmp/bazel.deb && \
    rm -f -- /tmp/bazel.deb

FROM bazel AS build
#
# Install the external dependencies of Kythe.
# See: https://kythe.io/getting-started/
#
# Additions: arcanist, cmake, golint, jq, make, patch, sudo, zip
# Changes:   clang 3.8 → clang-4.0
#
# Go is described as a requirement, but Bazel pulls in a Go toolchain on its
# own so you can do without it. Similarly jq is not required to build, but is
# very helpful for munging output data from the tools.
#
ARG GO_VERSION=1.12.5
RUN env DEBIAN_FRONTEND=noninteractive apt-get install \
	--no-install-recommends -y tzdata arcanist && \
    apt-get install --no-install-recommends -y \
        asciidoc asciidoctor bison flex git golint graphviz \
	clang-4.0 gcc jq libncurses-dev make parallel patch \
	source-highlight sudo wget uuid-dev zip
RUN ( cd /usr/local && \
	curl -sL https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz | tar -xzf - )

FROM build AS clean
# Clean up random crud from the build environment before we copy out.
# N.B. These cleanup rules are Anglocentric (in re: locale).
RUN apt-get remove -y python3* && \
    apt-get autoremove -y && \
    rm -fr -- /var/lib/apt/lists/* && \
    rm -fr -- /usr/share/icons/* && \
    find /usr/share/locale -mindepth 1 -maxdepth 1 -type d \
       -not -name 'en' -exec rm -fr -- {} ';' && \
    groupadd -g 501 kythedev && \
    useradd -r -m -u 501 -g kythedev kythedev && \
    echo 'kythedev ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

FROM scratch AS kythe
#
# The container is expected to map volume kythe-dev-repo to $HOMEDIR so that
# results are persisted.
#
# To update the repo, attach to the container and run "git pull" normally.
#
ARG HOMEDIR=/home/kythedev
ARG CACHEDIR=/home/kythedev/buildcache
COPY --from=clean / /
RUN  chmod -v 04755 /usr/bin/sudo
    # Allow the user to sudo to install things.
    # We have to chmod sudo because COPY doesn't preserve that bit.
USER    kythedev:kythedev
ENV     CC=/usr/bin/clang-4.0 PATH="$HOMEDIR/go/bin:/usr/local/go/bin:${PATH}"
VOLUME  $HOMEDIR $CACHEDIR
WORKDIR "$HOMEDIR"/kythe
CMD     ["/bin/bash"]
