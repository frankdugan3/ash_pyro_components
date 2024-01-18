defmodule AshPyroComponentsExampleWeb.PageLive do
  @moduledoc false
  use AshPyroComponentsExampleWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div>Hello.</div>
    """
  end
end
