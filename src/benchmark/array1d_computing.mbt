///|
pub fn array1d_mat_mul(
  n : Int,
  a : Array[Double],
  b : Array[Double],
) -> Array[Double] {
  if n <= 64 {
    let c = Array::make(n * n, 0.0)
    for i = 0; i < n; i = i + 1 {
      let row_offset = i * n
      for j = 0; j < n; j = j + 1 {
        let mut sum = 0.0
        for k = 0; k < n; k = k + 1 {
          sum = sum + a[row_offset + k] * b[k * n + j]
        }
        c[row_offset + j] = sum
      }
    }
    c
  } else {
    let c = Array::make(n * n, 0.0)
    let mut res_idx = 0
    for i = 0; i < n; i = i + 1 {
      for k = 0; k < n; k = k + 1 {
        let aik = a[i * n + k]
        let other_row_start = k * n
        for j = 0; j < n; j = j + 1 {
          c[res_idx + j] = c[res_idx + j] + aik * b[other_row_start + j]
        }
      }
      res_idx += n
    }
    c
  }
}

///|
pub fn array1d_vec_dot(a : Array[Double], b : Array[Double]) -> Double {
  let mut sum = 0.0
  let len = a.length()
  for i = 0; i < len; i = i + 1 {
    sum = sum + a[i] * b[i]
  }
  sum
}

///|
pub fn array1d_mat_vec_mul(
  row : Int,
  col : Int,
  mat : Array[Double],
  vec : Array[Double],
) -> Array[Double] {
  let res = Array::make(row, 0.0)
  let mut idx = 0
  for i = 0; i < row; i = i + 1 {
    let mut sum = 0.0
    for j = 0; j < col; j = j + 1 {
      sum = sum + mat[idx] * vec[j]
      idx += 1
    }
    res[i] = sum
  }
  res
}

///|
pub fn array1d_mat_acc(rows : Int, cols : Int, data : Array[Double]) -> Double {
  let mut sum = 0.0
  let len = rows * cols
  for i = 0; i < len; i = i + 1 {
    sum = sum + data[i]
  }
  sum
}

///|
pub fn array1d_mat_mapi(
  rows : Int,
  cols : Int,
  data : Array[Double],
  f : (Int, Int, Double) -> Double,
) -> Array[Double] {
  let res = Array::make(rows * cols, 0.0)
  for i = 0; i < rows; i = i + 1 {
    let offset = i * cols
    for j = 0; j < cols; j = j + 1 {
      res[offset + j] = f(i, j, data[offset + j])
    }
  }
  res
}

///|
pub fn array1d_mat_map_inplace(
  _rows : Int,
  _cols : Int,
  data : Array[Double],
  f : (Double) -> Double,
) -> Unit {
  let len = data.length()
  for i = 0; i < len; i = i + 1 {
    data[i] = f(data[i])
  }
}

///|
pub fn array1d_mat_set_acc(
  _rows : Int,
  _cols : Int,
  data : Array[Double],
  val : Double,
) -> Unit {
  let len = data.length()
  for i = 0; i < len; i = i + 1 {
    data[i] = val
  }
}

///|
pub fn array1d_vec_acc(data : Array[Double]) -> Double {
  let mut sum = 0.0
  let len = data.length()
  for i = 0; i < len; i = i + 1 {
    sum = sum + data[i]
  }
  sum
}

// --- Advanced Computing ---

///|
pub fn array1d_reduce_row_elimination(
  rows : Int,
  cols : Int,
  data : Array[Double],
) -> Array[Double] {
  let m = data.copy()
  let mut col = 0
  for i = 0; i < rows; i = i + 1 {
    if col >= cols {
      break
    }
    let mut max_row = i
    for j = i + 1; j < rows; j = j + 1 {
      if m[j * cols + col].abs() > m[max_row * cols + col].abs() {
        max_row = j
      }
    }
    // Swap rows
    if max_row != i {
      for k = 0; k < cols; k = k + 1 {
        let tmp = m[i * cols + k]
        m[i * cols + k] = m[max_row * cols + k]
        m[max_row * cols + k] = tmp
      }
    }
    if m[i * cols + col].abs() < 1.0e-15 {
      col = col + 1
      continue
    }
    let val = m[i * cols + col]
    for k = 0; k < cols; k = k + 1 {
      m[i * cols + k] = m[i * cols + k] / val
    }
    for j = 0; j < rows; j = j + 1 {
      if j == i {
        continue
      }
      let factor = m[j * cols + col]
      for k = 0; k < cols; k = k + 1 {
        m[j * cols + k] = m[j * cols + k] - m[i * cols + k] * factor
      }
    }
    col = col + 1
  }
  m
}

///|
pub fn array1d_det(n : Int, data : Array[Double]) -> Double {
  let m = data.copy()
  if n == 0 {
    return 1.0
  }
  let mut det_sign = 1.0
  for j = 0; j < n; j = j + 1 {
    let mut max_row = j
    for i = j + 1; i < n; i = i + 1 {
      if m[i * n + j].abs() > m[max_row * n + j].abs() {
        max_row = i
      }
    }
    if max_row != j {
      // Swap rows
      for k = 0; k < n; k = k + 1 {
        let tmp = m[j * n + k]
        m[j * n + k] = m[max_row * n + k]
        m[max_row * n + k] = tmp
      }
      det_sign = -det_sign
    }
    let pivot = m[j * n + j]
    if pivot.abs() < 1.0e-15 {
      return 0.0
    }
    for i = j + 1; i < n; i = i + 1 {
      let factor = m[i * n + j] / pivot
      for k = j + 1; k < n; k = k + 1 {
        m[i * n + k] = m[i * n + k] - factor * m[j * n + k]
      }
    }
  }
  let mut det = det_sign
  for i = 0; i < n; i = i + 1 {
    det = det * m[i * n + i]
  }
  det
}

///|
pub fn array1d_rank(rows : Int, cols : Int, data : Array[Double]) -> Int {
  let m = array1d_reduce_row_elimination(rows, cols, data)
  let mut rank = 0
  for i = 0; i < rows; i = i + 1 {
    let mut has_nonzero = false
    for j = 0; j < cols; j = j + 1 {
      if m[i * cols + j].abs() > 1.0e-15 {
        has_nonzero = true
        break
      }
    }
    if has_nonzero {
      rank += 1
    }
  }
  rank
}

///|
pub fn array1d_inv(n : Int, data : Array[Double]) -> Array[Double]? {
  let rows = n
  let cols = 2 * n
  let augmented = Array::make(rows * cols, 0.0)
  for i = 0; i < n; i = i + 1 {
    for j = 0; j < n; j = j + 1 {
      augmented[i * cols + j] = data[i * n + j]
    }
    augmented[i * cols + n + i] = 1.0
  }
  let res = array1d_reduce_row_elimination(rows, cols, augmented)
  for i = 0; i < n; i = i + 1 {
    if res[i * cols + i].abs() < 1.0e-15 {
      return None
    }
  }
  let inv = Array::make(n * n, 0.0)
  for i = 0; i < n; i = i + 1 {
    for j = 0; j < n; j = j + 1 {
      inv[i * n + j] = res[i * cols + n + j]
    }
  }
  Some(inv)
}

// --- Utility Functions ---

///|
pub fn array1d_mat_each(data : Array[Double], f : (Double) -> Unit) -> Unit {
  let len = data.length()
  for i = 0; i < len; i = i + 1 {
    f(data[i])
  }
}

///|
pub fn array1d_mat_each_row_col(
  rows : Int,
  cols : Int,
  data : Array[Double],
  f : (Int, Int, Double) -> Unit,
) -> Unit {
  let mut idx = 0
  for i = 0; i < rows; i = i + 1 {
    for j = 0; j < cols; j = j + 1 {
      f(i, j, data[idx])
      idx += 1
    }
  }
}
