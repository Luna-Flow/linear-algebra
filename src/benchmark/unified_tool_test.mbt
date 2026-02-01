///|
test "unified_bench_tool" {
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

    // --- 1. Matrix Access ---
    let summary1 = single_bench(
      fn() { sum = m2d_matrix_access(n, n, data_2d) },
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
        sum = 0.0
        let rows = mat.row()
        let cols = mat.col()
        for i = 0; i < rows; i = i + 1 {
          for j = 0; j < cols; j = j + 1 {
            sum = sum + mat.get(i, j)
          }
        }
      },
      name="lib_matrix_access scale(\{n})",
    )
    pack(results, "lib_matrix_access scale(\{n})", ToJson::to_json(summary3))
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
        m2d_matrix_mapi(n, n, data_2d, fn(_i, _j, x) { x + 1.0 }) |> ignore
      },
      name="2d_matrix_mapi scale(\{n})",
    )
    pack(results, "2d_matrix_mapi scale(\{n})", ToJson::to_json(summary5))
    let summary6 = single_bench(
      fn() {
        naive_matrix_mapi(n, n, data_2d, fn(_i, _j, x) { x + 1.0 }) |> ignore
      },
      name="naive_matrix_mapi scale(\{n})",
    )
    pack(results, "naive_matrix_mapi scale(\{n})", ToJson::to_json(summary6))
    let summary6_native = single_bench(
      fn() {
        native_matrix_mapi(n, n, arr_1d, fn(_i, _j, x) { x + 1.0 }) |> ignore
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

    // --- 3. Map (In-place) ---
    let summary8 = single_bench(
      fn() { m2d_matrix_map_inplace(n, n, data_2d, fn(x) { x + 1.0 }) },
      name="2d_matrix_map_inplace scale(\{n})",
    )
    pack(
      results,
      "2d_matrix_map_inplace scale(\{n})",
      ToJson::to_json(summary8),
    )
    let summary9 = single_bench(
      fn() { naive_matrix_map_inplace(n, n, data_2d, fn(x) { x + 1.0 }) },
      name="naive_matrix_map_inplace scale(\{n})",
    )
    pack(
      results,
      "naive_matrix_map_inplace scale(\{n})",
      ToJson::to_json(summary9),
    )
    let summary9_native = single_bench(
      fn() { native_matrix_map_inplace(n, n, arr_1d, fn(x) { x + 1.0 }) },
      name="native_matrix_map_inplace scale(\{n})",
    )
    pack(
      results,
      "native_matrix_map_inplace scale(\{n})",
      ToJson::to_json(summary9_native),
    )
    let summary10 = single_bench(
      fn() { mat.map_inplace(fn(x) { x + 1.0 }) },
      name="lib_matrix_map_inplace scale(\{n})",
    )
    pack(
      results,
      "lib_matrix_map_inplace scale(\{n})",
      ToJson::to_json(summary10),
    )

    // --- 4. Vector Access (1D) ---
    let vec_1d = arr_1d.copy()
    let vec_lib = Vector::from_array(arr_1d.copy())
    let summary11 = single_bench(
      fn() {
        sum = 0.0
        for i = 0; i < size; i = i + 1 {
          sum = sum + vec_1d[i]
        }
      },
      name="native_vector_access scale(\{n})",
    )
    pack(
      results,
      "native_vector_access scale(\{n})",
      ToJson::to_json(summary11),
    )
    let summary11_naive = single_bench(
      fn() { sum = naive_vector_access(vec_1d) },
      name="naive_vector_access scale(\{n})",
    )
    pack(
      results,
      "naive_vector_access scale(\{n})",
      ToJson::to_json(summary11_naive),
    )
    let summary12 = single_bench(
      fn() {
        sum = 0.0
        for i = 0; i < size; i = i + 1 {
          sum = sum + vec_lib[i]
        }
      },
      name="lib_vector_access scale(\{n})",
    )
    pack(results, "lib_vector_access scale(\{n})", ToJson::to_json(summary12))
  }
  println(results.stringify())
}
