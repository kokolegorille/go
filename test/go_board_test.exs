defmodule GoBoardTest do
  use ExUnit.Case
  alias Go.Board
  doctest Board
  
  # Describe Adjacent Coordinates
  
  test "yields the correct 4 when coordinate is in center" do
    {:ok, board} = Board.place_stone Board.new, {9, 9}, :black
    assert Board.adjacent_coordinates(board, {9, 9}) |> Enum.sort == [{8, 9}, {9, 8}, {9, 10}, {10, 9}]
  end
  
  test "yields the correct 3 when coordinate is on side" do
    {:ok, board} = Board.place_stone Board.new, {0, 9}, :black
    assert Board.adjacent_coordinates(board, {0, 9}) |> Enum.sort == [{0, 8}, {0, 10}, {1, 9}]
  end
  
  test "yields the correct 2 when coordinate is in corner" do
    {:ok, board} = Board.place_stone Board.new, {18, 18}, :black
    assert Board.adjacent_coordinates(board, {18, 18}) |> Enum.sort == [{17, 18}, {18, 17}]
  end
  
  # Describe Matching Adjacent Coordinates
  
  test "matching adjacent" do
    {:ok, board} = Board.place_stones Board.new, [{9, 8}], :black
    {:ok, board} = Board.place_stones board, [{9, 10}, {8, 9}], :white
    assert Board.matching_adjacent_coordinates(board, {9, 9}, :white) |> Enum.sort == [{8, 9}, {9, 10}]
    assert Board.matching_adjacent_coordinates(board, {9, 9}, :black) |> Enum.sort == [{9, 8}]
    assert Board.matching_adjacent_coordinates(board, {9, 9}, :empty) |> Enum.sort == [{10, 9}]
  end
  
  # Describe Group
  
  test "finds a group of 1" do
    coordinate = {2, 2}
    board = Board.new(%{size: 5})
    {:ok, board} = Board.place_stone board, coordinate, :black
    assert Board.group(board, coordinate) == [{2, 2}]
  end

  test "finds a group of 2" do
    coordinate = {2, 2}
    board = Board.new(%{size: 5})
    {:ok, board} = Board.place_stones board, [{2, 1}, {2, 2}], :black
    assert Board.group(board, coordinate) |> Enum.sort == [{2, 1}, {2, 2}]
  end
  
  test "finds a group of 1 with adjacent opposite color" do
    coordinate = {2, 2}
    board = Board.new(%{size: 5})
    {:ok, board} = Board.place_stone board, {2, 2}, :black
    {:ok, board} = Board.place_stone board, {2, 1}, :white
    assert Board.group(board, coordinate) == [{2, 2}]
  end

  test "finds empty triangle" do
    coordinate = {2, 2}
    board = Board.new(%{size: 5})
    {:ok, board} = Board.place_stones board, [{2, 2}, {2, 1}, {1, 2}], :black
    assert Board.group(board, coordinate) |> Enum.sort == 
      [{1, 2}, {2, 1}, {2, 2}]
  end
  
  # Describe Opposite Color
  
  test "returns opposite of black" do
    assert Board.opposite_color(:black) == :white
  end
  
  test "returns opposite of white" do
    assert Board.opposite_color(:white) == :black
  end
  
  test "returns empty for random strings" do
    assert Board.opposite_color("zorglub") == :empty
  end
  
  # Describe Liberties and Liberty Count
  
  test "find values for 1 stone" do
    coordinate = {2, 2}
    board = Board.new(%{size: 5})
    {:ok, board} = Board.place_stone board, {2, 2}, :black
    assert Board.liberties(board, coordinate) |> Enum.sort == 
      [{1, 2}, {2, 1}, {2, 3}, {3, 2}]
    assert Board.liberty_count(board, coordinate) == 4
  end
  
  test "find values for group of 2" do
    coordinate = {2, 2}
    board = Board.new(%{size: 5})
    {:ok, board} = Board.place_stones board, [{2, 2}, {2, 1}], :black
    assert Board.liberties(board, coordinate) |> Enum.sort == 
      [{1, 1}, {1, 2}, {2, 0}, {2, 3}, {3, 1}, {3, 2}]
    assert Board.liberty_count(board, coordinate) == 6
  end
  
  test "properly decrement liberty with opposite color adjacent" do
    coordinate = {2, 2}
    board = Board.new(%{size: 5})
    {:ok, board} = Board.place_stone board, {2, 2}, :black
    {:ok, board} = Board.place_stone board, {2, 1}, :white
    assert Board.liberties(board, coordinate) |> Enum.sort == 
      [{1, 2}, {2, 3}, {3, 2}]
    assert Board.liberty_count(board, coordinate) == 3
  end
  
  test "count shared liberties in empty triangle" do
    coordinate = {2, 2}
    board = Board.new(%{size: 5})
    {:ok, board} = Board.place_stones board, [{2, 2}, {2, 1}, {3, 2}], :black
    assert Board.liberties(board, coordinate) |> Enum.sort == 
      [{1, 1}, {1, 2}, {2, 0}, {2, 3}, {3, 1}, {3, 3}, {4, 2}]
    assert Board.liberty_count(board, coordinate) == 7
  end
  
  # Describe Is Legal Move
  
  test "identifies suicide moves as invalid" do
    board = Board.new(%{size: 3})
    {:ok, board} = Board.place_stones board, [{1, 0}, {0, 1}, {2, 1}, {1, 2}], :black
    {:ok, board} = Board.toggle_turn board
    assert ! Board.is_legal_move(board, {{1, 1}, :white})
  end
  
  test "allows filling in a ponnuki" do
    board = Board.new(%{size: 3})
    {:ok, board} = Board.place_stones board, [{1, 0}, {0, 1}, {2, 1}, {1, 2}], :black
    assert Board.is_legal_move(board, {{1, 1}, :black})
  end

  test "marks suicide in corner as invalid" do
    board = Board.new(%{size: 3})
    {:ok, board} = Board.place_stones board, [{2, 0}, {2, 1}, {1, 2}], :black
    assert ! Board.is_legal_move(board, {{2, 2}, :white})
  end

  test "marks suicide in corner that kills first as valid" do
    board = Board.new(%{size: 3})
    {:ok, board} = Board.place_stones board, [{1, 2}, {2, 0}, {2, 1}], :black
    {:ok, board} = Board.place_stones board, [{1, 0}, {1, 1}], :white
    {:ok, board} = Board.toggle_turn board
    assert Board.is_legal_move(board, {{2, 2}, :white})
  end
  
  # Describe Remove Stone
  
  test "can remove a specified stone" do
    coordinate = {9, 9}
    board = Board.new
    {:ok, board} = Board.place_stone board, coordinate, :black
    {:ok, board} = Board.remove_stone board, coordinate
    assert board.coordinates[coordinate] == :empty
  end
  
  test "does not blow up even if a coordinate is not there" do
    coordinate = {9, 9}
    board = Board.new
    {:ok, board} = Board.remove_stone board, coordinate
    assert board.coordinates[coordinate] == :empty
  end
  
  # Describe Remove Stones
  
  test "can remove a bunch of stones" do
    board = Board.new
    {:ok, board} = Board.place_stones board, [{9, 9}, {9, 10}, {3, 9}], :black
    {:ok, board} = Board.place_stones board, [{3, 4}, {5, 9}], :white
    {:ok, board} = Board.remove_stones board, [{9, 9}, {3, 9}, {5, 9}]
    assert board.coordinates[{9, 9}] == :empty
    assert board.coordinates[{3, 9}] == :empty
    assert board.coordinates[{5, 9}] == :empty
    assert board.coordinates[{3, 4}] == :white
    assert board.coordinates[{9, 10}] == :black
  end
  
  # Describe Add Move
  
  test "adds a move to simple empty board" do
    board = Board.new
    {:ok, board} = Board.add_move board, {{9, 9}, :black}
    assert board.coordinates[{9, 9}] == :black
  end
  
  test "throws if adding same move twice" do
    board = Board.new
    {:ok, board} = Board.add_move board, {{9, 9}, :black}
    assert is_in_error?(Board.add_move board, {{9, 9}, :white})
  end
  
  test "kills groups that run out of liberties" do
    board = Board.new(%{size: 3})
    {:ok, board} = Board.place_stones board, [{2, 0}, {2, 1}, {1, 2}], :black
    {:ok, board} = Board.place_stones board, [{1, 0}, {1, 1}], :white
    {:ok, board} = Board.toggle_turn board
    {:ok, board} = Board.add_move board, {{2, 2}, :white}
    assert board.coordinates[{2, 0}] == :empty
    assert board.coordinates[{2, 1}] == :empty
  end

  test "can kill 3 stone groups" do
    board = Board.new(%{size: 5})
    {:ok, board} = Board.place_stones board, [{0, 0}, {0, 1}, {0, 2}, {2, 0}, {2, 1}, {2, 2}], :black
    {:ok, board} = Board.place_stones board, [{1, 0}, {1, 1}, {1, 2}], :white
    {:ok, board} = Board.add_move board, {{1, 3}, :black}
    assert board.coordinates[{1, 0}] == :empty
    assert board.coordinates[{1, 1}] == :empty
    assert board.coordinates[{1, 2}] == :empty
  end
  
  # Describe Pass
  
  test "pass" do
    {:ok, board} = Board.pass Board.new, :black
    assert board.next_turn == :white
    assert Enum.count(board.history) == 1
  end
  
  # Describe Toggle Turn
  
  test "toggle_turn" do
    {:ok, board} = Board.toggle_turn Board.new
    assert board.next_turn == :white
    assert Enum.count(board.history) == 0
  end
  
  # Describe Placements
  
  test "placements" do
    board = Board.new
    {:ok, board} = Board.place_stones board, [{1, 1}, {1, 2}, {1, 3}], :black
    {:ok, board} = Board.add_move board, {{2, 3}, :black}
    {:ok, board} = Board.remove_stones board, [{1, 1}, {1, 2}]
    {:ok, board} = Board.add_move board, {{1, 1}, :white}
    assert Board.to_ascii_board(board) |> String.slice(0, 60) == 
      "+++++++++++++++++++\n+X+O+++++++++++++++\n+++O+++++++++++++++\n"
  end
  
  # Describe Place Stone
  
  test "can place a stone on an empty board" do
    coordinate = {9, 9}
    {:ok, board} = Board.place_stone Board.new, coordinate, :black
    assert board.coordinates[coordinate] == :black
  end

  test "throws if placing onto a coordinate with an opposite stone color" do
    coordinate = {9, 9}
    {:ok, board} = Board.place_stone Board.new, coordinate, :black
    assert is_in_error?(Board.place_stone board, coordinate, :white)
  end

  test "can force an existing opposite color stone placement" do
    coordinate = {9, 9}
    {:ok, board} = Board.place_stone Board.new, coordinate, :black
    {:ok, board} = Board.place_stone board, coordinate, :white, true
    assert board.coordinates[coordinate] == :white
  end

  test "can place a stone that breaks the rules" do
    coordinates = [{2, 1}, {2, 3}, {1, 2}, {3, 2}]
    coordinate = {2, 2}
    {:ok, board} = Board.place_stones Board.new, coordinates, :black
    {:ok, board} = Board.place_stone board, coordinate, :white
    assert board.coordinates[coordinate] == :white
  end
  
  # Describe Place Stones
    
  test "can place a bunch of stones" do
    coordinates = [{2, 1}, {2, 3}, {1, 2}, {3, 2}]
    {:ok, board} = Board.place_stones Board.new, coordinates, :black
    assert Enum.map(coordinates, fn (c) -> board.coordinates[c] end) == [:black, :black, :black, :black]
  end
  
  # Describe Superko
  
  test "superko rule" do
    board = Board.new
    {:ok, board} = Board.add_move board, {{2, 3}, :black}
    {:ok, board} = Board.add_move board, {{4, 2}, :white}
    {:ok, board} = Board.add_move board, {{3, 2}, :black}
    {:ok, board} = Board.add_move board, {{5,3}, :white}
    {:ok, board} = Board.add_move board, {{3, 4}, :black}
    {:ok, board} = Board.add_move board, {{4,4}, :white}
    {:ok, board} = Board.add_move board, {{4, 3}, :black}
    {:ok, board} = Board.add_move board, {{3, 3}, :white}
    assert is_in_error?(Board.add_move(board, {{4, 3}, :black}))
  end
  
  # Describe To Ascii Board
  
  test "can produce a simple empty board" do
    board = Board.new(%{size: 3})
    assert Board.to_ascii_board(board) == "+++\n+++\n+++\n"
  end
  
  test "can produce a board with one move" do
    board = Board.new(%{size: 3})
    {:ok, board} = Board.add_move board, {{1, 1}, :black}
    assert Board.to_ascii_board(board) == "+++\n+O+\n+++\n"
  end
  
  # Describe Game Over
  
  test "new board is not over" do
    board = Board.new()
    assert ! board.is_over
  end
  
  test "double pass end the game" do
    board = Board.new(%{size: 3})
    {:ok, board} = Board.pass board, :black
    {:ok, board} = Board.pass board, :white
    assert board.is_over
  end
  
  test "adding a move reset passes counter" do
    board = Board.new(%{size: 3})
    {:ok, board} = Board.pass board, :black
    {:ok, board} = Board.add_move board, {{1, 1}, :white}
    {:ok, board} = Board.pass board, :black
    assert ! board.is_over
    assert board.consecutive_passes == 1
  end
  
  test "resign end the game" do
    board = Board.new(%{size: 3})
    {:ok, board} = Board.resign board, :black
    assert board.is_over
    assert board.winner == :white
  end
  
  test "cannot add move after end of the game" do
    board = Board.new(%{size: 3})
    {:ok, board} = Board.pass board, :black
    {:ok, board} = Board.pass board, :white
    assert is_in_error?(Board.add_move board, {{1, 1}, :black})
  end
  
  test "cannot pass after end of the game" do
    board = Board.new(%{size: 3})
    {:ok, board} = Board.pass board, :black
    {:ok, board} = Board.pass board, :white
    assert is_in_error?(Board.pass board, :black)
  end
  
  # Most functions returns are tuple of form {:ok, t} | {:error, reason}
  # This helper help to check if a response is an error, 
  # without caring about reason
  defp is_in_error?(response) do
    Tuple.to_list(response) |> List.first == :error
  end
end
