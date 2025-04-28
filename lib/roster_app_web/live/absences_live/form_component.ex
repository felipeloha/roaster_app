defmodule RosterAppWeb.AbsencesLive.FormComponent do
  use RosterAppWeb, :live_component

  alias RosterApp.Orgs

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage absences records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="absences-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <span>Selected values: {inspect(@form.params |> Map.get("unavailable_days", []))}</span>
        <.input
          field={@form[:unavailable_days]}
          type="select"
          multiple={true}
          label="Unavailable days"
          options={Orgs.day_map_as_tuples()}
        />
        <:actions>
          <.button phx-disable-with="Saving...">Save Absences</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{absences: absences} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Orgs.change_absences(absences))
     end)}
  end

  defp previous_days(%{assigns: %{form: %{source: %{changes: %{unavailable_days: days}}}}}),
    do: days

  defp previous_days(_), do: []

  @impl true
  def handle_event("validate", %{"absences" => absences_params} = _opts, socket) do
    full_absences_params = get_full_absences_params(socket, absences_params)

    changeset = Orgs.change_absences(socket.assigns.absences, full_absences_params)
    form = to_form(changeset, action: :validate)

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("save", %{"absences" => absences_params}, socket) do
    save_absences(socket, socket.assigns.action, absences_params)
  end

  defp save_absences(socket, :edit, absences_params) do
    full_absences_params = get_full_absences_params(socket, absences_params)

    case Orgs.update_absences(socket.assigns.absences, full_absences_params) do
      {:ok, absences} ->
        notify_parent({:saved, absences})

        {:noreply,
         socket
         |> put_flash(:info, "Absences updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_absences(socket, :new, absences_params) do
    full_absences_params = get_full_absences_params(socket, absences_params)

    case Orgs.create_absences(full_absences_params) do
      {:ok, absences} ->
        notify_parent({:saved, absences})

        {:noreply,
         socket
         |> put_flash(:info, "Absences created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp get_full_absences_params(socket, absences_params) do
    Map.put(
      absences_params,
      "unavailable_days",
      (previous_days(socket) ++ absences_params["unavailable_days"]) |> Enum.uniq()
    )
  end
end
