defmodule AshPyroComponents.LiveComponent do
  @moduledoc ~S"""
  This is basically a wrapper around `Pyro.LiveComponent`, but it uses `AshPyroComponents.Component` instead of `Pyro.Component` to enable AshPyroComponents's extended features.
  """

  @doc false
  defmacro __using__(opts \\ []) do
    [
      quote do
        import Phoenix.LiveView
      end,
      quote do
        @behaviour Phoenix.LiveComponent
        @before_compile Phoenix.LiveView.Renderer
      end,
      quote do
        # AshPyroComponents.Component must come last so its @before_compile runs last
        use AshPyroComponents.Component, Keyword.take(unquote(opts), [:global_prefixes])

        @doc false
        def __live__, do: %{kind: :component, module: __MODULE__, layout: false}
      end
    ]
  end
end
