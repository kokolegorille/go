# Shared Tools for BOARD

defmodule Go.Board.Tools do
  alias Go.Board
  
  # Transform coordinates (Map) to encoded string
  def coordinates_to_string(coordinates) do
    size = size_from_coordinates(coordinates)
    range = 0..(size - 1)
    for x <- range do
      for y <- range do
        coordinates[{x, y}] |> symbol_to_text
      end |> Enum.join
    end
    |> Enum.join
    |> encode
  end
  
  def string_to_coordinates(string) do
    decoded_string = string |> decode
    size = size_from_string(decoded_string)    
    decoded_string
    |> String.split("")
    |> List.delete_at(-1)
    |> Enum.with_index 
    |> Enum.reduce(%{}, fn({item, index} = _tuple, acc) -> 
      x = (index / size) |> Float.floor |> round
      y = rem(index, size)
      Map.put(acc, {x, y}, text_to_symbol(item))
    end)
  end
  
  # Transform coordinate to sgf move, vice-versa
  
  # "ab" => {x, y}
  def move_to_coordinate(move) do
    array_of_index = move
    |> to_charlist
    |> Enum.map(& &1 - 97)
    {Enum.at(array_of_index, 0), Enum.at(array_of_index, 1)}
  end
  
  # {x, y} => "ab"
  def coordinate_to_move(coordinate) do
    [elem(coordinate, 0) + 97, elem(coordinate, 1) + 97]
    |> to_string
  end
  
  def to_fengo(board) do
    to_fengo(board.coordinates, board.next_turn)
  end
  
  def to_fengo(coordinates, next_turn) do 
    "#{next_turn_to_string(next_turn)} #{coordinates_to_string(coordinates)}"
  end
  
  def from_fengo(fengo) do
    [string_next_turn, _string_coordinates] = fengo |> String.split
    
    coordinates = fengo |> string_to_coordinates

    size = size_from_coordinates(coordinates)
    next_turn = next_turn_from_string(string_next_turn)
    
    Board.new(%{size: size, coordinates: coordinates, next_turn: next_turn})
  end
  
  # any_to_fengo cannot work without next_turn info
  def fengo_to_string(string) do
    string 
    |> String.slice(2, String.length(string))
    |> decode
  end
  
  def fengo_to_ascii_board(string) do
    string 
    |> fengo_to_string
    |> string_to_ascii_board
  end
  
  def string_to_ascii_board(string) do
    size = size_from_string(string)
    string 
    |> to_charlist 
    |> Enum.chunk(size) 
    |> Enum.join("\n")
  end
  
  def ascii_board_to_string(string) do
    string |> String.replace("\n", "")
  end
  
  def next_turn_to_string(next_turn) do
    next_turn 
    |> to_string 
    |> String.first 
    |> String.upcase
  end
  
  def next_turn_from_string(string) do
    case string do
      "W" -> :white
      "B" -> :black
      _ -> {:error, "should be W or B"}
    end
  end
  
  ### END NEW
  
  def symbol_to_text(symbol) do
    case symbol do
      :black -> "O"
      :white -> "X"
      _ -> "+"
    end
  end
  
  def text_to_symbol(text) do
    case text do
      "O" -> :black
      "X" -> :white
      _ -> :empty
    end
  end
  
  def symbol_to_game_format(symbol) do
    case symbol do
      :black -> "1"
      :white -> "-1"
      _ -> "0"
    end
  end
  
  def coordinates_to_ascii_board(coordinates) do
    size = size_from_coordinates(coordinates)
    range = 0..(size - 1)
    
    for x <- range do
      row = for y <- range do
        coordinates[{x, y}] |> symbol_to_text
      end |> Enum.join
      row <> "\n"
    end |> Enum.join
  end
  
  def coordinates_to_game_format(coordinates, next_turn) do
    size = size_from_coordinates(coordinates)
    range = 0..(size - 1)
    
    header = 
"# 1=black -1=white 0=open
height #{size}
width #{size}
player_to_move #{next_turn |> symbol_to_game_format}\n"
    
    body = for x <- range do
      row = for y <- range do
        " " <> (coordinates[{x, y}] |> symbol_to_game_format)
      end |> Enum.join
      row <> "\n"
    end |> Enum.join
    
    header <> body
  end
  
  # Run Length Encoder for Elixir
  # https://www.rosettacode.org/wiki/Run-length_encoding#Elixir
  def encode(str) when is_bitstring(str) do
    to_char_list(str) |> encode |> to_string
  end
  def encode(list) when is_list(list) do
    Enum.chunk_by(list, &(&1))
    |> Enum.flat_map(fn chars -> to_char_list(length(chars)) ++ [hd(chars)] end)
  end
 
  def decode(str) when is_bitstring(str) do
    Regex.scan(~r/(\d+)(.)/, str)
    |> Enum.map_join(fn [_,n,c] -> String.duplicate(c, String.to_integer(n)) end)
  end
  def decode(list) when is_list(list) do
    to_string(list) |> decode |> to_char_list
  end
  
  # PRIVATE
  defp size_from_coordinates(coordinates), do: coordinates |> Enum.count |> :math.sqrt |> round
  
  defp size_from_string(string), do: string |> String.length |> :math.sqrt |> round
end