defmodule BirdWatcherWeb.DBController do
  use BirdWatcherWeb, :controller

  def get(conn, %{"key" => key}) do
    value = BirdWatcher.DB.get(key)
    json(conn, %{key: value})
  end

  def put(conn, %{"key" => key, "value" => value, "ttl" => ttl}) do
    ttl_s = ttl |> String.to_integer()
    BirdWatcher.DB.put(key, value, ttl_s)
    json(conn, "success")
  end

  def put_new(conn, %{"key" => key, "value" => value, "ttl" => ttl}) do
    ttl_s = ttl |> String.to_integer()

    case BirdWatcher.DB.put_new(key, value, ttl_s) do
      :ok ->
        json(conn, "success")

      :error ->
        json(conn, "failure")
    end
  end
end
