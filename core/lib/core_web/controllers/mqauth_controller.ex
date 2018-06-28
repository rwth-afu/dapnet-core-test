defmodule CoreWeb.MqAuthController do
  use CoreWeb, :controller

  def user(conn, params) do
    user = Map.get(params, "username")
    pass = Map.get(params, "password")

    case user do
      "core-" <> core_id ->
        db = Core.CouchDB.db("cores")
        {:ok, result} = CouchDB.Database.get(db, core_id)
        auth_key = result |> Poison.decode! |> Map.get("auth_key")

        if pass == auth_key do
          send_resp(conn, 200, "allow administrator")
        else
          send_resp(conn, 200, "deny")
        end
      "tx-" <> tx_id ->
        db = Core.CouchDB.db("transmitters")
        {:ok, result} = CouchDB.Database.get(db, tx_id)
        auth_key = result |> Poison.decode! |> Map.get("auth_key")

        if pass == auth_key do
          send_resp(conn, 200, "allow")
        else
          send_resp(conn, 200, "deny")
        end
      _ -> send_resp(conn, 200, "deny")
    end
  end

  def vhost(conn, params) do
    user = Map.get(params, "username")

    case user do
      "core" -> send_resp(conn, 200, "allow")
      _ -> send_resp(conn, 200, "allow")
    end
  end

  def resource(conn, params) do
    user = Map.get(params, "username")

    case user do
      "core" -> send_resp(conn, 200, "allow")
      _ -> send_resp(conn, 200, "allow")
    end
  end

  def topic(conn, params) do
    user = Map.get(params, "username")

    case user do
      "core" -> send_resp(conn, 200, "allow")
      _ -> send_resp(conn, 200, "allow")
    end
  end
end
