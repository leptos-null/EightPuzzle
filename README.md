## EightPuzzle

This project is a command line tool that shows the shortest sequences of moves to get from a given state in an Eight Puzzle board to another state on the board.

See [15 Puzzle](https://en.wikipedia.org/wiki/15_Puzzle) for more information on the general board game.
15 Puzzle is a 4x4 board, where 8 Puzzle is the 3x3 equivalent.

This project was originally developed to solve Eight Puzzle, however the solution technique is generic across board sizes, and the project now supports any rectangular board.

This project uses a graph to describe each reachable board state as a node and then use Dijkstra's shortest path algorithm to find the sequence of moves between 2 board states.

Example of an Eight Puzzle board for reference:

```
┌───┬───┬───┐
│ 1 │ 2 │ 3 │
├───┼───┼───┤
│ 4 │ 5 │ 6 │
├───┼───┼───┤
│ 7 │ 8 │   │
└───┴───┴───┘
```
