defmodule ImagePreviewer.Mixfile do
  use Mix.Project

  def project do
    [app: :image_previewer,
     version: "0.1.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [
      applications: [:logger, :cowboy, :plug, :httpoison, :poison],
      mod: {ImagePreviewer.Application, []}
    ]
  end

  defp deps do
    [
      cowboy: "~> 1.0",
      plug: "~> 1.0",
      httpoison: "~> 0.11.1",
      floki: "~> 0.17.0",
      poison: "~> 3.0"
    ]
  end
end
