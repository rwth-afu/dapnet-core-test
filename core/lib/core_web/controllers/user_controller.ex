defmodule CoreWeb.UserController do
  use CoreWeb, :controller

  plug :auth_required when action in [:index, :show]
  plug :admin_only when action in [:create]

  def index(conn, _params) do
    {:ok, result} = Core.CouchDB.db("users")
    |> CouchDB.Database.all_docs([include_docs: true])

    users = result
    |> Poison.decode!
    |> Map.get("rows")
    |> Enum.map(fn(tx) ->
      Map.get(tx, "doc")
      |> Map.delete("password")
    end)

    conn |> json(users)
  end

  def create(conn, params) do
    conn
  end

  def update(conn, params) do
    conn
  end

  def show(conn, %{"id" => id}) do
    {:ok, result} = CouchDB.Database.get(db, String.downcase(id))
    user = Poison.decode!(result) |> Map.delete("password")
    conn |> json(user)
  end

  defp db() do
    Core.CouchDB.db("users")
  end

  defp hashed_password(password) do
    Comeonin.Bcrypt.hashpwsalt(password)
  end
end
