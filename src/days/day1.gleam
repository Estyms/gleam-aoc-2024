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
      x
      |> string.split_once("   ")
      |> result.unwrap(#("", ""))

    let left =
      splitted.0
      |> int.parse()
      |> result.unwrap(0)

    let right =
      splitted.1
      |> int.parse()
      |> result.unwrap(0)

    #(acc.0 |> list.append([left]), acc.1 |> list.append([right]))
  })
}

fn part1(data: #(List(Int), List(Int))) {
  let sorted_left =
    data.0
    |> list.sort(int.compare)

  let sorted_right =
    data.1
    |> list.sort(int.compare)

  list.zip(sorted_left, sorted_right)
  |> list.map(fn(x) {
    let #(a, b) = x
    a - b
    |> int.absolute_value
  })
  |> int.sum
}

fn part2(data: #(List(Int), List(Int))) {
  data.0
  |> list.map(fn(x) { x * list.count(data.1, fn(y) { y == x }) })
  |> int.sum
}
