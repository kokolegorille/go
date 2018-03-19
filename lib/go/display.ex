defmodule Go.Display do
  @moduledoc false
  
  alias Go.Game
  alias Go.Board.Tools
  
  @doc ~S"""
  Generate an ascii from current board game.
  """
  @spec to_ascii(Game.t) :: String.t
  def to_ascii(game) do
    board = game.current_board
    Tools.coordinates_to_ascii_board(board.coordinates)
  end
  
  @doc ~S"""
  Returns list from current board game.
  """
  @spec to_list(Game.t) :: list
  def to_list(game) do
    board = game.current_board
    range = 0..(board.size - 1)
    for x <- range do
      for y <- range do
        symbol = board.coordinates |> Map.get({x, y})
        Tools.symbol_to_text(symbol)
      end
    end
  end
end