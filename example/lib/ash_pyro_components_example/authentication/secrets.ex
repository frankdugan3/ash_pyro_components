defmodule AshPyroComponentsExample.Authentication.Secrets do
  @moduledoc false
  use AshAuthentication.Secret

  def secret_for([:authentication, :tokens, :signing_secret], AshPyroComponentsExample.Authentication.User, _) do
    case Application.fetch_env(:ash_pyro_components_example, AshPyroComponentsExampleWeb.Endpoint) do
      {:ok, endpoint_config} ->
        Keyword.fetch(endpoint_config, :secret_key_base)

      :error ->
        :error
    end
  end
end
