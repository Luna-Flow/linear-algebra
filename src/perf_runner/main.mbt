///|
fn main {
  let args = @env.args()
  match find_case_arg(args) {
    Some(case_id) => {
      match @support.find_prepared_case(case_id) {
        Some(case_item) => {
          let checksum = @support.run_prepared_case_once(case_item)
          println(@support.case_json_payload(case_item.case_item, checksum))
        }
        None => abort("unknown benchmark case: " + case_id)
      }
    }
    None => {
      abort("usage: moon run src/perf_runner <case-id>")
    }
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
