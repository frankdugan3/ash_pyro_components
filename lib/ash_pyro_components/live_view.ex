defmodule AshPyroComponents.LiveView do
  @moduledoc """
  This is basically a wrapper around `Pyro.LiveView`, but it uses `AshPyroComponents.Component` instead of `Pyro.Component` to enable AshPyroComponents's extended features.
  """

  @doc false
  defmacro __using__(opts) do
    # Expand layout if possible to avoid compile-time dependencies
    opts =
      with true <- Keyword.keyword?(opts),
           {layout, template} <- Keyword.get(opts, :layout) do
        layout = Macro.expand(layout, %{__CALLER__ | function: {:__live__, 0}})
        Keyword.replace!(opts, :layout, {layout, template})
      else
        _ -> opts
      end

    [
      quote do
        import Phoenix.LiveView
      end,
      quote bind_quoted: [opts: opts] do
        @behaviour Phoenix.LiveView
        @before_compile Phoenix.LiveView.Renderer

        @phoenix_live_opts opts
        Module.register_attribute(__MODULE__, :phoenix_live_mount, accumulate: true)
        @before_compile Phoenix.LiveView
      end,
      quote bind_quoted: [opts: opts] do
        # AshPyroComponents.Component must come last so its @before_compile runs last
        use AshPyroComponents.Component, Keyword.take(opts, [:global_prefixes])
      end
    ]
  end
end
