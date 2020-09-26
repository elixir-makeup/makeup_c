defmodule MakeupC.MixProject do
  use Mix.Project

  @version "0.1.0"
  @url "https://github.com/boydm/makeup_c"

  def project do
    [
      app: :makeup_c,
      version: "0.1.0",
      elixir: "~> 1.4",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      # Package
      package: package(),
      description: description(),
      # aliases: aliases(),
      docs: docs()
    ]
  end

  defp description do
    """
    C lexer for the Makeup syntax highlighter.
    """
  end

  defp package do
    [
      name: :makeup_c,
      licenses: ["BSD"],
      maintainers: ["Boyd Multerer <boyd@kry10.com>"],
      links: %{"GitHub" => @url}
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [],
      mod: {Makeup.Lexers.CLexer.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:makeup, "~> 1.0"},
      {:ex_doc, ">= 0.0.0", only: [:dev, :docs]},
    ]
  end

  def docs do
    [
      extras: ["README.md"],
      source_ref: "v#{@version}",
      main: "Makeup.Lexers.CLexer"
    ]
  end

end
