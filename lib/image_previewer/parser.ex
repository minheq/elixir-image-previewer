defmodule ImagePreviewer.Parser do
  import Plug.Conn

  defmodule Exception do
    defexception plug_status: 400, message: "Oops"
  end
  @moduledoc """
  Provides a function `get_image/1` to get the best fit image preview from a url
  """

  @doc """
  returns an JSON object with meta information about the image

  ## Parameters

    - url: The URL to be used for getting the image

  ## Examples
      iex> ImagePreviewer.Parser.get_image("http://www.lazada.sg/")

  """
  # @spec get_image(String.t) :: 
  def get_preview(conn) do
    preview = conn.body_params["url"]
      |> find_tags_from_url
      |> get_preview_properties

    conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, Poison.encode!(%{preview: preview}))
  end
  
  defp find_tags_from_url(url) do
    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        # Get <title>, <img> and <meta> tags
        Floki.find(body, "title, meta, img")
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        raise message: "Not found", plug_status: 400
      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.puts reason
        raise message: reason, plug_status: 400
      _ ->
        raise Exception
    end
  end

  defp get_preview_properties(tags) do
    # Prioritize getting image, title, description from og attributes
    # performance and readibility. Opted for readibility for people reading the code
    # Find og tags first, if there are og tags, we return tags with og values

    # Prioritize getting images and meta information from :og
    case find_og_properties(tags) do
      {:og, filtered_tags} ->
        filtered_tags
          |> get_values_from_og_attributes
    # If og attributes not found, use standard <img> and <title>
      {:standard} -> get_values_from_standard_attr(tags)
      _ -> %{}
    end
  end

  def find_og_properties(tags) do
    lookup_og_value = ["og:title", "og:description", "og:image", "og:width", "og:height"]

    og_properties = tags
          # Get only items that has attributes "content" for <meta> tags or "src" for <img> tags
          |> Enum.filter(
            # Loop through all the tags we received
            fn tag ->
              # { tag_name, attributes, children_nodes }
              # Here we get attributes
              elem(tag, 1)
                # We are interested in tags with "og" attributes
                |> Enum.filter(&(Enum.member?(lookup_og_value, elem(&1, 1))))
                |> Enum.any?
            end
          )

    cond do
      Enum.any?(og_properties) -> {:og, og_properties}
      true -> {:standard}
    end
  end

  def get_values_from_standard_attr(tags) do
    lookup_standard_tags = ["title", "img"]

    filtered_tags = tags
                  # Filter out only <img> ang <title> tags
                  |> Enum.filter(&(Enum.member?(lookup_standard_tags, elem(&1, 0))))
      
    image_url = filtered_tags
                # Get only items that has non-empty "src" for <img> tags
                |> Enum.filter(
                  fn tag ->
                    # { tag_name, attributes, children_nodes }
                    elem(tag, 1)
                      # We look for <img> tags with non-empty src
                      |> Enum.filter(
                        fn attribute ->
                          case attribute do
                            {"src", ""} -> false
                            {"src", value} -> true
                            _ -> false
                          end
                        end
                      )
                      |> Enum.any?
                  end
                )
                # Get the first image
                |> List.first
                # Get the attributes list
                |> elem(1)
                # Filter out other attributes other that src
                |> Enum.filter(
                  fn attribute ->
                    case attribute do
                      {"src", ""} -> false
                      {"src", value} -> true
                      _ -> false
                    end
                  end
                )
                # Get the src attribute
                |> List.first
                # Get the image url
                |> elem(1)
      
    title = filtered_tags
            # Get the first tag which is by assumption a <title> tag
            |> List.first
            # Gets its array of children nodes
            |> elem(2)
            # Get the only child text which is the title
            |> List.first

    %{image_url: image_url, title: title}
  end

  @doc """
  Returns a Map with values extracted from meta tags with :og attributes
  returns %{title: String, image_url: String, description: String}

  """
  def get_values_from_og_attributes(tags) do
    tags
      |> Enum.map(
        # { tag_name, attributes, children_nodes }
        fn tag -> 
          # Here we get attributes
          attributes = elem(tag, 1)
                    # Filter out unwanted attributes, 
                    # except property and content
                    |> Enum.filter(&(
                      elem(&1, 0) == "property" 
                      || elem(&1, 0) == "content"))

          property = List.first(attributes)
          value = List.last(attributes)

          case property do
            {"property", "og:title"} ->
              {"title", elem(value, 1)}
            {"property", "og:image"} ->
              {"image_url", elem(value, 1)}
            {"property", "og:description"} ->
              {"description", elem(value, 1)}
          end
        end
      )
      |> Enum.into(%{})
  end
end
