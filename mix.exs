defmodule ElixirAgi.Mixfile do
  use Mix.Project

  def project do
    [
      name: "elixir_agi",
      elixir: "~> 1.0",
      description: description,
      package: package,
      source_url: "https://github.com/marcelog/elixir_ami",
      app: :elixir_agi,
      version: "0.0.9",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps
    ]
  end

  def application do
    [
      applications: [:logger],
      mod: {ElixirAgi, []}
    ]
  end

  defp description do
    """
Elixir client for the Asterisk AGI protocol.

Find the user guide in the github repo at: https://github.com/marcelog/elixir_agi.
    """
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README*", "LICENSE*", "examples"],
      maintainers: ["Marcelo Gornstein"],
      licenses: ["Apache 2.0"],
      links: %{
        "GitHub" => "https://github.com/marcelog/elixir_agi"
      }
    ]
  end

  defp deps do
    [
      {:earmark, "~> 0.1", only: :dev},
      {:ex_doc, "~> 0.12.0", only: :dev},
    ]
  end
end
