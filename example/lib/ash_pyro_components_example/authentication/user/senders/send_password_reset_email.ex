defmodule AshPyroComponentsExample.Authentication.User.Senders.SendPasswordResetEmail do
  @moduledoc """
  Sends a password reset email
  """
  use AshAuthentication.Sender
  use AshPyroComponentsExampleWeb, :verified_routes

  @impl AshAuthentication.Sender
  def send(user, token, _) do
    AshPyroComponentsExample.Authentication.Emails.deliver_reset_password_instructions(
      user,
      url(~p"/password-reset/#{token}")
    )
  end
end
