///|
fn generated_fixture_for_case(
  case_item : Case,
  case_path : String,
) -> LoadedCaseFixture {
  let seed = fixture_seed_for_case(case_item.id).unwrap_or_else(fn() {
    abort("missing generated fixture seed for benchmark case: " + case_item.id)
  })
  let rng = [seed]
  let fixture = generate_fixture_inputs(case_item, rng)
  persist_generated_fixture(case_item, case_path, fixture)
  fixture
}

///|
fn generate_fixture_inputs(
  case_item : Case,
  rng : Array[UInt64],
) -> LoadedCaseFixture {
  match case_item.operation {
    "mul" =>
      {
        data_a: dense_matrix(case_item.rows, case_item.cols, rng, -1.0, 1.0),
        data_b: dense_matrix(case_item.cols, case_item.rhs_cols, rng, -1.0, 1.0),
      }
    "mul_vec" => {
      let data_a = if case_item.structure == "diagonal_dominant" {
        make_dominant_symmetric(case_item.rows, rng, 0.03)
      } else if case_item.structure == "projector_like" {
        make_projector_like(case_item.rows, case_item.cols, rng)
      } else {
        dense_matrix(case_item.rows, case_item.cols, rng, -1.0, 1.0)
      }
      { data_a, data_b: dense_vector(case_item.cols, rng, -1.0, 1.0) }
    }
    "determinant" => {
      let data_a = if case_item.structure == "dense_shifted" {
        make_dense_shifted(case_item.rows, rng, 1.25)
      } else if case_item.structure == "upper_triangular" {
        make_upper_triangular(case_item.rows, rng)
      } else {
        make_near_singular(case_item.rows, rng)
      }
      { data_a, data_b: [] }
    }
    "inverse" => {
      let data_a = if case_item.structure == "dense_shifted" {
        make_dense_shifted(case_item.rows, rng, 1.25)
      } else if case_item.structure == "spd" {
        make_spd(case_item.rows, rng, case_item.rows.to_double() * 0.75)
      } else {
        add_matrices(
          make_near_singular(case_item.rows, rng),
          identity_matrix(case_item.rows, 1.0),
        )
      }
      { data_a, data_b: [] }
    }
    "rank" => {
      let data_a = if case_item.structure == "block_pattern" {
        make_block_pattern(case_item.rows, case_item.cols, rng)
      } else if case_item.structure == "rank_deficient" {
        make_rect_rank_deficient(case_item.rows, case_item.cols, rng)
      } else {
        dense_matrix(case_item.rows, case_item.cols, rng, -1.0, 1.0)
      }
      { data_a, data_b: [] }
    }
    "reduce_row_elimination" => {
      let data_a = if case_item.structure == "block_pattern" {
        make_block_pattern(case_item.rows, case_item.cols, rng)
      } else if case_item.structure == "rank_deficient" {
        make_rank_deficient(case_item.rows, rng)
      } else {
        dense_matrix(case_item.rows, case_item.cols, rng, -1.0, 1.0)
      }
      { data_a, data_b: [] }
    }
    "cholesky_decomposition" => {
      let diagonal_bias = if case_item.structure == "well_conditioned_spd" {
        case_item.rows.to_double() * 1.5
      } else if case_item.structure == "weakly_spd" {
        1.0
      } else {
        case_item.rows.to_double()
      }
      { data_a: make_spd(case_item.rows, rng, diagonal_bias), data_b: [] }
    }
    "eigen" => {
      let data_a = if case_item.structure == "clustered_spectrum" {
        make_clustered_symmetric(case_item.rows, rng)
      } else if case_item.structure == "close_eigenvalues" {
        make_small_gap_symmetric(case_item.rows, rng)
      } else {
        make_symmetric(case_item.rows, rng, 0.75)
      }
      { data_a, data_b: [] }
    }
    "power_method" => {
      let data_a = if case_item.structure == "large_spectral_gap" {
        make_dominant_symmetric(case_item.rows, rng, 0.02)
      } else if case_item.structure == "small_spectral_gap" {
        make_small_gap_symmetric(case_item.rows, rng)
      } else {
        make_dominant_symmetric(case_item.rows, rng, 0.08)
      }
      { data_a, data_b: [] }
    }
    _ => abort("unknown generated benchmark operation: " + case_item.operation)
  }
}

///|
fn persist_generated_fixture(
  case_item : Case,
  case_path : String,
  fixture : LoadedCaseFixture,
) -> Unit {
  let default_path = default_case_path(case_item.id)
  if case_path == default_path && !@fs.path_exists("bench/datasets/cases") {
    @fs.create_dir("bench/datasets/cases") catch {
      _ => ()
    }
  }
  @fs.write_string_to_file(case_path, case_fixture_json(case_item, fixture)) catch {
    _ => ()
  }
}

///|
fn case_fixture_json(case_item : Case, fixture : LoadedCaseFixture) -> String {
  "{\"dataset_version\":\"" +
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
  "\",\"shape\":{\"rows\":" +
  case_item.rows.to_string() +
  ",\"cols\":" +
  case_item.cols.to_string() +
  ",\"rhs_cols\":" +
  case_item.rhs_cols.to_string() +
  "},\"inputs\":{\"data_a\":" +
  double_array_json(fixture.data_a) +
  ",\"data_b\":" +
  double_array_json(fixture.data_b) +
  "}}\n"
}

///|
fn double_array_json(values : Array[Double]) -> String {
  let mut out = "["
  for i = 0; i < values.length(); i = i + 1 {
    if i > 0 {
      out = out + ","
    }
    out = out + values[i].to_string()
  }
  out + "]"
}

///|
fn dense_matrix(
  rows : Int,
  cols : Int,
  rng : Array[UInt64],
  lo : Double,
  hi : Double,
) -> Array[Double] {
  let out = []
  for _ in 0..<(rows * cols) {
    out.push(uniform(rng, lo, hi))
  }
  out
}

///|
fn dense_vector(
  size : Int,
  rng : Array[UInt64],
  lo : Double,
  hi : Double,
) -> Array[Double] {
  let out = []
  for _ in 0..<size {
    out.push(uniform(rng, lo, hi))
  }
  out
}

///|
fn diagonal_matrix(diag : Array[Double]) -> Array[Double] {
  let size = diag.length()
  let data = Array::make(size * size, 0.0)
  for i = 0; i < size; i = i + 1 {
    data[i * size + i] = diag[i]
  }
  data
}

///|
fn identity_matrix(size : Int, scale : Double) -> Array[Double] {
  let data = Array::make(size * size, 0.0)
  for i = 0; i < size; i = i + 1 {
    data[i * size + i] = scale
  }
  data
}

///|
fn transpose(rows : Int, cols : Int, data : Array[Double]) -> Array[Double] {
  let out = Array::make(rows * cols, 0.0)
  for i = 0; i < rows; i = i + 1 {
    let row_offset = i * cols
    for j = 0; j < cols; j = j + 1 {
      out[j * rows + i] = data[row_offset + j]
    }
  }
  out
}

///|
fn matmul(
  a_rows : Int,
  a_cols : Int,
  b_cols : Int,
  a : Array[Double],
  b : Array[Double],
) -> Array[Double] {
  let out = Array::make(a_rows * b_cols, 0.0)
  for i = 0; i < a_rows; i = i + 1 {
    let row_offset = i * b_cols
    let a_row_offset = i * a_cols
    for k = 0; k < a_cols; k = k + 1 {
      let av = a[a_row_offset + k]
      let b_offset = k * b_cols
      for j = 0; j < b_cols; j = j + 1 {
        out[row_offset + j] = out[row_offset + j] + av * b[b_offset + j]
      }
    }
  }
  out
}

///|
fn add_matrices(a : Array[Double], b : Array[Double]) -> Array[Double] {
  let out = []
  for i = 0; i < a.length(); i = i + 1 {
    out.push(a[i] + b[i])
  }
  out
}

///|
fn scale_matrix(data : Array[Double], factor : Double) -> Array[Double] {
  let out = []
  for value in data {
    out.push(factor * value)
  }
  out
}

///|
fn make_symmetric(
  size : Int,
  rng : Array[UInt64],
  scale : Double,
) -> Array[Double] {
  let base = dense_matrix(size, size, rng, -scale, scale)
  let data = Array::make(size * size, 0.0)
  for i = 0; i < size; i = i + 1 {
    let row_offset = i * size
    for j = 0; j < size; j = j + 1 {
      data[row_offset + j] = 0.5 * (base[row_offset + j] + base[j * size + i])
    }
  }
  data
}

///|
fn make_spd(
  size : Int,
  rng : Array[UInt64],
  diagonal_bias : Double,
) -> Array[Double] {
  let base = dense_matrix(size, size, rng, -0.9, 0.9)
  let gram = matmul(size, size, size, transpose(size, size, base), base)
  add_matrices(gram, identity_matrix(size, diagonal_bias))
}

///|
fn make_near_singular(size : Int, rng : Array[UInt64]) -> Array[Double] {
  let data = dense_matrix(size, size, rng, -0.5, 0.5)
  for col = 0; col < size; col = col + 1 {
    let value = data[col]
    data[size + col] = value * 0.999999 + (col + 1).to_double() * 1.0e-7
  }
  for i = 0; i < size; i = i + 1 {
    let idx = i * size + i
    data[idx] = data[idx] + 0.25
  }
  data
}

///|
fn make_rank_deficient(size : Int, rng : Array[UInt64]) -> Array[Double] {
  let data = dense_matrix(size, size, rng, -0.8, 0.8)
  let dst_row_offset = (size - 1) * size
  for col = 0; col < size; col = col + 1 {
    data[dst_row_offset + col] = data[col]
  }
  data
}

///|
fn make_rect_rank_deficient(
  rows : Int,
  cols : Int,
  rng : Array[UInt64],
) -> Array[Double] {
  let data = dense_matrix(rows, cols, rng, -0.8, 0.8)
  let mut row = 1
  while row < rows {
    let src = (row - 1) * cols
    let dst = row * cols
    for col = 0; col < cols; col = col + 1 {
      data[dst + col] = data[src + col]
    }
    row += 3
  }
  data
}

///|
fn make_upper_triangular(size : Int, rng : Array[UInt64]) -> Array[Double] {
  let data = Array::make(size * size, 0.0)
  for i = 0; i < size; i = i + 1 {
    let row_offset = i * size
    for j = i; j < size; j = j + 1 {
      let mut value = uniform(rng, -0.9, 0.9)
      if i == j {
        value = value + 1.5
      }
      data[row_offset + j] = value
    }
  }
  data
}

///|
fn make_dominant_symmetric(
  size : Int,
  rng : Array[UInt64],
  noise_scale : Double,
) -> Array[Double] {
  let diag = []
  for i = 0; i < size; i = i + 1 {
    diag.push((size - i).to_double() * 0.4 + 1.0)
  }
  let matrix = diagonal_matrix(diag)
  let noise = make_symmetric(size, rng, 0.75)
  add_matrices(matrix, scale_matrix(noise, noise_scale))
}

///|
fn make_dense_shifted(
  size : Int,
  rng : Array[UInt64],
  identity_scale : Double,
) -> Array[Double] {
  add_matrices(
    dense_matrix(size, size, rng, -1.0, 1.0),
    identity_matrix(size, identity_scale),
  )
}

///|
fn make_projector_like(
  rows : Int,
  cols : Int,
  rng : Array[UInt64],
) -> Array[Double] {
  let data = dense_matrix(rows, cols, rng, -0.25, 0.25)
  for row = 0; row < rows; row = row + 1 {
    let row_offset = row * cols
    for col = 0; col < cols; col = col + 1 {
      if row % 7 == col % 7 {
        data[row_offset + col] = data[row_offset + col] + 1.5
      }
    }
  }
  data
}

///|
fn make_block_pattern(
  rows : Int,
  cols : Int,
  rng : Array[UInt64],
) -> Array[Double] {
  let data = dense_matrix(rows, cols, rng, -0.15, 0.15)
  for row = 0; row < rows; row = row + 1 {
    let row_offset = row * cols
    for col = 0; col < cols; col = col + 1 {
      if (row / 8 + col / 8) % 2 == 0 {
        data[row_offset + col] = data[row_offset + col] + uniform(rng, 0.6, 1.0)
      }
    }
  }
  data
}

///|
fn make_clustered_symmetric(size : Int, rng : Array[UInt64]) -> Array[Double] {
  let diag = []
  for i = 0; i < size; i = i + 1 {
    let cluster = 1.0 + (i % 4).to_double() * 0.03
    diag.push(cluster + i.to_double() * 0.0005)
  }
  let matrix = diagonal_matrix(diag)
  let noise = make_symmetric(size, rng, 0.2)
  add_matrices(matrix, scale_matrix(noise, 0.05))
}

///|
fn make_small_gap_symmetric(size : Int, rng : Array[UInt64]) -> Array[Double] {
  let diag = []
  for i = 0; i < size; i = i + 1 {
    diag.push(1.0 + i.to_double() * 0.002)
  }
  let matrix = diagonal_matrix(diag)
  let noise = make_symmetric(size, rng, 0.25)
  add_matrices(matrix, scale_matrix(noise, 0.1))
}

///|
fn uniform(rng : Array[UInt64], lo : Double, hi : Double) -> Double {
  lo + (hi - lo) * splitmix64_unit(rng)
}

///|
fn splitmix64_unit(rng : Array[UInt64]) -> Double {
  let bits = (splitmix64_next(rng) >> 11) & 0x1FFFFFFFFFFFFFUL
  bits.to_double() / 9007199254740992.0
}

///|
fn splitmix64_next(rng : Array[UInt64]) -> UInt64 {
  let state = rng[0] + 0x9E3779B97F4A7C15UL
  rng[0] = state
  let z1 = (state ^ (state >> 30)) * 0xBF58476D1CE4E5B9UL
  let z2 = (z1 ^ (z1 >> 27)) * 0x94D049BB133111EBUL
  z2 ^ (z2 >> 31)
}
