import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

pub fn start() -> Nil {
  let assert Ok(content) = simplifile.read("inputs/day1.txt")
  let data = parse(content)

  let _ = io.debug(part1(data))
  let _ = io.debug(part2(data))

  Nil
}

fn parse(data: String) {
  data
  |> string.split("\n")
  |> list.fold(#([], []), fn(acc, x) {
    let splitted =
      string.split_once(x, "   ")
      |> result.unwrap(#("", ""))

    let left =
      int.parse(splitted.0)
      |> result.unwrap(0)

    let right =
      int.parse(splitted.1)
      |> result.unwrap(0)

    #(acc.0 |> list.append([left]), acc.1 |> list.append([right]))
  })
}

fn part1(data: #(List(Int), List(Int))) {
  let sorted_left = list.sort(data.0, int.compare)

  let sorted_right = list.sort(data.1, int.compare)

  list.zip(sorted_left, sorted_right)
  |> list.map(fn(x) {
    let #(a, b) = x
    int.absolute_value(a - b)
  })
  |> int.sum
}

fn part2(data: #(List(Int), List(Int))) {
  data.0
  |> list.map(fn(x) { x * list.count(data.1, fn(y) { y == x }) })
  |> int.sum
}
