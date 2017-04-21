# Go

## Description

This package contains logic to play the game of go. 
Nothing related to the go language...
It is [godash](https://github.com/duckpunch/godash) ported to elixir, but it 
checks also ko rule, and holds information about captures count.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `go` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:elixir_go, "~> 0.1.0"}]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/go](https://hexdocs.pm/go).

## Usage

See tests for sample usage.

```elixir
iex> alias Go.Board
iex> board = Board.new(%{size: 9})
iex> {:ok, board} = Board.add_move(board, {{2, 2}, :black})
iex> {:ok, board} = Board.add_move(board, {{3, 3}, :white})
iex> IO.puts Board.to_ascii_board board
+++++++++
+++++++++
++O++++++
+++X+++++
+++++++++
+++++++++
+++++++++
+++++++++
+++++++++
```