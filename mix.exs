defmodule Go.Mixfile do
  use Mix.Project

  def project do
    [app: :elixir_go,
     version: "0.4.3",
     elixir: "~> 1.4",
     dialyzer: [plt_add_deps: :transitive],
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     erlc_paths: ["src"],
     description: description(),
     package: package(),
     deps: deps(),

     # Docs
     name: "Go",
     source_url: "https://github.com/kokolegorille/go",
     homepage_url: "https://github.com/kokolegorille/go",
     # docs: [main: "Go", # The main page in the docs
     #        #logo: "path/to/logo.png",
     #        extras: ["README.md"]]
   ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger]]
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
    [
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.22.1", only: :dev, runtime: false},
      {:credo, "~> 1.4", only: [:dev], runtime: false},
    ]
  end

  defp description do
    """
    Elixir struct for playing the game of go. Ported from javascript/godash.
    """
  end

  defp package do
    # These are the default files included in the package
    [
      name: :elixir_go,
      files: ["lib", "mix.exs", "README*", "src"],
      maintainers: ["koko.le.gorille"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/kokolegorille/go"}
    ]
  end
end
