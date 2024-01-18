defmodule AshPyroComponentsExampleWeb.Vendor.CompanyLive do
  @moduledoc false
  use AshPyroComponentsExampleWeb, :live_view

  use AshPage,
    resource: AshPyroComponentsExample.Vendor.Company,
    page: :companies,
    router: AshPyroComponentsExampleWeb.Router
end
