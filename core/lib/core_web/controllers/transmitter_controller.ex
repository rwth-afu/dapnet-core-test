defmodule CoreWeb.TransmitterController do
  use CoreWeb, :controller

  def bootstrap(conn, params) do
    case auth(Map.get(params, "callsign"), Map.get(params, "auth_key")) do
      {:ok, transmitter} ->
        nodes = Core.Discovery.nodes()
        timeslots = transmitter |> Map.get("timeslots", [])
        conn |> json(%{nodes: nodes, timeslots: timeslots})
      _ ->
        send_forbidden conn
    end
  end

  def heartbeat(conn, params) do
    case auth(Map.get(params, "callsign"), Map.get(params, "auth_key")) do
      {:ok, transmitter} ->
        conn |> json(%{status: :ok})
      _ ->
        send_forbidden conn
    end
  end

  defp auth(callsign, auth_key) do
    db = Core.CouchDB.db("transmitters")
    result = CouchDB.Database.get(db, String.downcase(callsign))

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

  defp send_forbidden(conn) do
    conn
    |> put_status(:forbidden)
    |> json(%{"error": "Forbidden."})
  end
end
