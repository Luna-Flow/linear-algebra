///|
test "run_prepared_cases/mixes_all_repeat_checksums" {
  let case_item = @support.find_case("mul_vec_baseline_dense_256").unwrap()
  let prepared = @support.prepare_case(case_item)
  let single = @support.run_prepared_case_inplace(prepared, false)
  let expected = (1469598103934665603UL ^ single) * 1099511628211UL
  inspect(run_prepared_cases([prepared]), content=expected.to_string())
  let expected_twice = (expected ^ single) * 1099511628211UL
  inspect(
    run_prepared_cases([prepared, prepared]),
    content=expected_twice.to_string(),
  )
}

///|
test "prepare_repeat_cases/scratch_copies_preserve_custom_fixture" {
  let case_item = @support.find_case("det_baseline_shifted_16").unwrap()
  let temp_dir = "src/perf_runner/tmp_perf_runner_wbtest"
  let case_path = "\{temp_dir}/det_baseline_shifted_16.json"
  if !@fs.path_exists(temp_dir) {
    @fs.create_dir(temp_dir)
  }
  @fs.write_string_to_file(case_path, custom_fixture_json(case_item))

  let prepared = @support.prepare_case_from_fixture(case_item, case_path)
  let repeated = prepare_repeat_cases(prepared, 2, true)

  inspect(repeated.length(), content="2")
  inspect(repeated[0].matrix_a.get(0, 0).to_string(), content="0")
  inspect(repeated[1].matrix_a.get(0, 0).to_string(), content="0")

  repeated[0].matrix_a.set(0, 0, 7.0)
  inspect(prepared.matrix_a.get(0, 0).to_string(), content="0")
  inspect(repeated[1].matrix_a.get(0, 0).to_string(), content="0")

  @fs.remove_file(case_path) catch {
    _ => ()
  }
  @fs.remove_dir(temp_dir) catch {
    _ => ()
  }
}

///|
fn custom_fixture_json(case_item : @support.Case) -> String {
  let rows = case_item.rows
  let cols = case_item.cols
  let total = rows * cols
  let zeros = float_array_json(total, 0.0)
  "{\"dataset_version\":\"" +
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
  "\",\"shape\":{\"rows\":" +
  rows.to_string() +
  ",\"cols\":" +
  cols.to_string() +
  ",\"rhs_cols\":" +
  case_item.rhs_cols.to_string() +
  "},\"inputs\":{\"data_a\":" +
  zeros +
  ",\"data_b\":[]}}"
}

///|
fn float_array_json(length : Int, value : Double) -> String {
  let mut out = "["
  for i = 0; i < length; i = i + 1 {
    if i > 0 {
      out = out + ","
    }
    out = out + value.to_string()
  }
  out + "]"
}
