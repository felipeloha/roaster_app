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
alias RosterApp.Orgs.{Department, WorkType, UserDepartment, UserQualification}

# pass123
hashed = "$2b$12$n9WY8EkCGA6dR/ual5SyI.jt.xx5hqQZ.eBnU3BvDVQ8osKKJQ.vS"

_manager =
  Repo.insert!(%User{email: "manager@example.com", hashed_password: hashed, role: "manager"},
    on_conflict: [
      set: [
        hashed_password: hashed,
        role: "manager"
      ]
    ],
    conflict_target: :email
  )

worker =
  Repo.insert!(
    %User{
      email: "worker@example.com",
      hashed_password: "$2b$12$n9WY8EkCGA6dR/ual5SyI.jt.xx5hqQZ.eBnU3BvDVQ8osKKJQ.vS",
      role: "worker"
    },
    on_conflict: [
      set: [
        hashed_password: hashed,
        role: "manager"
      ]
    ],
    conflict_target: :email
  )

cleaning = Repo.insert!(%WorkType{name: "Cleaning"})
_security = Repo.insert!(%WorkType{name: "Security"})

maintenance = Repo.insert!(%Department{name: "Maintenance"})
_support = Repo.insert!(%Department{name: "Customer Support"})

Repo.insert!(%UserQualification{user_id: worker.id, work_type_id: cleaning.id})
Repo.insert!(%UserDepartment{user_id: worker.id, department_id: maintenance.id})
