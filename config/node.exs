use Mix.Config

config :core, Core,
  hostname: "example.ampr.org"

config :core, Core.Discovery,
  seed: %{
    "dapnetdc1.db0sda.ampr.org": %{
      port: 4000
    },
    "dapnetdc2.db0sda.ampr.org": %{
      port: 4000
    },
    "dapnetdc3.db0sda.ampr.org": %{
      port: 4000
    }
  }

import_config "/config/*.local.exs"
