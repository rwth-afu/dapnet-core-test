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
    auth_key = Map.get(params, "auth_key")
    body = Poison.encode!(%{_id: call, auth_key: auth_key})

    {:ok, _} = CouchDB.Database.insert(db, body)

    conn |> redirect(to: "/") |> halt()
  end

  def sendcall(conn, params) do
    address = Map.get(params, "address")
    message = Map.get(params, "message")
    transmitter = Map.get(params, "transmitter")

    hostname = Application.get_env(:core, Core)[:hostname]
    id = UUID.uuid5(:dns, hostname)

    data = %{
      id: id,
      mtype: "AlphaNum",
      speed: 1200,
      addr: address,
      func: 3,
      data: message
    }

    Core.RabbitMQ.publish_call(transmitter, data)

    conn |> redirect(to: "/") |> halt()
  end
end
