import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :bird_organizer, BirdOrganizerWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "I5aw6nXN5t0UmoZHV3/1CQ9tKKkwa4E5lHXcjmphlJoMtY1ufhBDdwNkXzcJshUj",
  server: false

# In test we don't send emails.
config :bird_organizer, BirdOrganizer.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

config :phoenix_live_view,
  # Enable helpful, but potentially expensive runtime checks
  enable_expensive_runtime_checks: true
