defmodule Birds.EnsureBirdIsOnline do
  import Plug.Conn

  @allowed_paths ["/fix_network"]

  def init(opts), do: opts

  def call(conn, _opts) do
    port = conn.port |> Integer.to_string() |> String.to_atom()
    is_bird_online = Birds.Bird.get_state(port).status == :online
    is_path_allowed = Enum.any?(@allowed_paths, fn path -> path == conn.request_path end)

    if is_bird_online or is_path_allowed do
      conn
    else
      conn
      |> send_resp(404, "Not Found")
      |> halt()
    end
  end
end
