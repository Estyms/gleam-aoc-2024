import gleam/dict
import gleam/io
import gleam/list
import gleam/option
import gleam/otp/task
import gleam/set
import gleam/string
import simplifile

type CellType {
  Empty
  Wall
  Visited
}

type Facing {
  North
  South
  East
  West
}

type Labyrinth =
  dict.Dict(#(Int, Int), CellType)

type Guard =
  #(#(Int, Int), Facing)

type Inputs =
  #(Labyrinth, Guard)

pub fn start() -> Nil {
  let assert Ok(content) = simplifile.read("inputs/day6.txt")
  let data = parse(content)

  let _ = io.debug(part1(data))
  let _ = io.debug(part2(data))

  Nil
}

fn parse_line(line: String, row: Int) -> List(#(#(Int, Int), CellType)) {
  let #(_, cells) =
    line
    |> string.to_graphemes()
    |> list.fold(#(0, []), fn(acc, char) {
      let val = case char {
        "#" -> #(#(acc.0, row), Wall)
        "v" | ">" | "^" | "<" -> #(#(acc.0, row), Visited)
        _ -> #(#(acc.0, row), Empty)
      }
      #(acc.0 + 1, list.append(acc.1, [val]))
    })
  cells
}

fn parse(data: String) -> Inputs {
  let #(_, cells) =
    data
    |> string.split("\n")
    |> list.fold(#(0, []), fn(acc, line) {
      #(acc.0 + 1, list.append(acc.1, parse_line(line, acc.0)))
    })

  let assert #(y, option.Some(#(x, option.Some(facing)))) =
    data
    |> string.split("\n")
    |> list.fold_until(#(0, option.None), fn(y, line) {
      let val =
        line
        |> string.to_graphemes
        |> list.fold_until(#(0, option.None), fn(x, char) {
          case char {
            "^" -> list.Stop(#(x.0, option.Some(North)))
            ">" -> list.Stop(#(x.0, option.Some(East)))
            "<" -> list.Stop(#(x.0, option.Some(West)))
            "v" -> list.Stop(#(x.0, option.Some(South)))
            _ -> list.Continue(#(x.0 + 1, option.None))
          }
        })

      case val.1 {
        option.Some(_) -> list.Stop(#(y.0, option.Some(val)))
        option.None -> list.Continue(#(y.0 + 1, y.1))
      }
    })

  let guard = #(#(x, y), facing)

  #(dict.from_list(cells), guard)
}

fn rotate_90(facing: Facing) -> Facing {
  case facing {
    East -> South
    North -> East
    South -> West
    West -> North
  }
}

fn is_wall(labyrinth: Labyrinth, position: #(Int, Int)) -> Bool {
  case dict.get(labyrinth, position) {
    Ok(Wall) -> True
    _ -> False
  }
}

fn step_guard(guard: Guard, labyrinth: Labyrinth) -> Guard {
  let #(#(x, y), facing) = guard

  let new_pos = case facing {
    East -> #(x + 1, y)
    North -> #(x, y - 1)
    South -> #(x, y + 1)
    West -> #(x - 1, y)
  }

  case is_wall(labyrinth, new_pos) {
    True -> {
      step_guard(#(#(x, y), rotate_90(facing)), labyrinth)
    }
    False -> {
      #(new_pos, facing)
    }
  }
}

fn step(labyrinth: Labyrinth, guard: Guard) -> #(Labyrinth, Guard, Bool) {
  let new_guard = step_guard(guard, labyrinth)

  case dict.get(labyrinth, new_guard.0) {
    Ok(_) -> {
      let new_lab = dict.insert(labyrinth, new_guard.0, Visited)
      #(new_lab, new_guard, True)
    }
    Error(_) -> #(labyrinth, guard, False)
  }
}

fn simulate(labyrinth: Labyrinth, guard: Guard) -> Labyrinth {
  case step(labyrinth, guard) {
    #(new_lab, new_guard, True) -> simulate(new_lab, new_guard)
    #(new_lab, _, False) -> new_lab
  }
}

fn part1(data: Inputs) {
  let #(labyrinth, guard) = data
  simulate(labyrinth, guard)
  |> dict.to_list()
  |> list.count(fn(cell) {
    let #(_, cell_type) = cell
    case cell_type {
      Visited -> True
      _ -> False
    }
  })
}

fn simulate_part_2(
  labyrinth: Labyrinth,
  guard: Guard,
  visited: set.Set(Guard),
) -> Bool {
  case set.contains(visited, guard) {
    True -> True
    False -> {
      case step(labyrinth, guard) {
        #(new_lab, new_guard, True) ->
          simulate_part_2(new_lab, new_guard, set.insert(visited, guard))
        #(_, _, False) -> False
      }
    }
  }
}

fn part2(data: Inputs) {
  let #(labyrinth, guard) = data
  let possible_obstacle_positions =
    simulate(labyrinth, guard)
    |> dict.to_list()
    |> list.filter(fn(cell) {
      let #(_, cell_type) = cell
      case cell_type {
        Visited -> True
        _ -> False
      }
    })
    |> list.map(fn(cell) { cell.0 })
    |> list.filter(fn(x) { x != guard.0 })

  // Parallelisme
  possible_obstacle_positions
  |> list.map(fn(cell_pos) {
    task.async(fn() {
      dict.insert(labyrinth, cell_pos, Wall)
      |> simulate_part_2(guard, set.new())
    })
  })
  |> list.map(task.await_forever)
  |> list.count(fn(x) { x })
}
