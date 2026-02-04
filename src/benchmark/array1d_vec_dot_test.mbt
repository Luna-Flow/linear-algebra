///|
test "array1d_vec_dot" {
  let results = Json::object({})
  let steps = [1000, 100000]
  for n in steps {
    let rng = PRNG::new(42L)
    let a = Array::makei(n, fn(_i) { rng.next() })
    let b = Array::makei(n, fn(_i) { rng.next() })
    let mut acc = 0.0
    let summary = single_bench(
      fn() { acc = acc + array1d_vec_dot(a, b) },
      name="array1d_vec_dot scale(\{n})",
    )
    ignore(acc)
    pack(results, "array1d_vec_dot scale(\{n})", ToJson::to_json(summary))
  }
  println(results.stringify())
}
