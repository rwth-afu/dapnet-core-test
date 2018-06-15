defmodule Core.Discovery do
  use GenServer
  require Logger

  def nodes, do: GenServer.call(__MODULE__, :nodes)

  def start_link do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init(_opts) do
    Process.send_after(self(), :update, 1000)

    nodes = File.read!("/config/seed.json")
    |> Poison.decode!
    |> Enum.map(fn host -> {host, %{reachable: false}} end)
    |> Map.new

    Logger.info("Initial node list: #{inspect nodes}")

    {:ok, nodes}
  end

  def handle_info(:update, nodes) do
    Logger.info("Starting nokkde discovery.")

    nodes = Enum.map(nodes, fn {node, params} ->
      case HTTPoison.get(node <> "/api/discovery", [recv_timeout: 3000]) do
        {:ok, response} ->
          Logger.info("Reached #{node}!")
          {node, %{reachable: true}}
        _ ->
          Logger.warn("Could not reach #{node}!")
          {node, %{reachable: false}}
      end
    end) |> Map.new

    Logger.info("Finished node discovery.")

    Process.send_after(self(), :update, 60000)
    {:noreply, nodes}
  end

  def handle_call(:nodes, _from, nodes) do
    {:reply, nodes, nodes}
  end
end
