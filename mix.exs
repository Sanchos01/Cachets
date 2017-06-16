defmodule Cachets.Mixfile do
  use Mix.Project

  def project do
    [app: :cachets,
     version: "0.2.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),

     # Coveralls
     test_coverage: [tool: ExCoveralls],
     preferred_cli_env: ["coveralls": :test, "coveralls.detail": :test, "coveralls.post": :test, "coveralls.html": :test],

     # Docs
     name: "Cachets",
     source_url: "https://github.com/Sanchos01/Cachets",
     docs: [main: "Cachets", # The main page in the docs
          extras: ["README.md"]]]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger, :runtime_tools],
     mod: {Cachets, [add_caches: []]}]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:exactor, "~> 2.2.3", warn_missing: false},
     {:ex_doc, "~> 0.14", only: :dev, runtime: false},
     {:excoveralls, "~> 0.6", only: :test}]
  end
end
