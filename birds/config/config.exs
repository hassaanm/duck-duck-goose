import Config

config :birds,
  halt: true,
  take_leadership_frequency_ms: 1000

import_config "#{config_env()}.exs"
