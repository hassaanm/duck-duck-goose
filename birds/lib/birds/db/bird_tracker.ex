defmodule Birds.DB.BirdTracker do
  @behaviour Birds.DB.Database

  @base_url "localhost:4000/api/db"

  @impl Birds.DB.Database
  @spec get(key :: String.t()) :: any()
  def get(key) do
    url = "#{@base_url}/get?key=#{key}"
    resp = HTTPoison.get!(url)
    body = Jason.decode!(resp.body)
    Map.get(body, key)
  end

  @impl Birds.DB.Database
  @spec put(key :: String.t(), value :: any(), ttl :: integer() | nil) :: :ok
  def put(key, value, ttl) do
    url = "#{@base_url}/put"
    body = Jason.encode!(%{key: key, value: value, ttl: ttl})
    HTTPoison.post!(url, body, [{"Content-Type", "application/json"}])
    :ok
  end

  @impl Birds.DB.Database
  @spec put_new(key :: String.t(), value :: any(), ttl :: integer() | nil) :: :ok | :error
  def put_new(key, value, ttl) do
    url = "#{@base_url}/put_new"
    body = Jason.encode!(%{key: key, value: value, ttl: ttl})
    resp = HTTPoison.post!(url, body, [{"Content-Type", "application/json"}])

    if resp.status_code == 200 do
      :ok
    else
      :error
    end
  end
end
