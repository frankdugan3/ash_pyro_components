defmodule AshPyroComponentsExample.Authentication do
  @moduledoc false
  use Ash.Domain

  authorization do
    authorize :by_default
    require_actor? false
  end

  resources do
    resource AshPyroComponentsExample.Authentication.User
    resource AshPyroComponentsExample.Authentication.Token
  end
end
