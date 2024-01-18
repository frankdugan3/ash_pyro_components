defmodule AshPyroComponents.Component do
  @moduledoc """
  Shared helpers used to build AshPyroComponents components.
  """

  @doc """
  Wraps `use Pyro.Component`, also importing this module's helpers.
  """
  defmacro __using__(opts \\ []) do
    component = quote bind_quoted: [opts: opts] do
      use Pyro.Component, opts
    end

    imports = quote do
      import AshPyro.Helpers
      import unquote(__MODULE__)
    end

    [component, imports]
  end
end
