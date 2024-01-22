# Used by "mix format"

[
  import_deps: [:phoenix, :pyro, :ash, :ash_pyro],
  plugins: [Spark.Formatter, Phoenix.LiveView.HTMLFormatter, Styler],
  inputs: ["*.{heex,ex,exs}", "{config,lib}/**/*.{heex,ex,exs}"]
]
