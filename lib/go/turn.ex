defmodule Go.Turn do
  @moduledoc """
  Documentation for Go.Turn
  
  This entity is responsible for saving a turn in the game.
  It will persists:
    * current_board before the move as fengo string
    * the turn's move
    * a list of additional actions, eg place/remove stone/s
  
  It will be used to check for superko rule
  """
  
  alias __MODULE__
    
  @type move :: any 
  @type t :: %Turn{
    fengo: String.t,
    move: move,
    placements: list
  }
  @enforce_keys [:fengo, :move, :placements]
  defstruct [:fengo, :move, :placements]
  
  @doc ~S"""
  Returns a new turn from a map.
  Because of enforce_keys, You must pass key/val in 
  the structure constructor
  """  
  def new(%{fengo: fengo, move: move, placements: placements} = _initial_state), 
    do: %Turn{fengo: fengo, move: move, placements: placements}
end