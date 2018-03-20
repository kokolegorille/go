defmodule Go.Game do
  @moduledoc """
  
  Documentation for Go.Game
  
  This is the main entity since version 0.2.0
  
  It manages the count (komi, captures) and history of turns.
  It manages superko rule
  
  It delegates rest of play to a current_board
  
  June 2017, hf
  
  ## Examples
  
      iex> alias Go.Game
      iex> game = Game.new
      iex> {:ok, game} = game |> Game.add_move({{3, 3}, :black})
      iex> {:ok, game} = game |> Game.add_move({{16, 3}, :white})
      iex> {:ok, game} = game |> Game.add_move({{3, 16}, :black}) 
      iex> {:ok, game} = game |> Game.add_move({{16, 16}, :white})
      iex> current_board = game.current_board 
      iex> current_board.coordinates[{3, 3}]
      :black
      iex> current_board.coordinates[{16, 16}]
      :white
      
  """
  
  alias __MODULE__
  alias Go.Board
  alias Go.Board.Tools
  alias Go.Turn
  alias Go.Coordinate
  
  @type t :: %Game{
    size: integer,
    komi: float,
    current_board: Board.t,
    
    black_captures: integer, 
    white_captures: integer, 
    
    turns: list(Turn.t),
    placements: list,
    consecutive_passes: integer,
    
    is_over: boolean,
    winner: Board.color | :none
  }
  
  defstruct [
    size: 19, 
    komi: 7.5,
    current_board: nil,
    
    black_captures: 0, 
    white_captures: 0, 
    
    turns: [],
    placements: [],
    consecutive_passes: 0,
    
    is_over: false,
    winner: :none
  ]
  
  @doc ~S"""
  Returns a new Game structure from an optional map or struct.
  """  
  @spec new(nil | map) :: t
  def new(), do: new(%{})
  def new(%{__struct__: _} = initial_state), do: new(initial_state |> Map.from_struct)
  def new(initial_state) when is_list(initial_state) do 
    if Keyword.keyword?(initial_state) do
      initial_state
      |> Enum.into(%{})
      |> new
    else
      new(%{})
    end    
  end
  def new(initial_state) when is_map(initial_state) do 
    size = Map.get(initial_state, :size, 19)
    current_board = Map.get(initial_state, :current_board, Board.new(%{size: size}))
    
    # build new state
    new_state = Map.merge(
      initial_state,
      %{size: size, current_board: current_board},
      fn _k, _v1, v2 -> v2 end
    )
    
    # return new struct
    struct(%Game{}, new_state)
  end
  
  # GAME API
  
  @doc ~S"""
  Add move to a game. 
  """
  @spec add_move(t, {Board.coordinate, Board.color}) :: {:ok, t} | {:error, String.t}
  def add_move(%{is_over: true} = _game, _move), do: {:error, "game is over."}
  def add_move(game, {coordinate, color} = move) do
    # Check if current_board.add_move() is Legal
    case Board.add_move(game.current_board, move) do
      {:ok, new_board} ->
        # Checking for superko needs to keep track of turns
        # Check if the board does not repeat!
        # http://senseis.xmp.net/?Superko
        
        if Enum.member?(Enum.map(game.turns, & &1.fengo), new_board  |> Tools.to_fengo) do
          {:error, "superko."}
        else
          # Add to history
          payload = %{
            coordinate: serialized_coordinate(coordinate), 
            color: color
          }
          serialized_move = %{
            action: :add_move, 
            payload: payload
          }
          turn = Turn.new(%{
            fengo: game.current_board |> Tools.to_fengo,
            move: serialized_move,
            placements: game.placements
          })
          new_turns = [turn | game.turns]
        
          # Calculate new state
          new_game = %Game{game | 
            current_board: new_board, 
            turns: new_turns,
            placements: [], 
            consecutive_passes: 0
          }
        
          # Return new_state
          {:ok, new_game}
        end
      {:error, reason} -> 
        {:error, reason}
    end
  end
  
  @doc ~S"""
  Pass move. 
  """
  @spec pass(t, Board.color) :: {:ok, t} | {:error, String.t}
  def pass(%{is_over: true} = _game, _color), do: {:error, "game is over."}
  def pass(game, color) do
    case Board.pass(game.current_board, color) do
      {:ok, new_board} ->
        
        # Add to history
        serialized_move = %{action: :pass, payload: %{color: color}}
        turn = Turn.new(%{
          fengo: game.current_board |> Tools.to_fengo,
          move: serialized_move,
          placements: game.placements
        })
        new_turns = [turn | game.turns]
        
        # Calculate new state
        new_consecutive_passes = game.consecutive_passes + 1
        new_is_over = new_consecutive_passes >= 2
        
        new_game = %Game{game |
          current_board: new_board, 
          turns: new_turns,
          consecutive_passes: new_consecutive_passes,
          is_over: new_is_over
        }
        
        # Return new_state
        {:ok, new_game}
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  @doc ~S"""
  Resign the game, status will change to is_over
  """
  @spec resign(t, Board.color) :: {:ok, t}
  def resign(%{is_over: true} = _game, _color), do: {:error, "game is over."}
  def resign(game, color) do
    new_game = %Game{game |
      is_over: true,
      winner: opposite_color(color)
    }
    {:ok, new_game}
  end
  
  @doc ~S"""
  Reset the game, but keep size and komi
  """
  @spec reset(t) :: {:ok, t}
  def reset(%{size: size, komi: komi} = _game) do
    new_game = Game.new(%{
      size: size,
      komi: komi})
    {:ok, new_game}
  end
  
  ## PLACEMENTS (should happen before add_move or pass!)
  
  @doc ~S"""
  Place one stone on the game.
  """
  @spec place_stone(t, Board.coordinate, Board.color, boolean) :: {:ok, t} | {:error, String.t}
  def place_stone(%{is_over: true} = _game, _coordinate, _color), do: {:error, "game is over."}
  def place_stone(game, coordinate, color, force \\ false) do
    case Board.place_stone(game.current_board, coordinate, color, force) do
      {:ok, new_board} ->
        payload = %{
          coordinate: serialized_coordinate(coordinate), 
          color: color
        }
        serialized_move = %{
          action: :place_stone, 
          payload: payload
        }
        new_placements = [serialized_move | game.placements]
    
        new_game = %Game{game | 
          current_board: new_board,
          placements: new_placements
        }
        {:ok, new_game}
        
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  # @doc ~S"""
  # Place multiple stones on the game.
  # """
  @spec place_stones(t, Board.list_of_coordinates, Board.color) :: {:ok, t} | {:error, String.t}
  def place_stones(game, [], _color), do: {:ok, game}
  def place_stones(game, [coordinate | tail], color) do
    case place_stone(game, coordinate, color) do
      {:ok, new_game} -> 
        place_stones(new_game, tail, color)
      {:error, reason} -> 
        {:error, reason}
    end
  end
  
  @doc ~S"""
  Remove the stone at the given location.
  """
  @spec remove_stone(t, Board.coordinate) :: {:ok, t}
  def remove_stone(%{is_over: true} = _game, _coordinate), do: {:error, "game is over."}
  def remove_stone(game, coordinate) do
    {:ok, new_board} = Board.remove_stone(game.current_board, coordinate)
    
    serialized_move = %{
      action: :remove_stone, 
      payload: serialized_coordinate(coordinate)
    }
    new_placements = [serialized_move | game.placements]
    
    new_game = %Game{game | 
      current_board: new_board,
      placements: new_placements
    }
    {:ok, new_game}
  end
  
  # @doc ~S"""
  # Remove multiple stones.
  # call remove_stone under the hood
  # """
  @spec remove_stones(t, Board.list_of_coordinates) :: {:ok, t}
  def remove_stones(%{is_over: true} = _game, _coordinates), do: {:error, "game is over."}
  def remove_stones(game, []) do
    {:ok, game}
  end  
  def remove_stones(game, [coordinate | tail]) do
    {:ok, new_game} = remove_stone(game, coordinate)
    remove_stones(new_game, tail)
  end
  
  ## END OF PLACEMENTS
  
  @doc ~S"""
  Like pass move, but does not change history state. 
  Useful when parsing faulty variations in KJD.
  """
  @spec toggle_turn(t) :: {:ok, t}
  def toggle_turn(game) do
    {:ok, new_board} = Board.toggle_turn(game.current_board)
    {:ok, %Game{game | current_board: new_board}}
  end
  
  # UTILITIES
  
  @doc ~S"""
  Generate an ascii from current board game.
  """
  @spec to_ascii(Game.t) :: String.t
  def to_ascii(game) do
    board = game.current_board
    Tools.coordinates_to_ascii_board(board.coordinates)
  end
  
  @doc ~S"""
  Returns list from current board game.
  """
  @spec to_list(Game.t) :: list
  def to_list(game) do
    board = game.current_board
    range = 0..(board.size - 1)
    for x <- range do
      for y <- range do
        symbol = board.coordinates |> Map.get({x, y})
        Tools.symbol_to_text(symbol)
      end
    end
  end
  
  @doc ~S"""
  Returns the tally of the game
  """
  @spec tally(t) :: map()
  def tally(%Game{is_over: true} = game) do
    %{
      game_state: :game_over,
      move_number: length(game.turns),
      next_turn: nil,
      winner: game.winner,
      board: to_ascii(game)
    }
  end
  def tally(%Game{} = game) do
    %{
      game_state: :running,
      move_number: length(game.turns),
      next_turn: game.current_board.next_turn,
      winner: game.winner,
      board: to_ascii(game)
    }
  end
  
  # END OF UTILITIES
  
  # PRIVATE
  defp opposite_color(color) do
    Board.opposite_color(color)
  end
  
  defp serialized_coordinate(coordinate) do
    coordinate |> Coordinate.from_tuple
  end
end