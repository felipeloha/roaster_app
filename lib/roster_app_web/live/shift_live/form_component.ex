defmodule RosterAppWeb.ShiftLive.FormComponent do
  use RosterAppWeb, :live_component

  alias RosterApp.Shifts
  alias RosterApp.Orgs
  alias RosterApp.Repo

  @impl true
  def render(assigns) do
    assigned_user_options =
      if assigns.form[:assigned_user_id].value in [nil, ""] do
        [{"— Select —", ""} | Enum.map(assigns.users, &{&1.email, &1.id})]
      else
        Enum.map(assigns.users, &{&1.email, &1.id})
      end

    default_start_time =
      assigns.form[:start_time].value || NaiveDateTime.new!(Date.utc_today(), ~T[08:00:00])

    default_end_time =
      assigns.form[:end_time].value || NaiveDateTime.new!(Date.utc_today(), ~T[18:00:00])

    assigns =
      assigns
      |> assign(:assigned_user_options, assigned_user_options)
      |> assign(:default_start_time, default_start_time)
      |> assign(:default_end_time, default_end_time)
      |> assign(:is_worker, assigns.current_user.role == "worker")

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
        <.input field={@form[:description]} type="text" label="Description" disabled={@is_worker} />
        <.input
          type="select"
          field={@form[:work_type_id]}
          options={Enum.map(@work_types, &{&1.name, &1.id})}
          label="Work type"
          disabled={@is_worker}
        />
        <.input
          type="select"
          field={@form[:department_id]}
          options={Enum.map(@departments, &{&1.name, &1.id})}
          label="Department"
          disabled={@is_worker}
        />
        <.input
          field={@form[:start_time]}
          type="datetime-local"
          value={@default_start_time}
          label="Start time"
          disabled={@is_worker}
        />
        <.input
          field={@form[:end_time]}
          type="datetime-local"
          value={@default_end_time}
          label="End time"
          disabled={@is_worker}
        />
        <.input
          type="select"
          field={@form[:assigned_user_id]}
          options={@assigned_user_options}
          label="Assignee"
          disabled={@is_worker && @form[:assigned_user_id].value not in [nil, ""]}
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
    current_user = assigns.current_user
    changeset = Shifts.change_shift(shift)

    {work_types, departments, users} =
      case Map.get(assigns, :tenant_id, nil) do
        nil ->
          {[], [], []}

        tenant_id ->
          {
            Orgs.list_work_types(tenant_id),
            Orgs.list_departments(tenant_id),
            eligible_workers(shift, current_user)
          }
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:work_types, work_types)
     |> assign(:departments, departments)
     |> assign(:users, users)
     |> assign(:form, to_form(changeset))}
  end

  defp present?(value), do: not is_nil(value) and value != ""

  defp maybe_add_assigned_user(list, %{assigned_user_id: nil}), do: list
  defp maybe_add_assigned_user(list, %{assigned_user: user}), do: list ++ [user]
  defp maybe_add_assigned_user(list, _), do: list

  def eligible_workers(
        %{
          tenant_id: tenant_id,
          work_type_id: work_type_id,
          department_id: department_id,
          start_time: start_time,
          end_time: end_time
        } = shift,
        current_user
      ) do
    if present?(department_id) && present?(work_type_id) &&
         present?(start_time) && present?(end_time) &&
         present?(tenant_id) do
      %{
        tenant_id: tenant_id,
        work_type_id: work_type_id,
        department_id: department_id,
        start_time: start_time,
        end_time: end_time
      }
      |> Shifts.eligible_workers_for_shift()
      |> maybe_add_assigned_user(shift)
      # TODO this is a bit horrible but the time is up
      |> Enum.filter(fn user ->
        current_user.role == "manager" || user.id == current_user.id
      end)
      |> Enum.uniq()
    else
      []
    end
  end

  def eligible_workers(_) do
    []
  end

  @impl true
  def handle_event("validate", %{"shift" => shift_params}, socket) do
    tenant_id = socket.assigns.tenant_id

    changeset =
      shift_params
      |> Map.put("tenant_id", tenant_id)
      |> then(&Shifts.change_shift(socket.assigns.shift, &1))

    shift =
      changeset
      |> Ecto.Changeset.apply_changes()
      |> Map.put(:tenant_id, tenant_id)
      |> maybe_assign_user()

    users = eligible_workers(shift, socket.assigns.current_user)

    {:noreply,
     socket
     |> assign(:form, to_form(changeset, action: :validate))
     |> assign(:users, users)}
  end

  defp maybe_assign_user(%{assigned_user_id: nil} = shift), do: shift

  defp maybe_assign_user(%{assigned_user_id: user_id} = shift) do
    user = Repo.get!(RosterApp.Accounts.User, user_id)
    Map.put(shift, :assigned_user, user)
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
        shift = Repo.preload(shift, :assigned_user)
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
        shift = Repo.preload(shift, :assigned_user)
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
