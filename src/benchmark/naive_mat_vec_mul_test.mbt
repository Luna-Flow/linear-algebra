///|
test "naive_mat_vec_mul" {
  let results = Json::object({})
  let steps = [128, 512, 1024]
  for n in steps {
    let rng = PRNG::new(42L)
    let mat = Array::makei(n, fn(_i) { Array::makei(n, fn(_j) { rng.next() }) })
    let vec = Array::makei(n, fn(_i) { rng.next() })
    let summary = single_bench(
      fn() { naive_mat_vec_mul(n, n, mat, vec) |> ignore },
      name="naive_mat_vec_mul scale(\{n})",
    )
    pack(results, "naive_mat_vec_mul scale(\{n})", ToJson::to_json(summary))
  }
  println(results.stringify())
}
