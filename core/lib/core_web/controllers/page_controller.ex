defmodule CoreWeb.PageController do
  use CoreWeb, :controller

  def index(conn, _params) do
    db = Core.CouchDB.db("transmitters")
    {:ok, result} = CouchDB.Database.all_docs(db, include_docs: true)
    result = result |> Poison.decode!
    render conn, "index.html", transmitters: Map.get(result, "rows")
  end

  def save(conn, params) do
    db = Core.CouchDB.db("transmitters")

    call = Map.get(params, "call")
    body = Poison.encode!(%{call: call})

    {:ok, _} = CouchDB.Database.insert(db, body)

    conn |> redirect(to: "/") |> halt()
  end
end
