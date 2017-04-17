# Shared Tools for BOARD

# TESTING coordinates to string and reverse!
#
# str = "43+1X16+1X11+1X24+1O171+1O25+1O3+1X1+1O5+1O53+"
# c = Tools.string_to_coordinates str
# c == Tools.coordinates_to_string(c) |> Tools.string_to_coordinates
# str == Tools.string_to_coordinates(str) |> Tools.coordinates_to_string

defmodule Go.Board.Tools do
  # Transform coordinates (Map) to encoded string
  def coordinates_to_string(coordinates) do
    size = coordinates |> Enum.count |> :math.sqrt |> round
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
    string 
    |> decode
    |> String.split("")
    |> List.delete_at(-1)
    |> Enum.with_index 
    |> Enum.reduce(%{}, fn({item, index} = _tuple, acc) -> 
      x = (index / 19) |> Float.floor |> round
      y = rem(index, 19)
      Map.put(acc, {x, y}, text_to_symbol(item))
    end)
  end

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
    size = coordinates |> Enum.count |> :math.sqrt |> round
    range = 0..(size - 1)
    
    for x <- range do
      row = for y <- range do
        coordinates[{x, y}] |> symbol_to_text
      end |> Enum.join
      row <> "\n"
    end |> Enum.join
  end
  
  def coordinates_to_game_format(coordinates, next_turn) do
    size = coordinates |> Enum.count |> :math.sqrt |> round
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
end