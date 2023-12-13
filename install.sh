#!/bin/sh /etc/rc.common
# Copyright (C) 2007 OpenWrt.org

START=90
INTERFACE=br-lan
PORT=1337

# check if configuration exists
[ -e "/etc/bdix.conf" ] || exit 0

iptable_start() {
    /bin/echo -n "running bdix iptables ..."

    # Run iptable commands
    iptables -t nat -N BDIX

    iptables -t nat -A BDIX -d 0.0.0.0/8 -j RETURN
    iptables -t nat -A BDIX -d 10.0.0.0/8 -j RETURN
    iptables -t nat -A BDIX -d 127.0.0.0/8 -j RETURN
    iptables -t nat -A BDIX -d 169.254.0.0/16 -j RETURN
#    iptables -t nat -A BDIX -d 172.16.0.0/12 -j RETURN
    iptables -t nat -A BDIX -d 192.168.0.0/16 -j RETURN
    iptables -t nat -A BDIX -d 224.0.0.0/4 -j RETURN
    iptables -t nat -A BDIX -d 240.0.0.0/4 -j RETURN

    iptables -t nat -A BDIX -p tcp -j REDIRECT --to-ports ${PORT}

    iptables -t nat -A PREROUTING -i ${INTERFACE} -p tcp -j BDIX

    iptables -A INPUT -i br-lan -p tcp --dport ${PORT} -j ACCEPT

    /bin/echo " done"
}

iptable_stop() {
    /bin/echo -n "cleaning bdix iptables ..."

    # Run iptable commands
    iptables -t nat -F BDIX
    iptables -t nat -F PREROUTING
    iptables -t nat -F POSTROUTING
    iptables -F INPUT
    iptables -F FORWARD
    iptables -t nat -X BDIX

    /bin/echo " done"
}

start() {
    if [ -e "/var/run/bdix.pid" ]; then
        echo "bdix is already running"
        exit 0
    fi

    /bin/echo -n "running bdix ..."

    # startup the safety-wrapper for the daemon
    /usr/sbin/redsocks -c /etc/bdix.conf -p /var/run/bdix.pid

    /bin/echo " done"
    iptable_start
}


stop() {
    if [ ! -e "/var/run/bdix.pid" ]; then
        echo "bdix is not running"
        exit 0
    fi

    /bin/echo -n "stopping bdix ..."

    # kill the process
    /bin/kill $(cat /var/run/bdix.pid)
    rm /var/run/bdix.pid

    echo " done"
    iptable_stop

    /bin/echo -n "restarting firewall ..."
    /etc/init.d/firewall restart &> /dev/null
    /bin/echo " done"
}
