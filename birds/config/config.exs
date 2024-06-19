import Config

config :birds,
  port: String.to_integer(System.get_env("PORT", "4001")),
  halt: true,
  take_leadership_frequency_ms: 1000

import_config "#{config_env()}.exs"
