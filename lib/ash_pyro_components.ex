defmodule AshPyroComponents do
  @moduledoc """
  The easiest way to use the components from PyroComponents and AshPyroComponets is to import them into `my_app_web.ex` helpers to make the available in all views and components:

   ```elixir
   defp html_helpers do
     quote do
       # Import all components from PyroComponents/AshPyroComponents
       use AshPyroComponents
       # ...
   ```

  Comprehensive installation instructions can be found in [Get Started](get-started.md).
  """

  defmacro __using__(_) do
    quote do
      use PyroComponents

      import AshPyroComponents.Components.DataTable
      import AshPyroComponents.Components.Form

      alias AshPyroComponents.Components.Page, as: AshPage
    end
  end
end
