import birl
import birl/duration
import days/day1
import days/day2
import days/day3
import days/day4
import gleam/erlang
import gleam/int
import gleam/io
import gleam/result
import gleam/string

pub fn main() {
  erlang.get_line("What day do you wanna run ? ")
  |> result.unwrap("")
  |> string.trim()
  |> int.parse()
  |> result.unwrap(0)
  |> run_day()
}

pub fn run_day(day: Int) {
  let start = birl.now()
  case day {
    0 -> io.println_error("Invalid day")
    1 -> day1.start()
    2 -> day2.start()
    3 -> day3.start()
    4 -> day4.start()
    _ -> io.println("Tried to run day " <> int.to_string(day))
  }
  birl.now()
  |> birl.difference(start)
  |> duration.accurate_decompose
  |> io.debug
}