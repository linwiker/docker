#!/bin/sh
set -e

# allow arguments to be passed to squid
if [[ ${1:0:1} = '-' ]]; then
  EXTRA_ARGS="$@"
  set --
elif [[ ${1} == squid || ${1} == /sbin/squid ]]; then
  EXTRA_ARGS="${@:2}"
  set --
fi

if [[ -f /var/spool/squid/conf/squid.user.conf ]]; then
    rm -rf /etc/squid/squid.conf
    cp /var/spool/squid/conf/squid.user.conf /etc/squid/squid.conf
fi


# default behaviour is to launch squid
if [[ -z ${1} ]]; then
  if [[ ! -d ${SQUID_CACHE_DIR}/00 ]]; then
    echo "Initializing cache..."
    /sbin/squid -N -f /etc/squid/squid.conf -z
  fi
  echo "Starting squid..."
  exec /sbin/squid -f /etc/squid/squid.conf -NYCd 1 ${EXTRA_ARGS}
else
  exec "$@"
fi
