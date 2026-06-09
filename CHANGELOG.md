# Changelog

All notable changes to `makeup_c` are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-05-08

A near-complete rewrite of the lexer's behaviour to follow C23 (ISO/IEC 9899:2024)
and shed the Elixir-isms inherited from the original lexer template. The token
shape (Makeup token tuples) and public API (`Makeup.Lexers.CLexer.lex/2`) are
unchanged; classifications of individual tokens are not.

### Added

- **C23 keywords**: `constexpr`, `nullptr`, `static_assert`, `thread_local`,
  `typeof`, `typeof_unqual`, `restrict`, plus the underscore-capital
  alternative spellings (`_Atomic`, `_BitInt`, `_Generic`, `_Bool`,
  `_Complex`, `_Imaginary`, `_Noreturn`, `_Static_assert`, `_Thread_local`,
  `_Alignas`, `_Alignof`, `_Decimal32`/`_Decimal64`/`_Decimal128`).
- **Standard library typedefs** highlighted as types: stdint exact-,
  least-, and fast-width forms (`int8_t`, `int_least16_t`, `int_fast32_t`,
  …), `intmax_t`/`uintmax_t`, `intptr_t`/`uintptr_t`, `size_t`/`ssize_t`/
  `ptrdiff_t`/`max_align_t`/`errno_t`, the C23 `char8_t` and `nullptr_t`,
  and the ubiquitous `FILE` and `va_list`.
- **Standard predefined macros** as `:name_builtin_pseudo`: `__func__`
  (C99), `__FILE__`, `__LINE__`, `__DATE__`, `__TIME__`, `__STDC__`,
  `__STDC_VERSION__`, `__STDC_HOSTED__`, `__STDC_UTF_16__`,
  `__STDC_UTF_32__`, `__VA_ARGS__`, the C23 additions `__VA_OPT__` /
  `__has_include` / `__has_c_attribute` / `__has_embed`, and the GCC/
  Clang extensions `__FUNCTION__` / `__PRETTY_FUNCTION__`.
- **Integer suffixes**: `u`/`U`, `l`/`L`, `ll`/`LL`, and the C23
  `wb`/`WB` (`_BitInt`) suffix in any valid combination.
- **Float suffixes**: `f`/`F`, `l`/`L`, the C23 fixed-width forms
  `f16`/`f32`/`f64`/`f128` (and uppercase), `bf16`/`BF16`, and the
  decimal forms `df`/`dd`/`dl` (and uppercase).
- **Float literal forms** previously unrecognised: `5.`, `.5`, `1e10`
  (no decimal point but exponent), and full **hex floats**
  (`0x1.fp10`, `0x1p-3`, `0x.fp+5`).
- **C23 digit separator** `'` between any two digits in a numeric
  constant (`1'000`, `0xFFFF'FFFF`, `1'234.567'89`).
- **Character literals** as `:string_char`, including the encoding
  prefixes `L`, `u`, `U`, `u8` (C23). Octal (`\NNN`), hex (`\xNN`),
  and Unicode (`\u`, `\U`) escapes inside char and string literals.
- **String literal prefixes**: `L"…"`, `u"…"`, `U"…"`, `u8"…"`.
- **All C23 preprocessor directives**, including `#elifdef`,
  `#elifndef`, `#embed`, `#warning`. Whitespace is now allowed between
  `#` and the directive name (`# include`, `#\tdefine`).
- **`#include <header.h>`** is collapsed into a single `:string` token
  by a postprocess pass; `<` and `>` outside an `#include` line stay
  ordinary operators.
- **C23 `[[…]]` attribute sequences** as `:name_decorator`
  (`[[nodiscard]]`, `[[gnu::aligned(8)]]`, …).
- **CHANGELOG.md** (this file) and a comprehensive test suite (~80
  tests covering whitespace, comments, all numeric forms, all
  literal forms, every keyword class, attributes, and the
  preprocessor) modelled on `makeup_erlang`.
- **Basic C++ keyword coverage** retained from the original lexer so
  the same tokenizer works on `.cpp` / `.h` files: `class`,
  `namespace`, `template`, `typename`, `try`/`catch`/`throw`, the
  `co_*` coroutine keywords, `*_cast` operators, `public`/`private`/
  `protected`, etc. Highlighted purely as `:keyword`; no template-,
  namespace-, or type-aware logic.

### Changed

- **Elixir requirement**: bumped to `~> 1.14` from `~> 1.4`.
- **CI**: Travis replaced with GitHub Actions, matrixed across Elixir
  1.14 / OTP 24 (oldest supported) and Elixir 1.19 / OTP 28 (newest,
  with lint stage running `mix format --check-formatted`,
  `mix deps.unlock --check-unused`, and `mix compile --warnings-as-errors`).
- **Source layout** moved to the standard makeup arrangement:
  `lib/makeup_c.ex` → `lib/makeup/lexers/c_lexer.ex`, plus the
  supporting modules under `lib/makeup/lexers/c_lexer/`. Tests
  moved to `test/makeup/c_lexer/`.
- **Identifier rule** is now C-correct: `[A-Za-z_][A-Za-z0-9_]*`. The
  uppercase-vs-lowercase split (which routed names like `NULL` to
  `:name_constant` and so prevented postprocessor classification) is
  gone; both cases produce `:name` and the postprocessor decides.
- **Octal numbers** use the traditional C `0` prefix (`0755`); the
  C23 alternative `0o`/`0O` form is also accepted. Plain `0` stays
  a decimal integer.
- **Whitespace** now includes `\t` and `\v` per C23 6.4 (was missing
  both, so tabs in source produced `:error` tokens).
- **`nullptr`** is classified as `:keyword_constant` (alongside
  `true`/`false`/`NULL`) rather than `:keyword`, matching its
  semantic role as a predefined constant.
- **`void`** is classified as `:keyword_type` (was incorrectly listed
  under constants).

### Removed

- **Elixir-only combinators**: the `?x`/`?\x` "char literal" forms,
  the `key:` / `"key":` Elixir keyword-list combinators, and the
  trailing-`?`/`!` allowance in identifiers.
- **Leading-underscore-as-comment rule**: identifiers like `_foo` are
  no longer rendered as `:comment`. In C a leading underscore is
  reserved to the implementation but still forms an ordinary
  identifier.
- **`@operator_word`** (the `<iso646.h>` macros `and`, `or`, `not`,
  `xor`, `and_eq`, `or_eq`, `xor_eq`, `not_eq`, `bitand`, `bitor`).
  Those are *macros* expanding to C operators, not C operators
  themselves; they now lex as plain `:name`. (`compl` keeps its
  `:keyword` classification because it's also a C++ alternative-
  token keyword.)
- **`alignoif`** (typo for `alignof`) and **`byte`** (not a C type)
  removed from the keyword/type lists.
- **`_` digit separator**: was Elixir; replaced by the C23 `'`
  separator above.
- **`0o`-only octal prefix**: replaced by the standard `0`-prefix
  form (with `0o`/`0O` accepted as a C23-compatible alternative).
- **Dead `Makeup.Lexers.CLexer.Helper` module**: all of its functions
  (`with_optional_separator`, `escape_delim`, `sigil`, `escaped`,
  `keyword_matcher`) were either Elixir-only or unused.

### Fixed

- Tabs and form feeds in source no longer produce `:error` tokens.
- The deprecated uppercase-sigil escape (`~W( ( \) [ ] { })`) that
  caused warnings on Elixir 1.19 is replaced by a list literal.

## [0.1.1] - 2020-10-03

- Mix file updated to point to the new repository location.

## [0.1.0] - 2020-09-26

- Initial release. Basic C lexer covering keywords, types,
  numbers (decimal/hex/binary/float), strings, single- and
  multi-line comments, operators, and preprocessor directives.
