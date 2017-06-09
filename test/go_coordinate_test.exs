defmodule GoCoordinateTest do
  use ExUnit.Case
  alias Go.Coordinate
  
  doctest Coordinate
  
  test "yield a new coordinate from tuple" do
    coordinate = Coordinate.new({3, 3})
    assert coordinate |> is_map
  end
  
  test "yield a new coordinate from 2 arguments" do
    coordinate = Coordinate.new(3, 3)
    assert coordinate |> is_map
  end
  
  test "yield a coordinate from a valid tuple" do
    coordinate = Coordinate.from_tuple({3, 3})
    assert coordinate |> is_map
  end
  
  test "yield a tuple from a valid coordinate" do
    coordinate = Coordinate.new({3, 3}) |> Coordinate.to_tuple
    assert coordinate === {3, 3}
  end
  
  # test "yield coordinates from a valid list of tuples" do
  #   coordinates = Coordinate.list_from_tuples([{3, 3}, {4, 4}])
  #   assert
  # end
  
  test "yield tuples from a valid list of coordinates" do
    coordinates = Coordinate.list_from_tuples([{3, 3}, {4, 4}]) |> Coordinate.list_to_tuples
    assert coordinates === [{3, 3}, {4, 4}]
  end
end