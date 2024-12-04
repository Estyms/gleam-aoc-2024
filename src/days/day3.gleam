import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/regexp
import gleam/result
import simplifile

pub fn start() -> Nil {
  let assert Ok(data) = simplifile.read("inputs/day3.txt")

  let _ = io.debug(part1(data))
  let _ = io.debug(part2(data))

  Nil
}

fn part1(data: String) {
  let assert Ok(reg) = regexp.from_string("mul\\(([0-9]{1,3}),([0-9]{1,3})\\)")
  data
  |> regexp.scan(with: reg)
  |> list.map(fn(x) {
    x.submatches
    |> list.map(option.unwrap(_, ""))
    |> list.map(int.parse)
    |> list.map(result.unwrap(_, 0))
    |> list.reduce(int.multiply)
    |> result.unwrap(0)
  })
  |> int.sum
}

fn part2(data: String) {
  let mul_expr = "mul\\(([0-9]{1,3}),([0-9]{1,3})\\)"
  let assert Ok(reg) =
    regexp.from_string(
      "(" <> mul_expr <> "|" <> "do\\(\\)" <> "|" <> "don't\\(\\))",
    )
  data
  |> regexp.scan(with: reg)
  |> list.fold(#(False, 0), fn(acc, match) {
    case acc.0 {
      True -> {
        case match.content {
          "do()" -> #(False, acc.1)
          _ -> acc
        }
      }
      False -> {
        case match.content {
          "don't()" -> #(True, acc.1)
          "do()" -> acc
          _ -> {
            let res =
              match.submatches
              |> list.drop(1)
              |> list.map(option.unwrap(_, ""))
              |> list.map(int.parse)
              |> list.map(result.unwrap(_, 0))
              |> list.reduce(int.multiply)
              |> result.unwrap(0)

            #(acc.0, acc.1 + res)
          }
        }
      }
    }
  })
}
