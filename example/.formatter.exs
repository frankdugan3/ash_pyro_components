# Used by "mix format"

[
  import_deps: [
    :phoenix,
    :pyro,
    :ash_pyro,
    :ash,
    :ash_authentication,
    :ash_authentication_phoenix
  ],
  subdirectories: ["priv/*/migrations"],
  plugins: [Spark.Formatter, Phoenix.LiveView.HTMLFormatter, Styler],
  inputs: ["*.{heex,ex,exs}", "{config,lib}/**/*.{heex,ex,exs}"]
]
