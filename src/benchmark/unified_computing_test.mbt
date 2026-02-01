///|
test "unified_bench_computing" {
  let results = Json::object({})
  let steps_mul = [8, 16, 32, 64, 96, 128]
  for n in steps_mul {
    let rng = PRNG::new(42L)
    // 2D data
    let a_2d = Array::makei(n, fn(_i) { Array::makei(n, fn(_j) { rng.next() }) })
    let b_2d = Array::makei(n, fn(_i) { Array::makei(n, fn(_j) { rng.next() }) })
    // 1D data
    let size = n * n
    let a_1d = Array::makei(size, fn(idx) { a_2d[idx / n][idx % n] })
    let b_1d = Array::makei(size, fn(idx) { b_2d[idx / n][idx % n] })
    // Lib data
    let a_mat = Matrix::from_array(n, n, a_1d.copy())
    let b_mat = Matrix::from_array(n, n, b_1d.copy())
    let summary1 = single_bench(
      fn() { m2d_matrix_mul(n, a_2d, b_2d) |> ignore },
      name="2d_matrix_mul scale(\{n})",
    )
    pack(results, "2d_matrix_mul scale(\{n})", ToJson::to_json(summary1))
    let summary2 = single_bench(
      fn() { naive_matrix_mul(n, a_2d, b_2d) |> ignore },
      name="naive_matrix_mul scale(\{n})",
    )
    pack(results, "naive_matrix_mul scale(\{n})", ToJson::to_json(summary2))
    let summary3 = single_bench(
      fn() { native_matrix_mul(n, a_1d, b_1d) |> ignore },
      name="native_matrix_mul scale(\{n})",
    )
    pack(results, "native_matrix_mul scale(\{n})", ToJson::to_json(summary3))
    let summary4 = single_bench(
      fn() { (a_mat * b_mat) |> ignore },
      name="lib_matrix_mul scale(\{n})",
    )
    pack(results, "lib_matrix_mul scale(\{n})", ToJson::to_json(summary4))
  }

  // --- Vector Ops ---
  let steps_vec = [1000, 100000]
  for n in steps_vec {
    let rng = PRNG::new(42L)
    let arr1 = Array::makei(n, fn(_i) { rng.next() })
    let arr2 = Array::makei(n, fn(_i) { rng.next() })
    let v1 = Vector::from_array(arr1.copy())
    let v2 = Vector::from_array(arr2.copy())
    let summary1 = single_bench(
      fn() { native_vector_dot(arr1, arr2) |> ignore },
      name="native_vector_dot scale(\{n})",
    )
    pack(results, "native_vector_dot scale(\{n})", ToJson::to_json(summary1))
    let summary2 = single_bench(
      fn() { naive_vector_dot(arr1, arr2) |> ignore },
      name="naive_vector_dot scale(\{n})",
    )
    pack(results, "naive_vector_dot scale(\{n})", ToJson::to_json(summary2))
    let summary3 = single_bench(
      fn() { v1.dot(v2) |> ignore },
      name="lib_vector_dot scale(\{n})",
    )
    pack(results, "lib_vector_dot scale(\{n})", ToJson::to_json(summary3))
  }

  // --- Matrix-Vector Mul ---
  let steps_mat_vec = [128, 512, 1024]
  for n in steps_mat_vec {
    let rng = PRNG::new(42L)
    let mat_2d = Array::makei(n, fn(_i) {
      Array::makei(n, fn(_j) { rng.next() })
    })
    let vec_1d = Array::makei(n, fn(_i) { rng.next() })
    let size = n * n
    let mat_1d = Array::makei(size, fn(idx) { mat_2d[idx / n][idx % n] })
    let mat_lib = Matrix::from_array(n, n, mat_1d.copy())
    let vec_lib = Vector::from_array(vec_1d.copy())
    let summary1 = single_bench(
      fn() { m2d_matrix_vector_mul(n, n, mat_2d, vec_1d) |> ignore },
      name="2d_matrix_vector_mul scale(\{n})",
    )
    pack(results, "2d_matrix_vector_mul scale(\{n})", ToJson::to_json(summary1))
    let summary2 = single_bench(
      fn() { naive_matrix_vector_mul(n, n, mat_2d, vec_1d) |> ignore },
      name="naive_matrix_vector_mul scale(\{n})",
    )
    pack(
      results,
      "naive_matrix_vector_mul scale(\{n})",
      ToJson::to_json(summary2),
    )
    let summary3 = single_bench(
      fn() { native_matrix_vector_mul(n, n, mat_1d, vec_1d) |> ignore },
      name="native_matrix_vector_mul scale(\{n})",
    )
    pack(
      results,
      "native_matrix_vector_mul scale(\{n})",
      ToJson::to_json(summary3),
    )
    let summary4 = single_bench(
      fn() { mat_lib.mul_vec(vec_lib) |> ignore },
      name="lib_matrix_vector_mul scale(\{n})",
    )
    pack(
      results,
      "lib_matrix_vector_mul scale(\{n})",
      ToJson::to_json(summary4),
    )
  }
  println(results.stringify())
}
