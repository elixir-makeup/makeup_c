# MakeupC

[![Build Status](https://github.com/elixir-makeup/makeup_c/workflows/CI/badge.svg)](https://github.com/elixir-makeup/makeup_c/actions)

A [Makeup](https://github.com/elixir-makeup/makeup/) lexer for the C language.

## Installation

Add `makeup_c` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:makeup_c, ">= 0.0.0"}
  ]
end
```

The lexer will be automatically registered in Makeup for
the languages "c" as well as the extensions ".c" and ".h".

## Status

This lexer was built to highlight C code in a blog. It works for my purposes
so I'm happy. It is fairly naive as it doesn't take into account any of the C language's
type checking. It also has the C++ keywords, but doesn't attempt to do anything fancy
regarding templates and other fancy type definitions. I needed it just for C, and that
is what it does.

If anybody wants to take a crack at making it more type aware or providing better
support for C++, please have a go at it.
