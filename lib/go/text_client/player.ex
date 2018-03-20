defmodule Go.TextClient.Player do
  @moduledoc false
  
  alias Go.TextClient.{Mover, State, Summary, Prompter}
  
  def play(%State{tally: %{game_state: :game_over, winner: winner}}) do
    IO.puts "game over, the winner is #{winner}"
    exit(:normal)
  end
  def play(%State{tally: %{game_state: :running}} = game) do
    game
    |> Summary.display()
    |> Prompter.accept_move()
    |> Mover.make_move()
    |> play()
  end
end