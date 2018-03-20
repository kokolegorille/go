defmodule Go.TextClient.Summary do
  @moduledoc false
  
  def display(%{tally: tally} = game) do
    IO.puts [
      "\n",
      tally.board,
      "game_state: #{tally.game_state}\n", 
      "move_number: #{tally.move_number}\n", 
      "winner: #{tally.winner}\n"
    ]
    game
  end
end