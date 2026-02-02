///|
test "array1d_vec_dot" {
  let results = Json::object({})
  let steps = [1000, 100000]
  for n in steps {
    let rng = PRNG::new(42L)
    let a = Array::makei(n, fn(_i) { rng.next() })
    let b = Array::makei(n, fn(_i) { rng.next() })
    let summary = single_bench(
      fn() { array1d_vec_dot(a, b) |> ignore },
      name="array1d_vec_dot scale(\{n})",
    )
    pack(results, "array1d_vec_dot scale(\{n})", ToJson::to_json(summary))
  }
  println(results.stringify())
}
