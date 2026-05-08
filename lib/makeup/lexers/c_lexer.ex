defmodule Makeup.Lexers.CLexer do
  import NimbleParsec
  import Makeup.Lexer.Combinators
  import Makeup.Lexer.Groups
  @behaviour Makeup.Lexer

  ###################################################################
  # Step #1: tokenize the input (into a list of tokens)
  ###################################################################
  # We will often compose combinators into larger combinators.
  # Sometimes, the smaller combinator is usefull on its own as a token, and sometimes it isn't.
  # We'll adopt the following "convention":
  #
  # 1. A combinator that ends with `_name` returns a string
  # 2. Other combinators will *usually* return a token
  #
  # Why this convention? Tokens can't be composed further, while raw strings can.
  # This way, we immediately know which of the combinators we can compose.
  # TODO: check we're following this convention

  whitespace = ascii_string([?\s, ?\t, ?\r, ?\n, ?\f, ?\v], min: 1) |> token(:whitespace)

  any_char = utf8_char([]) |> token(:error)

  # Numbers
  digits = ascii_string([?0..?9], min: 1)
  bin_digits = ascii_string([?0..?1], min: 1)
  hex_digits = ascii_string([?0..?9, ?a..?f, ?A..?F], min: 1)
  oct_digits = ascii_string([?0..?7], min: 1)

  # C23 6.4.4.1 integer-suffix:
  #   unsigned-suffix optional(size-suffix)
  # | size-suffix optional(unsigned-suffix)
  # where size-suffix is long-suffix (l/L), long-long-suffix (ll/LL), or
  # bit-precise-int-suffix (wb/WB). The `ll`/`LL` form must be a single
  # case; we reject `lL`/`Ll` by listing the pairs explicitly.
  unsigned_suffix = choice([string("u"), string("U")])
  long_long_suffix = choice([string("ll"), string("LL")])
  long_suffix = choice([string("l"), string("L")])
  bit_precise_suffix = choice([string("wb"), string("WB")])
  size_suffix = choice([long_long_suffix, long_suffix, bit_precise_suffix])

  integer_suffix =
    choice([
      unsigned_suffix |> optional(size_suffix),
      size_suffix |> optional(unsigned_suffix)
    ])

  number_bin =
    choice([string("0b"), string("0B")])
    |> concat(bin_digits)
    |> optional(integer_suffix)
    |> token(:number_bin)

  number_hex =
    choice([string("0x"), string("0X")])
    |> concat(hex_digits)
    |> optional(integer_suffix)
    |> token(:number_hex)

  # Octal: traditional C `0` prefix (`0755`) and the C23 `0o`/`0O` prefix
  # (`0o755`). The `0o`/`0O` form requires at least one octal digit; the
  # bare `0` form requires at least one too, so plain `0` falls through
  # to number_integer below.
  number_oct =
    choice([
      choice([string("0o"), string("0O")]) |> concat(oct_digits),
      string("0") |> concat(oct_digits)
    ])
    |> optional(integer_suffix)
    |> token(:number_oct)

  number_integer =
    digits
    |> optional(integer_suffix)
    |> token(:number_integer)

  float_scientific_notation_part =
    ascii_string([?e, ?E], 1)
    |> optional(ascii_char([?+, ?-]))
    |> concat(digits)

  # C23 6.4.4.2 floating-suffix:
  #   f, F, l, L,
  #   df, dd, dl, DF, DD, DL  (decimal floating types)
  #   f16, f32, f64, f128, F16, F32, F64, F128 (binary fixed-width)
  #   bf16, BF16 (brain floating)
  # Order matters: try multi-character suffixes before the single-char
  # `f`/`F` to avoid swallowing only the first letter.
  float_suffix =
    choice([
      string("f128"),
      string("F128"),
      string("f64"),
      string("F64"),
      string("f32"),
      string("F32"),
      string("f16"),
      string("F16"),
      string("bf16"),
      string("BF16"),
      string("df"),
      string("dd"),
      string("dl"),
      string("DF"),
      string("DD"),
      string("DL"),
      string("f"),
      string("F"),
      string("l"),
      string("L")
    ])

  number_float =
    digits
    |> string(".")
    |> concat(digits)
    |> optional(float_scientific_notation_part)
    |> optional(float_suffix)
    |> token(:number_float)

  # C identifier: [A-Za-z_][A-Za-z0-9_]*
  identifier =
    ascii_string([?A..?Z, ?a..?z, ?_], 1)
    |> optional(ascii_string([?A..?Z, ?a..?z, ?_, ?0..?9], min: 1))

  variable =
    identifier
    |> lexeme
    |> token(:name)

  operator_name = word_from_list(~W(
      -> + -  * / % ++ -- ~ ^ & && | ||
      =  += -= *= /= &= |= %= ^= << >>
      <<= >>= > < >= <= == != ! ? : 
    ))

  operator = token(operator_name, :operator)

  directive =
    string("#")
    |> concat(identifier)
    |> token(:keyword_pseudo)

  punctuation =
    word_from_list(
      ["\\\\", ":", ";", ",", "."],
      :punctuation
    )

  delimiters_punctuation =
    word_from_list(
      ["(", ")", "[", "]", "{", "}"],
      :punctuation
    )

  comment = many_surrounded_by(parsec(:root_element), "/*", "*/")

  delimiter_pairs = [
    delimiters_punctuation,
    comment
  ]

  unicode_char_in_string =
    string("\\u")
    |> ascii_string([?0..?9, ?a..?f, ?A..?F], 4)
    |> token(:string_escape)

  escaped_char =
    string("\\")
    |> utf8_string([], 1)
    |> token(:string_escape)

  combinators_inside_string = [
    unicode_char_in_string,
    escaped_char
  ]

  double_quoted_string = string_like("\"", "\"", combinators_inside_string, :string)

  line = repeat(lookahead_not(ascii_char([?\n])) |> utf8_string([], 1))

  inline_comment =
    string("//")
    |> concat(line)
    |> token(:comment_single)

  multiline_comment = string_like("/*", "*/", combinators_inside_string, :comment_multiline)

  root_element_combinator =
    choice(
      [
        whitespace,
        # Comments
        multiline_comment,
        inline_comment,
        # Preprocessor directive (must come before operators because of #)
        directive,
        # Strings
        double_quoted_string
      ] ++
        delimiter_pairs ++
        [
          # Operators
          operator,
          # Numbers
          number_bin,
          number_oct,
          number_hex,
          # Floats must come before integers
          number_float,
          number_integer,
          # Names
          variable,
          punctuation,
          # If we can't parse any of the above, we highlight the next character as an error
          # and proceed from there.
          # A lexer should always consume any string given as input.
          any_char
        ]
    )

  # By default, don't inline the lexers.
  # Inlining them increases performance by ~20%
  # at the cost of doubling the compilation times...
  @inline false

  @doc false
  def __as_c_language__({ttype, meta, value}) do
    {ttype, Map.put(meta, :language, :c), value}
  end

  # Semi-public API: these two functions can be used by someone who wants to
  # embed an Elixir lexer into another lexer, but other than that, they are not
  # meant to be used by end-users.

  # @impl Makeup.Lexer
  defparsec(
    :root_element,
    root_element_combinator |> map({__MODULE__, :__as_c_language__, []}),
    inline: @inline
  )

  # @impl Makeup.Lexer
  defparsec(
    :root,
    repeat(parsec(:root_element)),
    inline: @inline
  )

  ###################################################################
  # Step #2: postprocess the list of tokens
  ###################################################################

  @keyword ~W[
    alignas alignof asm atomic_cancel atomic_commit
    atomic_noexcept auto break case catch class co_await
    co_return co_yield compl concept const const_cast
    constexpr continue decltype default delete do dynamic_cast
    else enum explicit export extern for friend goto if
    import inline module mutable namespace new noexcept
    nullptr operator private protected public register
    reinterpret_cast requires restrict return sizeof static static_assert
    static_cast struct switch synchronized template this
    thread_local throw try typedef typeid typename typeof typeof_unqual union
    using virtual volatile while
  ]

  @keyword_type ~W[
    bool int long unsigned double char short signed float void wchar_t
    char16_t char32_t int8_t uint8_t int16_t uint16_t int32_t uint32_t
    int64_t uint64_t
  ]

  @keyword_constant ~W[
    NULL true false
  ]

  @operator_word ~W[and and_eq bitand bitor not not_eq or or_eq xor xor_eq]
  @name_builtin_pseudo ~W[__FUNCTION__ __FILE__ __LINE__]

  # The `postprocess/1` function will require a major redesign when we decide to support
  # custom `def`-like keywords supplied by the user.
  defp postprocess_helper([]), do: []

  # match function names. They are followed by parens...
  defp postprocess_helper([
         {:name, attrs, text},
         {:punctuation, %{language: :c}, "("}
         | tokens
       ]) do
    [
      {:name_function, attrs, text},
      {:punctuation, %{language: :c}, "("}
      | postprocess_helper(tokens)
    ]
  end

  defp postprocess_helper([{:name, attrs, text} | tokens]) when text in @keyword,
    do: [{:keyword, attrs, text} | postprocess_helper(tokens)]

  defp postprocess_helper([{:name, attrs, text} | tokens]) when text in @keyword_type,
    do: [{:keyword_type, attrs, text} | postprocess_helper(tokens)]

  defp postprocess_helper([{:name, attrs, text} | tokens]) when text in @keyword_constant,
    do: [{:keyword_constant, attrs, text} | postprocess_helper(tokens)]

  defp postprocess_helper([{:name, attrs, text} | tokens]) when text in @operator_word,
    do: [{:operator_word, attrs, text} | postprocess_helper(tokens)]

  defp postprocess_helper([{:name, attrs, text} | tokens]) when text in @name_builtin_pseudo,
    do: [{:name_builtin_pseudo, attrs, text} | postprocess_helper(tokens)]

  # Otherwise, don't do anything with the current token and go to the next token.
  defp postprocess_helper([token | tokens]), do: [token | postprocess_helper(tokens)]

  # Public API
  @impl Makeup.Lexer
  def postprocess(tokens, _opts \\ []), do: postprocess_helper(tokens)

  ###################################################################
  # Step #3: highlight matching delimiters
  ###################################################################

  @impl Makeup.Lexer
  defgroupmatcher(:match_groups,
    parentheses: [
      open: [[{:punctuation, %{language: :c}, "("}]],
      close: [[{:punctuation, %{language: :c}, ")"}]]
    ],
    array: [
      open: [[{:punctuation, %{language: :c}, "["}]],
      close: [[{:punctuation, %{language: :c}, "]"}]]
    ],
    brackets: [
      open: [[{:punctuation, %{language: :c}, "{"}]],
      close: [[{:punctuation, %{language: :c}, "}"}]]
    ]
  )

  defp remove_initial_newline([{ttype, meta, text} | tokens]) do
    case to_string(text) do
      "\n" -> tokens
      "\n" <> rest -> [{ttype, meta, rest} | tokens]
    end
  end

  # Finally, the public API for the lexer
  @impl Makeup.Lexer
  def lex(text, opts \\ []) do
    group_prefix = Keyword.get(opts, :group_prefix, random_prefix(10))
    {:ok, tokens, "", _, _, _} = root("\n" <> text)

    tokens
    |> remove_initial_newline()
    |> postprocess([])
    |> match_groups(group_prefix)
  end
end
