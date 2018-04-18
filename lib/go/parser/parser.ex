defmodule Go.Parser do
  @moduledoc """
  
  Documentation for Go.Parser
  
  Add export/import from sgf data.
  
  ## Examples
  
      iex> filename = "test/fixtures/example.sgf"
      iex> {:ok, sgf} = File.read filename
      iex> {:ok, %Go.Parser.Tree{} = tree} = Go.Parser.parse sgf
        
  """
  
  alias Go.Parser.Tree
  
  @spec parse(String.t()) :: {:ok, Tree.t()} | {:error, term()}
  def parse(sgf) when is_binary(sgf) do
    case :sgf_lexer.string sgf |> String.to_charlist do
      {:ok, tokens, _end_line} -> 
        tree = tokens |> parse_tokens()
        {:ok, tree}

      # Sample error
      # {:error, {1, :sgf_lexer, {:illegal, ':'}}, 1}
      {:error, {_, _, {reason, token}}, _} ->
        {:error, "#{to_string(reason)} #{to_string(token)}"}
    end
  end
  
  # PRIVATE
  defp parse_tokens(tokens) do
    # Initial processing state
    state = %{
      tree: Tree.new,
      stack:  [],
      current_node: nil,
      current_prop: nil
    }
    process_tokens(tokens, state)
  end
  
  # Recursive call returning a list of nodes
  defp process_tokens([], %{tree: tree} = _state), do: tree
  defp process_tokens([token | rest], state) do
    new_state = parse_token(token, state)
    process_tokens(rest, new_state)
  end
  
  # Parse token
  defp parse_token(
    {:game_tree_start, _}, 
    %{current_node: current_node, stack: stack} = state) 
  do
    # Stack is pushed from start!
    %{state | stack: [current_node | stack]}
  end
  defp parse_token({:game_tree_end, _}, %{stack: stack} = state) do
    # Pop from start, because stack is reversed!
    {new_current_node, new_stack} = List.pop_at(stack, 0)    
    %{state | current_node: new_current_node, stack: new_stack}
  end
  defp parse_token(
    {:node_start, _}, 
    %{current_node: current_node, tree: tree} = state) 
  do
    case current_node do
      nil ->
        {:ok, new_current_node, tree} = Tree.add_node tree
        
        %{state | current_node: new_current_node, tree: tree}
      _ ->
        {:ok, new_current_node, tree} = Tree.add_child_node tree, current_node
        
        %{state | current_node: new_current_node, tree: tree}
    end
  end
  defp parse_token({:propident, _, value}, state), do: 
    %{state | current_prop: value}
  defp parse_token(
    {:propvalue, _, value}, 
    %{current_node: current_node, 
    current_prop: current_prop, 
    tree: tree} = state) 
  do
    {:ok, tree} = Tree.add_property(tree, current_node, current_prop, value)
    %{state | tree: tree}
  end
  defp parse_token({_, _}, state), do: state
  defp parse_token({_, _, _}, state), do: state
end