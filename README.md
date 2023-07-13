# corro-sandwiches-ex

An Elixir client/demo for Corrosion


## Run all-in-one, locally
Build corrosion for amd64 ()
Copy the corrosion executable to the project dir
Set some env vars
iex mix phx.server

## Deploy to Fly.io
fly apps create
put the new app name into fly.toml so you don't have to keep using -a
fly secrets set SECRET_KEY_BASE=$(mix phx.gen.secret 64)
fly volumes create corro_data -y -s 1
fly ips allocate-v4 --shared
fly ips allocate-v6
<!-- If using a separate app running on Fly.io for corrosion -->
fly deploy -a corrodemo -c fly-separate.toml --dockerfile Dockerfile-separate

<!-- To use corrosion built into the Machine -->
<!-- Make sure to copy an up-to-date Corrosion binary to the project dir -->
fly deploy -a sandwich-builtin --dockerfile Dockerfile-allinone


## What else 

* CORRO_BUILTIN and FLY_CORROSION_APP are used to determine whether to use local corrosion or a separate app
* right now it exits when corrosion app isn't reachable. THis is for corrosion testing, so I can see the logs