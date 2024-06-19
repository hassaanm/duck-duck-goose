defmodule Birds.Router do
  use Plug.Router

  plug(Birds.EnsureBirdIsOnline)
  plug(:match)
  plug(:dispatch)

  get "/status" do
    port = conn.port
    state = Birds.Bird.get_state(port)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(state))
  end

  post "/shutdown" do
    port = conn.port
    Birds.Bird.shutdown(port)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, "success")
  end

  post "/terminate_network" do
    {:ok, body, conn} = Plug.Conn.read_body(conn)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, ~s({"message": "POST /that endpoint", "body": #{body}}))
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end
end
