defmodule RosterAppWeb.ShiftLive.Index do
  use RosterAppWeb, :live_view

  alias RosterApp.Shifts
  alias RosterApp.Shifts.Shift
  alias RosterApp.Accounts

  @impl true
  def mount(_params, %{"user_token" => user_token} = _session, socket) do
    user = Accounts.get_user_by_session_token(user_token)

    if not is_nil(user) and connected?(socket) do
      Phoenix.PubSub.subscribe(RosterApp.PubSub, "user:#{user.id}")
    end

    {
      :ok,
      socket
      |> assign(:current_user, user)
      |> assign(:tenant_id, user.tenant_id)
      |> stream(:shifts, Shifts.list_shifts(user))
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
  def handle_info({:shift_assigned, shift}, socket),
    do:
      {:noreply,
       put_flash(socket, :info, "You've been assigned to a new shift '#{shift.description}'")}

  def handle_info({:shift_deleted, shift}, socket),
    do:
      {:noreply,
       put_flash(socket, :info, "Shift '#{shift.description}' related to you has been removed")}

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    shift = Shifts.get_shift!(id)
    {:ok, _} = Shifts.delete_shift(shift)

    RosterAppWeb.ShiftLive.FormComponent.maybe_notify_assignee(shift, :shift_deleted)

    {:noreply, stream_delete(socket, :shifts, shift)}
  end
end
