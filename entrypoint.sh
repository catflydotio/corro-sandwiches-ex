#!/bin/bash

sed -i '1s;^;gossip_addr = \"['${FLY_PRIVATE_IP}']:8787\"\n\n;' /app/corrosion.toml

if [ ${CORRO_BUILTIN} -eq "1" ]
    then
        echo "CORRO_BUILTIN was 1"
        sed -i '1s;^;bootstrap = [\"'${FLY_APP_NAME}'.internal:8787\"]\n\n;' /app/corrosion.toml
        sed -i '1s;^;api_addr = \"127.0.0.1:8081\"\n\n;' /app/corrosion.toml
    else
        sed -i '1s;^;bootstrap = [\"'${FLY_CORROSION_APP}'.internal:8787\"]\n\n;' /app/corrosion.toml
        sed -i '1s;^;api_addr = \"[::]:8081\"\n\n;' /app/corrosion.toml
fi

# bootstrap = ["sandwich-builtin.internal:8787"]

# export CORRO_BASEURL="http://top1.nearest.of.$FLY_CORROSION_APP.internal:8080"
# export PHX_HOST="$FLY_APP_NAME.fly.dev"
exec "$@"

## Could do instead of Overmind:
# set -m # to make job control work
# /app/corrosion agent &
# /app/bin/server &
# fg %1 # gross!

#sleep infinity