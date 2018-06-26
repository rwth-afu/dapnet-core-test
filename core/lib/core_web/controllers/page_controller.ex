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

  def sendcall(conn, params) do
    address = Map.get(params, "address")
    message = Map.get(params, "message")
    transmitter = Map.get(params, "transmitter")

    data = %{
          address: address,
          message: message,
          transmitter: transmitter}

    Core.RabbitMQ.publish_call(data)

    conn |> redirect(to: "/") |> halt()
  end
end
