defmodule Go.Parser.Node do
  @moduledoc false
  
  alias __MODULE__
  alias Go.Board.Tools
  require Logger
  
  @type optional_integer :: integer | :none
  @type t :: %Node{ 
    id: optional_integer, 
    parent_id: optional_integer, 
    children_ids: [],
    properties: map
  }
  @type map_of_nodes :: map
  @type list_of_nodes :: [t]
  
  defstruct [
    id: nil, parent_id: nil, children_ids: [],
    #
    properties: %{}
  ]
  
  @spec new(map) :: t
  def new(initial_state \\ %{}) do 
    struct(%Node{}, initial_state)
  end
  
  # NODE API
  
  @spec add_property(t, String.t, String.t) :: t
  def add_property(node, key, value) do
    %{node | 
      properties: Map.put(node.properties, to_string(key), to_string(value))
    }
  end
  
  @spec delete_property(t, String.t) :: t
  def delete_property(node, key) do
    %{node | properties: Map.delete(node.properties, key)}
  end
  
  @spec delete_properties(t) :: t
  def delete_properties(node) do
    %{node | properties: %{}}
  end
  
  @spec is_leaf?(t) :: boolean
  def is_leaf?(node), do: node.children_ids === []
  
  # SGF SPECIFIC

  @spec get_move(t) :: term
  def get_move(node) do
    move_black = node.properties["B"]
    move_white = node.properties["W"]

    cond do
      move_black == "[]" -> {:pass, :black}
      move_white == "[]" -> {:pass, :white}
      !! move_black ->
        coordinate = move_black |> Tools.move_to_coordinates() |> List.first
        {:add_move, {coordinate, :black}}
      !! move_white ->
        coordinate = move_white |> Tools.move_to_coordinates() |> List.first
        {:add_move, {coordinate, :white}}
      true -> nil
    end
  end

  @spec get_placements(t) :: term
  def get_placements(node) do
    place_black = node.properties["AB"]
    place_white = node.properties["AW"]

    cond do
      !! place_black && !! place_white ->
        Logger.debug(fn -> "node #{node.id} : simultaneous placements for B/W." end)

        black_coordinates = Tools.move_to_coordinates(place_black)
        white_coordinates = Tools.move_to_coordinates(place_white)

        [
          placements_to_action(black_coordinates, :black),
          placements_to_action(white_coordinates, :white)
        ]

      !! place_black ->
        place_black
        |> Tools.move_to_coordinate
        |> placements_to_action(:black)

      !! place_white ->
        place_white
        |> Tools.move_to_coordinate
        |> placements_to_action(:white)

      true -> nil
    end
  end

  @spec get_removes(t) :: term
  def get_removes(node) do
    remove_stones = node.properties["AE"]
    case !! remove_stones do
      true ->
        coordinates = Tools.move_to_coordinates(remove_stones)

        if Enum.count(coordinates) === 1 do
          {:remove_stone, List.first(coordinates)}
        else
          {:remove_stones, coordinates}
        end
      false -> nil
    end
  end

  @spec get_actions(t) :: list
  def get_actions(node) do
    [get_removes(node)] ++ [get_placements(node)] ++ [get_move(node)]
    |> List.flatten
    |> Enum.filter(fn(action) -> !! action end)
  end

  @spec get_markers(t) :: list
  def get_markers(node) do
    # Subset of markups, only Cross, Circle, Square, Triangle, Greyed, Selected, Label
    # Do not include Arrow and Line ("AR", "LN")

    allowed_keys = ["CR", "DD", "LB", "MA", "SL", "SQ", "TR"]

    node.properties
    |> Enum.filter(fn ({key, _value} = _property) ->
      Enum.member?(allowed_keys, key)
    end)
  end
  
  # NODES COLLECTION API

  @spec roots(map_of_nodes) :: list_of_nodes
  def roots(nodes) do
    nodes
    |> Map.values
    |> Enum.filter(fn(n) -> n.parent_id === nil end)
  end

  @spec root(map_of_nodes) :: t
  def root(nodes) do
    nodes |> roots() |> List.first
  end

  @spec leaves(map_of_nodes) :: list_of_nodes
  def leaves(nodes) do
    nodes
    |> Map.values
    |> Enum.filter(& is_leaf? &1)
  end

  @spec leaves_count(map_of_nodes) :: integer
  def leaves_count(nodes), do: nodes |> leaves() |> Enum.count

  @spec children(map_of_nodes, t) :: list_of_nodes
  def children(_nodes, node) when is_nil(node), do: {:error, "Node not found."}
  def children(nodes, node) do
    node.children_ids |> Enum.map(& nodes[&1]) |> Enum.reverse
  end

  @spec children_count(map_of_nodes, t) :: integer
  def children_count(_nodes, node) when is_nil(node), do: {:error, "Node not found."}
  def children_count(nodes, node), do: nodes |> children(node) |> Enum.count

  @spec descendants(map_of_nodes, t) :: list_of_nodes
  def descendants(_nodes, node) when is_nil(node), do: {:error, "Node not found."}  
  def descendants(nodes, node) do
    children = children(nodes, node)
    if children |> Enum.count > 0 do
      (children ++ (children |> Enum.map(& descendants(nodes, &1))))
      |> List.flatten
    else
      []
    end
  end
  
  @spec self_and_descendants(map_of_nodes, t) :: list_of_nodes
  def self_and_descendants(_nodes, node) when is_nil(node), do: {:error, "Node not found."}
  def self_and_descendants(nodes, node) do
    [node | descendants(nodes, node)]
  end

  @spec ancestors(map_of_nodes, t) :: list_of_nodes
  def ancestors(_nodes, node) when is_nil(node), do: {:error, "Node not found."}
  def ancestors(nodes, node) do
    if node.parent_id === nil do
      []
    else
      parent = nodes[node.parent_id]
      [parent | Enum.reverse(ancestors(nodes, parent))]
      |> Enum.reverse
    end
  end

  @spec ancestors_and_self(map_of_nodes, t) :: list_of_nodes
  def ancestors_and_self(_nodes, node) when is_nil(node), do: {:error, "Node not found."}
  def ancestors_and_self(nodes, node) do
    [node | Enum.reverse(ancestors(nodes, node))]
    |> Enum.reverse
  end

  @spec siblings(map_of_nodes, t) :: list_of_nodes
  def siblings(_nodes, node) when is_nil(node), do: {:error, "Node not found."}
  def siblings(nodes, node) do
    nodes |> self_and_siblings(node) |> List.delete(node)
  end

  @spec self_and_siblings(map_of_nodes, t) :: list_of_nodes
  def self_and_siblings(_nodes, node) when is_nil(node), do: {:error, "Node not found."}
  def self_and_siblings(nodes, node) do
    if node.parent_id === :none do
      roots(nodes)
    else
      parent = nodes[node.parent_id]
      children(nodes, parent)
    end
  end

  @spec depth(map_of_nodes, t) :: integer
  def depth(_nodes, node) when is_nil(node), do: {:error, "Node not found."}
  def depth(nodes, node), do: nodes |> ancestors_and_self(node) |> Enum.count
  
  # PRIVATE

  defp placements_to_action(coordinates, color) do
    if Enum.count(coordinates) == 1 do
      {:place_stone, List.first(coordinates), color}
    else
      {:place_stones, coordinates, color}
    end
  end
end