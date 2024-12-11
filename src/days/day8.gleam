import gleam/dict.{type Dict}
import gleam/io
import gleam/list.{Continue, Stop}
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import simplifile
import utils/utils

type Size {
  Size(width: Int, height: Int)
}

type Coord {
  Coord(x: Int, y: Int)
}

type Input {
  Input(size: Size, antennas: Dict(String, List(Coord)))
}

pub fn start() -> Nil {
  let assert Ok(content) = simplifile.read("inputs/day8.txt")
  let data = parse(content)

  let _ = io.debug(part1(data))
  let _ = io.debug(part2(data))

  Nil
}

fn parse(data: String) -> Input {
  let width =
    data
    |> string.split("\n")
    |> list.first()
    |> result.unwrap("")
    |> string.length

  let height =
    data
    |> string.split("\n")
    |> list.length

  let antennas =
    data
    |> string.split("\n")
    |> list.index_map(fn(row, row_index) {
      row
      |> string.to_graphemes
      |> list.index_map(fn(letter, col_index) {
        case letter {
          "." -> None
          x -> Some(#(x, Coord(col_index, row_index)))
        }
      })
      |> list.filter(option.is_some)
      |> list.map(option.unwrap(_, #("#", Coord(0, 0))))
    })
    |> list.flatten
    |> list.fold(dict.new(), fn(dictio, cell_data) {
      let #(char, coords) = cell_data
      case dict.has_key(dictio, char) {
        True -> {
          dictio
          |> dict.get(char)
          |> result.unwrap([])
          |> list.append([coords])
          |> dict.insert(dictio, char, _)
        }
        False -> {
          dict.insert(dictio, char, [coords])
        }
      }
    })

  Input(Size(width, height), antennas)
}

fn in_bound(coord: Coord, size: Size) -> Bool {
  case coord.x < size.width && coord.x >= 0 {
    True -> coord.y < size.height && coord.y >= 0
    False -> False
  }
}

fn create_antinode(coords: List(Coord)) {
  let assert [a, b] = coords

  let antinode_mirroded = Coord(b.x - a.x, b.y - a.y)

  Coord(a.x - antinode_mirroded.x, a.y - antinode_mirroded.y)
}

fn create_antinodes_in_bound(antennas: List(Coord), size: Size) {
  antennas
  |> list.combinations(2)
  |> list.map(list.permutations)
  |> list.flatten
  |> list.map(create_antinode(_))
  |> list.filter(in_bound(_, size))
}

fn part1(data: Input) {
  let Input(size, antennas) = data

  antennas
  |> dict.keys()
  |> list.map(dict.get(antennas, _))
  |> list.map(result.unwrap(_, []))
  |> list.map(create_antinodes_in_bound(_, size))
  |> list.flatten
  |> list.unique
  |> list.length
}

fn create_repeating_antinodes(coords: List(Coord), size: Size) {
  let assert [a, b] = coords

  let res =
    utils.create_int_range(1, size.height)
    |> list.fold_until([], fn(acc, multiplier) {
      let antinode_mirroded =
        Coord({ b.x - a.x } * multiplier, { b.y - a.y } * multiplier)
      let antinode = Coord(a.x - antinode_mirroded.x, a.y - antinode_mirroded.y)
      case in_bound(antinode, size) {
        True -> Continue(list.append(acc, [antinode]))
        False -> Stop(acc)
      }
    })
  res
}

fn create_repeating_antinodes_in_bound(antennas: List(Coord), size: Size) {
  antennas
  |> list.combinations(2)
  |> list.map(list.permutations)
  |> list.flatten
  |> list.map(create_repeating_antinodes(_, size))
  |> list.flatten
}

fn part2(data: Input) {
  let Input(size, antennas) = data

  let triangulated_antennas =
    antennas
    |> dict.values
    |> list.filter(fn(x) { list.length(x) > 1 })
    |> list.flatten

  antennas
  |> dict.keys()
  |> list.map(dict.get(antennas, _))
  |> list.map(result.unwrap(_, []))
  |> list.map(create_repeating_antinodes_in_bound(_, size))
  |> list.flatten
  |> list.append(triangulated_antennas)
  |> list.unique
  |> list.length
}
