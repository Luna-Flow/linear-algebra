///|
test "array2d_mat_set_acc" {
  let results = Json::object({})
  let steps = [64, 128, 256, 512]
  for n in steps {
    let rng = PRNG::new(42L)
    let data = Array::makei(n, fn(_i) { Array::makei(n, fn(_j) { rng.next() }) })
    let summary = single_bench(
      fn() { array2d_mat_set_acc(n, n, data, 1.0) },
      name="array2d_mat_set_acc scale(\{n})",
    )
    pack(results, "array2d_mat_set_acc scale(\{n})", ToJson::to_json(summary))
  }
  println(results.stringify())
}
