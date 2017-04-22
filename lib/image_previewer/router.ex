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

  get "/",                do: send_resp(conn, 200, "Default")
  post "/image-preview",  do: ImagePreviewer.Parser.get_preview(conn)
  match _,                do: send_resp(conn, 404, "Oops")

  def handle_errors(conn, %{kind: _kind, reason: _reason, stack: _stack}) do
    send_resp(conn, conn.status, "Something went wrong")
  end
end