defmodule RosterAppWeb.ShiftLive.FormComponent do
  use RosterAppWeb, :live_component

  alias RosterApp.Shifts
  alias RosterApp.Orgs
  alias RosterApp.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage shift records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="shift-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          type="select"
          field={@form[:work_type_id]}
          options={Enum.map(@work_types, &{&1.name, &1.id})}
        />
        <.input
          type="select"
          field={@form[:department_id]}
          options={Enum.map(@departments, &{&1.name, &1.id})}
        />
        <.input
          type="select"
          field={@form[:assigned_user_id]}
          options={Enum.map(@users, &{&1.email, &1.id})}
        />
        <.input field={@form[:start_time]} type="datetime-local" label="Start time" />
        <.input field={@form[:end_time]} type="datetime-local" label="End time" />
        <.input field={@form[:description]} type="text" label="Description" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Shift</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{shift: shift} = assigns, socket) do
    work_types = Orgs.list_work_types()
    departments = Orgs.list_departments()
    # You’ll filter this later
    users = Accounts.list_users()

    changeset = Shifts.change_shift(shift)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:work_types, work_types)
     |> assign(:departments, departments)
     |> assign(:users, users)
     |> assign(:form, to_form(changeset))}
  end

  @impl true
  def handle_event("validate", %{"shift" => shift_params}, socket) do
    changeset = Shifts.change_shift(socket.assigns.shift, with_tenant_id(socket, shift_params))
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"shift" => shift_params}, socket) do
    save_shift(socket, socket.assigns.action, with_tenant_id(socket, shift_params))
  end

  defp with_tenant_id(socket, shift_params) do
    user = socket.assigns.current_user
    Map.put(shift_params, "tenant_id", user.tenant_id)
  end

  defp save_shift(socket, :edit, shift_params) do
    case Shifts.update_shift(socket.assigns.shift, shift_params) do
      {:ok, shift} ->
        notify_parent({:saved, shift})

        {:noreply,
         socket
         |> put_flash(:info, "Shift updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_shift(socket, :new, shift_params) do
    case Shifts.create_shift(shift_params) do
      {:ok, shift} ->
        notify_parent({:saved, shift})

        {:noreply,
         socket
         |> put_flash(:info, "Shift created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
