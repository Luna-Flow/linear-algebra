///|
test "array1d_mat_vec_mul" {
  let results = Json::object({})
  let steps = [128, 512, 1024]
  for n in steps {
    let rng = PRNG::new(42L)
    let size = n * n
    let mat = Array::makei(size, fn(_idx) { rng.next() })
    let vec = Array::makei(n, fn(_idx) { rng.next() })
    let summary = single_bench(
      fn() { array1d_mat_vec_mul(n, n, mat, vec) |> ignore },
      name="array1d_mat_vec_mul scale(\{n})",
    )
    pack(results, "array1d_mat_vec_mul scale(\{n})", ToJson::to_json(summary))
  }
  println(results.stringify())
}
