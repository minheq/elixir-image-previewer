defmodule ImagePreviewer.Plug.ValidateRequest do
  @moduledoc """
  Error raised when a required "url" field is missing.
  Error raised when a required "url" is an invalid URL
  """

  defmodule MissingURLRequestError do
    defexception message: "You must provide a URL for image previewing", plug_status: 400
  end

  defmodule InvalidURLRequestError do
    defexception message: "The URL is malformed", plug_status: 400
  end

  def init(options), do: options

  def call(%Plug.Conn{request_path: path} = conn, opts) do
    if path in opts[:paths], do: validate_request!(conn.body_params, opts[:fields])
    conn
  end

  defp validate_request!(body_params, fields) do
    valid_input = body_params
               |> Map.keys
               |> contains_fields?(fields)
    unless valid_input, do: raise MissingURLRequestError
    
    valid_url = body_params["url"]
              |> valid_url?

    unless valid_url, do: raise InvalidURLRequestError
  end

  defp contains_fields?(keys, fields), do: Enum.all?(fields, &(&1 in keys))
  
  defp valid_url?(url) do
    uri = URI.parse(url)
    uri.scheme != nil && uri.host =~ "."
  end
end