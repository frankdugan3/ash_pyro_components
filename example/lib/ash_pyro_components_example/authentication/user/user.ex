defmodule AshPyroComponentsExample.Authentication.User do
  @moduledoc false
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication],
    authorizers: [Ash.Policy.Authorizer],
  domain: AshPyroComponentsExample.Authentication


  postgres do
    table "users"
    repo(AshPyroComponentsExample.Repo)
  end

  authentication do

    strategies do
      password :password do
        identity_field(:email)
        sign_in_tokens_enabled?(true)

        resettable do
          sender AshPyroComponentsExample.Authentication.User.Senders.SendPasswordResetEmail
        end
      end
    end

    tokens do
      enabled? true
      token_resource AshPyroComponentsExample.Authentication.Token

      signing_secret AshPyroComponentsExample.Authentication.Secrets
    end
  end

  attributes do
    uuid_primary_key :id
    attribute :email, :ci_string, allow_nil?: false, public?: true
    attribute :hashed_password, :string, allow_nil?: false, sensitive?: true
  end

  identities do
    identity :unique_email, [:email]
  end

  policies do
    bypass AshAuthentication.Checks.AshAuthenticationInteraction do
      authorize_if always()
    end
  end
end
