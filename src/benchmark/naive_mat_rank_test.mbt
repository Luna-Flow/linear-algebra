///|
test "naive_mat_rank" {
  let results = Json::object({})
  let steps = [32, 64, 128]
  for n in steps {
    let rng = PRNG::new(42L)
    let mat = Array::makei(n, fn(i) {
      Array::makei(n, fn(j) {
        if i == j {
          rng.next() + 100.0
        } else {
          rng.next()
        }
      })
    })
    let summary = single_bench(
      fn() { naive_rank(n, n, mat) |> ignore },
      name="naive_mat_rank scale(\{n})",
    )
    pack(results, "naive_mat_rank scale(\{n})", ToJson::to_json(summary))
  }
  println(results.stringify())
}
