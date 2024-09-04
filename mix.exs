defmodule IckyVenus.MixProject do
  use Mix.Project

  def project do
    [
      app: :icky_venus,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {IckyVenus.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:bandit, "~> 1.0"},
      {:websockex, "~> 0.4.3"},
      {:cbor, "~> 1.0.0"},
      {:websock_adapter, "~> 0.5.7"},
      {:number, "~> 1.0"}
    ]
  end
end
