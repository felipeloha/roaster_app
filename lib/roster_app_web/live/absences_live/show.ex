defmodule RosterAppWeb.AbsencesLive.Show do
  use RosterAppWeb, :live_view

  alias RosterApp.Orgs

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:absences, Orgs.get_absences!(id))}
  end

  defp page_title(:show), do: "Show Absences"
  defp page_title(:edit), do: "Edit Absences"
end
