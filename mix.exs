defmodule Enchufeweb.Mixfile do
  use Mix.Project

  @version "0.2.1"
  
  def project do
    [
      app: :enchufeweb,
      version: @version,
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps(),
      package: package(),
      description: "Websocket Library written in Elixir",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      docs: [main: "Enchufeweb", source_ref: "v#{@version}",
      source_url: "https://github.com/mendrugory/enchufeweb"]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:websocket_client, "1.3.0"},
      {:earmark, ">= 0.0.0", only: :dev},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:poison, ">= 0.0.0", only: :test}, # it should only be for test
      {:cowboy, github: "ninenines/cowboy", tag: "2.0.0-pre.3", only: :test} # only for testing
    ]
  end

  defp package() do
    %{licenses: ["MIT"],
    maintainers: ["Gonzalo Jiménez Fuentes"],
    links: %{"GitHub" => "https://github.com/mendrugory/enchufeweb"}}
  end
end
