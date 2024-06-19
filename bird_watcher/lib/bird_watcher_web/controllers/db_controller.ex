defmodule BirdWatcherWeb.DBController do
  use BirdWatcherWeb, :controller

  @spec get(conn :: Plug.Conn.t(), map()) :: Plug.Conn.t()
  def get(conn, %{"key" => key}) do
    value = BirdWatcher.DB.get("#{key}")
    json(conn, %{key => value})
  end

  @spec put(conn :: Plug.Conn.t(), map()) :: Plug.Conn.t()
  def put(conn, %{"key" => key, "value" => value, "ttl" => ttl}) do
    BirdWatcher.DB.put("#{key}", value, ttl)
    json(conn, "success")
  end

  @spec put_new(conn :: Plug.Conn.t(), map()) :: Plug.Conn.t()
  def put_new(conn, %{"key" => key, "value" => value, "ttl" => ttl}) do
    case BirdWatcher.DB.put_new("#{key}", value, ttl) do
      :ok ->
        json(conn, "success")

      :error ->
        conn
        |> put_status(:bad_request)
        |> json("failure")
    end
  end
end
