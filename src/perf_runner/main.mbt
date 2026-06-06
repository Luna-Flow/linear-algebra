///|
fn main {
  let args = @env.args()
  let repeat = find_repeat_arg(args)
  let sample_count = find_samples_arg(args)
  let warmup_count = find_warmup_arg(args)
  let case_path = find_case_path_arg(args)
  guard repeat > 0 else { abort("repeat must be positive") }
  guard sample_count >= 0 else { abort("samples must be non-negative") }
  guard warmup_count >= 0 else { abort("warmup must be non-negative") }
  match find_case_arg(args) {
    Some(case_id) =>
      match @support.find_case(case_id) {
        Some(case_item) => {
          let prepared = @support.prepare_case_from_fixture(
            case_item, case_path,
          )
          let scratch = case_item.mutation_policy == "scratch_per_sample"
          if sample_count == 0 {
            let checksum = run_repeat(prepared, repeat, scratch)
            println(@support.case_diagnostic_payload(case_item, checksum))
          } else {
            run_warmup(prepared, repeat, warmup_count, scratch)
            let samples = collect_samples(
              prepared, repeat, sample_count, scratch,
            )
            println(benchmark_payload(case_item, samples, repeat))
          }
        }
        None => abort("unknown benchmark case: " + case_id)
      }
    None =>
      abort(
        "usage: moon run src/perf_runner <case-id> --case-file <path> [--repeat <n>] [--samples <n>] [--warmup <n>]",
      )
  }
}

///|
fn find_case_arg(args : Array[String]) -> String? {
  let mut skip_next = false
  for candidate in args {
    if skip_next {
      skip_next = false
      continue
    }
    if candidate == "--repeat" ||
      candidate == "--samples" ||
      candidate == "--warmup" ||
      candidate == "--case-file" {
      skip_next = true
      continue
    }
    if @support.find_case(candidate) is Some(_) {
      return Some(candidate)
    }
  }
  None
}

///|
fn find_case_path_arg(args : Array[String]) -> String {
  for i = 0; i + 1 < args.length(); i = i + 1 {
    if args[i] == "--case-file" {
      return args[i + 1]
    }
  }
  abort("missing --case-file")
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
fn run_repeat(
  case_item : @support.PreparedCase,
  repeat : Int,
  scratch : Bool,
) -> UInt64 {
  let scratch_cases = prepare_repeat_cases(case_item, repeat, scratch)
  run_prepared_cases(scratch_cases)
}

///|
fn run_warmup(
  case_item : @support.PreparedCase,
  repeat : Int,
  warmup_count : Int,
  scratch : Bool,
) -> Unit {
  for _ in 0..<warmup_count {
    ignore(run_repeat(case_item, repeat, scratch))
  }
}

///|
fn collect_samples(
  case_item : @support.PreparedCase,
  repeat : Int,
  sample_count : Int,
  scratch : Bool,
) -> Array[Int] {
  let samples = []
  for _ in 0..<sample_count {
    let scratch_cases = prepare_repeat_cases(case_item, repeat, scratch)
    let start = @bench.monotonic_clock_start()
    ignore(run_prepared_cases(scratch_cases))
    let elapsed_us = @bench.monotonic_clock_end(start)
    let elapsed_ns = (elapsed_us * 1000.0).to_int()
    samples.push(elapsed_ns / repeat)
  }
  samples
}

///|
fn prepare_repeat_cases(
  case_item : @support.PreparedCase,
  repeat : Int,
  scratch : Bool,
) -> Array[@support.PreparedCase] {
  let out = []
  for _ in 0..<repeat {
    if scratch {
      out.push(@support.clone_prepared_case(case_item))
    } else {
      out.push(case_item)
    }
  }
  out
}

///|
fn run_prepared_cases(cases : Array[@support.PreparedCase]) -> UInt64 {
  let mut checksum = 1469598103934665603UL
  for case_item in cases {
    let value = @support.run_prepared_case_inplace(case_item, false)
    checksum = (checksum ^ value) * 1099511628211UL
  }
  checksum
}

///|
fn benchmark_payload(
  case_item : @support.Case,
  samples : Array[Int],
  repeat : Int,
) -> String {
  "{\"kind\":\"benchmark\",\"dataset_version\":\"" +
  @support.dataset_version +
  "\",\"case_id\":\"" +
  case_item.id +
  "\",\"operation\":\"" +
  case_item.operation +
  "\",\"family\":\"" +
  case_item.family +
  "\",\"workload_tier\":\"" +
  case_item.workload_tier +
  "\",\"structure\":\"" +
  case_item.structure +
  "\",\"timing_scope\":\"" +
  case_item.timing_scope +
  "\",\"input_layout\":\"" +
  case_item.input_layout +
  "\",\"mutation_policy\":\"" +
  case_item.mutation_policy +
  "\",\"size_tier\":\"" +
  case_item.size_tier +
  "\",\"cost_model\":\"" +
  case_item.cost_model +
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
