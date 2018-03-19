defmodule GoTest do
  use ExUnit.Case
  # doctest Go
  
  alias Go.Game
  
  test "can create a new game" do
    game = Go.new_game()
    assert %Game{} = game
  end
  
  test "can create a new game from a map" do
    game = Go.new_game(%{size: 19})
    assert %Game{size: 19} = game
  end
  
  test "can create a new game from a keyword list" do
    game = Go.new_game(size: 19)
    assert %Game{size: 19} = game
  end
end
