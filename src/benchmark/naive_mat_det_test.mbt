///|
test "naive_mat_det" {
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
      fn() { naive_det(n, mat) |> ignore },
      name="naive_mat_det scale(\{n})",
    )
    pack(results, "naive_mat_det scale(\{n})", ToJson::to_json(summary))
  }
  println(results.stringify())
}
