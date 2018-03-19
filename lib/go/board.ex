defmodule Go.Board do
  @moduledoc """

  Documentation for Go.Board

  Godash port to elixir
  godash url: https://github.com/duckpunch/godash

  Avril 2017, hf
  """

  alias __MODULE__

  @type coordinate :: {integer, integer}
  @type list_of_coordinates :: [coordinate]
  @type color :: :black | :white | :empty
  @type move :: {coordinate, color}

  @type t :: %Board{
    size: integer, coordinates: map, next_turn: color
  }

  defstruct [
    size: 19, coordinates: %{}, next_turn: :black
  ]

  @doc ~S"""
  Returns a new Board structure from a map.
  """
  @spec new(map) :: t
  def new(initial_state \\ %{}) do
    size = initial_state[:size] || 19
    coordinates = initial_state[:coordinates] ||
      initial_coordinates(size)

    new_state = initial_state
    |> Map.put(:size, size)
    |> Map.put(:coordinates, coordinates)

    struct(%Board{}, new_state)
  end

  # BOARD API

  @doc ~S"""
  Add move to a board.
  """
  def add_move(board, {coordinate, color} = move) do
    legal_move = is_legal_move(board, move)

    cond do
      color != board.next_turn -> {:error, "not your turn."}
      # board.is_over -> {:error, "game is over."}
      ! legal_move -> {:error, "illegal move."}
      legal_move ->
        # Add move
        new_coordinates = Map.put(board.coordinates, coordinate, color)

        # Remove killed stones
        kills = killed_stones(board, coordinate, color)

        # It is a reduction of the killed stones, taking the new_coordinates
        # as entry point, and returning it to new coordinates!
        new_coordinates = kills
        |> Enum.reduce(new_coordinates, fn(c, acc) -> Map.put(acc, c, :empty) end)

        new_board = %Board{board |
          coordinates: new_coordinates,
          next_turn: opposite_color(board.next_turn)
        }
        {:ok, new_board}

    end
  end

  @doc ~S"""
  Pass move. Not in original godash!
  """
  @spec pass(t, color) :: {:ok, t} | {:error, String.t}
  def pass(board, color) do
    if color == board.next_turn do
      new_board = %Board{board | next_turn: opposite_color(board.next_turn)}
      {:ok, new_board}
    else
      {:error, "not your turn."}
    end
  end

  @doc ~S"""
  Reset. Not in original godash!
  """
  @spec reset(t) :: {:ok, t}
  def reset(board) do
    new_board = Board.new(%{size: board.size})
    {:ok, new_board}
  end

  ## PLACEMENTS (should happen before add_move or pass!)

  @doc ~S"""
  Place one stone on the board.
  """
  @spec place_stone(t, coordinate, color, boolean) :: {:ok, t} | {:error, String.t}
  def place_stone(board, coordinate, color, force \\ false) do
    current_color = board.coordinates[coordinate]

    if (! force && opposite_color(current_color) == color) do
      {:error, "there is already a stone, pass force=true to override."}
    else
      new_board = %Board{board |
        coordinates: Map.put(board.coordinates, coordinate, color)
      }
      {:ok, new_board}
    end
  end

  # @doc ~S"""
  # Place multiple stones on the board.
  # """
  @spec place_stones(t, list_of_coordinates, color) :: {:ok, t} | {:error, String.t}
  def place_stones(board, [], _color), do: {:ok, board}
  def place_stones(board, [coordinate | tail], color) do
    case place_stone(board, coordinate, color) do
      {:ok, new_board} -> place_stones(new_board, tail, color)
      {:error, reason} -> {:error, reason}
    end
  end

  @doc ~S"""
  Remove the stone at the given location.
  """
  @spec remove_stone(t, coordinate) :: {:ok, t}
  def remove_stone(board, coordinate) do
    new_board = %Board{board |
      coordinates: Map.put(board.coordinates, coordinate, :empty)
    }
    {:ok, new_board}
  end

  # @doc ~S"""
  # Remove multiple stones.
  # call remove_stone under the hood
  # """
  @spec remove_stones(t, list_of_coordinates) :: {:ok, t}
  def remove_stones(board, []) do
    {:ok, board}
  end
  def remove_stones(board, [coordinate | tail]) do
    {:ok, new_board} = remove_stone(board, coordinate)
    remove_stones(new_board, tail)
  end

  ## END OF PLACEMENTS

  @doc ~S"""
  Like pass move, but does not change history state.
  Not in original godash!
  """
  @spec toggle_turn(t) :: {:ok, t}
  def toggle_turn(board) do
    new_board = %Board{board | next_turn: opposite_color(board.next_turn)}
    {:ok, new_board}
  end

  # LOGIC

  @doc ~S"""
  Returns a list of valid adjacent coordinates.
  """
  @spec adjacent_coordinates(t, coordinate) :: list_of_coordinates
  def adjacent_coordinates(board, {x, y} = _coordinate) do
    [{x, y + 1}, {x, y - 1}, {x + 1, y}, {x - 1, y}]
    |> Enum.filter(&in_range(&1, board.size))
  end

  @doc ~S"""
  Returns a list of matching adjacent coordinates
  It will try to guess the color if not specified
  """
  @spec matching_adjacent_coordinates(t, coordinate) :: list_of_coordinates
  def matching_adjacent_coordinates(board, coordinate) do
    color_to_match = board.coordinates[coordinate]
    matching_adjacent_coordinates(board, coordinate, color_to_match)
  end

  @doc ~S"""
  Returns a list of matching adjacent coordinates
  For a given color
  """
  @spec matching_adjacent_coordinates(t, coordinate, color) :: list_of_coordinates
  def matching_adjacent_coordinates(board, coordinate, color) do
    board
    |> adjacent_coordinates(coordinate)
    |> Enum.filter(fn(c) -> board.coordinates[c] == color end)
  end

  @doc ~S"""
  Returns the group for a given coordinate
  Recursive calculation differs from godash
  """
  @spec group(t, coordinate) :: list_of_coordinates
  def group(board, coordinate) do
    add_to_group(board, [coordinate], [])
  end

  # Recursive call with found as the accumulator
  defp add_to_group(_board, [], found), do: found
  defp add_to_group(board, [current | tail] = _queue, found) do
    more_matching = matching_adjacent_coordinates(board, current)

    # New queue is the union of tail and new matching square
    # -- is used to intersect 2 lists
    new_queue = list_union(tail, (more_matching -- found))

    add_to_group(board, new_queue, [current | found])
  end

  @doc ~S"""
  Returns the list of liberties from a coordinate
  """
  @spec liberties(t, coordinate) :: list_of_coordinates
  def liberties(board, coordinate) do
    board
    |> group(coordinate)
    |> Enum.reduce([], fn (c, acc) ->
      list_union(matching_adjacent_coordinates(board, c, :empty), acc)
    end)
  end

  @doc ~S"""
  Returns the numbder of liberties from a coordinate
  """
  @spec liberty_count(t, coordinate) :: integer
  def liberty_count(board, coordinate) do
    board 
    |> liberties(coordinate) 
    |> Enum.count
  end

  @doc ~S"""
  Returns the list of killed stones from a coordinate and color
  Not in godash
  """
  @spec killed_stones(t, coordinate, color) :: list_of_coordinates
  def killed_stones(board, coordinate, color) do
    board
    |> matching_adjacent_coordinates(coordinate, opposite_color(color))
    |> Enum.filter(fn(c) -> liberty_count(board, c) == 1 end)
    |> Enum.map(fn(c) -> group(board, c) end)
    |> List.flatten
    |> Enum.uniq
  end

  @doc ~S"""
  Returns the validity of a move

  Modified from godash implementation
  Original implementation create a new board to check if it will_have_liberties
  Instead, check if any of surrounding helping groups have more than 1 lib

  This does not check superko, as it needs history to validate ko rule.
  It is done when adding a move, by checking if next position + next_turn does
  not exists in history already.
  """
  @spec is_legal_move(t, move) :: boolean
  def is_legal_move(board, {coordinate, color} = _move) do
    is_not_occupied = board.coordinates[coordinate] == :empty

    # Will be true if has liberties, or connect to a group with at least 2 libs!
    will_have_liberties = liberty_count(board, coordinate) > 0 ||
      board
      |> matching_adjacent_coordinates(coordinate, color)
      |> Enum.any?(fn (c) -> liberty_count(board, c) > 1 end)

    will_kill_something = board
    |> matching_adjacent_coordinates(coordinate, opposite_color(color))
    |> Enum.any?(fn(c) -> liberty_count(board, c) == 1 end)

    is_not_occupied && (will_have_liberties || will_kill_something)
  end

  @doc ~S"""
  Returns the validity of a black move
  """
  @spec is_legal_black_move(t, coordinate) :: boolean
  def is_legal_black_move(board, coordinate) do
    is_legal_move(board, {coordinate, :black})
  end

  @doc ~S"""
  Returns the validity of a white move
  """
  @spec is_legal_white_move(t, coordinate) :: boolean
  def is_legal_white_move(board, coordinate) do
    is_legal_move(board, {coordinate, :white})
  end

  @doc ~S"""
  Returns the opposite color of a given one.
  """
  @spec opposite_color(color) :: color
  def opposite_color(color) do
    case color do
      :black -> :white
      :white -> :black
      _ -> :empty
    end
  end

  # PRIVATE

  defp initial_coordinates(size) do
    range = 0..(size - 1)
    for x <- range, y <- range, into: %{}, do: {{x, y}, :empty}
  end

  # Returns true if coordinate is inside board range
  defp in_range({x, y} = _coordinate, size) do
    x >= 0 && x < size && y >= 0 && y < size
  end

  # Returns union between list1 and list2
  # You transform to MapSet, and convert back to list
  # Set is deprecated in favor of MapSet!
  defp list_union(list1, list2) when is_list(list1) and is_list(list2) do
    list1
    |> mapset_from_list
    |> MapSet.union(mapset_from_list(list2))
    |> Enum.into([])
  end
  
  defp mapset_from_list(list), do: Enum.into(list, MapSet.new)
end