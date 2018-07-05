defmodule Core.CallStorage do
  require Logger

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def insert(%{"id" => id} = call) do
    :ets.insert(:calls, {id, call})
  end

  def lookup(id) do
    case :ets.lookup(:calls, id) do
      {_, call} -> call
      _ -> nil
    end
  end

  def all do
    :ets.tab2list(:calls)
  end

  def init(_) do
    :ets.new(:calls, [:set, :named_table, :public, read_concurrency: true,
                      write_concurrency: true])
    schedule_sweep()
    {:ok, %{requests: %{}}}
  end

  def handle_info(:sweep, state) do
    Logger.info("Sweeping Call Database")
    schedule_sweep()
    {:noreply, state}
  end

  defp schedule_sweep do
    Process.send_after(self(), :sweep, 3600000)
  end
end
