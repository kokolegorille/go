defmodule Go.Coordinate do
  @moduledoc """
  Documentation for Go.Coordinate

  To be more compliant with Ecto and JSON, this entity replace old tuple form
  of coordinate.

  It is a simple struct with row and col keys.
  """

  alias __MODULE__

  @enforce_keys [:row, :col]

  @type row :: integer
  @type col :: integer

  @type t :: %Coordinate{
    row: row,
    col: col
  }
  defstruct [:row, :col]

  @doc ~S"""
  Returns a new Coordinate structure
  it accepts:
    * a tuple
    * 2 arguments (row, col)
  """
  @spec new({row, col}) :: t
  #def new({row, col}), do: %Coordinate{row: row, col: col}
  def new({_row, _col} = coordinate), do: from_tuple(coordinate)
  @spec new(row, col) :: t
  def new(row, col), do: new({row, col})

  @doc ~S"""
  Returns a new Coordinate structure from a tuple
  """
  @spec from_tuple({row, col}) :: t
  def from_tuple(coordinate) do
    %Coordinate{row: elem(coordinate, 0), col: elem(coordinate, 1)}
  end

  @doc ~S"""
  Returns a tuple from Coordinate structure
  """
  @spec to_tuple(t) :: {row, col}
  def to_tuple(coordinate), do: {coordinate.row, coordinate.col}

  @doc ~S"""
  Returns a list of new Coordinate structures from a list of tuples
  """
  @spec list_from_tuples(list({row, col})) :: list(t)
  def list_from_tuples(coordinates), do: coordinates |> Enum.map(&from_tuple(&1))

  @doc ~S"""
  Returns a list of new tuples from a list of Coordinate structures
  """
  @spec list_to_tuples(list(t)) :: list({row, col})
  def list_to_tuples(coordinates), do: coordinates |> Enum.map(&to_tuple(&1))
end