#!/bin/bash

sed -i '1s;^;gossip_addr = \"['${FLY_PRIVATE_IP}']:8787\"\n;' /app/corrosion.toml

# echo -e 'gossip_addr = '$FLY_PRIVATE_IP':8787\n'$(cat /app/corrosion.toml) > /app/corrosion.toml
exec "$@"

# set -m # to make job control work
# /app/corrosion agent &
# /app/bin/server &
# fg %1 # gross!

#sleep infinity