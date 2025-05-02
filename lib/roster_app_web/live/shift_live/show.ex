defmodule RosterAppWeb.ShiftLive.Show do
  use RosterAppWeb, :live_view

  alias RosterApp.Shifts
  alias RosterApp.Accounts

  @impl true
  def mount(_params, %{"user_token" => user_token} = _session, socket) do
    user = Accounts.get_user_by_session_token(user_token)

    {:ok,
     socket
     |> assign(current_user: user)
     |> assign(tenant_id: user.tenant_id)}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:shift, Shifts.get_shift!(id))}
  end

  defp page_title(:show), do: "Show Shift"
  defp page_title(:edit), do: "Edit Shift"
end
