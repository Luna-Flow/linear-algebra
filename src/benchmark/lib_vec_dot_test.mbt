///|
test "lib_vec_dot" {
  let results = Json::object({})
  let steps = [1000, 100000]
  for n in steps {
    let rng = PRNG::new(42L)
    let v1 = Vector::makei(n, fn(_i) { rng.next() })
    let v2 = Vector::makei(n, fn(_i) { rng.next() })
    let summary = single_bench(
      fn() { v1.dot(v2) |> ignore },
      name="lib_vec_dot scale(\{n})",
    )
    pack(results, "lib_vec_dot scale(\{n})", ToJson::to_json(summary))
  }
  println(results.stringify())
}
