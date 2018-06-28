defmodule Core.CouchDB do
  use GenServer, shutdown: 5000
  require Logger

  @mgmt_databases ["_users", "_replicator", "_global_changes"]
  @databases ["users", "transmitters", "rubrics", "cores"]

  def sync_with(node), do: GenServer.cast(__MODULE__, {:sync_with, node})
  def db(name), do: GenServer.call(__MODULE__, {:db, name})

  def start_link() do
    GenServer.start_link(__MODULE__, {}, [name: __MODULE__])
  end

  def init(args) do
    server = CouchDB.connect("couchdb", 5984, "http", "admin", "admin")
    Process.send_after(self(), :migrate, 5000)
    {:ok, server}
  end

  def handle_info(:migrate, server) do
    Logger.info("Creating CouchDB databases if necessary.")

    results = Enum.concat([@databases, @mgmt_databases])
    |> Enum.map(fn name ->
      database = server |> CouchDB.Server.database(name)
      CouchDB.Database.create database
    end)

    errors = results |> Enum.filter(&match?({:error, _}, &1))
    |> Enum.map(fn {:error, reason} -> reason end)
    |> Enum.map(&Poison.decode/1)
    |> Enum.filter(fn {_, error} -> Map.get(error, "error") != "file_exists" end)

    if !Enum.empty?(errors) do
      Logger.error("Can't connect to CouchDB.")
      Process.send_after(self(), :migrate, 10000)
    end

    {:noreply, server}
  end

  def handle_cast({:sync_with, node}, server) do
    Logger.info("Sync CouchDB with #{node}")

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

  def handle_call({:db, name}, _from, server) do
    {:reply, CouchDB.Server.database(server, name), server}
  end
end
