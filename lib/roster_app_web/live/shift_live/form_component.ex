defmodule RosterAppWeb.ShiftLive.FormComponent do
  use RosterAppWeb, :live_component

  alias RosterApp.Shifts
  alias RosterApp.Orgs

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
        <.input field={@form[:description]} type="text" label="Description" />
        <.input
          type="select"
          field={@form[:work_type_id]}
          options={Enum.map(@work_types, &{&1.name, &1.id})}
          label="Work type"
        />
        <.input
          type="select"
          field={@form[:department_id]}
          options={Enum.map(@departments, &{&1.name, &1.id})}
          label="Department"
        />
        <.input field={@form[:start_time]} type="datetime-local" label="Start time" />
        <.input field={@form[:end_time]} type="datetime-local" label="End time" />
        <.input
          type="select"
          field={@form[:assigned_user_id]}
          options={Enum.map(@users, &{&1.email, &1.id})}
          label="Assigned workforce"
        />
        <:actions>
          <.button phx-disable-with="Saving...">Save Shift</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{shift: shift} = assigns, socket) do
    {work_types, departments, users} =
      case Map.get(assigns, :tenant_id, nil) do
        nil ->
          {[], [], []}

        tenant_id ->
          {
            Orgs.list_work_types(tenant_id),
            Orgs.list_departments(tenant_id),
            eligible_workers(shift)
          }
      end

    changeset = Shifts.change_shift(shift)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:work_types, work_types)
     |> assign(:departments, departments)
     |> assign(:users, users)
     |> assign(:form, to_form(changeset))}
  end

  def present?(value), do: not is_nil(value) and value != ""

  def eligible_workers(%{
        tenant_id: tenant_id,
        work_type_id: work_type_id,
        department_id: department_id,
        start_time: start_time,
        end_time: end_time
      }) do
    if present?(department_id) && present?(work_type_id) &&
         present?(start_time) && present?(end_time) &&
         present?(tenant_id) do
      Shifts.eligible_workers_for_shift(%{
        tenant_id: tenant_id,
        work_type_id: work_type_id,
        department_id: department_id,
        start_time: start_time,
        end_time: end_time
      })
    else
      []
    end
  end

  def eligible_workers(_), do: []

  @impl true
  def handle_event("validate", %{"shift" => shift_params}, socket) do
    shift_params = Map.put(shift_params, "tenant_id", socket.assigns.tenant_id)
    changeset = Shifts.change_shift(socket.assigns.shift, shift_params)

    users =
      changeset.changes
      |> Map.put(:tenant_id, socket.assigns.tenant_id)
      |> eligible_workers()

    {
      :noreply,
      socket
      |> assign(form: to_form(changeset, action: :validate))
      |> assign(:users, users)
    }
  end

  def handle_event("save", %{"shift" => shift_params}, socket) do
    save_shift(
      socket,
      socket.assigns.action,
      Map.put(shift_params, "tenant_id", socket.assigns.tenant_id)
    )
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
