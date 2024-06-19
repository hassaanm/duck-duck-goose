# duck-duck-goose

## Walkthrough
Click below to watch the video walkthrough on youtube. For some reason, my screen recorder didn't pick up the mouse properly, so some parts seem confusing. However, it should be enough to get the overall picture.
[![IMAGE ALT TEXT HERE](https://img.youtube.com/vi/d4Fao7std-s/0.jpg)](https://www.youtube.com/watch?v=d4Fao7std-s)

## How to run applications

### Docker (easiest)
1. Install docker on your machine.
2. Navigate to the main folder: `cd duck-duck-goose`. You should see a Dockerfile.
3. Build the docker image: `docker build -t duck-duck-goose .`.
4. Run the docker image: `docker run --network="host" --name=ducky duck-duck-goose`.
Note: that we're just running the dev version of the applications locally, so exposing all network ports is fine.
5. Open the phoenix application on a browser to easily view bird nodes: `localhost:4000`.
8. Create bird nodes either by clicking the "Add bird" button or manually: `docker exec -it ducky sh -c "cd /app/birds && PORT=4001 mix run --no-halt"`.
Note: that you'll have to manually manage the ports to avoid reusing them.

### Manually
1. Install elixir 1.17.1 and mix.
2. Navigate to the bird_watcher application: `cd duck-duck-goose/bird_watcher`.
3. Fetch dependencies and compile: `mix do deps.get, deps.compile, compile`.
4. Start the phoenix application: `mix phx.server`.
5. Open the phoenix application on a browser to easily view bird nodes: `localhost:4000`.
6. Navigate to the birds application: `cd ../birds`.
7. Fetch dependencies and compile: `mix do deps.get, deps.compile, compile`.
8. Create bird nodes either by clicking the "Add bird" button or manually: `PORT=4001 mix run --no-halt`.
Note: that you'll have to manually manage the ports to avoid reusing them.

## How to run tests

The birds application has basic tests in the `/birds/tests/birds_test.exs` file.

1. Navigate to the birds application: `cd birds`.
2. Run tests: `mix test`
