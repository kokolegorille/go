# Changelog

## 0.3.0

Update for Elixir 1.6

* ex_doc 0.18.3
* dialyxir 0.5.1

Add 

* credo 0.8.10

Fix credo linting error
Fix test

Add display module
Add display test
Move Board to_array, to_list -> Go.Display
Rename to_array -> to_list

## 0.2.0

THIS VERSION ADD NEW ENTITIES!

1. Add new entities and corresponding tests
  * Game
  * Turn
  * Coordinate
  * (Board)

2. Remove some board responsabilities (moved to game)

Game is now the main entity. It contains a current board, count_info and a turn history (turns)  
Turn contains a fengo string, the current move, additional actions (eg: stone placements)
Board is now simplified, it stores size, coordinates and next_turn
(size can also be deduced from coordinates size!)

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