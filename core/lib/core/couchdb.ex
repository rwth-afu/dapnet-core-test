defmodule Core.CouchDB do
  use GenServer
  require Logger

  @mgmt_databases ["_users", "_replicator", "_global_changes"]
  @databases ["users", "transmitters", "rubrics"]

  def start_link() do
    GenServer.start_link(__MODULE__, {}, [name: __MODULE__])
  end

  def init(args) do
    server = CouchDB.connect("couchdb", 5984, "http", "admin", "admin")
    GenServer.cast(__MODULE__, :migrate)
    {:ok, server}
  end

  def handle_cast(:migrate, server) do
    Enum.concat([@databases, @mgmt_databases])
    |> Enum.each(fn name ->
      database = server |> CouchDB.Server.database(name)
      CouchDB.Database.create database
    end)

    {:noreply, server}
  end

#  def handle_cast(:sync, server) do
#    %{name: local_db} = contacts
#
#    local_url = CouchDB.Server.url(server, "/#{local_db}")
#
#    remote_user = sync |> Map.get(:user)
#    remote_password = sync |> Map.get(:key)
#    remote_db = "user_" <> String.downcase(remote_user)
#    remote_url = "https://#{remote_user}:#{remote_password}"
#    <> "@cloudshack.org:6984/#{remote_db}"
#
#    options = [create_target: false, filter: "logbook/sync", continuous: true]
#    CouchDB.Server.replicate(server, local_url, remote_url, options)
#    |> inspect |> Logger.debug
#
#    # TODO: Enable other direction
#    # options = [filter: "logbook/sync"]
#    # CouchDB.Server.replicate server, remote_url, local_url, options
#
#    {:noreply, server}
#  end
end
