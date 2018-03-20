defmodule Go.TextClient.Interact do
  @moduledoc false
  
  alias __MODULE__
  alias Go.Game
  alias Go.TextClient.{Player, State}
  
  def start(size) do
    %{size: size}
    |> Go.new_game()
    |> setup_state()
    |> Player.play()
  end
  
  defp setup_state(game) do
    %State{
      game_service: game,
      tally: Game.tally(game)
    }
  end
end