defmodule Makeup.Lexers.CLexer.TokenizerTest do
  use ExUnit.Case, async: true
  import Makeup.Lexers.CLexer.Testing, only: [lex: 1]

  test "empty string" do
    assert lex("") == []
  end

  describe "whitespace" do
    test "single characters" do
      assert lex(" ") == [{:whitespace, %{}, " "}]
      assert lex("\t") == [{:whitespace, %{}, "\t"}]
      assert lex("\n") == [{:whitespace, %{}, "\n"}]
      assert lex("\r") == [{:whitespace, %{}, "\r"}]
      assert lex("\f") == [{:whitespace, %{}, "\f"}]
      assert lex("\v") == [{:whitespace, %{}, "\v"}]
    end

    test "multiple characters collapse into one token" do
      assert lex("  \n\t\n  ") == [{:whitespace, %{}, "  \n\t\n  "}]
    end
  end

  describe "comments" do
    test "single-line comment" do
      assert lex("// hello") == [{:comment_single, %{}, "// hello"}]
    end

    test "single-line comment stops at newline" do
      assert lex("// hi\nx") == [
               {:comment_single, %{}, "// hi"},
               {:whitespace, %{}, "\n"},
               {:name, %{}, "x"}
             ]
    end

    test "multi-line comment on one line" do
      assert lex("/* hi */") == [{:comment_multiline, %{}, "/* hi */"}]
    end

    test "multi-line comment spanning lines" do
      assert lex("/* a\n  b */") == [{:comment_multiline, %{}, "/* a\n  b */"}]
    end
  end

  describe "numbers" do
    test "decimal integer" do
      assert lex("0") == [{:number_integer, %{}, "0"}]
      assert lex("42") == [{:number_integer, %{}, "42"}]
      assert lex("123456") == [{:number_integer, %{}, "123456"}]
    end

    test "hex integer" do
      assert lex("0xFF") == [{:number_hex, %{}, "0xFF"}]
      assert lex("0xdeadbeef") == [{:number_hex, %{}, "0xdeadbeef"}]
    end

    test "binary integer" do
      assert lex("0b1010") == [{:number_bin, %{}, "0b1010"}]
    end

    test "float without exponent" do
      assert lex("1.5") == [{:number_float, %{}, "1.5"}]
      assert lex("0.0") == [{:number_float, %{}, "0.0"}]
    end

    test "float with scientific exponent" do
      assert lex("1.5e10") == [{:number_float, %{}, "1.5e10"}]
      assert lex("2.0E-3") == [{:number_float, %{}, "2.0E-3"}]
    end
  end

  describe "strings" do
    test "double-quoted string" do
      assert lex(~s("hello")) == [{:string, %{}, ~s("hello")}]
    end

    test "string with simple escape" do
      # `string_like` glues delimiter + adjacent literal text into a single
      # :string token, so the open quote travels with the leading text and
      # the close quote with the trailing text.
      assert lex(~s("a\\nb")) == [
               {:string, %{}, ~s("a)},
               {:string_escape, %{}, "\\n"},
               {:string, %{}, ~s(b")}
             ]
    end
  end

  describe "identifiers" do
    test "lowercase identifier is a name" do
      assert lex("foo") == [{:name, %{}, "foo"}]
      assert lex("foo_bar") == [{:name, %{}, "foo_bar"}]
      assert lex("foo123") == [{:name, %{}, "foo123"}]
    end

    test "function call (name immediately followed by parens)" do
      assert lex("foo(1)") == [
               {:name_function, %{}, "foo"},
               {:punctuation, %{group_id: "group-1"}, "("},
               {:number_integer, %{}, "1"},
               {:punctuation, %{group_id: "group-1"}, ")"}
             ]
    end
  end

  describe "operators" do
    test "single-character operators" do
      for op <- ~w(+ - * / % ~ ^ & | = < > ! ? :) do
        assert lex(op) == [{:operator, %{}, op}], "operator #{inspect(op)} did not lex"
      end
    end

    test "multi-character operators" do
      for op <- ~w(-> ++ -- == != >= <= && || << >> += -= *= /= %= &= |= ^= <<= >>=) do
        assert lex(op) == [{:operator, %{}, op}], "operator #{inspect(op)} did not lex"
      end
    end
  end

  describe "punctuation" do
    test "statement punctuation" do
      for p <- ~w(; , .) do
        assert lex(p) == [{:punctuation, %{}, p}]
      end
    end

    test "balanced delimiters get group ids" do
      assert lex("()") == [
               {:punctuation, %{group_id: "group-1"}, "("},
               {:punctuation, %{group_id: "group-1"}, ")"}
             ]

      assert lex("[]") == [
               {:punctuation, %{group_id: "group-1"}, "["},
               {:punctuation, %{group_id: "group-1"}, "]"}
             ]

      assert lex("{}") == [
               {:punctuation, %{group_id: "group-1"}, "{"},
               {:punctuation, %{group_id: "group-1"}, "}"}
             ]
    end
  end

  describe "keywords" do
    test "control-flow keywords" do
      for kw <- ~w(if else for while do switch case default break continue return goto) do
        assert lex(kw) == [{:keyword, %{}, kw}]
      end
    end

    test "storage-class keywords" do
      for kw <- ~w(static extern auto register inline) do
        assert lex(kw) == [{:keyword, %{}, kw}]
      end
    end
  end

  describe "type keywords" do
    test "primitive types" do
      for t <- ~w(int char short long float double signed unsigned void) do
        assert lex(t) == [{:keyword_type, %{}, t}]
      end
    end

    test "stdint types" do
      for t <- ~w(int8_t uint8_t int16_t uint16_t int32_t uint32_t int64_t uint64_t) do
        assert lex(t) == [{:keyword_type, %{}, t}]
      end
    end
  end

  describe "constants" do
    test "true/false are keyword_constant; void is a type, not a constant" do
      assert lex("true") == [{:keyword_constant, %{}, "true"}]
      assert lex("false") == [{:keyword_constant, %{}, "false"}]
      assert lex("void") == [{:keyword_type, %{}, "void"}]
    end

    test "NULL is currently lexed as :name_constant (Phase 1c will upgrade to :keyword_constant)" do
      assert lex("NULL") == [{:name_constant, %{}, "NULL"}]
    end

    test "alignof is recognised (not the typo alignoif)" do
      assert lex("alignof") == [{:keyword, %{}, "alignof"}]
      # alignoif is not a real C identifier; it should fall through to :name.
      assert lex("alignoif") == [{:name, %{}, "alignoif"}]
    end
  end

  describe "preprocessor" do
    test "directive is a single token" do
      assert lex("#include") == [{:keyword_pseudo, %{}, "#include"}]
      assert lex("#define") == [{:keyword_pseudo, %{}, "#define"}]
      assert lex("#ifdef") == [{:keyword_pseudo, %{}, "#ifdef"}]
    end
  end

  describe "smoke test" do
    test "minimal int declaration" do
      assert lex("int a = 0;") == [
               {:keyword_type, %{}, "int"},
               {:whitespace, %{}, " "},
               {:name, %{}, "a"},
               {:whitespace, %{}, " "},
               {:operator, %{}, "="},
               {:whitespace, %{}, " "},
               {:number_integer, %{}, "0"},
               {:punctuation, %{}, ";"}
             ]
    end
  end
end
