defmodule GoDisplayTest do
  use ExUnit.Case
  
  alias Go.{Game, Display}
  
  # Describe To Ascii
  test "can display to_ascii a simple game" do
    game = Game.new(%{size: 3})
    assert Display.to_ascii(game) == "+++\n+++\n+++\n"
  end
  
  # Describe To List
  test "can display to_list a simple game" do
    game = Game.new(%{size: 3})
    assert Display.to_list(game) == [
      ["+", "+", "+"], 
      ["+", "+", "+"], 
      ["+", "+", "+"]
    ]
  end
end