defmodule Birds.Router do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get "/status" do
    body = Birds.Bird.get_state()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(body))
  end

  post "/kill" do
    System.halt(0)
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
