defmodule Go.Parser.Tree do
  @moduledoc false
  
  alias __MODULE__
  alias Go.Parser.Node
  require Logger
  
  @type optional_integer :: integer | :none
  @type t :: %Tree{ 
    id: optional_integer, 
    nodes: map,
    node_counter: integer
  }
  
  defstruct [
    id: nil,
    nodes: %{},
    node_counter: 0
  ]
  
  @spec new(map) :: t
  def new(initial_state \\ %{}) do 
    struct(%Tree{}, initial_state)
  end
  
  @spec add_node(t, map) :: {atom, integer, t}
  def add_node(tree, node_params \\ %{}) do    
    id = tree.node_counter + 1
    metadata = %{id: id}
    
    node_params = node_params
    |> Map.merge(metadata)
    
    new_node = Node.new node_params
    new_nodes = Map.put(tree.nodes, id, new_node)
        
    new_tree = %Tree{tree | nodes: new_nodes, node_counter: id}
    {:ok, id, new_tree}
  end
  
  @spec add_child_node(t, integer, map) :: {atom, integer, t}
  def add_child_node(tree, parent_id, node_params \\ %{}) do
    
    parent_node = tree.nodes[parent_id]
    
    case is_map(parent_node) do
      true ->
        id = tree.node_counter + 1
        metadata = %{id: id, parent_id: parent_id}
        
        node_params = node_params
        |> Map.merge(metadata)
        
        new_node = Node.new node_params
        new_parent = %{parent_node | children_ids: [id | parent_node.children_ids]}
        
        new_nodes = tree.nodes 
        |> Map.put(id, new_node)
        |> Map.put(parent_id, new_parent)
        
        new_tree = %Tree{tree | nodes: new_nodes, node_counter: id}
        {:ok, id, new_tree}
      false -> {:error, "Node not found."}
    end
  end
  
  @spec delete(t, integer) :: {atom, t}
  def delete(tree, node_id) do
    node = tree.nodes[node_id]
    case is_map(node) do
      true ->
        remove_ids = tree.nodes 
        |> Node.self_and_descendants(node) 
        |> Enum.map(& &1.id)
        
        new_nodes = tree.nodes 
        
        new_nodes = remove_ids 
        |> Enum.reduce(new_nodes, fn (id, acc) -> Map.delete(acc, id) end)
        
        parent_id = node.parent_id
        
        new_nodes = if is_integer(parent_id) do
          parent_node = tree.nodes[parent_id]
          new_parent = %{parent_node | children_ids: List.delete(parent_node.children_ids, node_id)}
          new_nodes 
          |> Map.put(parent_id, new_parent)
        else
          new_nodes
        end
        
        new_tree = %Tree{tree | nodes: new_nodes}
        {:ok, new_tree}
      false -> {:error, "Node not found."}
    end
  end

  @spec move_to_child_of(t, integer, integer) :: {atom, t}
  def move_to_child_of(tree, node_id, parent_id) do
    node = tree.nodes[node_id]
    parent_node = tree.nodes[parent_id]
    
    case is_map(node) && is_map(parent_node) do
      true ->
        new_node = %{node | parent_id: parent_id}
        new_parent = %{parent_node | children_ids: [node_id | parent_node.children_ids]}
        
        new_nodes = tree.nodes  
        |> Map.put(node_id, new_node)
        |> Map.put(parent_id, new_parent)
        
        previous_parent_id = node.parent_id
        new_nodes = if previous_parent_id &&  previous_parent_id !== :none do
          previous_parent = tree.nodes[previous_parent_id]
          
          new_previous_parent = 
            %{previous_parent | children_ids: List.delete(previous_parent.children_ids, node_id)}
          
          new_nodes 
          |> Map.put(previous_parent_id, new_previous_parent)
        else
          new_nodes
        end
        
        new_tree = %Tree{tree | nodes: new_nodes}
        {:ok, new_tree}
       
      false -> {:error, "Node not found."}
    end
  end
  
  @spec add_property(t, integer, String.t, String.t) :: {atom, t}
  def add_property(tree, node_id, key, value) do
    node = tree.nodes[node_id]
    case is_map(node) do
      true ->
        node = node
        |> Node.add_property(key, value)
    
        new_nodes = tree.nodes
        |> Map.put(node_id, node)
                
        new_tree = %Tree{tree | nodes: new_nodes}
        {:ok, new_tree}
      false -> {:error, "Node not found."}
    end
  end
  
  @spec delete_property(t, integer, String.t) :: {atom, t}
  def delete_property(tree, node_id, key) do
    node = tree.nodes[node_id]
    case is_map(node) do
      true ->
        node = node
        |> Node.delete_property(key)

        new_nodes = tree.nodes
        |> Map.put(node_id, node)

        new_tree = %Tree{tree | nodes: new_nodes}
        {:ok, new_tree}
      false -> {:error, "Node not found."}
    end
  end

  @spec delete_properties(t, integer) :: {atom, t}
  def delete_properties(tree, node_id) do
    node = tree.nodes[node_id]
    case is_map(node) do
      true ->
        node = node
        |> Node.delete_properties

        new_nodes = tree.nodes
        |> Map.put(node_id, node)

        new_tree = %Tree{tree | nodes: new_nodes}
        {:ok, new_tree}
      false -> {:error, "Node not found."}
    end
  end
  
  # NODES DELEGATION

  def roots(tree), do: tree.nodes |> Node.roots

  def root(tree), do: tree.nodes |> Node.root

  def leaves(tree), do: tree.nodes |> Node.leaves

  def leaves_count(tree), do: tree.nodes |> Node.leaves_count

  def children(tree, node_id),
    do: tree.nodes |> Node.children(tree.nodes[node_id])

  def children_count(tree, node_id),
    do: tree.nodes |> Node.children_count(tree.nodes[node_id])

  def descendants(tree, node_id), do: tree.nodes |> Node.descendants(tree.nodes[node_id])

  def self_and_descendants(tree, node_id),
    do: tree.nodes |> Node.self_and_descendants(tree.nodes[node_id])

  def ancestors(tree, node_id),
    do: tree.nodes |> Node.ancestors(tree.nodes[node_id])

  def ancestors_and_self(tree, node_id),
    do: tree.nodes |> Node.ancestors_and_self(tree.nodes[node_id])

  def siblings(tree, node_id),
    do: tree.nodes |> Node.siblings(tree.nodes[node_id])

  def self_and_siblings(tree, node_id),
    do: tree.nodes |> Node.self_and_siblings(tree.nodes[node_id])

  def depth(tree, node_id), do: tree.nodes |> Node.depth(tree.nodes[node_id])
end
