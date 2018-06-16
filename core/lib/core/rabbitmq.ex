defmodule Core.RabbitMQ do
  use GenServer
  use AMQP
  require Logger

  def start_link do
    GenServer.start_link(__MODULE__, [], [])
  end

  @exchanges ["calls", "telemetry"]

  def init(_opts) do
    Process.send_after(self(), :connect, 5000)
    {:ok, nil}
  end

  def handle_info(:connect, state) do
    case Connection.open("amqp://guest:guest@rabbitmq") do
      {:ok, conn} ->
        Logger.info("Connection to RabbitMQ successful.")

        {:ok, chan} = Channel.open(conn)

        Enum.each(@exchanges, fn exchange ->
          Logger.info("Creating #{exchange} exchange.")
          :ok = Exchange.fanout(chan, exchange, durable: true)
        end)

        Process.send_after(self(), :shovel, 5000)

        {:noreply, chan}
      _ ->
        Logger.error("Could not connect to RabbitMQ.")
        Process.send_after(self(), :connect, 5000)
        {:noreply, nil}
    end
  end

  def handle_info(:shovel, state) do
    Core.Discovery.reachable_nodes() |> Enum.each(fn {node, _} ->
      Enum.each(@exchanges, fn exchange ->
        case shovel_get(node, exchange) do
          {:ok, %HTTPoison.Response{status_code: 200}} ->
            Logger.debug("Shovel #{node}-#{exchange} exists.")
          {:ok, %HTTPoison.Response{status_code: 404}} ->
            case shovel_create(node, exchange) do
              {:ok, _} -> Logger.info("Creating shovel #{node}-#{exchange}.")
              _ -> Logger.error("Failed to create shovel #{node}-#{exchange}.")
            end
          {:error, %HTTPoison.Error{reason: reason}} ->
            Logger.error("Failed to query shovel #{node}-#{exchange}.")
        end
      end)
    end)

    Process.send_after(self(), :shovel, 60000)
    {:noreply, state}
  end

  def shovel_create(node, exchange) do
    url = "http://rabbitmq:15672/api/parameters/shovel/%2f/#{node}-#{exchange}"
    params = %{value: %{"src-protocol": "amqp091",
                        "src-uri":  "amqp://",
                        "src-exchange":  exchange,
                        "dest-protocol": "amqp091",
                        "dest-uri": "amqp://guest:guest@#{node}",
                        "dest-exchange": exchange
                       }} |> Poison.encode!

    options = [hackney: [basic_auth: {"guest", "guest"}]]
    HTTPoison.put(url, params, [], options)
  end

  def shovel_delete(node, exchange) do
    url = "http://rabbitmq:15672/api/parameters/shovel/%2f/#{node}-#{exchange}"
    options = [hackney: [basic_auth: {"guest", "guest"}]]
    HTTPoison.delete(url, [], options)
  end

  def shovel_get(node, exchange) do
    url = "http://rabbitmq:15672/api/parameters/shovel/%2f/#{node}-#{exchange}"
    options = [hackney: [basic_auth: {"guest", "guest"}]]
    HTTPoison.get(url, [], options)
  end
end
