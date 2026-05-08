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
      assert lex("0B1010") == [{:number_bin, %{}, "0B1010"}]
    end

    test "hex integer accepts 0X prefix as well as 0x" do
      assert lex("0XFF") == [{:number_hex, %{}, "0XFF"}]
    end

    test "octal integer (traditional 0-prefix)" do
      assert lex("0755") == [{:number_oct, %{}, "0755"}]
      assert lex("01") == [{:number_oct, %{}, "01"}]
    end

    test "octal integer (C23 0o / 0O prefix)" do
      assert lex("0o755") == [{:number_oct, %{}, "0o755"}]
      assert lex("0O755") == [{:number_oct, %{}, "0O755"}]
    end

    test "bare 0 is an integer, not octal" do
      assert lex("0") == [{:number_integer, %{}, "0"}]
    end

    test "decimal integer suffixes" do
      assert lex("42u") == [{:number_integer, %{}, "42u"}]
      assert lex("42U") == [{:number_integer, %{}, "42U"}]
      assert lex("42l") == [{:number_integer, %{}, "42l"}]
      assert lex("42L") == [{:number_integer, %{}, "42L"}]
      assert lex("42ll") == [{:number_integer, %{}, "42ll"}]
      assert lex("42LL") == [{:number_integer, %{}, "42LL"}]
      assert lex("42ul") == [{:number_integer, %{}, "42ul"}]
      assert lex("42lu") == [{:number_integer, %{}, "42lu"}]
      assert lex("42ull") == [{:number_integer, %{}, "42ull"}]
      assert lex("42llU") == [{:number_integer, %{}, "42llU"}]
    end

    test "C23 _BitInt suffix" do
      assert lex("42wb") == [{:number_integer, %{}, "42wb"}]
      assert lex("42WB") == [{:number_integer, %{}, "42WB"}]
      assert lex("42uwb") == [{:number_integer, %{}, "42uwb"}]
      assert lex("42WBU") == [{:number_integer, %{}, "42WBU"}]
    end

    test "hex/octal/binary integer suffixes" do
      assert lex("0xFFu") == [{:number_hex, %{}, "0xFFu"}]
      assert lex("0xFFULL") == [{:number_hex, %{}, "0xFFULL"}]
      assert lex("0755UL") == [{:number_oct, %{}, "0755UL"}]
      assert lex("0b101u") == [{:number_bin, %{}, "0b101u"}]
    end

    test "float without exponent" do
      assert lex("1.5") == [{:number_float, %{}, "1.5"}]
      assert lex("0.0") == [{:number_float, %{}, "0.0"}]
    end

    test "float with empty fractional part (5.)" do
      assert lex("5.") == [{:number_float, %{}, "5."}]
      assert lex("100.") == [{:number_float, %{}, "100."}]
    end

    test "float with empty integer part (.5)" do
      assert lex(".5") == [{:number_float, %{}, ".5"}]
      assert lex(".25e3") == [{:number_float, %{}, ".25e3"}]
    end

    test "float with no decimal point but exponent (1e10)" do
      assert lex("1e10") == [{:number_float, %{}, "1e10"}]
      assert lex("3E-5") == [{:number_float, %{}, "3E-5"}]
      assert lex("1e10f") == [{:number_float, %{}, "1e10f"}]
    end

    test "float with scientific exponent" do
      assert lex("1.5e10") == [{:number_float, %{}, "1.5e10"}]
      assert lex("2.0E-3") == [{:number_float, %{}, "2.0E-3"}]
      assert lex("1.0e+5") == [{:number_float, %{}, "1.0e+5"}]
    end

    test "float suffixes (f, F, l, L)" do
      for s <- ~w(f F l L) do
        assert lex("1.5" <> s) == [{:number_float, %{}, "1.5" <> s}]
      end
    end

    test "C23 binary fixed-width float suffixes" do
      for s <- ~w(f16 f32 f64 f128 F16 F32 F64 F128 bf16 BF16) do
        assert lex("1.0" <> s) == [{:number_float, %{}, "1.0" <> s}]
      end
    end

    test "C23 decimal float suffixes" do
      for s <- ~w(df dd dl DF DD DL) do
        assert lex("1.0" <> s) == [{:number_float, %{}, "1.0" <> s}]
      end
    end

    test "hex floats" do
      assert lex("0x1.fp10") == [{:number_float, %{}, "0x1.fp10"}]
      assert lex("0X1.Fp10") == [{:number_float, %{}, "0X1.Fp10"}]
      assert lex("0x1p10") == [{:number_float, %{}, "0x1p10"}]
      assert lex("0x1.p-3") == [{:number_float, %{}, "0x1.p-3"}]
      assert lex("0x.fp+5") == [{:number_float, %{}, "0x.fp+5"}]
      assert lex("0x1.fp10f") == [{:number_float, %{}, "0x1.fp10f"}]
      assert lex("0x1p10L") == [{:number_float, %{}, "0x1p10L"}]
    end

    test "hex integer is unaffected by hex float" do
      assert lex("0xFF") == [{:number_hex, %{}, "0xFF"}]
      assert lex("0x1234") == [{:number_hex, %{}, "0x1234"}]
    end

    test "C23 digit separator (')" do
      assert lex("1'000") == [{:number_integer, %{}, "1'000"}]
      assert lex("1'000'000") == [{:number_integer, %{}, "1'000'000"}]
      assert lex("0xFFFF'FFFF") == [{:number_hex, %{}, "0xFFFF'FFFF"}]
      assert lex("0b1010'1010") == [{:number_bin, %{}, "0b1010'1010"}]
      assert lex("0o755'755") == [{:number_oct, %{}, "0o755'755"}]
      assert lex("1'234.567'89") == [{:number_float, %{}, "1'234.567'89"}]
    end

    test "trailing ' is not absorbed into a number" do
      # `42'` followed by something else: the `'` must NOT be consumed
      # as part of the number, otherwise the next char literal's opening
      # quote gets eaten.
      assert [{:number_integer, %{}, "42"} | _] = lex("42';")
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

    test "encoding-prefixed strings" do
      assert lex(~s(L"hi")) == [{:string, %{}, ~s(L"hi")}]
      assert lex(~s(u"hi")) == [{:string, %{}, ~s(u"hi")}]
      assert lex(~s(U"hi")) == [{:string, %{}, ~s(U"hi")}]
      assert lex(~s(u8"hi")) == [{:string, %{}, ~s(u8"hi")}]
    end

    test "hex escape inside string" do
      assert lex(~S("\xFF")) == [
               {:string, %{}, ~s(")},
               {:string_escape, %{}, "\\xFF"},
               {:string, %{}, ~s(")}
             ]
    end

    test "octal escape inside string" do
      assert lex(~S("\033")) == [
               {:string, %{}, ~s(")},
               {:string_escape, %{}, "\\033"},
               {:string, %{}, ~s(")}
             ]
    end

    test "unicode \\u and \\U escapes inside string" do
      assert lex("\"\\u00E9\"") == [
               {:string, %{}, ~s(")},
               {:string_escape, %{}, "\\u00E9"},
               {:string, %{}, ~s(")}
             ]

      assert lex("\"\\U0001F600\"") == [
               {:string, %{}, ~s(")},
               {:string_escape, %{}, "\\U0001F600"},
               {:string, %{}, ~s(")}
             ]
    end
  end

  describe "identifiers" do
    test "lowercase identifier is a name" do
      assert lex("foo") == [{:name, %{}, "foo"}]
      assert lex("foo_bar") == [{:name, %{}, "foo_bar"}]
      assert lex("foo123") == [{:name, %{}, "foo123"}]
    end

    test "uppercase identifier is also a name (no separate name_constant)" do
      assert lex("FOO") == [{:name, %{}, "FOO"}]
      assert lex("MyType") == [{:name, %{}, "MyType"}]
      assert lex("ALL_CAPS_123") == [{:name, %{}, "ALL_CAPS_123"}]
    end

    test "underscore-prefixed identifier is a name (not a comment)" do
      # In C, leading underscores are reserved to the implementation but
      # they still form ordinary identifiers. They must not be rendered
      # as comments (that was an Elixir convention).
      assert lex("_foo") == [{:name, %{}, "_foo"}]
      assert lex("_internal_state") == [{:name, %{}, "_internal_state"}]
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

    test "C99/C11/C23 keywords" do
      # nullptr is also a C23 keyword but classified as :keyword_constant
      # for highlighting (see the constants describe block).
      for kw <- ~w(restrict alignas alignof constexpr static_assert
                   thread_local typeof typeof_unqual) do
        assert lex(kw) == [{:keyword, %{}, kw}]
      end
    end

    test "underscore-capital alternative spellings" do
      for kw <- ~w(_Alignas _Alignof _Atomic _BitInt _Bool _Complex
                   _Decimal32 _Decimal64 _Decimal128 _Generic _Imaginary
                   _Noreturn _Static_assert _Thread_local) do
        assert lex(kw) == [{:keyword, %{}, kw}]
      end
    end

    test "basic C++ keyword coverage" do
      # No template/namespace-aware logic; these just highlight as keywords
      # so the same lexer can be used for .cpp/.h files.
      for cxx <- ~w(class namespace template typename try catch throw
                    public private protected friend virtual operator
                    explicit export delete new this co_await co_return
                    co_yield concept requires decltype const_cast
                    static_cast dynamic_cast reinterpret_cast typeid
                    using mutable noexcept module import) do
        assert lex(cxx) == [{:keyword, %{}, cxx}], "#{cxx} did not lex as :keyword"
      end
    end
  end

  describe "type keywords" do
    test "primitive types" do
      for t <- ~w(int char short long float double signed unsigned void) do
        assert lex(t) == [{:keyword_type, %{}, t}]
      end
    end

    test "stdint exact-width types" do
      for t <- ~w(int8_t uint8_t int16_t uint16_t int32_t uint32_t int64_t uint64_t) do
        assert lex(t) == [{:keyword_type, %{}, t}]
      end
    end

    test "stdint least-width and fast-width types" do
      for t <- ~w(int_least8_t uint_least16_t int_fast32_t uint_fast64_t) do
        assert lex(t) == [{:keyword_type, %{}, t}]
      end
    end

    test "stddef and pointer-sized types" do
      for t <- ~w(size_t ssize_t ptrdiff_t intptr_t uintptr_t intmax_t uintmax_t) do
        assert lex(t) == [{:keyword_type, %{}, t}]
      end
    end

    test "C23 char8_t and nullptr_t" do
      assert lex("char8_t") == [{:keyword_type, %{}, "char8_t"}]
      assert lex("nullptr_t") == [{:keyword_type, %{}, "nullptr_t"}]
    end
  end

  describe "constants" do
    test "true/false are keyword_constant; void is a type, not a constant" do
      assert lex("true") == [{:keyword_constant, %{}, "true"}]
      assert lex("false") == [{:keyword_constant, %{}, "false"}]
      assert lex("void") == [{:keyword_type, %{}, "void"}]
    end

    test "NULL and nullptr are keyword_constant" do
      assert lex("NULL") == [{:keyword_constant, %{}, "NULL"}]
      assert lex("nullptr") == [{:keyword_constant, %{}, "nullptr"}]
    end

    test "alignof is recognised (not the typo alignoif)" do
      assert lex("alignof") == [{:keyword, %{}, "alignof"}]
      # alignoif is not a real C identifier; it should fall through to :name.
      assert lex("alignoif") == [{:name, %{}, "alignoif"}]
    end
  end

  describe "builtin pseudo identifiers" do
    test "__func__ (C99) and __FUNCTION__ (GCC)" do
      assert lex("__func__") == [{:name_builtin_pseudo, %{}, "__func__"}]
      assert lex("__FUNCTION__") == [{:name_builtin_pseudo, %{}, "__FUNCTION__"}]
    end

    test "standard predefined macros" do
      for m <- ~w(__FILE__ __LINE__ __DATE__ __TIME__
                  __STDC__ __STDC_VERSION__ __STDC_HOSTED__
                  __VA_ARGS__) do
        assert lex(m) == [{:name_builtin_pseudo, %{}, m}]
      end
    end

    test "C23 __VA_OPT__ and __has_* operators" do
      assert lex("__VA_OPT__") == [{:name_builtin_pseudo, %{}, "__VA_OPT__"}]
      assert lex("__has_include") == [{:name_builtin_pseudo, %{}, "__has_include"}]
      assert lex("__has_c_attribute") == [{:name_builtin_pseudo, %{}, "__has_c_attribute"}]
    end
  end

  describe "iso646 macros" do
    test "iso646 alternative spellings are not C operators" do
      # `and`, `or`, etc. come from <iso646.h> as macros expanding to &&, ||.
      # They are NOT C operators (those are the symbols themselves), so the
      # lexer treats them as plain identifiers.
      #
      # `compl` is a C++ alternative-token keyword and is classified as
      # :keyword (see basic-C++-coverage test) - not in this list.
      for word <- ~w(and or not xor and_eq or_eq xor_eq not_eq bitand bitor) do
        assert lex(word) == [{:name, %{}, word}]
      end
    end
  end

  describe "preprocessor" do
    test "directive is a single token" do
      assert lex("#include") == [{:keyword_pseudo, %{}, "#include"}]
      assert lex("#define") == [{:keyword_pseudo, %{}, "#define"}]
      assert lex("#ifdef") == [{:keyword_pseudo, %{}, "#ifdef"}]
    end
  end

  describe "char literals" do
    test "plain single-character literal" do
      assert lex("'a'") == [{:string_char, %{}, "'a'"}]
      assert lex("'Z'") == [{:string_char, %{}, "'Z'"}]
    end

    test "named escape inside char literal" do
      assert lex("'\\n'") == [
               {:string_char, %{}, "'"},
               {:string_escape, %{}, "\\n"},
               {:string_char, %{}, "'"}
             ]
    end

    test "hex escape inside char literal" do
      assert lex("'\\xFF'") == [
               {:string_char, %{}, "'"},
               {:string_escape, %{}, "\\xFF"},
               {:string_char, %{}, "'"}
             ]
    end

    test "octal escape inside char literal" do
      assert lex("'\\033'") == [
               {:string_char, %{}, "'"},
               {:string_escape, %{}, "\\033"},
               {:string_char, %{}, "'"}
             ]
    end

    test "encoding-prefixed char literals" do
      assert lex("L'a'") == [{:string_char, %{}, "L'a'"}]
      assert lex("u'a'") == [{:string_char, %{}, "u'a'"}]
      assert lex("U'a'") == [{:string_char, %{}, "U'a'"}]
      assert lex("u8'a'") == [{:string_char, %{}, "u8'a'"}]
    end

    test "char literal does not eat surrounding code" do
      assert lex("c = 'a';") == [
               {:name, %{}, "c"},
               {:whitespace, %{}, " "},
               {:operator, %{}, "="},
               {:whitespace, %{}, " "},
               {:string_char, %{}, "'a'"},
               {:punctuation, %{}, ";"}
             ]
    end
  end

  describe "no Elixir-isms" do
    test "ternary ? is just an operator (not a char literal prefix)" do
      assert lex("a ? b : c") == [
               {:name, %{}, "a"},
               {:whitespace, %{}, " "},
               {:operator, %{}, "?"},
               {:whitespace, %{}, " "},
               {:name, %{}, "b"},
               {:whitespace, %{}, " "},
               {:operator, %{}, ":"},
               {:whitespace, %{}, " "},
               {:name, %{}, "c"}
             ]
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
