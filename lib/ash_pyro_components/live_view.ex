defmodule AshPyroComponents.LiveView do
  @moduledoc """
  This is basically a wrapper around `Pyro.LiveView`, but it uses `AshPyroComponents.Component` instead of `Pyro.Component` to enable AshPyroComponents's extended features.
  """

  @doc false
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      import Phoenix.LiveView
      @behaviour Phoenix.LiveView
      @before_compile Phoenix.LiveView.Renderer

      @phoenix_live_opts opts
      Module.register_attribute(__MODULE__, :phoenix_live_mount, accumulate: true)
      @before_compile Phoenix.LiveView

      # AshPyroComponents.Component must come last so its @before_compile runs last
      use AshPyroComponents.Component, Keyword.take(opts, [:global_prefixes])
    end
  end
end
