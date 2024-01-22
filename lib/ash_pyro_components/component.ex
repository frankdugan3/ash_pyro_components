defmodule AshPyroComponents.Component do
  @moduledoc """
  Shared helpers used to build AshPyroComponents components.
  """

  @doc """
  Wraps `use Pyro.Component`, also importing this module's helpers.
  """
  defmacro __using__(opts \\ []) do
    [
      quote bind_quoted: [opts: opts] do
        use Pyro.Component, opts
      end,
      quote do
        import AshPyro.Helpers
        import unquote(__MODULE__)
      end
    ]
  end
end
