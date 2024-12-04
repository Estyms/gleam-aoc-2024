import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/regexp
import gleam/result
import gleam/string
import simplifile

pub fn start() -> Nil {
  let assert Ok(content) = simplifile.read("inputs/day4.txt")

  let _ = io.debug(part1(parse_part_1(content)))
  let _ = io.debug(part2(content))

  Nil
}

fn get_vertical_string(matrix: List(String)) -> String {
  matrix
  |> list.map(string.to_graphemes)
  |> list.transpose
  |> list.map(string.concat)
  |> list.first
  |> result.unwrap("")
}

fn get_diagonal_right(matrix: List(String), init_drop: Int) -> String {
  matrix
  |> list.fold(#(init_drop, []), fn(acc, line) {
    let shifted =
      line
      |> string.to_graphemes
      |> list.drop(acc.0)
      |> string.concat

    #(acc.0 + 1, acc.1 |> list.append([shifted]))
  })
  |> fn(x) { x.1 }
  |> get_vertical_string
}

fn recursive_diagonal_right(
  matrix: List(String),
  init_drop: Int,
) -> List(String) {
  case matrix |> list.length < init_drop {
    True -> []
    False -> {
      let data = get_diagonal_right(matrix, init_drop)
      list.append([data], recursive_diagonal_right(matrix, init_drop + 1))
    }
  }
}

fn parse_part_1(data: String) -> List(String) {
  let horizontal =
    data
    |> string.split("\n")

  let vertical =
    horizontal
    |> list.map(string.to_graphemes)
    |> list.transpose
    |> list.map(string.concat)

  let inverse_vertical =
    horizontal
    |> list.map(string.to_graphemes)
    |> list.map(list.reverse)
    |> list.transpose()
    |> list.map(string.concat)

  let diagonals1 = recursive_diagonal_right(horizontal, 0)

  let diagonals2 =
    recursive_diagonal_right(
      horizontal
        |> list.map(fn(x) {
          x
          |> string.to_graphemes
          |> list.reverse
          |> string.concat
        }),
      0,
    )

  let diagonals3 =
    recursive_diagonal_right(vertical, 0)
    |> list.drop(1)
  let diagonals4 =
    recursive_diagonal_right(inverse_vertical, 0)
    |> list.drop(1)

  [horizontal, vertical, diagonals1, diagonals2, diagonals3, diagonals4]
  |> list.flatten
}

fn part1(data: List(String)) {
  data
  |> list.map(fn(s) {
    let a =
      s
      |> string.split("XMAS")
    let b =
      s
      |> string.split("SAMX")

    list.length(a) + list.length(b) - 2
  })
  |> int.sum
}

// Part 2

fn loop_horizontal(
  matrix: List(List(String)),
  start_index: Int,
  do: fn(List(List(String))) -> a,
) -> List(a) {
  case
    list.length(matrix |> list.first |> result.unwrap([])) - start_index < 3
  {
    True -> []
    False -> {
      let value =
        matrix
        |> list.map(fn(x) { list.drop(x, start_index) |> list.take(3) })
        |> do

      list.append([value], loop_horizontal(matrix, start_index + 1, do))
    }
  }
}

fn loop_vertical(
  matrix: List(List(String)),
  start_index: Int,
  do: fn(List(List(String))) -> a,
) -> List(a) {
  case list.length(matrix) - start_index < 3 {
    True -> []
    False -> {
      let value =
        matrix
        |> list.drop(start_index)
        |> list.take(3)
        |> do

      list.append([value], loop_vertical(matrix, start_index + 1, do))
    }
  }
}

fn test_if_xmas(matrix: List(List(String))) -> Bool {
  let xmas_string =
    matrix
    |> list.map(string.concat)
    |> string.concat

  let assert Ok(re) =
    regexp.from_string("(S.M.A.S.M|M.M.A.S.S|M.S.A.M.S|S.S.A.M.M)")

  let assert 9 = string.length(xmas_string)

  xmas_string
  |> regexp.check(with: re)
}

fn part2(data) {
  let char_matrix =
    data
    |> string.split("\n")
    |> list.map(string.to_graphemes)

  loop_vertical(char_matrix, 0, loop_horizontal(_, 0, test_if_xmas))
  |> list.flatten
  |> list.count(bool.and(_, True))
}
