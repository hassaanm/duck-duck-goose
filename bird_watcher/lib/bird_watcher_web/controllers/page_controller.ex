defmodule BirdWatcherWeb.PageController do
  use BirdWatcherWeb, :controller

  def bird_watcher(conn, _params) do
    render(conn, :bird_watcher, layout: false)
  end
end
