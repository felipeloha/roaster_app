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

    assigns = assign(assigns, :assigned_user_options, assigned_user_options)

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
          options={@assigned_user_options}
          label="Assignee"
        />
        <div>Assgined{inspect(@form[:assigned_user_id].value)}</div>
        <div>opts{inspect(@assigned_user_options)}</div>
        <:actions>
          <.button phx-disable-with="Saving...">Save Shift</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{shift: shift} = assigns, socket) do
    changeset = Shifts.change_shift(shift)

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
        } = shift
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
    shift_params = Map.put(shift_params, "tenant_id", socket.assigns.tenant_id)
    changeset = Shifts.change_shift(socket.assigns.shift, shift_params)

    shift =
      changeset
      |> Ecto.Changeset.apply_changes()
      |> Map.put(:tenant_id, socket.assigns.tenant_id)

    users =
      shift
      |> case do
        %{assigned_user_id: nil} = shift ->
          shift

        %{assigned_user_id: user_id} = shift ->
          user = Repo.get!(RosterApp.Accounts.User, user_id)
          Map.put(shift, :assigned_user, user)
      end
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
