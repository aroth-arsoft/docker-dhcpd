FROM ubuntu:focal

MAINTAINER Robin Smidsrød <robin@smidsrod.no>

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get -q -y update \
 && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends --no-install-suggests -y -o "DPkg::Options::=--force-confold" -o "DPkg::Options::=--force-confdef" dumb-init isc-dhcp-server \
 && apt-get -q -y autoremove \
 && apt-get -q -y clean \
 && cp -a /etc/dhcp /data \
 && rm -rf /var/lib/apt/lists/*

ENV DHCPD_PROTOCOL=4

VOLUME /data

COPY util/entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
