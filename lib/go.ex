defmodule Go do
  @moduledoc false
  
  alias Go.Game
  
  def new_game(args \\ %{}), do: Go.Game.new(args)
  
  defdelegate add_move(game, move), to: Game
  defdelegate pass(game, color), to: Game
  defdelegate place_stone(game, coordinate, color), to: Game
  defdelegate place_stone(game, coordinate, color, force), to: Game
  defdelegate place_stones(game, coordinates, color), to: Game
  defdelegate remove_stone(game, coordinate), to: Game
  defdelegate remove_stones(game, coordinates), to: Game
  defdelegate reset(game), to: Game
  defdelegate resign(game, color), to: Game
  defdelegate toggle_turn(game), to: Game
  defdelegate to_ascii(game), to: Game
  defdelegate to_list(game), to: Game
  defdelegate tally(game), to: Game
end
