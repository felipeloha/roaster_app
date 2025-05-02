defmodule RosterAppWeb.ShiftLive.Index do
  use RosterAppWeb, :live_view

  alias RosterApp.Shifts
  alias RosterApp.Shifts.Shift
  alias RosterApp.Accounts

  @impl true
  def mount(_params, %{"user_token" => user_token} = _session, socket) do
    user = Accounts.get_user_by_session_token(user_token)

    {
      :ok,
      socket
      |> assign(:current_user, user)
      |> stream(:shifts, Shifts.list_shifts())
    }
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Shift")
    |> assign(:shift, Shifts.get_shift!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Shift")
    |> assign(:shift, %Shift{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Shifts")
    |> assign(:shift, nil)
  end

  @impl true
  def handle_info({RosterAppWeb.ShiftLive.FormComponent, {:saved, shift}}, socket) do
    {:noreply, stream_insert(socket, :shifts, shift)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    shift = Shifts.get_shift!(id)
    {:ok, _} = Shifts.delete_shift(shift)

    {:noreply, stream_delete(socket, :shifts, shift)}
  end
end
