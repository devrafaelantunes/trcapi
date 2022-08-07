import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :trc, Trc.Repo,
  username: "root",
  password: "root",
  hostname: "localhost",
  database: "trc_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :trc, TrcWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "RSAoTzpbtI0PH18vccdL+WxuLsqAgcCGwyuusqaMv3NUT9e7RDBlcKqgNByTO7Ql",
  server: false

config :trc,
  exchange_backend: Trc.AMQP.ExchangeMock,
  queue_backend: Trc.AMQP.QueueMock,
  file_io: Trc.Publisher.FileIOMock

config :trc,
  redis_url: "redis://localhost:6379/3"

# Print only warnings and errors during test
config :logger, level: :info

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
