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
  [{:elixir_go, "~> 0.2.0"}]
end
```

[Available in Hex](https://hex.pm/packages/elixir_go).
[Documentation](https://hexdocs.pm/elixir_go).

## Usage

See tests for sample usage.

```elixir
iex> alias Go.{Game, Board}
iex> game = Game.new(%{size: 9})
iex> {:ok, game} = Game.add_move(game, {{2, 2}, :black})
iex> {:ok, game} = Game.add_move(game, {{3, 3}, :white})
iex> game.current_board |> Board.to_ascii_board |> IO.puts 
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