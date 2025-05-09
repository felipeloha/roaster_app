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
        <div class="mb-4">
          <label class="block text-sm font-medium text-gray-700">Unavailable days</label>
          <div class="mt-2 space-y-1">
            <%= for {label, value} <- Orgs.day_map_as_tuples() do %>
              <label class="flex items-center space-x-2">
                <input
                  type="checkbox"
                  name="absences[unavailable_days][]"
                  value={to_string(value)}
                  checked={checked_day?(@form, value)}
                  class="rounded border-gray-300 text-indigo-600 shadow-sm focus:ring-indigo-500"
                />
                <span>{label}</span>
              </label>
            <% end %>
          </div>
        </div>
        <:actions>
          <.button phx-disable-with="Saving...">Save Absences</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  defp checked_day?(form, day) do
    values =
      form.params["unavailable_days"] ||
        form.source.changes[:unavailable_days] ||
        form.data.unavailable_days ||
        []

    to_string(day) in Enum.map(values, &to_string/1)
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
    user = socket.assigns[:current_user]

    with %RosterApp.Accounts.User{id: user_id} <- user,
         [] <- Orgs.list_absences(user_id) do
      full_params = get_full_absences_params(socket, absences_params)

      case Orgs.create_absences(full_params) do
        {:ok, absences} ->
          notify_parent({:saved, absences})

          {:noreply,
           socket
           |> put_flash(:info, "Absences created successfully")
           |> push_patch(to: socket.assigns.patch)}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign(socket, form: to_form(changeset))}
      end
    else
      _ ->
        {:noreply,
         socket
         |> put_flash(
           :error,
           "Only one absence record can be created for now. Please edit the current absence record."
         )
         |> push_patch(to: socket.assigns.patch)}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp get_full_absences_params(socket, absences_params) do
    unavailable_days =
      absences_params
      |> Map.get("unavailable_days", [])
      |> Enum.map(fn
        day when is_binary(day) -> String.to_integer(day)
        day -> day
      end)

    absences_params
    |> Map.put("unavailable_days", unavailable_days)
    |> Map.put("user_id", socket.assigns.current_user.id)
  end
end
