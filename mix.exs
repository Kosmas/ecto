defmodule Ecto.Mixfile do
  use Mix.Project

  def project do
    [app: :ecto,
     version: "0.2.2",
     elixir: "~> 0.14.0",
     deps: deps,
     build_per_environment: false,
     test_paths: test_paths(Mix.env),

     description: description,
     package: package,

     # Docs
     name: "Ecto",
     docs: &docs/0,
     source_url: "https://github.com/elixir-lang/ecto"]
  end

  def application do
    [applications: [:decimal, :poolboy, :emysql]]
  end

  defp deps do
    [{:poolboy, "~> 1.2.1"},
     # {:decimal, github: "ericmj/decimal", optional: true},
     # {:postgrex, github: "ericmj/postgrex", optional: true},
     {:decimal, "~> 0.2.1", optional: true},
     {:postgrex, "~> 0.5.1", optional: true},
     {:emysql, github: "eonblast/emysql" },
     {:ex_doc, github: "elixir-lang/ex_doc", only: :dev},
     {:markdown, github: "devinus/markdown", only: :dev}]
  end

  defp test_paths(:pg),  do: ["integration_test/pg"]
  defp test_paths(:all), do: ["test", "integration_test/pg"]
  defp test_paths(_),    do: ["test"]

  defp description do
    """
    Ecto is a domain specific language for writing queries and interacting with databases in Elixir.
    """
  end

  defp envs do
    [ pg: [ test_paths: ["integration_test/pg"] ],
      mysql: [ test_paths: ["integration_test/mysql"] ],
      all: [ test_paths: ["test", "integration_test/pg", "integration_test/mysql"] ] ]
  end

  defp package do
    [contributors: ["Eric Meadows-Jönsson", "José Valim"],
     licenses: ["Apache 2.0"],
     links: %{"GitHub" => "https://github.com/elixir-lang/ecto",
              "Docs" => "http://elixir-lang.org/docs/ecto/"}]
  end

  defp docs do
    [source_ref: System.cmd("git rev-parse --verify --quiet HEAD"),
     main: "overview",
     readme: true]
  end
end
