# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :ash_pyro_components_example,
  ecto_repos: [AshPyroComponentsExample.Repo],
  generators: [timestamp_type: :utc_datetime]

config :ash_pyro_components_example, ash_domains: [AshPyroComponentsExample.Authentication, AshPyroComponentsExample.Vendor]

config :elixir, :time_zone_database, Tz.TimeZoneDatabase

config :pyro,
  gettext: AshPyroComponentsExampleWeb.Gettext,
  overrides: [AshPyroComponents.Overrides.BEM, PyroComponents.Overrides.BEM]

config :spark, :formatter,
  remove_parens?: true,
  "Ash.Resource": [
    type: Ash.Resource,
    section_order: [
      :resource,
      :pyro,
      :postgres,
      :authentication,
      :pub_sub,
      :attributes,
      :identities,
      :relationships,
      :aggregates,
      :calculations,
      :validations,
      :changes,
      :actions,
      :code_interface,
      :policies
    ]
  ]

config :ash, :utc_datetime_type, :datetime

config :ash, :use_all_identities_in_manage_relationship?, false

config :ash, :policies, log_policy_breakdowns: :error

# Configures the endpoint
config :ash_pyro_components_example, AshPyroComponentsExampleWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: AshPyroComponentsExampleWeb.ErrorHTML, json: AshPyroComponentsExampleWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: AshPyroComponentsExample.PubSub,
  live_view: [signing_salt: "0rQe1tkU"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :ash_pyro_components_example, AshPyroComponentsExample.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.20.2",
  default: [
    args: ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.3",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
