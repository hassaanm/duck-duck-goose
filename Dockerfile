FROM elixir:1.17.1

RUN mix local.hex --force && mix local.rebar --force
