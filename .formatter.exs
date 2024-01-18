# Used by "mix format"

[
  import_deps: [:phoenix, :pyro, :ash, :ash_pyro],
  plugins: [Spark.Formatter, Phoenix.LiveView.HTMLFormatter, Styler],
  # HACK: Ignore files that need special module attribute ordering
  inputs:
    Enum.flat_map(
      ["*.{heex,ex,exs}", "{config,lib}/**/*.{heex,ex,exs}"],
      &Path.wildcard(&1, match_dot: true)
    ) --
      [
        "lib/ash_pyro_components/component.ex",
        "lib/ash_pyro_components/live_component.ex",
        "lib/ash_pyro_components/live_view.ex"
      ]
]
