defmodule AshPyroComponentsExample.Authentication.Token do
  @moduledoc false
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication.TokenResource],
    authorizers: [Ash.Policy.Authorizer],
  domain: AshPyroComponentsExample.Authentication

  postgres do
    table "tokens"
    repo(AshPyroComponentsExample.Repo)
  end

  policies do
    bypass AshAuthentication.Checks.AshAuthenticationInteraction do
      authorize_if always()
    end
  end
end
