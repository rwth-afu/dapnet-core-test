defmodule CoreWeb.CallController do
  use CoreWeb, :controller

  plug :auth_required

  def index(conn, _params) do
    calls = Core.CallStorage.all()
    |> Enum.map(fn ({_id, call}) -> call end)

    conn |> json(calls)
  end

  def create(conn, params) do
    Core.CallStorage.insert(params)
    conn
  end
end
