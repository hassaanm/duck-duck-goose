import Config

config :birds, port: String.to_integer(System.get_env("PORT", "4001"))
