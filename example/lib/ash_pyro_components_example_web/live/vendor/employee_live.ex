defmodule AshPyroComponentsExampleWeb.Vendor.EmployeeLive do
  @moduledoc false
  use AshPyroComponentsExampleWeb, :live_view

  use AshPage,
    resource: AshPyroComponentsExample.Vendor.Employee,
    page: :employees,
    router: AshPyroComponentsExampleWeb.Router
end
