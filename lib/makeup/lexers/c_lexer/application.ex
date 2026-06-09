defmodule Makeup.Lexers.CLexer.Application do
  @moduledoc false
  use Application

  alias Makeup.Registry
  alias Makeup.Lexers.CLexer

  def start(_type, _args) do
    Registry.register_lexer(CLexer,
      options: [],
      names: ["c"],
      extensions: ["c", "h"]
    )

    Supervisor.start_link([], strategy: :one_for_one)
  end
end
