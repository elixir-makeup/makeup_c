defmodule MakeupCTest do
  use ExUnit.Case
  doctest Makeup.Lexers.CLexer

  test "minimal lex test" do
    assert Makeup.Lexers.CLexer.lex("int a = 0;") == [
             {:keyword_type, %{language: :c}, "int"},
             {:whitespace, %{language: :c}, " "},
             {:name, %{language: :c}, "a"},
             {:whitespace, %{language: :c}, " "},
             {:operator, %{language: :c}, "="},
             {:whitespace, %{language: :c}, " "},
             {:number_integer, %{language: :c}, "0"},
             {:punctuation, %{language: :c}, ";"}
           ]
  end
end
