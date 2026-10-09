#!/bin/bash
set -e
MASTER_IP="${MASTER_IP:-localhost}"
printf 'master: %s\n' "$MASTER_IP" > /etc/salt/minion.d/master.conf
exec /sbin/init