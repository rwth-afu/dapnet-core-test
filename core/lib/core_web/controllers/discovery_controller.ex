defmodule CoreWeb.DiscoveryController do
  use CoreWeb, :controller

  def index(conn, _params) do
    nodes = Core.Discovery.nodes()
    conn |> json(%{nodes: nodes})
  end
end
