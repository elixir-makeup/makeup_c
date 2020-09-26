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
      aliases: aliases(),
      docs: [
        main: "readme",
        assets: "assets",
        extras: [
          "README.md"
        ]
      ]
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
      {:benchee, "~> 0.13", only: [:dev, :test]}
    ]
  end

  defp aliases do
    [
      docs: &build_docs/1,
      release: "run scripts/release.exs"
    ]
  end

  defp build_docs(_) do
    Mix.Task.run("compile")
    ex_doc = Path.join(Mix.path_for(:escripts), "ex_doc")

    unless File.exists?(ex_doc) do
      raise "cannot build docs because escript for ex_doc is not installed"
    end

    args = ["MakeupC", @version, Mix.Project.compile_path()]
    opts = ~w[--main Makeup.Lexers.CLexer --source-ref v#{@version} --source-url #{@url}]
    System.cmd(ex_doc, args ++ opts)
    Mix.shell().info("Docs built successfully")
  end
end
