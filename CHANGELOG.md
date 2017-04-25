# Changelog

## 0.1.1

1. Add CHANGELOG.md

2. Add helpers to Go.Board.Tools :
  * to_fengo(coordinates, next_turn) 
  * fengo_to_string(string) 
  * fengo_to_ascii_board(string)
  * string_to_ascii_board(string)
  * ascii_board_to_string(string) 
  * next_turn_to_symbol(next_turn)

3. Update Go.Board :
  * rename and move private fengo() to public Go.Board.Tools.to_fengo()

## 0.1.0

1. Initial commit