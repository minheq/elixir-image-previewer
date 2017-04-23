defmodule ImagePreviewer.Router do
  use Plug.Router
  alias ImagePreviewer.Plug.ValidateRequest
  
  if Mix.env == :dev do
    use Plug.Debugger
  end
  use Plug.ErrorHandler

  plug Plug.Logger
  plug Plug.Parsers,      parsers: [:urlencoded, :multipart]
  plug ValidateRequest,   fields: ["url"],
                          paths:  ["/image-preview"]

  plug :match
  plug :dispatch

  post "/image-preview" do
    conn
    |> put_resp_content_type("application/json")
    |> ImagePreviewer.Parser.get_preview
  end

  match _ do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(404, Poison.encode!(%{error: true, message: "Not found"}))
  end

  def handle_errors(conn, %{kind: _kind, reason: _reason, stack: _stack}) do
    send_resp(conn, conn.status, "Something went wrong")
  end
end