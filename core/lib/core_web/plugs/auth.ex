defmodule CoreWeb.Plugs.Auth do
  import Plug.Conn
  import Phoenix.Controller

  def auth_required(conn, _) do
    if conn.assigns[:user] do
      conn
    else
      conn |> forbidden
    end
  end

  def admin_only(conn, _) do
    user = conn.assigns[:user]
    if user and user.admin do
      conn
    else
      conn |> forbidden
    end
  end

  defp forbidden(conn) do
    conn
    |> send_resp(403, "Forbidden")
    |> halt()
  end
end
