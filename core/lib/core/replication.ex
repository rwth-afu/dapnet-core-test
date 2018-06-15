defmodule Core.Replication do
  use GenServer
  require Logger

  @databases ["users", "transmitters", "rubrics"]

  def start_link do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init(_opts) do
    Process.send_after(self(), :update, 1000)
    {:ok, nil}
  end

  def handle_info(:update, state) do
    nodes = Core.Discovery.nodes()

    Process.send_after(self(), :update, 60000)
    {:noreply, state}
  end
end
