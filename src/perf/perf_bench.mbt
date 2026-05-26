///|
test (b : @bench.T) {
  let cases = @support.cases.map(@support.prepare_case)
  for case_item in cases {
    b.bench(name=case_item.case_item.operation + "/" + case_item.case_item.id, fn() {
      b.keep(@support.run_prepared_case_once(case_item))
    })
  }
}
