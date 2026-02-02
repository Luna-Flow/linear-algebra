///|
test "naive_vec_dot" {
  let results = Json::object({})
  let steps = [1000, 100000]
  for n in steps {
    let rng = PRNG::new(42L)
    let a = Array::makei(n, fn(_i) { rng.next() })
    let b = Array::makei(n, fn(_i) { rng.next() })
    let summary = single_bench(
      fn() { naive_vec_dot(a, b) |> ignore },
      name="naive_vec_dot scale(\{n})",
    )
    pack(results, "naive_vec_dot scale(\{n})", ToJson::to_json(summary))
  }
  println(results.stringify())
}
