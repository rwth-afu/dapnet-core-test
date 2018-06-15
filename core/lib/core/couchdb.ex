defmodule Core.CouchDB do
  use GenServer
  require Logger

  @mgmt_databases ["_users", "_replicator", "_global_changes"]
  @databases ["users", "transmitters", "rubrics"]

  def sync_with(node), do: GenServer.cast(__MODULE__, {:sync_with, node})

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

  def handle_cast({:sync_with, node}, server) do
    Logger.info("sync couchdb with #{node}")

    @databases
    |> Enum.each(fn db ->
      local_url = CouchDB.Server.url(server, "/#{db}")
      remote_url = "http://admin:admin@#{node}:5984/#{db}"

      options = [create_target: false, continuous: true]

      result = CouchDB.Server.replicate(server, remote_url, local_url, options)

      Logger.debug "Replication status: #{inspect result}"
    end)

    {:noreply, server}
  end
end
