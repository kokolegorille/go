defmodule Go.Board do
  @moduledoc """
  
  Documentation for Go.Board
  
  Godash port to elixir
  godash url: https://github.com/duckpunch/godash
  
  Avril 2017, hf
  """
  
  alias __MODULE__
  require Go.Board.Tools
  alias Go.Board.Tools
  
  @type coordinate :: {integer, integer}
  @type list_of_coordinates :: [coordinate]
  @type color :: :black | :white | :empty
  @type move :: {coordinate, color}
  
  @typedoc """
  Represents the state for a game of go.
  """
  @type t :: %Board{ 
    size: integer, coordinates: map, next_turn: color, 
    black_captures: integer, white_captures: integer, komi: float,
    history: list,
    placements: list
  }
  
  defstruct [
    size: 19, coordinates: %{}, next_turn: :black,
    black_captures: 0, white_captures: 0, komi: 7.5,
    history: [],
    placements: []
  ]
  
  @doc ~S"""
  Returns a new Board structure from a map.
  If You want to clone from an existing structure, 
  transform to a map firstby  using : 
  
  initial_state |> Map.from_struct |> Go.Board.new
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
  
  ## Examples : Testing superko
      iex> alias Go.Board
      iex> board = Board.new
      iex> {:ok, board} = Board.add_move board, {{2, 3}, :black}
      iex> {:ok, board} = Board.add_move board, {{4, 2}, :white}
      iex> {:ok, board} = Board.add_move board, {{3, 2}, :black}
      iex> {:ok, board} = Board.add_move board, {{5,3}, :white}
      iex> {:ok, board} = Board.add_move board, {{3, 4}, :black}
      iex> {:ok, board} = Board.add_move board, {{4,4}, :white}
      iex> {:ok, board} = Board.add_move board, {{4, 3}, :black}
      iex> {:ok, board} = Board.add_move board, {{3, 3}, :white}
      iex> Board.add_move board, {{4, 3}, :black}
      {:error, "superko."}
      
  """
  @spec add_move(t, move) :: {:ok, t} | {:error, binary}
  def add_move(board, {coordinate, color} = move) do
    legal_move = is_legal_move(board, move)
    
    cond do
      color != board.next_turn -> {:error, "not your turn."}
      ! legal_move -> {:error, "illegal move."}
      legal_move -> 
        # Add move
        new_coordinates = Map.put(board.coordinates, coordinate, color)
        
        # Remove killed stones
        kills = killed_stones(board, coordinate, color)
        kills_count = kills |> Enum.count
        
        # Calculate captures info
        captures = build_captures(
          color, 
          kills_count, 
          board.black_captures, 
          board.white_captures)
        
        # It is a reduction of the killed stones, taking the new_coordinates 
        # as entry point, and returning it to new coordinates!        
        new_coordinates = kills
        |> Enum.reduce(new_coordinates, fn(c, acc) -> Map.put(acc, c, :empty) end)
        
        # Checking for superko needs to keep track of history
        
        lookup_table = board.history |> Enum.map(fn h -> h.fengo end)
        if is_superko(new_coordinates, opposite_color(board.next_turn), lookup_table) do
          {:error, "superko."}
        else
          # Add to history
          history_item = build_history_item(board, [{:add_move, move} | board.placements])
          new_history = [history_item | board.history]
          
          new_board = %Board{Map.merge(board, captures) | 
            coordinates: new_coordinates,
            next_turn: opposite_color(board.next_turn),
            history: new_history,
            placements: []
          }
          {:ok, new_board}
        end
    end
  end
  
  @doc ~S"""
  Pass move. Not in original godash!
  
  ## Examples
      iex> alias Go.Board
      iex> board = Board.new
      iex> {status, _} = Board.pass board, :black
      iex> status == :ok
      true
      
  """
  @spec pass(t, color) :: {:ok, t} | {:error, binary}
  def pass(board, color) do 
    case color == board.next_turn do 
      true -> 
        # Add to history
        history_item = build_history_item(board, [{:pass, color} | board.placements])
        new_history = [history_item | board.history]
        
        new_board = %Board{board | 
          next_turn: opposite_color(board.next_turn),
          history: new_history,
          placements: []
        }
        {:ok, new_board}
        
      false -> {:error, "not your turn."}
    end
  end
  
  @doc ~S"""
  Place one stone on the board.
  """
  @spec place_stone(t, coordinate, color, boolean) :: {:ok, t} | {:error, binary}
  def place_stone(board, coordinate, color, force \\ false) do
    current_color = board.coordinates[coordinate]
    
    if (! force && opposite_color(current_color) == color) do
      {:error, "there is already a stone, pass force=true to override."}
    else
      new_board = %Board{board | 
        coordinates: Map.put(board.coordinates, coordinate, color),
        placements: [{:place_stone, coordinate, color} | board.placements]
      }
      {:ok, new_board}
    end
  end
  
  # @doc ~S"""
  # Place multiple stones on the board.
  # """
  @spec place_stones(t, list_of_coordinates, color) :: {:ok, t}
  def place_stones(board, [], _color) do
    {:ok, board}
  end 
  def place_stones(board, [coordinate | tail], color) do
    {:ok, new_board} = place_stone(board, coordinate, color)
    place_stones(new_board, tail, color)
  end
  
  @doc ~S"""
  Remove the stone at the given location.
  """
  @spec remove_stone(t, coordinate) :: {:ok, t}
  def remove_stone(board, coordinate) do
    new_board = %Board{board | 
      coordinates: Map.put(board.coordinates, coordinate, :empty),
      placements: [{:remove_stone, coordinate} | board.placements]
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
  
  @doc ~S"""
  Like pass move, but does not change history state
  
  Not in original godash!
  
  ## Examples
      iex> alias Go.Board
      iex> board = Board.new
      iex> {:ok, board} = Board.toggle_turn board
      iex> board.next_turn
      :white
      
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
    adjacent_coordinates(board, coordinate)
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
    group(board, coordinate)
    |> Enum.reduce([], fn (c, acc) -> 
      list_union(matching_adjacent_coordinates(board, c, :empty), acc) 
    end)
  end
  
  @doc ~S"""
  Returns the numbder of liberties from a coordinate
  """
  @spec liberty_count(t, coordinate) :: integer
  def liberty_count(board, coordinate) do
    liberties(board, coordinate) |> Enum.count
  end
  
  @doc ~S"""
  Returns the list of killed stones from a coordinate and color
  Not in godash
  """
  @spec killed_stones(t, coordinate, color) :: list_of_coordinates
  def killed_stones(board, coordinate, color) do
    matching_adjacent_coordinates(board, coordinate, opposite_color(color))
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
      matching_adjacent_coordinates(board, coordinate, color)
      |> Enum.any?(fn (c) -> liberty_count(board, c) > 1 end)
    
    will_kill_something = matching_adjacent_coordinates(board, coordinate, opposite_color(color))
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
  Generate an ascii board.
  """
  @spec to_ascii_board(t) :: binary
  def to_ascii_board(board) do
    Tools.coordinates_to_ascii_board(board.coordinates)
  end
  
  @doc ~S"""
  Returns list from board.
  """
  @spec to_array(t) :: list
  def to_array(board) do

    range = 0..(board.size - 1)

    for x <- range do
      for y <- range do
        symbol = board.coordinates |> Map.get({x, y})
        Tools.symbol_to_text(symbol)
      end
    end
  end
  
  # PRIVATE
  
  defp initial_coordinates(size) do
    range = 0..(size - 1)
    for x <- range, y <- range do
      {{x, y}, :empty}
    end |> Enum.into(%{})
  end
  
  # Returns the opposite of a given color
  def opposite_color(color) do
    case color do
      :black -> :white
      :white -> :black
      _ -> :empty
    end
  end
  
  # Returns true if coordinate is inside board range
  defp in_range({x, y} = _coordinate, size) do
    x >= 0 && x < size && y >= 0 && y < size
  end
  
  # Returns union between list1 and list2
  # You transform to MapSet, and convert back to list
  # Set is deprecated in favor of MapSet!
  defp list_union(list1, list2) when is_list(list1) and is_list(list2) do
    MapSet.union(Enum.into(list1, MapSet.new), Enum.into(list2, MapSet.new))
    |> Enum.into([])
  end
  
  # Save history informations for each turn (add_move, pass)
  defp build_history_item(%{
    coordinates: coordinates, 
    next_turn: next_turn,
    black_captures: black_captures, 
    white_captures: white_captures, 
    komi: komi
    } = _board, actions) do
      
    %{
      fengo: fengo(coordinates, next_turn),
      actions: actions,
      count_info: %{black_captures: black_captures, white_captures: white_captures, komi: komi}
    }
  end
  
  # Keep track of captured stones for black and white
  # It only increments counter for each color in case of kill
  defp build_captures(color, kills_count, black_captures, white_captures) do
    cond do
      kills_count == 0 -> %{}
      color == :black -> 
        new_black_captures = black_captures + kills_count
        %{black_captures: new_black_captures}
      color == :white -> 
        new_white_captures = white_captures + kills_count
        %{white_captures: new_white_captures}
      true -> 
        %{}
    end
  end
  
  # Check if the position does not repeat!
  # http://senseis.xmp.net/?Superko
  #
  # From coordinates, next_turn we build a string which contains :
  #
  # next_turn |> String.first |> String.upcase <> 
  # A RLE encoded string representation of the coordinates
  #
  # which should be unique in the history key
  defp is_superko(coordinates, next_turn, lookup_table) do
    lookup = fengo(coordinates, next_turn)

    # Does the lookup key already exists in history?
    Enum.member?(lookup_table, lookup)
  end
  
  # Returns a string of next_turn and string_coordinates
  defp fengo(coordinates, next_turn) do 
    color_symbol = next_turn 
    |> to_string 
    |> String.first 
    |> String.upcase
    "#{color_symbol} #{Tools.coordinates_to_string(coordinates)}"
  end
end