defmodule RosterAppWeb.AbsencesLive.Index do
  use RosterAppWeb, :live_view

  alias RosterApp.Orgs
  alias RosterApp.Orgs.Absences
  alias RosterApp.Accounts

  @impl true
  def mount(_params, %{"user_token" => user_token} = _session, socket) do
    case Accounts.get_user_by_session_token(user_token) do
      nil ->
        {:ok, socket |> redirect(to: ~p"/")}

      user ->
        socket =
          socket
          |> assign(:current_user, user)
          |> assign(:tenant_id, user.tenant_id)
          |> stream(:absences_collection, Orgs.list_absences(user.id))

        {:ok, socket}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Absences")
    |> assign(:absences, Orgs.get_absences!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Absences")
    |> assign(:absences, %Absences{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Absences")
    |> assign(:absences, nil)
  end

  @impl true
  def handle_info({RosterAppWeb.AbsencesLive.FormComponent, {:saved, absences}}, socket) do
    {:noreply, stream_insert(socket, :absences_collection, absences)}
  end

  @impl true
  def handle_event(event, %{"id" => id}, socket) do
    case event do
      "delete" ->
        absences = Orgs.get_absences!(id)
        {:ok, _} = Orgs.delete_absences(absences)

        {:noreply, stream_delete(socket, :absences_collection, absences)}

      _ ->
        # todo add validate
        {:noreply, socket}
    end
  end
end
