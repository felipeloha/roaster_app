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
  @moduledoc """
  Script for populating the database with test data.
  It creates:
  - Two tenants: `"Test-Tenant"` and `"Next-Tenant"`.
  - For each tenant, 1 manager and 2 worker users (worker and worker_security) are generated.
  - Two work types are created for each tenant: Cleaning and Security
  - Two departments are created for each tenant: Maintenance, Customer Support
  - The Manager is assigned both qualifications and departments.
  - Worker is assigned:
   - Qualifications: **Cleaning**
   - Department: **Maintenance**
  - Worker Security:
   - Qualifications: **Security**
   - Department: **Customer Support**

  The credentials are the following for tenant_id in [1,2]:
  - email: `manager_<tenant_id>@example.com` with password `pass123`
  - email: `worker_<tenant_id>@example.com` with password `pass123`
  - email: `worker_security_<tenant_id>@example.com` with password `pass123`
  """

  # pass123
  @hashed "$2b$12$n9WY8EkCGA6dR/ual5SyI.jt.xx5hqQZ.eBnU3BvDVQ8osKKJQ.vS"

  @doc """
  This function builds data for a tenant. It creates a manager and a worker user,
    With work type and department associations.
  """
  def build_data_for_tenant(tenant) do
    manager =
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

    worker_security =
      Repo.insert!(
        %User{
          email: "worker_security_#{tenant.id}@example.com",
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
    security = Repo.insert!(%WorkType{name: "#{tenant.name} Security", tenant_id: tenant.id})

    maintenance =
      Repo.insert!(%Department{name: "#{tenant.name} Maintenance", tenant_id: tenant.id})

    support =
      Repo.insert!(%Department{name: "#{tenant.name} Customer Support", tenant_id: tenant.id})

    # the manager has both qualifications and departments
    Repo.insert!(%UserQualification{user_id: manager.id, work_type_id: cleaning.id})
    Repo.insert!(%UserQualification{user_id: manager.id, work_type_id: security.id})
    Repo.insert!(%UserDepartment{user_id: manager.id, department_id: maintenance.id})
    Repo.insert!(%UserDepartment{user_id: manager.id, department_id: support.id})

    # each worker has one qualification and one department
    Repo.insert!(%UserQualification{user_id: worker.id, work_type_id: cleaning.id})
    Repo.insert!(%UserDepartment{user_id: worker.id, department_id: maintenance.id})

    Repo.insert!(%UserQualification{user_id: worker_security.id, work_type_id: security.id})
    Repo.insert!(%UserDepartment{user_id: worker_security.id, department_id: support.id})
  end
end

# insert tenants
tenant = Repo.insert!(%Tenant{name: "Test-Tenant"})
next_tenant = Repo.insert!(%Tenant{name: "Next-Tenant"})

RosterApp.Seed.build_data_for_tenant(tenant)
RosterApp.Seed.build_data_for_tenant(next_tenant)
