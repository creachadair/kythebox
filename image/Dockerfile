#
# Name:    Dockerfile
# Purpose: Build a developer image of Kythe.
# Author:  M. J. Fromberger <michael.j.fromberger@gmail.com>
#
# See also: https://kythe.io/
#

FROM creachadair/bazelbox AS build
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

# If you want man pages and other niceties in your image, uncomment this.
# Be aware, however, that this will make the image much larger.
#
#RUN apt-get update && \
#    yes | unminimize && \
#    apt-get install --no-install-recommends -y man-db

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
