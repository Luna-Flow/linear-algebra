///|
fn main {
  let args = @env.args()
  let repeat = find_repeat_arg(args)
  let sample_count = find_samples_arg(args)
  let warmup_count = find_warmup_arg(args)
  guard repeat > 0 else {
    abort("repeat must be positive")
  }
  guard sample_count >= 0 else {
    abort("samples must be non-negative")
  }
  guard warmup_count >= 0 else {
    abort("warmup must be non-negative")
  }
  match find_case_arg(args) {
    Some(case_id) =>
      match @support.find_prepared_case(case_id) {
        Some(case_item) => {
          if sample_count == 0 {
            let checksum = run_repeat(case_item, repeat)
            println(@support.case_diagnostic_payload(case_item.case_item, checksum))
          } else {
            run_warmup(case_item, repeat, warmup_count)
            let samples = collect_samples(case_item, repeat, sample_count)
            println(benchmark_payload(case_item.case_item, samples, repeat))
          }
        }
        None => abort("unknown benchmark case: " + case_id)
      }
    None =>
      abort(
        "usage: moon run src/perf_runner <case-id> [--repeat <n>] [--samples <n>] [--warmup <n>]",
      )
  }
}

///|
fn find_case_arg(args : Array[String]) -> String? {
  for i = args.length() - 1; i >= 0; i = i - 1 {
    let candidate = args[i]
    if @support.find_prepared_case(candidate) is Some(_) {
      return Some(candidate)
    }
  }
  None
}

///|
fn find_repeat_arg(args : Array[String]) -> Int {
  find_flag_arg(args, "--repeat").unwrap_or(1)
}

///|
fn find_samples_arg(args : Array[String]) -> Int {
  find_flag_arg(args, "--samples").unwrap_or(0)
}

///|
fn find_warmup_arg(args : Array[String]) -> Int {
  find_flag_arg(args, "--warmup").unwrap_or(0)
}

///|
fn find_flag_arg(args : Array[String], flag : String) -> Int? {
  for i = 0; i + 1 < args.length(); i = i + 1 {
    if args[i] == flag {
      return Some(parse_int_arg(flag, args[i + 1]))
    }
  }
  None
}

///|
fn parse_int_arg(flag : String, value : String) -> Int {
  try @string.parse_int(value) catch {
    _ => abort("invalid value for " + flag + ": " + value)
  } noraise {
    parsed => parsed
  }
}

///|
fn run_repeat(case_item : @support.PreparedCase, repeat : Int) -> UInt64 {
  let mut checksum = 0UL
  for _ in 0..<repeat {
    checksum = @support.run_prepared_case_once(case_item)
  }
  checksum
}

///|
fn run_warmup(case_item : @support.PreparedCase, repeat : Int, warmup_count : Int) -> Unit {
  for _ in 0..<warmup_count {
    ignore(run_repeat(case_item, repeat))
  }
}

///|
fn collect_samples(
  case_item : @support.PreparedCase,
  repeat : Int,
  sample_count : Int,
) -> Array[Int] {
  let samples = []
  for _ in 0..<sample_count {
    let start = @bench.monotonic_clock_start()
    ignore(run_repeat(case_item, repeat))
    let elapsed_us = @bench.monotonic_clock_end(start)
    let elapsed_ns = (elapsed_us * 1000.0).to_int()
    samples.push(elapsed_ns / repeat)
  }
  samples
}

///|
fn benchmark_payload(case_item : @support.Case, samples : Array[Int], repeat : Int) -> String {
  "{\"kind\":\"benchmark\",\"dataset_version\":\"" +
  @support.dataset_version +
  "\",\"case_id\":\"" +
  case_item.id +
  "\",\"operation\":\"" +
  case_item.operation +
  "\",\"family\":\"" +
  case_item.family +
  "\",\"rows\":" +
  case_item.rows.to_string() +
  ",\"cols\":" +
  case_item.cols.to_string() +
  ",\"rhs_cols\":" +
  case_item.rhs_cols.to_string() +
  ",\"repeat\":" +
  repeat.to_string() +
  ",\"samples\":" +
  int_array_json(samples) +
  "}"
}

///|
fn int_array_json(values : Array[Int]) -> String {
  let mut out = "["
  for i = 0; i < values.length(); i = i + 1 {
    if i > 0 {
      out = out + ","
    }
    out = out + values[i].to_string()
  }
  out + "]"
}
