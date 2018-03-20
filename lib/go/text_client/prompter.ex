defmodule Go.TextClient.Prompter do
  @moduledoc false
  
  alias Go.Board.Tools
  alias Go.TextClient.State
  
  # pass, resign or move ... like cc
  def accept_move(%State{} = game) do
    "#{game.tally.next_turn}'s move: "
    |> IO.gets()
    |> check_input(game)
  end
  
  defp check_input({:error, reason}, _game) do
    exit_with_message("Game ended: #{reason}")
  end
  defp check_input(:eof, _game) do
    exit_with_message("Looks like you gave up...")
  end
  defp check_input(input, %State{} = game) do
    input = String.trim(input)
    color = game.tally.next_turn
    
    case input do
      "pass" ->
        %{game | move: {:pass, color}}
      "resign" ->
        %{game | move: {:resign, color}}
      "" ->
        IO.puts "empty input"
        game
      move ->
        coordinate = Tools.move_to_coordinate(move)
        %{game | move: {:add_move, {coordinate, color}}}
    end
  end
  
  defp exit_with_message(message) do
    IO.puts(message)
    exit(:normal)
  end
end