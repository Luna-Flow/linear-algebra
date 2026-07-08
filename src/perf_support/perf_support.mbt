///|
#warnings("-unused_type_declaration")
using @lg {trait AddMonoid, trait Field, trait Num}

///|
pub struct Case {
  id : String
  operation : String
  family : String
  workload_tier : String
  structure : String
  timing_scope : String
  input_layout : String
  mutation_policy : String
  size_tier : String
  cost_model : String
  rows : Int
  cols : Int
  rhs_cols : Int
}

///|
pub struct PreparedCase {
  case_item : Case
  matrix_a : @mutable.Matrix[Double]
  matrix_b : @mutable.Matrix[Double]
  vector_b : @mutable.Vector[Double]
}

///|
pub fn find_case(case_id : String) -> Case? {
  for candidate in cases {
    if candidate.id == case_id {
      return Some(candidate)
    }
  }
  None
}

///|
pub fn find_prepared_case(case_id : String) -> PreparedCase? {
  for candidate in cases {
    if candidate.id == case_id {
      return Some(prepare_case(candidate))
    }
  }
  None
}

///|
pub fn case_names() -> Array[String] {
  cases.map(fn(case_item) { case_item.id })
}

///|
pub fn sample_case_names() -> Array[String] {
  let names = []
  let seen = []
  for case_item in cases {
    if case_item.workload_tier == "baseline" && case_item.size_tier == "medium" {
      if !string_array_contains(seen, case_item.operation) {
        seen.push(case_item.operation)
        names.push(case_item.id)
      }
    }
  }
  for case_item in cases {
    if case_item.workload_tier == "baseline" {
      if !string_array_contains(seen, case_item.operation) {
        seen.push(case_item.operation)
        names.push(case_item.id)
      }
    }
  }
  names
}

///|
pub fn run_case_once(case_item : Case) -> UInt64 {
  run_prepared_case_once(
    prepare_case_from_fixture(case_item, default_case_path(case_item.id)),
  )
}

///|
pub fn run_prepared_case_once(prepared : PreparedCase) -> UInt64 {
  run_prepared_case_inplace(
    prepared,
    prepared.case_item.mutation_policy == "scratch_per_sample",
  )
}

///|
pub fn run_prepared_case_inplace(
  prepared : PreparedCase,
  scratch : Bool,
) -> UInt64 {
  ignore(require_numeric_traits(0.0))
  let case_item = prepared.case_item
  let matrix_a = if scratch {
    prepared.matrix_a.copy()
  } else {
    prepared.matrix_a
  }
  let matrix_b = if scratch {
    prepared.matrix_b.copy()
  } else {
    prepared.matrix_b
  }
  let vector_b = if scratch {
    @mutable.Vector::from_array(prepared.vector_b.iter().to_array())
  } else {
    prepared.vector_b
  }
  match case_item.operation {
    "mul" => checksum_matrix(matrix_a.unchecked_matmul(matrix_b))
    "mul_vec" => checksum_vector(matrix_a.unchecked_mul_vec(vector_b))
    "determinant" => checksum_double(matrix_a.unchecked_determinant())
    "inverse" =>
      match matrix_a.unchecked_inverse() {
        Some(value) => checksum_matrix(value)
        None => mix(seed_checksum(), 0xDEAD0001UL)
      }
    "rank" => checksum_int(matrix_a.rank())
    "reduce_row_elimination" =>
      checksum_matrix(matrix_a.reduce_row_elimination())
    "cholesky_decomposition" =>
      match matrix_a.cholesky_decomposition() {
        Some(value) => checksum_matrix(value)
        None => mix(seed_checksum(), 0xDEAD0002UL)
      }
    "eigen" => {
      let (values, vectors) = matrix_a.eigen()
      let acc = checksum_vector(values)
      fold_matrix(vectors, acc)
    }
    "power_method" =>
      match matrix_a.power_method(80) {
        Some((value, vector)) => fold_vector(vector, checksum_double(value))
        None => mix(seed_checksum(), 0xDEAD0003UL)
      }
    _ => abort("unknown benchmark operation: " + case_item.operation)
  }
}

///|
pub fn prepare_case(case_item : Case) -> PreparedCase {
  prepare_case_from_fixture(case_item, default_case_path(case_item.id))
}

///|
pub fn prepare_case_from_fixture(
  case_item : Case,
  case_path : String,
) -> PreparedCase {
  let fixture = load_case_fixture(case_item, case_path)
  prepare_case_from_arrays(case_item, fixture.data_a, fixture.data_b)
}

///|
pub fn clone_prepared_case(prepared : PreparedCase) -> PreparedCase {
  {
    case_item: prepared.case_item,
    matrix_a: prepared.matrix_a.copy(),
    matrix_b: prepared.matrix_b.copy(),
    vector_b: prepared.vector_b.copy(),
  }
}

///|
fn prepare_case_from_arrays(
  case_item : Case,
  data_a : Array[Double],
  data_b : Array[Double],
) -> PreparedCase {
  let matrix_a = @mutable.Matrix::from_array(
    case_item.rows,
    case_item.cols,
    data_a,
  )
  let matrix_b = if case_item.operation == "mul" {
    @mutable.Matrix::from_array(case_item.cols, case_item.rhs_cols, data_b)
  } else {
    @mutable.Matrix::new(0, 0, 0.0)
  }
  let vector_b = if case_item.operation == "mul_vec" {
    @mutable.Vector::from_array(data_b)
  } else {
    @mutable.Vector::from_array([])
  }
  { case_item, matrix_a, matrix_b, vector_b }
}

///|
fn[T : AddMonoid + Field + Num] require_numeric_traits(value : T) -> T {
  ((value + T::zero()) / T::one()).abs()
}

///|
fn string_array_contains(values : Array[String], target : String) -> Bool {
  for value in values {
    if value == target {
      return true
    }
  }
  false
}

///|
struct CaseFixtureInputs {
  data_a : Array[Double]
  data_b : Array[Double]
} derive(FromJson)

///|
struct CaseFixtureShape {
  rows : Int
  cols : Int
  rhs_cols : Int
} derive(FromJson)

///|
struct CaseFixtureFile {
  dataset_version : String
  case_id : String
  operation : String
  family : String
  workload_tier : String
  structure : String
  timing_scope : String
  input_layout : String
  mutation_policy : String
  size_tier : String
  cost_model : String
  shape : CaseFixtureShape
  inputs : CaseFixtureInputs
} derive(FromJson)

///|
priv struct LoadedCaseFixture {
  data_a : Array[Double]
  data_b : Array[Double]
}

///|
fn default_case_path(case_id : String) -> String {
  "bench/datasets/cases/" + case_id + ".json"
}

///|
fn load_case_fixture(case_item : Case, case_path : String) -> LoadedCaseFixture {
  if !@fs.path_exists(case_path) {
    return generated_fixture_for_case(case_item, case_path)
  }
  let content = @fs.read_file_to_string(case_path) catch {
    _ => abort("failed to read benchmark fixture: " + case_path)
  }
  let json = @json.parse(content) catch {
    _ => abort("invalid benchmark json: " + case_path)
  }
  let fixture : CaseFixtureFile = @json.from_json(json) catch {
    _ => abort("failed to decode benchmark json: " + case_path)
  }
  guard fixture.dataset_version == dataset_version else {
    abort("dataset version mismatch for " + case_path)
  }
  guard fixture.case_id == case_item.id else {
    abort("case id mismatch for " + case_path)
  }
  guard fixture.operation == case_item.operation &&
    fixture.family == case_item.family &&
    fixture.workload_tier == case_item.workload_tier &&
    fixture.structure == case_item.structure &&
    fixture.timing_scope == case_item.timing_scope &&
    fixture.input_layout == case_item.input_layout &&
    fixture.mutation_policy == case_item.mutation_policy &&
    fixture.size_tier == case_item.size_tier &&
    fixture.cost_model == case_item.cost_model else {
    abort("case metadata mismatch for " + case_path)
  }
  guard fixture.shape.rows == case_item.rows &&
    fixture.shape.cols == case_item.cols &&
    fixture.shape.rhs_cols == case_item.rhs_cols else {
    abort("shape mismatch for " + case_path)
  }
  { data_a: fixture.inputs.data_a, data_b: fixture.inputs.data_b }
}

///|
pub fn case_diagnostic_payload(case_item : Case, checksum : UInt64) -> String {
  "{\"kind\":\"diagnostic\",\"dataset_version\":\"" +
  dataset_version +
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
  ",\"checksum\":\"" +
  checksum.to_string() +
  "\"}"
}

///|
fn seed_checksum() -> UInt64 {
  1469598103934665603UL
}

///|
fn mix(acc : UInt64, value : UInt64) -> UInt64 {
  (acc ^ value) * 1099511628211UL
}

///|
fn checksum_double(value : Double) -> UInt64 {
  mix(seed_checksum(), value.reinterpret_as_uint64())
}

///|
fn checksum_int(value : Int) -> UInt64 {
  mix(seed_checksum(), value.reinterpret_as_uint().to_uint64())
}

///|
fn checksum_vector(vector : @mutable.Vector[Double]) -> UInt64 {
  fold_vector(vector, seed_checksum())
}

///|
fn checksum_matrix(matrix : @mutable.Matrix[Double]) -> UInt64 {
  fold_matrix(matrix, seed_checksum())
}

///|
fn fold_vector(vector : @mutable.Vector[Double], init : UInt64) -> UInt64 {
  let mut acc = init
  vector
  .iter()
  .each(fn(value) { acc = mix(acc, value.reinterpret_as_uint64()) })
  acc
}

///|
fn fold_matrix(matrix : @mutable.Matrix[Double], init : UInt64) -> UInt64 {
  let mut acc = mix(init, matrix.row().reinterpret_as_uint().to_uint64())
  acc = mix(acc, matrix.col().reinterpret_as_uint().to_uint64())
  matrix
  .iter()
  .each(fn(value) { acc = mix(acc, value.reinterpret_as_uint64()) })
  acc
}
