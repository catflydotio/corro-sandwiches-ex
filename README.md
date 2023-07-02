# Corrodemo
Build corrosion for amd64 ()
Copy the corrosion executable to the project dir

fly apps create
put the new app name into fly.toml so you don't have to keep using -a
fly secrets set SECRET_KEY_BASE=$(mix phx.gen.secret 64)
fly volumes create corro_data -y -s 1
fly ips allocate-v4 --shared
fly ips allocate-v6
fly deploy
