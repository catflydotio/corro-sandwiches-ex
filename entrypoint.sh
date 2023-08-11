#!/bin/bash

sed -i '1s;^;gossip_addr = \"['${FLY_PRIVATE_IP}']:8787\"\n\n;' /app/corrosion.toml


# Don't really need the case where it's not builtin, since by definition
# then Corrosion's not in the app so doesn't need the config.
if [ ${CORRO_BUILTIN} -eq "1" ]
    then
        echo "CORRO_BUILTIN was 1"
        sed -i '1s;^;bootstrap = [\"'${FLY_APP_NAME}'.internal:8787\"]\n\n;' /app/corrosion.toml
        sed -i '1s;^;api_addr = \"[::]:8081\"\n\n;' /app/corrosion.toml
    else
        sed -i '1s;^;bootstrap = [\"'${FLY_CORROSION_APP}'.internal:8787\"]\n\n;' /app/corrosion.toml
        sed -i '1s;^;api_addr = \"[::]:8081\"\n\n;' /app/corrosion.toml
fi

exec "$@"