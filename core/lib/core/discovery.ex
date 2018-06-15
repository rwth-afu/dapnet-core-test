defmodule Core.Discovery do
  use GenServer
  require Logger

  @behaviour :gen_event

  def nodes, do: GenServer.call(__MODULE__, :nodes)

  def start_link do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init(_opts) do
    Process.send_after(self(), :update, 1000)

    nodes = File.read!("/config/seed.json")
    |> Poison.decode!
    |> Enum.map(fn host -> {host, %{reachable: false, last_seen: nil}} end)
    |> Map.new

    Logger.info("Initial node list: #{inspect nodes}")

    {:ok, nodes}
  end

  def handle_info(:update, nodes) do
    Logger.info("Starting node discovery.")

    Enum.map(nodes, fn {node, params} ->
      task = Task.async(fn ->
      case HTTPoison.get(node <> "/api/discovery", [
          recv_timeout: 3000,
          timeout: 3000
        ]) do
          {:ok, response} ->
            Logger.info("Reached #{node}!")
            {node, %{params | reachable: true, last_seen: Timex.now()}}
          _ ->
            Logger.warn("Could not reach #{node}!")
            {node, %{params | reachable: false}}
        end
      end)
    end)

    Process.send_after(self(), :update, 60000)
    {:noreply, nodes}
  end

  def handle_info({ref, result}, nodes) when is_reference(ref) do
    {node, params} = result
    nodes = Map.put(nodes, node, params)
    {:noreply, nodes}
  end

  def handle_info({:DOWN, ref, proc, pid, shutdown}, nodes) when is_reference(ref) do
    {:noreply, nodes}
  end

  def handle_call(:nodes, _from, nodes) do
    {:reply, nodes, nodes}
  end
end
