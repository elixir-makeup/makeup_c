# MakeupC
A [Makeup](https://github.com/elixir-makeup/makeup) lexer for the C language.

## Installation

Add `makeup_c` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:makeup_c, ">= 0.0.0"}
  ]
end
```

The lexer registers itself with Makeup for the language name `"c"` and
the file extensions `c` and `h`.

## Coverage

The lexer targets C23 (ISO/IEC 9899:2024). It recognises:

- All C23 keywords, including the underscore-capital alternative
  spellings (`_Atomic`, `_BitInt`, `_Generic`, ...).
- The standard primitive types plus the typedefs from `<stdint.h>`
  (`int8_t` ... `uint64_t`, `int_least*_t`, `int_fast*_t`,
  `intmax_t`, `uintmax_t`, `intptr_t`, `uintptr_t`), `<stddef.h>`
  (`size_t`, `ptrdiff_t`, `nullptr_t`, `max_align_t`), and the
  ubiquitous `FILE` / `va_list`.
- Numeric constants in all bases (decimal, `0x`/`0X`, `0b`/`0B`,
  traditional `0`-prefix octal and the C23 `0o`/`0O` form), with
  full integer (`u`, `l`, `ll`, `wb`) and floating
  (`f`, `l`, `f16`/`f32`/`f64`/`f128`, `bf16`, `df`/`dd`/`dl`)
  suffixes, hex floats (`0x1.fp10`), and the C23 `'` digit separator.
- Character and string literals, including the `L`, `u`, `U`, `u8`
  encoding prefixes and `\NNN` / `\xNN` / `\u` / `\U` escape forms.
- All C23 preprocessor directives, including `#elifdef`, `#elifndef`,
  `#embed`, and `#warning`. `#include <header.h>` is collapsed into
  a single string token.
- C23 `[[...]]` attribute sequences as decorators.
- The standard predefined macros (`__FILE__`, `__LINE__`, `__func__`,
  `__VA_ARGS__`, `__VA_OPT__`, `__has_include`, ...).

Basic C++ coverage is included so the same lexer can be used for
`.cpp` / `.h` files: keywords like `class`, `namespace`, `template`,
`try`/`catch`/`throw`, the `co_*` coroutine keywords, and the
`*_cast` operators all highlight as keywords. There is no
template-, namespace-, or type-aware logic — these are recognised
purely as tokens.
