import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

type Input =
  List(#(Int, List(Int)))

type Ops {
  Add
  Mult
  Concat
}

pub fn start() -> Nil {
  let assert Ok(content) = simplifile.read("inputs/day7.txt")
  let data = parse(content)

  let _ = io.debug(part1(data))
  let _ = io.debug(part2(data))

  Nil
}

fn parse_list(list_string: String) -> List(Int) {
  list_string
  |> string.split(" ")
  |> list.map(int.parse)
  |> list.map(result.unwrap(_, 0))
}

fn parse_line(line: String) {
  let assert Ok(#(value_string, list_string)) =
    line
    |> string.split_once(": ")

  #(int.parse(value_string) |> result.unwrap(0), parse_list(list_string))
}

fn parse(data: String) {
  data
  |> string.split("\n")
  |> list.map(parse_line)
}

fn construct_op_lists_1(length: Int) {
  case length {
    0 -> []
    _ -> {
      case construct_op_lists_1(length - 1) {
        [] -> [[Add], [Mult]]
        a -> {
          list.flatten([
            a |> list.map(list.prepend(_, Add)),
            a |> list.map(list.prepend(_, Mult)),
          ])
        }
      }
    }
  }
}

fn apply_oplist_to_list(oplist: List(Ops), lst: List(Int)) {
  let assert Ok(first) = list.first(lst)
  let #(res, _) =
    lst
    |> list.drop(1)
    |> list.fold(#(first, oplist), fn(acc, val) {
      let #(first, oplist) = acc
      let assert Ok(op) = list.first(oplist)

      case op {
        Add -> #(first + val, list.drop(oplist, 1))
        Mult -> #(first * val, list.drop(oplist, 1))
        Concat -> #(
          int.parse(int.to_string(first) <> int.to_string(val))
            |> result.unwrap(0),
          list.drop(oplist, 1),
        )
      }
    })
  res
}

fn part1(data: Input) {
  data
  |> list.filter(fn(line) {
    let op_lists = construct_op_lists_1(list.length(line.1) - 1)

    op_lists
    |> list.any(fn(x) { apply_oplist_to_list(x, line.1) == line.0 })
  })
  |> list.map(fn(line) { line.0 })
  |> int.sum
}

fn construct_op_lists_2(length: Int) {
  case length {
    0 -> []
    _ -> {
      case construct_op_lists_2(length - 1) {
        [] -> [[Add], [Mult], [Concat]]
        a -> {
          list.flatten([
            a |> list.map(list.prepend(_, Add)),
            a |> list.map(list.prepend(_, Mult)),
            a |> list.map(list.prepend(_, Concat)),
          ])
        }
      }
    }
  }
}

fn part2(data: Input) {
  data
  |> list.filter(fn(line) {
    construct_op_lists_2(list.length(line.1) - 1)
    |> list.any(fn(x) { apply_oplist_to_list(x, line.1) == line.0 })
  })
  |> list.map(fn(line) { line.0 })
  |> int.sum
}
