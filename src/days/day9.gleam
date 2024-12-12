import gleam/int
import gleam/io
import gleam/list
import gleam/order
import gleam/result
import gleam/set.{type Set}
import gleam/string
import simplifile
import utils/utils

type Range {
  Range(start: Int, end: Int)
}

type Block {
  Block(id: Int, position: Int)
  BlockRange(id: Int, range: Range)
  EmptyRange(range: Range)
}

pub fn start() -> Nil {
  let assert Ok(content) = simplifile.read("inputs/day9.txt")

  let _ = io.debug(part1(parse_p1(content)))
  let _ = io.debug(part2(parse_p2(content)))

  Nil
}

fn parse_p1(data: String) {
  let #(_, _, _, files) =
    data
    |> string.to_graphemes()
    |> list.map(int.parse)
    |> list.map(result.unwrap(_, 0))
    |> list.fold(#(False, 0, 0, []), fn(acc, num) {
      let #(is_free, current_id, current_position, list_files) = acc
      case is_free {
        True -> #(False, current_id, current_position + num, list_files)
        False -> {
          #(
            True,
            current_id + 1,
            current_position + num,
            list.append(
              list_files,
              utils.create_int_range(current_position, current_position + num)
                |> list.map(Block(current_id, _)),
            ),
          )
        }
      }
    })
  files
}

fn parse_p2(data: String) {
  let #(_, _, _, files) =
    data
    |> string.to_graphemes()
    |> list.map(int.parse)
    |> list.map(result.unwrap(_, 0))
    |> list.fold(#(False, 0, 0, []), fn(acc, num) {
      let #(is_free, current_id, current_position, list_files) = acc
      case is_free {
        True -> #(False, current_id, current_position + num, list_files)
        False -> {
          #(
            True,
            current_id + 1,
            current_position + num,
            list.append(list_files, [
              BlockRange(
                current_id,
                Range(current_position, current_position + num - 1),
              ),
            ]),
          )
        }
      }
    })
  files
}

fn recurse_compress(
  lst: List(Block),
  reversed: List(Block),
  current_pos: Int,
) -> #(Set(Block), List(Block)) {
  case list.first(lst) {
    Ok(Block(id, pos)) if pos == current_pos -> {
      let following_list = [Block(id, current_pos)]
      let following_set = set.from_list([Block(id, pos)])
      let #(recursed_set, recursed_list) =
        recurse_compress(list.drop(lst, 1), reversed, current_pos + 1)

      case set.is_subset(following_set, recursed_set) {
        True -> #(following_set, following_list)
        False -> #(
          set.union(following_set, recursed_set),
          list.append(following_list, recursed_list),
        )
      }
    }
    _ -> {
      case list.first(reversed) {
        Ok(Block(id, pos)) -> {
          let following_list = [Block(id, current_pos)]
          let following_set = set.from_list([Block(id, pos)])
          let #(recursed_set, recursed_list) =
            recurse_compress(lst, list.drop(reversed, 1), current_pos + 1)

          case set.is_subset(following_set, recursed_set) {
            True -> #(following_set, following_list)
            False -> #(
              set.union(following_set, recursed_set),
              list.append(following_list, recursed_list),
            )
          }
        }
        _ -> #(set.new(), [])
      }
    }
  }
}

fn part1(data: List(Block)) {
  let #(_, compressed) = recurse_compress(data, list.reverse(data), 0)
  let range = utils.create_int_range(0, list.length(compressed))

  list.zip(compressed, range)
  |> list.map(fn(tup) {
    let assert #(Block(id, _), pos) = tup
    pos * id
  })
  |> int.sum
}

fn sort_blocks(a: Block, b: Block) {
  case a, b {
    BlockRange(_, range_a), BlockRange(_, range_b) ->
      int.compare(range_a.start, range_b.start)
    EmptyRange(range_a), EmptyRange(range_b) ->
      int.compare(range_a.start, range_b.start)
    Block(_, position_a), Block(_, position_b) ->
      int.compare(position_a, position_b)
    _, _ -> order.Eq
  }
}

fn part2(data: List(Block)) {
  let empty_ranges =
    data
    |> list.window_by_2
    |> list.filter(fn(w) {
      let assert #(BlockRange(id_a, _), BlockRange(id_b, _)) = w
      id_a < id_b
    })
    |> list.reverse
    |> list.drop(1)
    |> list.reverse
    |> list.map(fn(w) {
      let assert #(BlockRange(_, range_a), BlockRange(_, range_b)) = w
      EmptyRange(Range(range_a.end + 1, range_b.start - 1))
    })

  let #(new_compressed_ranges, _) =
    data
    |> list.reverse()
    |> list.fold(
      #([], empty_ranges),
      fn(acc: #(List(Block), List(Block)), block) {
        let #(new_ranges, empty_ranges) = acc
        let assert BlockRange(id, block_range) = block

        case
          empty_ranges
          |> list.find(fn(range) {
            let assert EmptyRange(range) = range
            range.end - range.start >= block_range.end - block_range.start
            && range.start < block_range.start
            // IMPORTANT OMG ⬆️
          })
        {
          Ok(range) -> {
            let assert EmptyRange(empty_range) = range
            let #(new_range, new_empty) = #(
              BlockRange(
                id,
                Range(
                  empty_range.start,
                  empty_range.start + { block_range.end - block_range.start },
                ),
              ),
              EmptyRange(Range(
                empty_range.start + { block_range.end - block_range.start } + 1,
                empty_range.end,
              )),
            )

            let new_empty = case new_empty.range.start > new_empty.range.end {
              True -> {
                set.from_list(empty_ranges)
                |> set.delete(range)
                |> set.to_list()
                |> list.sort(sort_blocks)
              }
              False -> {
                set.from_list(empty_ranges)
                |> set.delete(range)
                |> set.insert(new_empty)
                |> set.to_list()
                |> list.sort(sort_blocks)
              }
            }

            #(list.append(new_ranges, [new_range]), new_empty)
          }
          Error(_) -> #(list.append(new_ranges, [block]), empty_ranges)
        }
      },
    )

  new_compressed_ranges
  |> list.map(fn(block_range) {
    let assert BlockRange(id, range) = block_range
    utils.create_int_range(range.start, range.end + 1)
    |> int.sum
    |> int.multiply(id)
  })
  |> int.sum
}
