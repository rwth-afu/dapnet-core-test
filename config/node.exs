use Mix.Config

config :core, Core,
  hostname: "example.ampr.org"

config :core, Core.Discovery,
  seed: %{
    "dapnetdc1.db0sda.ampr.org" => %{
      port: 80
    },
    "dapnetdc2.db0sda.ampr.org" => %{
      port: 80
    },
    "dapnetdc3.db0sda.ampr.org" => %{
      port: 80
    }
  }

import_config "/config/*.local.exs"
