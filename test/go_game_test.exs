defmodule GoGameTest do
  use ExUnit.Case
  alias Go.Game
  
  doctest Game
  
  test "yield a game with a valid board" do
    game = Game.new
    assert game.current_board |> is_map
  end
  
  test "yield a game with a sized board" do
    game = Game.new(%{size: 9})
    assert game.current_board.size === 9
  end
  
  test "yield a game from another game" do
    game = Game.new(Game.new(%{size: 9}))
    assert game |> is_map
  end
  
  test "update current_board when add a valid move" do
    game = Game.new(%{size: 9})
    {:ok, game} = game |> Game.add_move({{3, 3}, :black})
    
    board = game.current_board
    assert Map.get(board.coordinates, {3, 3}) == :black
  end
  
  # Describe Pass
  test "pass" do
    {:ok, game} = Game.pass Game.new, :black
    assert game.current_board.next_turn == :white
  end

  # Describe Toggle Turn
  test "toggle_turn" do
    {:ok, game} = Game.toggle_turn Game.new
    assert game.current_board.next_turn == :white
  end

  # Describe Placements
  test "placements" do
    game = Game.new
    {:ok, game} = Game.place_stones game, [{1, 1}, {1, 2}, {1, 3}], :black
    {:ok, game} = Game.add_move game, {{2, 3}, :black}
    {:ok, game} = Game.remove_stones game, [{1, 1}, {1, 2}]
    {:ok, game} = Game.add_move game, {{1, 1}, :white}
    
    board = game.current_board
    assert Map.get(board.coordinates, {1, 1}) == :white
    assert Map.get(board.coordinates, {1, 2}) == :empty
  end

  # Describe Place Stone
  test "can place a stone on an empty game" do
    coordinate = {9, 9}
    {:ok, game} = Game.place_stone Game.new, coordinate, :black
    assert game.current_board.coordinates[coordinate] == :black
  end

  test "throws if placing onto a coordinate with an opposite stone color" do
    coordinate = {9, 9}
    {:ok, game} = Game.place_stone Game.new, coordinate, :black
    assert is_in_error?(Game.place_stone game, coordinate, :white)
  end

  test "can force an existing opposite color stone placement" do
    coordinate = {9, 9}
    {:ok, game} = Game.place_stone Game.new, coordinate, :black
    {:ok, game} = Game.place_stone game, coordinate, :white, true
    assert game.current_board.coordinates[coordinate] == :white
  end

  test "can place a stone that breaks the rules" do
    coordinates = [{2, 1}, {2, 3}, {1, 2}, {3, 2}]
    coordinate = {2, 2}
    {:ok, game} = Game.place_stones Game.new, coordinates, :black
    {:ok, game} = Game.place_stone game, coordinate, :white
    assert game.current_board.coordinates[coordinate] == :white
  end

  # Describe Place Stones
  test "can place a bunch of stones" do
    coordinates = [{2, 1}, {2, 3}, {1, 2}, {3, 2}]
    {:ok, game} = Game.place_stones Game.new, coordinates, :black
    assert Enum.map(coordinates, fn (c) -> game.current_board.coordinates[c] end) == [:black, :black, :black, :black]
  end

  # Describe Superko
  test "superko rule" do
    game = Game.new
    {:ok, game} = Game.add_move game, {{2, 3}, :black}
    {:ok, game} = Game.add_move game, {{4, 2}, :white}
    {:ok, game} = Game.add_move game, {{3, 2}, :black}
    {:ok, game} = Game.add_move game, {{5,3}, :white}
    {:ok, game} = Game.add_move game, {{3, 4}, :black}
    {:ok, game} = Game.add_move game, {{4,4}, :white}
    {:ok, game} = Game.add_move game, {{4, 3}, :black}
    {:ok, game} = Game.add_move game, {{3, 3}, :white}
    assert is_in_error?(Game.add_move(game, {{4, 3}, :black}))
  end

  # Describe turns
  test "store turns" do
    game = Game.new
    {:ok, game} = Game.add_move game, {{2, 3}, :black}
    {:ok, game} = Game.add_move game, {{4, 2}, :white}

    assert game.turns |> Enum.count === 2
  end

  # Describe Game Over
  test "new game is not over" do
    game = Game.new()
    assert ! game.is_over
  end

  test "double pass end the game" do
    game = Game.new(%{size: 3})
    {:ok, game} = Game.pass game, :black
    {:ok, game} = Game.pass game, :white
    assert game.is_over
  end

  test "adding a move reset passes counter" do
    game = Game.new(%{size: 3})
    {:ok, game} = Game.pass game, :black
    {:ok, game} = Game.add_move game, {{1, 1}, :white}
    {:ok, game} = Game.pass game, :black
    assert ! game.is_over
    assert game.consecutive_passes == 1
  end

  test "resign end the game" do
    game = Game.new(%{size: 3})
    {:ok, game} = Game.resign game, :black
    assert game.is_over
    assert game.winner == :white
  end

  test "cannot add move after end of the game" do
    game = Game.new(%{size: 3})
    {:ok, game} = Game.pass game, :black
    {:ok, game} = Game.pass game, :white
    assert is_in_error?(Game.add_move game, {{1, 1}, :black})
  end

  test "cannot pass after end of the game" do
    game = Game.new(%{size: 3})
    {:ok, game} = Game.pass game, :black
    {:ok, game} = Game.pass game, :white
    assert is_in_error?(Game.pass game, :black)
  end
  
  test "cannot place stone after end of the game" do
    game = Game.new(%{size: 3})
    {:ok, game} = Game.resign game, :black
    assert is_in_error?(Game.place_stone game, {1, 2}, :black)
  end
  
  test "cannot place stones after end of the game" do
    game = Game.new(%{size: 3})
    {:ok, game} = Game.resign game, :black
    assert is_in_error?(Game.place_stones game, [{1, 2}, {2, 1}], :black)
  end

  test "cannot remove stone after end of the game" do
    game = Game.new(%{size: 3})
    {:ok, game} = Game.resign game, :black
    assert is_in_error?(Game.remove_stone game, {1, 2})
  end

  test "cannot remove stones after end of the game" do
    game = Game.new(%{size: 3})
    {:ok, game} = Game.resign game, :black
    assert is_in_error?(Game.remove_stones game, [{1, 2}, {2, 1}])
  end
  
  test "reset the game" do
    initial_game = Game.new(%{size: 3})
    {:ok, game} = Game.add_move initial_game, {{1, 1}, :black}
    {:ok, game} = Game.reset game
    assert initial_game == game
  end
  
  # Most functions returns are tuple of form {:ok, t} | {:error, reason}
  # This helper help to check if a response is an error, 
  # without caring about reason
  defp is_in_error?(response) do
    Tuple.to_list(response) |> List.first == :error
  end
end