///|
test "unified_bench_computing" {
  let mut sink_double : Double = 0.0
  let mut sink_array_double : Array[Double] = []
  let mut sink_array_array_double : Array[Array[Double]] = []
  let results = Json::object({})

  // --- 1. Matrix Multiplication ---
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
      fn() { sink_array_array_double = _2d_matrix_mul(n, a_2d, b_2d) },
      name="2d_matrix_mul scale(\{n})",
    )
    pack(results, "2d_matrix_mul scale(\{n})", ToJson::to_json(summary1))
    let summary2 = single_bench(
      fn() { sink_array_array_double = naive_matrix_mul(n, a_2d, b_2d) },
      name="naive_matrix_mul scale(\{n})",
    )
    pack(results, "naive_matrix_mul scale(\{n})", ToJson::to_json(summary2))
    let summary3 = single_bench(
      fn() { sink_array_double = native_matrix_mul(n, a_1d, b_1d) },
      name="native_matrix_mul scale(\{n})",
    )
    pack(results, "native_matrix_mul scale(\{n})", ToJson::to_json(summary3))
    let summary4 = single_bench(
      fn() { (a_mat * b_mat) |> ignore },
      name="lib_matrix_mul scale(\{n})",
    )
    pack(results, "lib_matrix_mul scale(\{n})", ToJson::to_json(summary4))
  }

  // --- 2. Vector Ops ---
  let steps_vec = [1000, 100000]
  for n in steps_vec {
    let rng = PRNG::new(42L)
    let arr1 = Array::makei(n, fn(_i) { rng.next() })
    let arr2 = Array::makei(n, fn(_i) { rng.next() })
    let v1 = Vector::from_array(arr1.copy())
    let v2 = Vector::from_array(arr2.copy())
    let summary1 = single_bench(
      fn() { sink_double = native_vector_dot(arr1, arr2) },
      name="native_vector_dot scale(\{n})",
    )
    pack(results, "native_vector_dot scale(\{n})", ToJson::to_json(summary1))
    let summary2 = single_bench(
      fn() { sink_double = naive_vector_dot(arr1, arr2) },
      name="naive_vector_dot scale(\{n})",
    )
    pack(results, "naive_vector_dot scale(\{n})", ToJson::to_json(summary2))
    let summary3 = single_bench(
      fn() { sink_double = v1.dot(v2) },
      name="lib_vector_dot scale(\{n})",
    )
    pack(results, "lib_vector_dot scale(\{n})", ToJson::to_json(summary3))
  }

  // --- 3. Matrix-Vector Mul ---
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
      fn() { sink_array_double = _2d_matrix_vector_mul(n, n, mat_2d, vec_1d) },
      name="2d_matrix_vector_mul scale(\{n})",
    )
    pack(results, "2d_matrix_vector_mul scale(\{n})", ToJson::to_json(summary1))
    let summary2 = single_bench(
      fn() { sink_array_double = naive_matrix_vector_mul(n, n, mat_2d, vec_1d) },
      name="naive_matrix_vector_mul scale(\{n})",
    )
    pack(
      results,
      "naive_matrix_vector_mul scale(\{n})",
      ToJson::to_json(summary2),
    )
    let summary3 = single_bench(
      fn() {
        sink_array_double = native_matrix_vector_mul(n, n, mat_1d, vec_1d)
      },
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

  // --- 4. Advanced Computing ---
  let steps_adv = [32, 64, 128]
  for n in steps_adv {
    let rng = PRNG::new(42L)
    let mat_2d = Array::makei(n, fn(i) {
      Array::makei(n, fn(j) {
        if i == j {
          rng.next() + 100.0
        } else {
          rng.next()
        }
      })
    })
    let size = n * n
    let mat_1d = Array::makei(size, fn(idx) { mat_2d[idx / n][idx % n] })
    let mat_lib = Matrix::from_array(n, n, mat_1d.copy())

    // -- Determinant --
    let summary_det_lib = single_bench(
      fn() { mat_lib.determinant() |> ignore },
      name="lib_matrix_determinant scale(\{n})",
    )
    pack(
      results,
      "lib_matrix_determinant scale(\{n})",
      ToJson::to_json(summary_det_lib),
    )
    let summary_det_native = single_bench(
      fn() { native_determinant(n, mat_1d) |> ignore },
      name="native_matrix_determinant scale(\{n})",
    )
    pack(
      results,
      "native_matrix_determinant scale(\{n})",
      ToJson::to_json(summary_det_native),
    )
    let summary_det_naive = single_bench(
      fn() { naive_determinant(n, mat_2d) |> ignore },
      name="naive_matrix_determinant scale(\{n})",
    )
    pack(
      results,
      "naive_matrix_determinant scale(\{n})",
      ToJson::to_json(summary_det_naive),
    )
    let summary_det_2d = single_bench(
      fn() { _2d_determinant(n, mat_2d) |> ignore },
      name="2d_matrix_determinant scale(\{n})",
    )
    pack(
      results,
      "2d_matrix_determinant scale(\{n})",
      ToJson::to_json(summary_det_2d),
    )

    // -- Inverse --
    let summary_inv_lib = single_bench(
      fn() { mat_lib.inverse() |> ignore },
      name="lib_matrix_inverse scale(\{n})",
    )
    pack(
      results,
      "lib_matrix_inverse scale(\{n})",
      ToJson::to_json(summary_inv_lib),
    )
    let summary_inv_native = single_bench(
      fn() { native_inverse(n, mat_1d) |> ignore },
      name="native_matrix_inverse scale(\{n})",
    )
    pack(
      results,
      "native_matrix_inverse scale(\{n})",
      ToJson::to_json(summary_inv_native),
    )
    let summary_inv_naive = single_bench(
      fn() { naive_inverse(n, mat_2d) |> ignore },
      name="naive_matrix_inverse scale(\{n})",
    )
    pack(
      results,
      "naive_matrix_inverse scale(\{n})",
      ToJson::to_json(summary_inv_naive),
    )
    let summary_inv_2d = single_bench(
      fn() { _2d_inverse(n, mat_2d) |> ignore },
      name="2d_matrix_inverse scale(\{n})",
    )
    pack(
      results,
      "2d_matrix_inverse scale(\{n})",
      ToJson::to_json(summary_inv_2d),
    )

    // -- Rank --
    let summary_rank_lib = single_bench(
      fn() { mat_lib.rank() |> ignore },
      name="lib_matrix_rank scale(\{n})",
    )
    pack(
      results,
      "lib_matrix_rank scale(\{n})",
      ToJson::to_json(summary_rank_lib),
    )
    let summary_rank_native = single_bench(
      fn() { native_rank(n, n, mat_1d) |> ignore },
      name="native_matrix_rank scale(\{n})",
    )
    pack(
      results,
      "native_matrix_rank scale(\{n})",
      ToJson::to_json(summary_rank_native),
    )
    let summary_rank_naive = single_bench(
      fn() { naive_rank(n, n, mat_2d) |> ignore },
      name="naive_matrix_rank scale(\{n})",
    )
    pack(
      results,
      "naive_matrix_rank scale(\{n})",
      ToJson::to_json(summary_rank_naive),
    )
    let summary_rank_2d = single_bench(
      fn() { _2d_rank(n, n, mat_2d) |> ignore },
      name="2d_matrix_rank scale(\{n})",
    )
    pack(
      results,
      "2d_matrix_rank scale(\{n})",
      ToJson::to_json(summary_rank_2d),
    )
  }
  println(results.stringify())
  ignore(sink_double)
  ignore(sink_array_double)
  ignore(sink_array_array_double)
}
