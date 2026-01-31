///|
test "unified_bench_tool" {
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
    let bench = Bench::new()
    let mut sum = 0.0

    // --- 1. Matrix Access ---
    bench.bench(
      fn() { sum = m2d_matrix_access(n, n, data_2d) },
      name="2d_matrix_access scale(\{n})",
    )
    bench.bench(
      fn() { sum = native_matrix_access(n, n, arr_1d) },
      name="native_matrix_access scale(\{n})",
    )
    bench.bench(
      fn() {
        sum = 0.0
        let rows = mat.row()
        let cols = mat.col()
        for i = 0; i < rows; i = i + 1 {
          let row = mat[i]
          for j = 0; j < cols; j = j + 1 {
            sum = sum + row[j]
          }
        }
      },
      name="lib_matrix_access scale(\{n})",
    )

    // --- 2. Map (Copy) ---
    bench.bench(
      fn() {
        m2d_matrix_mapi(n, n, data_2d, fn(_i, _j, x) { x + 1.0 }) |> ignore
      },
      name="2d_matrix_mapi_copy scale(\{n})",
    )
    bench.bench(
      fn() {
        native_matrix_mapi(n, n, arr_1d, fn(_i, _j, x) { x + 1.0 }) |> ignore
      },
      name="native_matrix_mapi_copy scale(\{n})",
    )
    bench.bench(
      fn() { mat.mapi(fn(_i, _j, x) { x + 1.0 }) |> ignore },
      name="lib_optimized_map_copy scale(\{n})",
    )
    bench.bench(
      fn() { lib_naive_matrix_mapi(mat, fn(_i, _j, x) { x + 1.0 }) |> ignore },
      name="lib_naive_map_copy scale(\{n})",
    )

    // --- 3. Map (In-place) ---
    bench.bench(
      fn() { m2d_matrix_map_inplace(n, n, data_2d, fn(x) { x + 1.0 }) },
      name="2d_matrix_map_inplace scale(\{n})",
    )
    bench.bench(
      fn() { native_matrix_map_inplace(n, n, arr_1d, fn(x) { x + 1.0 }) },
      name="native_matrix_map_inplace scale(\{n})",
    )
    bench.bench(
      fn() { mat.map_inplace(fn(x) { x + 1.0 }) },
      name="lib_optimized_map_inplace scale(\{n})",
    )
    bench.bench(
      fn() { lib_naive_matrix_map_inplace(mat, fn(x) { x + 1.0 }) },
      name="lib_naive_map_inplace scale(\{n})",
    )
    println(bench.dump_summaries())
  }
}
