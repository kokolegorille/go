defmodule GoBoardToolsTest do
  use ExUnit.Case
  alias Go.Board
  alias Go.Board.Tools
  
  # Describe to/from string
  
  test "yield to string" do
    {:ok, board} = Board.add_move Board.new(%{size: 9}), {{3, 3}, :black}
    
    assert board.coordinates |> Tools.coordinates_to_string === "30+1O50+"
  end
  
  test "yield from string" do
    string = "30+1O50+"
    assert string 
    |> Tools.string_to_coordinates 
    |> Tools.coordinates_to_string === string
  end
  
  test "yield from complex string" do
    string = "43+1X16+1X11+1X24+1O171+1O25+1O3+1X1+1O5+1O53+"
    c = Tools.string_to_coordinates(string)
    
    assert Tools.coordinates_to_string(c) |> Tools.string_to_coordinates
    assert Tools.string_to_coordinates(string) |> Tools.coordinates_to_string
  end  
  
  # Describe Fengo
  
  test "yield to fengo" do
    {:ok, board} = Board.add_move Board.new(%{size: 9}), {{3, 3}, :black}
    assert board 
    |> Tools.to_fengo === "W 30+1O50+"
  end

  test "yield from fengo" do
    fengo = "W 30+1O50+"
    board = fengo |> Tools.from_fengo
    
    assert board |> Tools.to_fengo === fengo
    assert fengo |> Tools.from_fengo === board
  end
end
