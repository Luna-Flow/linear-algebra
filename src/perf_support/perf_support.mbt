///|
#warnings("-unused_type_declaration")
using @lg {trait AddMonoid, trait Field, trait Num}

///|
pub struct Case {
  id : String
  operation : String
  family : String
  rows : Int
  cols : Int
  rhs_cols : Int
  data_a : Array[Double]
  data_b : Array[Double]
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
pub fn run_case_once(case_item : Case) -> UInt64 {
  run_prepared_case_once(prepare_case(case_item))
}

///|
pub fn run_prepared_case_once(prepared : PreparedCase) -> UInt64 {
  require_numeric_traits(0.0)
  let case_item = prepared.case_item
  match case_item.operation {
    "mul" => {
      checksum_matrix(prepared.matrix_a * prepared.matrix_b)
    }
    "mul_vec" => {
      checksum_vector(prepared.matrix_a.mul_vec(prepared.vector_b))
    }
    "determinant" => {
      checksum_double(prepared.matrix_a.determinant())
    }
    "inverse" => {
      match prepared.matrix_a.inverse() {
        Some(value) => checksum_matrix(value)
        None => mix(seed_checksum(), 0xDEAD0001UL)
      }
    }
    "rank" => {
      checksum_int(prepared.matrix_a.rank())
    }
    "reduce_row_elimination" => {
      // Benchmark runs reuse one prepared case, so mutating kernels must work
      // on a fresh matrix to keep every timed iteration comparable.
      checksum_matrix(prepared.matrix_a.copy().reduce_row_elimination())
    }
    "cholesky_decomposition" => {
      match prepared.matrix_a.cholesky_decomposition() {
        Some(value) => checksum_matrix(value)
        None => mix(seed_checksum(), 0xDEAD0002UL)
      }
    }
    "eigen" => {
      let (values, vectors) = prepared.matrix_a.eigen()
      let acc = checksum_vector(values)
      fold_matrix(vectors, acc)
    }
    "power_method" => {
      match prepared.matrix_a.power_method(80) {
        Some((value, vector)) => fold_vector(vector, checksum_double(value))
        None => mix(seed_checksum(), 0xDEAD0003UL)
      }
    }
    _ => abort("unknown benchmark operation: " + case_item.operation)
  }
}

///|
pub fn prepare_case(case_item : Case) -> PreparedCase {
  let matrix_a = @mutable.Matrix::from_array(
    case_item.rows,
    case_item.cols,
    case_item.data_a,
  )
  let matrix_b =
    if case_item.operation == "mul" {
      @mutable.Matrix::from_array(
        case_item.cols,
        case_item.rhs_cols,
        case_item.data_b,
      )
    } else {
      @mutable.Matrix::new(0, 0, 0.0)
    }
  let vector_b =
    if case_item.operation == "mul_vec" {
      @mutable.Vector::from_array(case_item.data_b)
    } else {
      @mutable.Vector::from_array([])
    }
  { case_item, matrix_a, matrix_b, vector_b }
}

///|
fn[T : AddMonoid + Field + Num] require_numeric_traits(_ : T) -> Unit {

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
