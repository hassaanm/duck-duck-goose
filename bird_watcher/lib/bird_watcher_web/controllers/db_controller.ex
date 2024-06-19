defmodule BirdWatcherWeb.DBController do
  use BirdWatcherWeb, :controller

  def get(conn, %{"key" => key}) do
    value = BirdWatcher.DB.get(key)
    json(conn, %{key: value})
  end

  def put(conn, %{"key" => key, "value" => value, "ttl" => ttl}) do
    BirdWatcher.DB.put(key, value, ttl)
    json(conn, "success")
  end

  def put_new(conn, %{"key" => key, "value" => value, "ttl" => ttl}) do
    case BirdWatcher.DB.put_new(key, value, ttl) do
      :ok ->
        json(conn, "success")

      :error ->
        conn
        |> put_status(:bad_request)
        |> json("failure")
    end
  end
end
