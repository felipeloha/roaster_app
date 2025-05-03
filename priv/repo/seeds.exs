# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     RosterApp.Repo.insert!(%RosterApp.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias RosterApp.Repo
alias RosterApp.Accounts.User
alias RosterApp.Tenants.Tenant
alias RosterApp.Orgs.{Department, WorkType, UserDepartment, UserQualification}

defmodule RosterApp.Seed do
  # pass123
  @hashed "$2b$12$n9WY8EkCGA6dR/ual5SyI.jt.xx5hqQZ.eBnU3BvDVQ8osKKJQ.vS"

  @doc """
  This function builds data for a tenant. It creates a manager and a worker user,
    With work type and department associations.
  """
  def build_data_for_tenant(tenant) do
    _manager =
      Repo.insert!(
        %User{
          email: "manager_#{tenant.id}@example.com",
          hashed_password: @hashed,
          role: "manager",
          tenant_id: tenant.id
        },
        on_conflict: [
          set: [
            hashed_password: @hashed,
            role: "manager"
          ]
        ],
        conflict_target: :email
      )

    worker =
      Repo.insert!(
        %User{
          email: "worker_#{tenant.id}@example.com",
          hashed_password: @hashed,
          role: "worker",
          tenant_id: tenant.id
        },
        on_conflict: [
          set: [
            hashed_password: @hashed,
            role: "manager"
          ]
        ],
        conflict_target: :email
      )

    cleaning = Repo.insert!(%WorkType{name: "#{tenant.name} Cleaning", tenant_id: tenant.id})
    _security = Repo.insert!(%WorkType{name: "#{tenant.name} Security", tenant_id: tenant.id})

    maintenance =
      Repo.insert!(%Department{name: "#{tenant.name} Maintenance", tenant_id: tenant.id})

    _support =
      Repo.insert!(%Department{name: "#{tenant.name} Customer Support", tenant_id: tenant.id})

    Repo.insert!(%UserQualification{user_id: worker.id, work_type_id: cleaning.id})
    Repo.insert!(%UserDepartment{user_id: worker.id, department_id: maintenance.id})
  end
end

# insert tenants
tenant = Repo.insert!(%Tenant{name: "Test-Tenant"})
next_tenant = Repo.insert!(%Tenant{name: "Next-Tenant"})

RosterApp.Seed.build_data_for_tenant(tenant)
RosterApp.Seed.build_data_for_tenant(next_tenant)
