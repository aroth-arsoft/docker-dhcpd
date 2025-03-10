#!/bin/bash

set -e

if [ -z "$IFACE" ]; then
    # Single argument to command line is interface name
    if [ $# -eq 1 -a -n "$1" ]; then
        # skip wait-for-interface behavior if found in path
        if ! which "$1" >/dev/null; then
            # loop until interface is found, or we give up
            NEXT_WAIT_TIME=1
            until [ -e "/sys/class/net/$1" ] || [ $NEXT_WAIT_TIME -eq 4 ]; do
                sleep $(( NEXT_WAIT_TIME++ ))
                echo "Waiting for interface '$1' to become available... ${NEXT_WAIT_TIME}"
            done
            if [ -e "/sys/class/net/$1" ]; then
                IFACE="$1"
            fi
        fi
    fi

    # No arguments mean all interfaces
    if [ -z "$1" ]; then
        IFACE=" "
    fi
fi

if [ -n "$IFACE" ]; then
    # Run dhcpd for specified interface or all interfaces

    config_dir="/config"
    data_dir="/data"
    if [ ! -d "$data_dir" ]; then
        echo "Please ensure '$data_dir' folder is available."
        echo 'If you just want to keep your configuration in "data/", add -v "$(pwd)/data:/data" to the docker run command line.'
        exit 1
    fi
    if [ ! -d "$config_dir" ]; then
        echo "Please ensure '$config_dir' folder is available."
        echo 'If you just want to keep your configuration in "config/", add -v "$(pwd)/config:/config" to the docker run command line.'
        exit 1
    fi

    if [ "$DHCPD_PROTOCOL" == '6' ]; then
        dhcpd_conf="$config_dir/dhcpd6.conf"
    else
        dhcpd_conf="$config_dir/dhcpd.conf"
    fi
    if [ ! -r "$dhcpd_conf" ]; then
        echo "Please ensure '$dhcpd_conf' exists and is readable."
        echo "Run the container with arguments 'man dhcpd.conf' if you need help with creating the configuration."
        exit 1
    fi

    uid=$(stat -c%u "$data_dir")
    gid=$(stat -c%g "$data_dir")
    if [ $gid -ne 0 ]; then
        groupmod -g $gid dhcpd
    fi
    if [ $uid -ne 0 ]; then
        usermod -u $uid dhcpd
    fi

    [ -e "$data_dir/dhcpd.leases" ] || touch "$data_dir/dhcpd.leases"
    chown dhcpd:dhcpd "$data_dir/dhcpd.leases"
    if [ -e "$data_dir/dhcpd.leases~" ]; then
        chown dhcpd:dhcpd "$data_dir/dhcpd.leases~"
    fi

    container_id=$(grep docker /proc/self/cgroup | sort -n | head -n 1 | cut -d: -f3 | cut -d/ -f3)
    if perl -e '($id,$name)=@ARGV;$short=substr $id,0,length $name;exit 1 if $name ne $short;exit 0' $container_id $HOSTNAME; then
        echo "You must add the 'docker run' option '--net=host' if you want to provide DHCP service to the host network."
    fi
    echo "Start dhcpd with $dhcpd_conf for interfaces: $IFACE"
    exec /usr/sbin/dhcpd -$DHCPD_PROTOCOL -f -d --no-pid -cf "$dhcpd_conf" -lf "$data_dir/dhcpd.leases" $IFACE
else
    # Run another binary
    exec "$@"
fi
