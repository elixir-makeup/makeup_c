defmodule Makeup.Lexers.CLexer.ApplicationTest do
  use ExUnit.Case, async: true

  alias Makeup.Registry
  alias Makeup.Lexers.CLexer

  describe "start/2" do
    test "registers itself as a `makeup` lexer on application boot for the `c` language name" do
      assert {:ok, {CLexer, []}} == Registry.fetch_lexer_by_name("c")
    end

    test "registers itself as a `makeup` lexer on application boot for `c` and `h` file extensions" do
      assert {:ok, {CLexer, []}} == Registry.fetch_lexer_by_extension("c")
      assert {:ok, {CLexer, []}} == Registry.fetch_lexer_by_extension("h")
    end
  end
end
