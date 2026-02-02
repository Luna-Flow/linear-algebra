///|
test "naive_mat_mul" {
  let results = Json::object({})
  let steps = [8, 16, 32, 64, 96, 128]
  for n in steps {
    let rng = PRNG::new(42L)
    let a = Array::makei(n, fn(_i) { Array::makei(n, fn(_j) { rng.next() }) })
    let b = Array::makei(n, fn(_i) { Array::makei(n, fn(_j) { rng.next() }) })
    let summary = single_bench(
      fn() { naive_mat_mul(n, a, b) |> ignore },
      name="naive_mat_mul scale(\{n})",
    )
    pack(results, "naive_mat_mul scale(\{n})", ToJson::to_json(summary))
  }
  println(results.stringify())
}
