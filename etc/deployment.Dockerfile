# This file is part of montebianco. It is subject to the license terms in the COPYRIGHT file found in the top-level directory of this distribution and at https://raw.githubusercontent.com/libertine-linux/montebianco/master/COPYRIGHT. No part of montebianco, including this file, may be copied, modified, propagated, or distributed except according to the terms contained in the COPYRIGHT file.
# Copyright © 2016 The developers of montebianco. See the COPYRIGHT file in the top-level directory of this distribution and at https://raw.githubusercontent.com/libertine-linux/montebianco/master/COPYRIGHT.


FROM alpine:3.6
MAINTAINER Raphael Cohn <raphael.cohn@stormmq.com>



# (1) Arguments

# (1.1) Arguments intended to be overridden
ARG ENVIRONMENT=production

# (1.2) Version arguments
ARG VERSION_ALPINE_LINUX=3.6

# (1.3) Arguments for download locations
ARG URL_BASE_ALPINE_LINUX=http://dl-cdn.alpinelinux.org/alpine

# (1.4) Arguments that aren't intended to be overridden, but used in preference to ENV settings (which persist)
ARG USER=caddy
ARG GROUP=$USER
ARG HOME=/home/$USER



# (2) Baseline environment

# (2.1) Ensure PATH is consistent and contains /usr/local/sbin
WORKDIR /
RUN /bin/mkdir -m 0755 -p /usr/local/sbin
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# (2.2) Bring apk package manager up-to-date with known repositories
RUN printf '%s\n%s\n%s\n' "$URL_BASE_ALPINE_LINUX"/v${VERSION_ALPINE_LINUX}/main "$URL_BASE_ALPINE_LINUX"/v${VERSION_ALPINE_LINUX}/community >/etc/apk/repositories
RUN apk update
RUN apk upgrade



# (3) Make a regular user
RUN mkdir -m 0755 -p /home
RUN mkdir -m 0700 "$HOME"
RUN addgroup -g 1000 "$GROUP"
RUN adduser -u 1000 -G "$GROUP" -D -h "$GROUP" -s /bin/sh "$USER"



# (4) Add site

# (4.1) Copy across
ADD site.tar.gz /home/"$USER"/
RUN chown -R "$USER:$GROUP" "$HOME"

# (4.2) Remove binaries for different operating systems
WORKDIR "$HOME"/site/bin
RUN find . -maxdepth 1 -mindepth 1 -name 'caddy.*' | grep -v -E '^\./caddy\.'"$(uname)"'\.'"$(uname -m)" | xargs rm -rf
WORKDIR "$HOME"/site/environments
RUN find . -maxdepth 1 -mindepth 1 | grep -v -F "$ENVIRONMENT" | xargs rm -rf



# (5) Add permissions to caddy binary so it can bind to ports < 1024

# (5.1) Download setcap
RUN apk add libcap

# (5.2) Change permissions
RUN ls -la "$HOME"/site/bin/caddy
RUN setcap cap_net_bind_service=+ep "$(realpath "$HOME"/site/bin/caddy."$(uname)"."$(uname -m)")"

# (5.3) Remove setcap
RUN apk del libcap



# (6) Finish
USER root
RUN rm -rf /var/cache/apk/*
USER "$USER"
WORKDIR "$HOME"/site
ENTRYPOINT exec ./caddy-wrapper serve "$ENVIRONMENT"
