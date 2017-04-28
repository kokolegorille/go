# Changelog

## 0.1.2

THIS VERSION CHANGE STRUCTURE! 

To save the board in postgresql with Ecto, properties/fields need simpler types.
History store position, moves store actions (add_move, pass, place, remove).

1. Update structure to be more ecto compliant
  * Change type and add moves property to store actions 
  * Change history to contains only fengo
  * Do not store count info in history.

2. Add transform functions sgf->coordinate / coordinate->sgf in Tools

3. Add coresponding tests

4. Update Changelog

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