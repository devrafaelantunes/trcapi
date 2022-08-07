# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :trc,
  ecto_repos: [Trc.Repo]

# Configures the endpoint
config :trc, TrcWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: TrcWeb.ErrorView, accepts: ~w(json), layout: false],
  pubsub_server: Trc.PubSub,
  live_view: [signing_salt: "1/YLGZbQ"]

config :trc,
  file_io: Trc.Publisher.FileIO,
  exchange_backend: Trc.AMQP.Exchange,
  queue_backend: Trc.AMQP.Queue,
  datasets: %{
    memegenerator: %{
      path: "datasets/memegenerator.csv",
      consumers: 16
    },
    twitchdata: %{
      path: "datasets/twitchdata-update.csv",
      consumers: 16
    },
    dielectron: %{
      path: "datasets/dielectron.csv",
      consumers: 16
    }
  }

config :trc,
  redis_url: "redis://redis:6379/3"

# Swoosh API client is needed for adapters other than SMTP.
config :swoosh, :api_client, false

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
