#!/bin/bash
set -e
for name in VARNISH_BACKEND_PORT VARNISH_BACKEND_IP
do
    eval value=\$$name
    sed -i "s|\${${name}}|${value}|g" /etc/varnish/default.vcl
done

# Start varnish
/usr/sbin/varnishd -F \
        -f $VARNISH_VCL_CONF \
        -P /var/run/varnish.pid \
        -f $VARNISH_VCL_CONF \
        -a ${VARNISH_LISTEN_ADDRESS}:${VARNISH_LISTEN_PORT} \
        -T ${VARNISH_ADMIN_LISTEN_ADDRESS}:${VARNISH_ADMIN_LISTEN_PORT} \
        -t $VARNISH_TTL \
        -S $VARNISH_SECRET_FILE \
        -s $VARNISH_STORAGE \
        $DAEMON_OPTS
