FROM ubuntu:focal

MAINTAINER Robin Smidsrød <robin@smidsrod.no>

RUN apt-get -q -y update \
 && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends --no-install-suggests -y -o "DPkg::Options::=--force-confold" -o "DPkg::Options::=--force-confdef" \
    isc-dhcp-server dhcpd-pools \
 && apt-get -q -y autoremove \
 && apt-get -q -y clean \
 && cp -a /etc/dhcp /data \
 && rm -rf /var/lib/apt/lists/*

ENV DHCPD_PROTOCOL=4 \
	IFACE=

VOLUME /data /config

COPY util/entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
