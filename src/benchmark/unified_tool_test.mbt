///|
test "unified_bench_tool" {
  let mut sink_double : Double = 0.0
  let mut sink_array_double : Array[Double] = []
  let mut sink_array_array_double : Array[Array[Double]] = []
  let results = Json::object({})
  let steps = [64, 128, 256, 512]
  for n in steps {
    let rng = PRNG::new(42L)
    // 2D data
    let data_2d = Array::makei(n, fn(_i) {
      Array::makei(n, fn(_j) { rng.next() })
    })
    // 1D data
    let size = n * n
    let arr_1d = Array::makei(size, fn(idx) {
      let i = idx / n
      let j = idx % n
      data_2d[i][j]
    })
    // Lib data
    let mat = Matrix::from_array(n, n, arr_1d.copy())
    let mut sum = 0.0

    // --- 1. Matrix Access & Set ---
    let summary1 = single_bench(
      fn() { sum = _2d_matrix_access(n, n, data_2d) },
      name="2d_matrix_access scale(\{n})",
    )
    pack(results, "2d_matrix_access scale(\{n})", ToJson::to_json(summary1))
    let summary2 = single_bench(
      fn() { sum = naive_matrix_access(n, n, data_2d) },
      name="naive_matrix_access scale(\{n})",
    )
    pack(results, "naive_matrix_access scale(\{n})", ToJson::to_json(summary2))
    let summary2_native = single_bench(
      fn() { sum = native_matrix_access(n, n, arr_1d) },
      name="native_matrix_access scale(\{n})",
    )
    pack(
      results,
      "native_matrix_access scale(\{n})",
      ToJson::to_json(summary2_native),
    )
    let summary3 = single_bench(
      fn() {
        let mut inner_sum = 0.0
        let rows = mat.row()
        let cols = mat.col()
        for i = 0; i < rows; i = i + 1 {
          for j = 0; j < cols; j = j + 1 {
            inner_sum = inner_sum + mat.get(i, j)
          }
        }
        sum = inner_sum
      },
      name="lib_matrix_access scale(\{n})",
    )
    pack(results, "lib_matrix_access scale(\{n})", ToJson::to_json(summary3))

    // -- Set Access --
    let summary_set_2d = single_bench(
      fn() { _2d_matrix_set_access(n, n, data_2d, 1.0) },
      name="2d_matrix_set_access scale(\{n})",
    )
    pack(
      results,
      "2d_matrix_set_access scale(\{n})",
      ToJson::to_json(summary_set_2d),
    )
    let summary_set_naive = single_bench(
      fn() { naive_matrix_set_access(n, n, data_2d, 1.0) },
      name="naive_matrix_set_access scale(\{n})",
    )
    pack(
      results,
      "naive_matrix_set_access scale(\{n})",
      ToJson::to_json(summary_set_naive),
    )
    let summary_set_native = single_bench(
      fn() { native_matrix_set_access(n, n, arr_1d, 1.0) },
      name="native_matrix_set_access scale(\{n})",
    )
    pack(
      results,
      "native_matrix_set_access scale(\{n})",
      ToJson::to_json(summary_set_native),
    )
    let summary4 = single_bench(
      fn() {
        let rows = mat.row()
        let cols = mat.col()
        for i = 0; i < rows; i = i + 1 {
          for j = 0; j < cols; j = j + 1 {
            mat.set(i, j, 1.0)
          }
        }
      },
      name="lib_matrix_set_access scale(\{n})",
    )
    pack(
      results,
      "lib_matrix_set_access scale(\{n})",
      ToJson::to_json(summary4),
    )

    // --- 2. Map (Copy) ---
    let summary5 = single_bench(
      fn() {
        sink_array_array_double = _2d_matrix_mapi(n, n, data_2d, fn(_i, _j, x) {
          x + 1.0
        })
      },
      name="2d_matrix_mapi scale(\{n})",
    )
    pack(results, "2d_matrix_mapi scale(\{n})", ToJson::to_json(summary5))
    let summary6 = single_bench(
      fn() {
        sink_array_array_double = naive_matrix_mapi(n, n, data_2d, fn(
          _i,
          _j,
          x,
        ) {
          x + 1.0
        })
      },
      name="naive_matrix_mapi scale(\{n})",
    )
    pack(results, "naive_matrix_mapi scale(\{n})", ToJson::to_json(summary6))
    let summary6_native = single_bench(
      fn() {
        sink_array_double = native_matrix_mapi(n, n, arr_1d, fn(_i, _j, x) {
          x + 1.0
        })
      },
      name="native_matrix_mapi scale(\{n})",
    )
    pack(
      results,
      "native_matrix_mapi scale(\{n})",
      ToJson::to_json(summary6_native),
    )
    let summary7 = single_bench(
      fn() { mat.mapi(fn(_i, _j, x) { x + 1.0 }) |> ignore },
      name="lib_matrix_mapi scale(\{n})",
    )
    pack(results, "lib_matrix_mapi scale(\{n})", ToJson::to_json(summary7))

    // --- 3. Vector Access ---
    let (vec_lib, vec_arr) = {
      let arr = Array::makei(n, fn(_i) { rng.next() })
      (Vector::from_array(arr.copy()), arr)
    }
    let summary_va_lib = single_bench(
      fn() {
        let mut inner_sum = 0.0
        let len = vec_lib.length()
        for i = 0; i < len; i = i + 1 {
          inner_sum = inner_sum + vec_lib[i]
        }
        sum = inner_sum
      },
      name="lib_vector_access scale(\{n})",
    )
    pack(
      results,
      "lib_vector_access scale(\{n})",
      ToJson::to_json(summary_va_lib),
    )
    let summary_va_native = single_bench(
      fn() { sum = native_vector_access(vec_arr) },
      name="native_vector_access scale(\{n})",
    )
    pack(
      results,
      "native_vector_access scale(\{n})",
      ToJson::to_json(summary_va_native),
    )
    let summary_va_naive = single_bench(
      fn() { sum = naive_vector_access(vec_arr) },
      name="naive_vector_access scale(\{n})",
    )
    pack(
      results,
      "naive_vector_access scale(\{n})",
      ToJson::to_json(summary_va_naive),
    )

    // --- 4. Each / RowCol ---
    let summary_each_lib = single_bench(
      fn() {
        let mut inner_sum = 0.0
        mat.each(fn(x) { inner_sum = inner_sum + x })
        sum = inner_sum
      },
      name="lib_matrix_each scale(\{n})",
    )
    pack(
      results,
      "lib_matrix_each scale(\{n})",
      ToJson::to_json(summary_each_lib),
    )
    let summary_each_native = single_bench(
      fn() {
        let mut inner_sum = 0.0
        native_matrix_each(arr_1d, fn(x) { inner_sum = inner_sum + x })
        sum = inner_sum
      },
      name="native_matrix_each scale(\{n})",
    )
    pack(
      results,
      "native_matrix_each scale(\{n})",
      ToJson::to_json(summary_each_native),
    )
    let summary_each_naive = single_bench(
      fn() {
        let mut inner_sum = 0.0
        naive_matrix_each(data_2d, fn(x) { inner_sum = inner_sum + x })
        sum = inner_sum
      },
      name="naive_matrix_each scale(\{n})",
    )
    pack(
      results,
      "naive_matrix_each scale(\{n})",
      ToJson::to_json(summary_each_naive),
    )
    let summary_each_2d = single_bench(
      fn() {
        let mut inner_sum = 0.0
        _2d_matrix_each(data_2d, fn(x) { inner_sum = inner_sum + x })
        sum = inner_sum
      },
      name="2d_matrix_each scale(\{n})",
    )
    pack(
      results,
      "2d_matrix_each scale(\{n})",
      ToJson::to_json(summary_each_2d),
    )

    // -- Each Row Col --
    let summary_erc_lib = single_bench(
      fn() {
        let mut inner_sum = 0.0
        mat.each_row_col(fn(_i, _j, x) { inner_sum = inner_sum + x })
        sum = inner_sum
      },
      name="lib_matrix_each_row_col scale(\{n})",
    )
    pack(
      results,
      "lib_matrix_each_row_col scale(\{n})",
      ToJson::to_json(summary_erc_lib),
    )
    let summary_erc_native = single_bench(
      fn() {
        let mut inner_sum = 0.0
        native_matrix_each_row_col(n, n, arr_1d, fn(_i, _j, x) {
          inner_sum = inner_sum + x
        })
        sum = inner_sum
      },
      name="native_matrix_each_row_col scale(\{n})",
    )
    pack(
      results,
      "native_matrix_each_row_col scale(\{n})",
      ToJson::to_json(summary_erc_native),
    )
    let summary_erc_2d = single_bench(
      fn() {
        let mut inner_sum = 0.0
        _2d_matrix_each_row_col(n, n, data_2d, fn(_i, _j, x) {
          inner_sum = inner_sum + x
        })
        sum = inner_sum
      },
      name="2d_matrix_each_row_col scale(\{n})",
    )
    pack(
      results,
      "2d_matrix_each_row_col scale(\{n})",
      ToJson::to_json(summary_erc_2d),
    )
    let summary_erc_naive = single_bench(
      fn() {
        let mut inner_sum = 0.0
        naive_matrix_each_row_col(data_2d, fn(_i, _j, x) {
          inner_sum = inner_sum + x
        })
        sum = inner_sum
      },
      name="naive_matrix_each_row_col scale(\{n})",
    )
    pack(
      results,
      "naive_matrix_each_row_col scale(\{n})",
      ToJson::to_json(summary_erc_naive),
    )
    sink_double = sum
  }
  println(results.stringify())
  ignore(sink_double)
  ignore(sink_array_double)
  ignore(sink_array_array_double)
}
