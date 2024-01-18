defmodule AshPyroComponentsExampleWeb.SessionSetTimezoneController do
  @moduledoc false
  use AshPyroComponentsExampleWeb, :controller

  def set(conn, %{"timezone" => timezone}) when is_binary(timezone) do
    conn |> put_session(:timezone, timezone) |> json(%{})
  end
end
