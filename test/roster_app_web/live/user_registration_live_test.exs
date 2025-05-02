defmodule RosterAppWeb.UserRegistrationLiveTest do
  use RosterAppWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import RosterApp.AccountsFixtures

  describe "Registration page" do
    test "fails if user not logged in", %{conn: conn} do
      assert {:error,
              {:redirect,
               %{to: "/users/log_in", flash: %{"error" => "You must log in to access this page."}}}} =
               live(conn, ~p"/users/register")
    end

    test "redirects if already logged in", %{conn: conn} do
      result =
        conn
        |> log_in_user(user_fixture())
        |> live(~p"/users/register")

      assert {:ok, _view, _html} = result
    end

    test "renders errors for invalid data", %{conn: conn} do
      user = user_fixture(%{role: "manager"})
      conn = log_in_user(conn, user)
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      result =
        lv
        |> element("#registration_form")
        |> render_change(user: %{"email" => "with spaces", "password" => "too short"})

      assert result =~ "Register"
      assert result =~ "must have the @ sign and no spaces"
      assert result =~ "should be at least 12 character"
    end
  end

  describe "register user" do
    test "creates account and logs the user in", %{conn: conn} do
      user = user_fixture(%{role: "manager"})
      conn = log_in_user(conn, user)
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      form =
        form(lv, "#registration_form",
          user: %{
            email: unique_user_email(),
            password: valid_user_password()
          }
        )

      render_submit(form)
      conn = follow_trigger_action(form, conn)

      assert redirected_to(conn) == ~p"/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, "/shifts")
      response = html_response(conn, 200)
      assert response =~ "Settings"
      assert response =~ "Log out"
    end

    test "renders errors for duplicated email", %{conn: conn} do
      user = user_fixture(%{role: "manager"})
      conn = log_in_user(conn, user)
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      user = user_fixture(%{email: "test@email.com"})

      result =
        lv
        |> form("#registration_form",
          user: %{"email" => user.email, "password" => "valid_password"}
        )
        |> render_submit()

      assert result =~ "has already been taken"
    end
  end
end
