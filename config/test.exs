import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :corrodemo, CorrodemoWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "VkoHKbK5nvRSmIdn5alYc69sGIBZ64OJ30UHmicGRJTCh27F7n+43da2Lo+Q9jBP",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
