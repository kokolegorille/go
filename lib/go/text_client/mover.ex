defmodule Go.TextClient.Mover do
  @moduledoc false
  
  alias Go.Game
  alias Go.TextClient.State
  
  def make_move(%State{move: move} = game) when is_nil(move) do
    game
  end
  def make_move(
    %State{game_service: game_service, move: {action, arg}} = game
  ) do
    mfa = {Game, action, [game_service, arg]}
    apply_move(game, mfa)
  end
  
  defp apply_move(game, {m, f, a}) do
    try do
      case apply(m, f, a) do
        {:ok, new_game_service} ->
          %{game | 
            game_service: new_game_service, 
            tally: Game.tally(new_game_service), 
            move: nil}
        {:error, reason} ->
          IO.puts reason
          game
      end
    rescue
      error in UndefinedFunctionError -> 
        IO.puts "Error: #{inspect error}"
        game
    end
  end
end