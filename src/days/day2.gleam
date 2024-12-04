import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

pub fn start() -> Nil {
  let assert Ok(content) = simplifile.read("inputs/day2.txt")
  let data = parse(content)

  let _ = io.debug(part1(data))
  let _ = io.debug(part2(data))

  Nil
}

fn get_ints_in_line(line: String) -> List(Int) {
  line
  |> string.split(" ")
  |> list.map(int.parse)
  |> list.map(result.unwrap(_, 0))
}

fn parse(data: String) -> List(List(Int)) {
  data
  |> string.split("\n")
  |> list.map(get_ints_in_line)
}

fn is_stable(lst: List(Int)) -> Bool {
  let scanned =
    lst
    |> list.window_by_2
    |> list.map(fn(d) {
      let #(a, b) = d
      a - b
    })

  list.all(scanned, fn(x) { x < 0 && x >= -3 })
  || list.all(scanned, fn(x) { x > 0 && x <= 3 })
}

fn part1(data: List(List(Int))) {
  data
  |> list.count(is_stable)
}

fn part2(data: List(List(Int))) {
  data
  |> list.count(fn(lst) {
    case is_stable(lst) {
      True -> True
      False -> {
        lst
        |> list.combinations(list.length(lst) |> int.subtract(1))
        |> list.any(is_stable)
      }
    }
  })
}
