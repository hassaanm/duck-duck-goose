defmodule BirdWatcherWeb.BirdWatcherLive do
  use BirdWatcherWeb, :live_view

  @title "👀 Bird Watcher"
  @port_key "port"
  @starting_port 5000

  @spec mount(_params :: any(), _session :: any(), socked :: map()) :: {:ok, map()}
  def mount(_params, _session, socket) do
    if connected?(socket), do: Phoenix.PubSub.subscribe(BirdWatcher.PubSub, "status_updates")

    socket =
      socket
      |> assign(:page_title, @title)
      |> assign(:statuses, BirdWatcher.Watcher.get_statuses())

    {:ok, socket}
  end

  @spec render(assigns :: any()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <button phx-click="add_bird" class="text-lg p-4 m-4 rounded-xl bg-amber-200">
      Add bird
    </button>
    <div class="flex flex-row flex-wrap justify-evenly content-evenly gap-4">
      <%= for {bird_url, %{"status" => bird_status, "type" => bird_type}} <- @statuses do %>
        <div class="p-8 border-2 rounded-lg flex flex-col items-center gap-4">
          <img class="rounded-full size-24" src={bird_image_path(bird_type) |> IO.inspect()} />
          <div>
            <div>
              <b>URL:</b> <%= bird_url %>
            </div>
            <div>
              <b>STATUS:</b> <%= bird_status %>
            </div>
            <div>
              <b>TYPE:</b> <%= bird_type %>
            </div>
          </div>
          <div class="text-sm flex flex-col gap-2">
            <button phx-click="shutdown" phx-value-url={bird_url} class="p-2 rounded-xl bg-rose-300">
              Shutdown
            </button>
            <button
              phx-click="terminate_network"
              phx-value-url={bird_url}
              class="p-2 rounded-xl bg-sky-300"
            >
              Terminate network
            </button>
            <button
              phx-click="fix_network"
              phx-value-url={bird_url}
              class="p-2 rounded-xl bg-emerald-300"
            >
              Fix network
            </button>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  #############
  # Callbacks #
  #############

  @spec handle_event(String.t(), map(), map()) :: {:noreply, map()}
  def handle_event("add_bird", _value, socket) do
    # Find a free port
    port = BirdWatcher.DB.get(@port_key) || @starting_port
    BirdWatcher.DB.put(@port_key, port + 1)

    # Kick off a bird node in the background
    Task.start(fn ->
      System.cmd("sh", ["-c", "mix run --no-halt &"],
        env: [{"PORT", "#{port}"}],
        cd: Path.expand("../birds")
      )
    end)

    {:noreply, socket}
  end

  @spec handle_event(String.t(), map(), map()) :: {:noreply, map()}
  def handle_event("shutdown", %{"url" => bird_url}, socket) do
    HTTPoison.post("#{bird_url}/shutdown", "")
    {:noreply, socket}
  end

  @spec handle_event(String.t(), map(), map()) :: {:noreply, map()}
  def handle_event("terminate_network", %{"url" => bird_url}, socket) do
    HTTPoison.post("#{bird_url}/terminate_network", "")
    {:noreply, socket}
  end

  @spec handle_event(String.t(), map(), map()) :: {:noreply, map()}
  def handle_event("fix_network", %{"url" => bird_url}, socket) do
    HTTPoison.post("#{bird_url}/fix_network", "")
    {:noreply, socket}
  end

  @spec handle_info({:update, any()}, any()) :: {:noreply, any()}
  def handle_info({:update, statuses}, socket) do
    {:noreply, assign(socket, statuses: statuses)}
  end

  ###################
  # Private helpers #
  ###################

  @spec bird_image_path(bird_type :: String.t()) :: String.t()
  defp bird_image_path(bird_type) do
    case bird_type do
      "goose" -> ~p"/images/goose.png"
      "duck" -> ~p"/images/duck.png"
      _ -> ~p"/images/unknown.png"
    end
  end
end
