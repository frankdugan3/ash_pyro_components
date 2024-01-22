defmodule AshPyroComponentsExample.MixProject do
  use Mix.Project

  def project do
    [
      app: :ash_pyro_components_example,
      version: "0.0.0",
      elixir: "~> 1.16",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {AshPyroComponentsExample.Application, []},
      extra_applications: [:logger, :runtime_tools, :os_mon]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:ash_authentication, "~> 3.12"},
      {:ash_authentication_phoenix, "~> 1.9"},
      {:ash_phoenix, "~> 1.2"},
      # {:ash_postgres, "~> 1.0"},
      {:ash_postgres, github: "ash-project/ash_postgres", branch: "main"},
      # {:ash, "~> 2.4"},
      {:ash, github: "ash-project/ash", branch: "main", override: true},
      {:bandit, "~> 1.0"},
      {:dns_cluster, "~> 0.1.1"},
      {:ecto_sql, "~> 3.10"},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:finch, "~> 0.13"},
      {:floki, ">= 0.30.0", only: :test},
      {:gettext, "~> 0.20"},
      {:heroicons, github: "tailwindlabs/heroicons", tag: "v2.1.1", app: false, compile: false, sparse: "optimized"},
      {:jason, "~> 1.2"},
      {:phoenix_live_dashboard, "~> 0.8.2"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_ecto, "~> 4.0"},
      {:postgrex, ">= 0.0.0"},
      {:swoosh, "~> 1.3"},
      {:tailwind, "~> 0.2.0", runtime: Mix.env() == :dev},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:tz, "~> 0.26"},
      {:tz_extra, "~> 0.26"},
      {:ash_pyro_components, path: "../"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      reset: [
        "ash_postgres.drop",
        "ash_postgres.create",
        "cmd rm -rf priv/repo/migrations",
        "cmd rm -rf priv/resource_snapshots",
        "ash_postgres.generate_migrations",
        "ash_postgres.migrate",
        "seed"
      ],
      seed: "run priv/repo/seeds.exs",
      setup: ["deps.get", "seed", "assets.setup", "assets.build"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind default", "esbuild default"],
      "assets.deploy": ["tailwind default --minify", "esbuild default --minify", "phx.digest"]
    ]
  end
end
