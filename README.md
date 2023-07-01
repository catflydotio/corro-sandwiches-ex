# Corrodemo
Build corrosion in another directory
Copy the corrosion executable to the project dir

fly apps create
put the new app name into fly.toml so you don't have to keep using -a
fly secrets set SECRET_KEY_BASE=$(mix phx.gen.secret 64)
fly volumes create corro_data -y -s 1
fly ips allocate-v4 --shared
fly ips allocate-v6
fly deploy

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
