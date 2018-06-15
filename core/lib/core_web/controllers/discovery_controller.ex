defmodule CoreWeb.DiscoveryController do
  use CoreWeb, :controller

  def index(conn, _params) do
    nodes = Core.Discovery.nodes()
    send_resp(conn, 200, Poison.encode!(nodes))
  end
end
