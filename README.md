# Go

## Description

This package contains logic to play the game of go. 
Nothing related to the go language...
It is [godash](https://github.com/duckpunch/godash) ported to elixir, but it 
checks also ko rule, and holds information about captures count.

## Installation

The package can be installed by adding `elixir_go` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:elixir_go, "~> 0.1.0"}]
end
```

The package can be found at [https://hex.pm/packages/elixir_go](https://hex.pm/packages/elixir_go).
The docs can be found at [https://hexdocs.pm/elixir_go](https://hexdocs.pm/elixir_go).

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