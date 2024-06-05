FROM elixir:1.16.3-otp-26

RUN mix local.hex --force && mix local.rebar --force