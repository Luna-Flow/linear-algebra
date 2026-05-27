test "run_prepared_case_once/reduce_row_elimination_reuses_prepared_case_safely" {
  let case_item = find_case("rref_baseline_dense_64x48").unwrap()
  let prepared = prepare_case(case_item)
  let before = prepared.matrix_a.to_array()

  let first = run_prepared_case_once(prepared)
  let second = run_prepared_case_once(prepared)
  let after = prepared.matrix_a.to_array()

  inspect(first == second, content="true")
  inspect(before == after, content="true")
}

test "sample_case_names/covers_each_operation_once" {
  let names = sample_case_names()
  inspect(names.length(), content="9")
}
