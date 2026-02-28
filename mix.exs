defmodule SendKit.MixProject do
  use Mix.Project

  @version "1.0.0"
  @source_url "https://github.com/sendkitdev/sendkit-elixir"

  def project do
    [
      app: :sendkit,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: "Official Elixir SDK for the SendKit email API",
      source_url: @source_url,
      docs: [main: "readme", extras: ["README.md"]]
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:req, "~> 0.5"},
      {:bypass, "~> 2.1", only: :test},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      name: "sendkit",
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      files: ~w(lib mix.exs README.md LICENSE)
    ]
  end
end
