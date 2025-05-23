defmodule RosterAppWeb.ShiftLive.Index do
  use RosterAppWeb, :live_view

  alias RosterApp.Shifts
  alias RosterApp.Shifts.Shift
  alias RosterApp.Accounts

  @impl true
  def mount(_params, %{"user_token" => user_token} = _session, socket) do
    user = Accounts.get_user_by_session_token(user_token)

    if not is_nil(user) and connected?(socket) do
      # Subscribe to both user-specific and tenant-wide updates
      Phoenix.PubSub.subscribe(RosterApp.PubSub, "user:#{user.id}")
      Phoenix.PubSub.subscribe(RosterApp.PubSub, "tenant:#{user.tenant_id}")
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
  def handle_info({:shift_created, shift}, socket) do
    {:noreply, stream_insert(socket, :shifts, shift)}
  end

  @impl true
  def handle_info({:shift_updated, shift}, socket) do
    {:noreply, stream_insert(socket, :shifts, shift)}
  end

  @impl true
  def handle_info({:shift_deleted, shift}, socket) do
    {:noreply, stream_delete(socket, :shifts, shift)}
  end

  @impl true
  def handle_info({:shift_assigned, shift}, socket) do
    {:noreply, stream_insert(socket, :shifts, shift)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    shift = Shifts.get_shift!(id)
    {:ok, _} = Shifts.delete_shift(shift)

    # Broadcast to tenant channel instead of just the assignee
    Phoenix.PubSub.broadcast(
      RosterApp.PubSub,
      "tenant:#{socket.assigns.tenant_id}",
      {:shift_deleted, shift}
    )

    {:noreply, stream_delete(socket, :shifts, shift)}
  end
end
