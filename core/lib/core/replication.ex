defmodule Core.Replication do
  use GenServer
  require Logger

  @databases ["users", "transmitters", "rubrics"]

  def start_link do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init(_opts) do
    Process.send_after(self(), :update, 10000)
    {:ok, nil}
  end

  def handle_info(:update, state) do
    Core.Discovery.reachable_nodes()
    |> Enum.each(fn {node, _} -> Core.CouchDB.sync_with(node) end)

    Process.send_after(self(), :update, 60000)
    {:noreply, state}
  end
end
