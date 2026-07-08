///|
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

///|
test "sample_case_names/covers_each_operation_once" {
  let names = sample_case_names()
  inspect(names.length(), content="9")
}

///|
test "prepare_case_from_fixture/generates_missing_fixture_file" {
  let case_item = find_case("mul_baseline_dense_64").unwrap()
  let temp_dir = "src/perf_support/tmp_perf_support_wbtest"
  let case_path = "\{temp_dir}/mul_baseline_dense_64.json"
  if !@fs.path_exists(temp_dir) {
    @fs.create_dir(temp_dir)
  }
  @fs.remove_file(case_path) catch {
    _ => ()
  }

  let prepared = prepare_case_from_fixture(case_item, case_path)

  inspect(@fs.path_exists(case_path), content="true")
  inspect(prepared.matrix_a.row().to_string(), content="64")
  inspect(prepared.matrix_b.col().to_string(), content="64")

  @fs.remove_file(case_path) catch {
    _ => ()
  }
  @fs.remove_dir(temp_dir) catch {
    _ => ()
  }
}
