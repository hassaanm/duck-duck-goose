defmodule Birds.DB.BirdTracker do
  @behaviour Birds.DB.Database

  @impl Birds.DB.Database
  def get(key) do
    # TODO: Talk to ETS database on bird_watcher service
    ""
  end

  @impl Birds.DB.Database
  def put(key, value, ttl) do
    # TODO: Talk to ETS database on bird_watcher service
    :ok
  end

  @impl Birds.DB.Database
  def put_new(key, value, ttl) do
    # TODO: Talk to ETS database on bird_watcher service
    :ok
  end
end
