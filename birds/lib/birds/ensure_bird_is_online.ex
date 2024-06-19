defmodule Birds.EnsureBirdIsOnline do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    port = conn.port |> Integer.to_string() |> String.to_atom()
    bird_state = Birds.Bird.get_state(port)

    if bird_state.status == :online do
      conn
    else
      conn
      |> send_resp(404, "Not Found")
      |> halt()
    end
  end
end
