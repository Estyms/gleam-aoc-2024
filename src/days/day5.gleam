import gleam/int
import gleam/io
import gleam/list
import gleam/order
import gleam/result
import gleam/string
import simplifile

pub type Inputs =
  #(List(List(Int)), List(fn(List(Int)) -> Bool))

pub fn start() -> Nil {
  let assert Ok(content) = simplifile.read("inputs/day5.txt")
  let data = parse(content)

  let _ = io.debug(part1(data))
  let _ = io.debug(part2(data))

  Nil
}

fn construct_predicate_from_rule(rule: #(Int, Int)) -> fn(List(Int)) -> Bool {
  fn(lst: List(Int)) {
    case list.contains(lst, rule.0) && list.contains(lst, rule.1) {
      True -> {
        let index_rule0 =
          list.drop_while(lst, fn(x) { x != rule.0 }) |> list.length
        let index_rule1 =
          list.drop_while(lst, fn(x) { x != rule.1 }) |> list.length

        index_rule1 < index_rule0
      }
      False -> True
    }
  }
}

fn parse_rule(rule: String) {
  rule
  |> string.split_once("|")
  |> result.unwrap(#("", ""))
  |> fn(tup) {
    #(
      int.parse(tup.0) |> result.unwrap(0),
      int.parse(tup.1) |> result.unwrap(0),
    )
  }
  |> construct_predicate_from_rule
}

fn parse_rules(rules: String) {
  rules
  |> string.split("\n")
  |> list.map(parse_rule)
}

fn parse_list(list_string: String) {
  list_string
  |> string.split(",")
  |> list.map(fn(x) { int.parse(x) |> result.unwrap(0) })
}

fn parse_lists(lists_string: String) {
  lists_string
  |> string.split("\n")
  |> list.map(parse_list)
}

fn parse(data: String) -> Inputs {
  let #(rules, lines) =
    data
    |> string.split_once("\n\n")
    |> result.unwrap(#("", ""))

  let predicates = parse_rules(rules)
  let lists = parse_lists(lines)
  #(lists, predicates)
}

fn take_middle_number(lst: List(Int)) -> Int {
  lst
  |> list.drop(list.length(lst) / 2)
  |> list.first
  |> result.unwrap(0)
}

fn part1(data: Inputs) {
  data.0
  |> list.filter(fn(lst) { list.all(data.1, fn(predicate) { predicate(lst) }) })
  |> list.map(take_middle_number)
  |> int.sum
}

fn sort_with_predicates(
  predicates: List(fn(List(Int)) -> Bool),
  a: Int,
  b: Int,
) -> order.Order {
  case list.all(predicates, fn(predicate) { predicate([a, b]) }) {
    True -> order.Lt
    False -> order.Gt
  }
}

fn part2(data: Inputs) {
  data.0
  |> list.filter(fn(lst) { !list.all(data.1, fn(predicate) { predicate(lst) }) })
  |> list.map(list.sort(_, fn(a, b) { sort_with_predicates(data.1, a, b) }))
  |> list.map(take_middle_number)
  |> int.sum
}
