defmodule CoreWeb.Plugs.BasicAuth do
  import Plug.Conn
  @realm "Basic realm=\"Login\""

  def init(opts), do: opts

  def call(conn, _) do
    case get_req_header(conn, "authorization") do
      ["Basic " <> auth] -> verify(conn, auth)
      _                  -> conn
    end
  end

  defp verify(conn, auth) do
    case Base.decode64(auth)  do
      {:ok, auth} ->
        [username, password] = String.split(auth, ":")
        {:ok, user} = get_user(username)
        if check_password(password, Map.get(user, "password")) do
          Plug.Conn.assign(conn, :user, user)
        else
          unauthorized(conn)
        end
      _ -> unauthorized(conn)
    end
  end

  defp check_password(password, hash) do
    Comeonin.Bcrypt.checkpw(password, hash)
  end

  defp get_user(user) do
    db = Core.CouchDB.db("users")
    result = CouchDB.Database.get(db, String.downcase(user))

    case result do
      {:ok, data} ->
        Poison.decode(data)
      _ ->
        {:error, :not_found}
    end
  end

  defp unauthorized(conn) do
    conn
    |> put_resp_header("www-authenticate", @realm)
    |> send_resp(401, "unauthorized")
    |> halt()
  end
end
