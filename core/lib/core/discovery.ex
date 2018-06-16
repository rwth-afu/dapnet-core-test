defmodule Core.Discovery do
  use GenServer
  require Logger

  def nodes, do: GenServer.call(__MODULE__, :nodes)
  def reachable_nodes, do: GenServer.call(__MODULE__, :reachable_nodes)

  def start_link do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init(_opts) do
    Process.send_after(self(), :update, 1000)

    nodes = Application.get_env(:core, __MODULE__)[:seed]
    |> Enum.map(fn {node, params} -> {node,
         Map.merge(params, %{last_seen: nil, reachable: false})}
       end)
    |> Map.new

    Logger.info("Initial node list: #{inspect nodes}")

    {:ok, nodes}
  end

  def handle_info(:update, nodes) do
    Logger.info("Starting node discovery.")

    Enum.map(nodes, fn {node, params} ->
      task = Task.async(fn ->
      case HTTPoison.get("#{node}:#{params.port}/api/discovery", [
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

  def handle_call(:reachable_nodes, _from, nodes) do
    hostname = Application.get_env(:core, Core)[:hostname]

    reachable_nodes = nodes
    |> Enum.filter(fn {node, _} -> node != hostname end)
    |> Enum.filter(fn {_, params} -> Map.get(params, :reachable) end)

    {:reply, reachable_nodes, nodes}
  end
end
