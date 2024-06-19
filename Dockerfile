FROM elixir:1.17.1

WORKDIR /app

RUN mix local.hex --force && mix local.rebar --force

COPY bird_watcher bird_watcher
COPY birds birds

WORKDIR /app/birds
RUN mix do deps.get, deps.compile, compile

WORKDIR /app/bird_watcher
RUN mix do deps.get, deps.compile, compile

EXPOSE 4000

CMD ["mix", "phx.server"]
