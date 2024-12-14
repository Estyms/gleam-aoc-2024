import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/set.{type Set}
import gleam/string
import simplifile

type Coord {
  Coord(x: Int, y: Int)
}

type Cell {
  Cell(coord: Coord, value: Int)
}

type State {
  State(found_peak: Set(Cell), count: Int)
}

pub fn start() -> Nil {
  let assert Ok(content) = simplifile.read("inputs/day10.txt")
  let data = parse(content)

  let assert Ok(#(a, b)) = part1(data)

  io.debug(a)
  io.debug(b)

  Nil
}

fn create_cell(char: String, col_idx: Int, row_idx: Int) {
  case char {
    "." -> None
    _ ->
      Some(Cell(Coord(col_idx, row_idx), int.parse(char) |> result.unwrap(0)))
  }
}

fn parse(data: String) {
  data
  |> string.split("\n")
  |> list.index_map(fn(line, row_idx) {
    line
    |> string.to_graphemes()
    |> list.index_map(fn(c, i) { create_cell(c, i, row_idx) })
    |> list.filter(option.is_some)
    |> list.map(option.unwrap(_, Cell(Coord(0, 0), 0)))
  })
  |> list.flatten
}

fn find_neighbours(
  cell: Cell,
  map: Dict(Coord, Int),
  visited: Set(Coord),
) -> List(Cell) {
  [Coord(0, 1), Coord(0, -1), Coord(1, 0), Coord(-1, 0)]
  |> list.map(fn(relative) {
    let Coord(x, y) = relative
    let possible_neighbour = Coord(cell.coord.x + x, cell.coord.y + y)
    case set.contains(visited, possible_neighbour) {
      True -> None
      False -> {
        case dict.get(map, possible_neighbour) {
          Ok(value) -> Some(Cell(possible_neighbour, value))
          Error(_) -> None
        }
      }
    }
  })
  |> list.filter(option.is_some)
  |> list.map(option.unwrap(_, Cell(Coord(0, 0), 0)))
}

fn find_peaks(
  state: State,
  cell: Cell,
  map: Dict(Coord, Int),
  visited: Set(Coord),
) -> State {
  let new_visited = set.insert(visited, cell.coord)
  case cell.value == 9 {
    True -> State(set.insert(set.new(), cell), 1)
    False -> {
      cell
      |> find_neighbours(map, visited)
      |> list.filter(fn(neighbour) { neighbour.value == cell.value + 1 })
      |> list.map(find_peaks(state, _, map, new_visited))
      |> list.reduce(fn(state_a, state_b) {
        State(
          set.union(state_a.found_peak, state_b.found_peak),
          state_a.count + state_b.count,
        )
      })
      |> result.unwrap(State(set.new(), 0))
    }
  }
}

fn part1(data: List(Cell)) {
  let map =
    data
    |> list.fold(dict.new(), fn(acc, cell) {
      dict.insert(acc, cell.coord, cell.value)
    })

  data
  |> list.filter(fn(cell) { cell.value == 0 })
  |> list.map(find_peaks(State(set.new(), 0), _, map, set.new()))
  |> list.map(fn(state) { #(set.size(state.found_peak), state.count) })
  |> list.reduce(fn(a, b) { #(a.0 + b.0, a.1 + b.1) })
}
