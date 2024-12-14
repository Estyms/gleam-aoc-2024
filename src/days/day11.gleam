import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/set
import gleam/string
import simplifile

pub fn start() -> Nil {
  let assert Ok(content) = simplifile.read("inputs/day11.txt")
  let data = parse(content)

  let _ = io.debug(part1(data))
  let _ = io.debug(part2(data))

  Nil
}

fn parse(data: String) {
  data
  |> string.split(" ")
  |> list.map(int.parse)
  |> list.map(result.unwrap(_, 0))
}

fn process_rock(rock: Int) -> List(Int) {
  let is_even = string.length(int.to_string(rock)) % 2 == 0
  case rock {
    0 -> [1]
    _ if is_even -> {
      let chars =
        int.to_string(rock)
        |> string.to_graphemes()

      let a =
        list.take(chars, list.length(chars) / 2)
        |> string.join("")
        |> int.parse
        |> result.unwrap(0)

      let b =
        list.drop(chars, list.length(chars) / 2)
        |> string.join("")
        |> int.parse
        |> result.unwrap(0)

      [a, b]
    }
    _ -> [rock * 2024]
  }
}

fn part1(data: List(Int)) {
  list.range(0, 24)
  |> list.fold(data, fn(rocks, _) {
    rocks
    |> list.map(process_rock)
    |> list.flatten
  })
  |> list.length
}

fn process_rock_entry(rock_entry: #(Int, Int)) -> Dict(Int, Int) {
  let #(rock, count) = rock_entry
  let is_even = string.length(int.to_string(rock)) % 2 == 0
  case rock {
    0 -> {
      dict.insert(dict.new(), 1, count)
    }
    _ if is_even -> {
      let chars =
        int.to_string(rock)
        |> string.to_graphemes()

      let a =
        list.take(chars, list.length(chars) / 2)
        |> string.join("")
        |> int.parse
        |> result.unwrap(0)

      let b =
        list.drop(chars, list.length(chars) / 2)
        |> string.join("")
        |> int.parse
        |> result.unwrap(0)

      reduce_rock_dict(
        dict.insert(dict.new(), a, count),
        dict.insert(dict.new(), b, count),
      )
    }
    _ -> {
      dict.insert(dict.new(), rock * 2024, count)
    }
  }
}

fn reduce_rock_dict(dict_a: Dict(Int, Int), dict_b: Dict(Int, Int)) {
  let set_a = dict.keys(dict_a) |> set.from_list
  let set_b = dict.keys(dict_b) |> set.from_list

  set.union(set_a, set_b)
  |> set.to_list()
  |> list.fold(dict.new(), fn(acc, key) {
    let a = dict.get(dict_a, key) |> result.unwrap(0)
    let b = dict.get(dict_b, key) |> result.unwrap(0)
    dict.insert(acc, key, a + b)
  })
}

fn make_rock_dict(rocks: List(Int)) {
  rocks
  |> list.map(fn(rock) {
    let cnt =
      rocks
      |> list.count(fn(x) { x == rock })
    dict.insert(dict.new(), rock, cnt)
  })
  |> list.reduce(dict.merge)
  |> result.unwrap(dict.new())
}

fn part2(data: List(Int)) {
  let rock_dict = make_rock_dict(data)

  list.range(0, 74)
  |> list.fold(rock_dict, fn(acc, _) {
    acc
    |> dict.to_list()
    |> list.map(process_rock_entry)
    |> list.reduce(reduce_rock_dict)
    |> result.unwrap(dict.new())
  })
  |> dict.values
  |> int.sum
}
