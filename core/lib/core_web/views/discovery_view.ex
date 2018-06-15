defmodule CoreWeb.DiscoveryView do
  use CoreWeb, :view

  def render("index.json", %{nodes: nodes}) do
    nodes
  end
end
