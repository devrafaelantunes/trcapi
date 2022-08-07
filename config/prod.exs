import Config

# For production, don't forget to configure the url host
# to something meaningful, Phoenix uses this information
# when generating URLs.
#
# Note we also include the path to a cache manifest
# containing the digested version of static files. This
# manifest is generated by the `mix phx.digest` task,
# which you should run after static files are built and
# before starting your production server.
#config :trc, TrcWeb.Endpoint, cache_static_manifest: "priv/static/cache_manifest.json"

config :trc, Trc.Repo,
  username: "root",
  password: "root",
  hostname: "mysql",
  database: "trc_prod",
  pool_size: 10

# Do not print debug messages in production
config :logger, level: :info

config :trc, TrcWeb.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
  http: [ip: {0, 0, 0, 0}, port: 4000],
  check_origin: false,
  secret_key_base: "VUHYBPxqUYiXXiDsWVBaBTTH4fMYFJwszx8vXLpapQoDD2y54eNTzxmvBqCXtwou",
  watchers: [],
  server: true


config :trc,
  datasets: %{
    memegenerator: %{
      path: "/opt/datasets/memegenerator.csv",
      consumers: 16
    },
    twitchdata: %{
      path: "/opt/datasets/twitchdata-update.csv",
      consumers: 16
    },
    dielectron: %{
      path: "/opt/datasets/dielectron.csv",
      consumers: 16
    }
  }

config :trc, :environment, :prod

config :trc,
    redis_url: "redis://redis:6379/3"

# ## SSL Support
#
# To get SSL working, you will need to add the `https` key
# to the previous section and set your `:url` port to 443:
#
#     config :trc, TrcWeb.Endpoint,
#       ...,
#       url: [host: "example.com", port: 443],
#       https: [
#         ...,
#         port: 443,
#         cipher_suite: :strong,
#         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
#         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
#       ]
#
# The `cipher_suite` is set to `:strong` to support only the
# latest and more secure SSL ciphers. This means old browsers
# and clients may not be supported. You can set it to
# `:compatible` for wider support.
#
# `:keyfile` and `:certfile` expect an absolute path to the key
# and cert in disk or a relative path inside priv, for example
# "priv/ssl/server.key". For all supported SSL configuration
# options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
#
# We also recommend setting `force_ssl` in your endpoint, ensuring
# no data is ever sent via http, always redirecting to https:
#
#     config :trc, TrcWeb.Endpoint,
#       force_ssl: [hsts: true]
#
# Check `Plug.SSL` for all available options in `force_ssl`.
