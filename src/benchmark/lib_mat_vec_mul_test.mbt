///|
test "lib_mat_vec_mul" {
  let results = Json::object({})
  let steps = [128, 512, 1024]
  for n in steps {
    let rng = PRNG::new(42L)
    let mat = Matrix::make(n, n, fn(_i, _j) { rng.next() })
    let vec = Vector::makei(n, fn(_i) { rng.next() })
    let summary = single_bench(
      fn() { mat.mul_vec(vec) |> ignore },
      name="lib_mat_vec_mul scale(\{n})",
    )
    pack(results, "lib_mat_vec_mul scale(\{n})", ToJson::to_json(summary))
  }
  println(results.stringify())
}
