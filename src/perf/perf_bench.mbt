///|
test (b : @bench.T) {
  let cases = @support.cases.map(@support.prepare_case)
  for case_item in cases {
    let prewarm = warmup_count(case_item.case_item.operation)
    for _ in 0..<prewarm {
      ignore(@support.run_prepared_case_once(case_item))
    }
    b.bench(name=case_item.case_item.operation + "/" + case_item.case_item.id, fn() {
      b.keep(@support.run_prepared_case_once(case_item))
    })
  }
}

///|
fn warmup_count(operation : String) -> Int {
  if operation == "mul_vec" {
    12
  } else if operation == "rank" || operation == "reduce_row_elimination" {
    4
  } else if operation == "determinant" ||
    operation == "inverse" ||
    operation == "cholesky_decomposition" ||
    operation == "eigen" ||
    operation == "power_method" {
    2
  } else {
    3
  }
}
