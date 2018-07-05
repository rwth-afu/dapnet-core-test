defmodule CoreWeb.TransmitterController do
  use CoreWeb, :controller

  def index(conn, _params) do
    {:ok, result} = Core.CouchDB.db("transmitters")
    |> CouchDB.Database.all_docs([include_docs: true])

    transmitters = result
    |> Poison.decode!
    |> Map.get("rows")
    |> Enum.map(fn(tx) ->
      Map.get(tx, "doc")
      |> Map.delete("auth_key")
    end)

    conn |> json(transmitters)
  end

  def show(conn, %{"id" => id}) do
    {:ok, result} = Core.CouchDB.db("transmitters")
    |> CouchDB.Database.get(id)

    transmitter = result
    |> Poison.decode!

    conn |> json(transmitter)
  end


  def create(conn, transmitter) do
    transmitter = Poison.encode!(transmitter)

    {:ok, result} = Core.CouchDB.db("transmitters")
    |> CouchDB.Database.insert(transmitter)

    transmitter = Poison.decode!(result)

    conn |> json(transmitter)
  end

  def bootstrap(conn, %{"callsign" => callsign, "auth_key" => auth_key}) do
    case transmitter_auth(callsign, auth_key) do
      {:ok, transmitter} ->
        nodes = Core.Discovery.nodes()
        timeslots = transmitter |> Map.get("timeslots", [])
        conn |> json(%{nodes: nodes, timeslots: timeslots})
      _ ->
        forbidden conn
    end
  end

  def heartbeat(conn, %{"callsign" => callsign, "auth_key" => auth_key}) do
    case transmitter_auth(callsign, auth_key) do
      {:ok, _transmitter} ->
        conn |> json(%{status: :ok})
      _ ->
        forbidden conn
    end
  end

  defp transmitter_auth(callsign, auth_key) do
    result = Core.CouchDB.db("transmitters")
    |> CouchDB.Database.get(String.downcase(callsign))

    case result do
      {:ok, data} ->
        transmitter = data |> Poison.decode!
        if transmitter |> Map.get("auth_key") == auth_key do
          {:ok, transmitter}
        else
          :noauth
        end
      _ ->
        :noauth
    end
  end

  defp forbidden(conn) do
    conn
    |> put_status(:forbidden)
    |> json(%{"error": "Forbidden."})
  end
end
