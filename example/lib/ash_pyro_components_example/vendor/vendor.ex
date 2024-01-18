defmodule AshPyroComponentsExample.Vendor do
  @moduledoc false
  use Ash.Api

  authorization do
    authorize :by_default
    require_actor? true
  end

  resources do
    resource AshPyroComponentsExample.Vendor.Company
    resource AshPyroComponentsExample.Vendor.Employee
  end
end
