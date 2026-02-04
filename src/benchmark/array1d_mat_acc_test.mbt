///|
test "array1d_mat_acc" {
  let results = Json::object({})
  let steps = [64, 128, 256, 512]
  for n in steps {
    let rng = PRNG::new(42L)
    let data = Array::makei(n * n, fn(_idx) { rng.next() })
    let mut sum = 0.0
    let summary = single_bench(
      fn() { sum = sum + array1d_mat_acc(n, n, data) },
      name="array1d_mat_acc scale(\{n})",
    )
    ignore(sum)
    pack(results, "array1d_mat_acc scale(\{n})", ToJson::to_json(summary))
  }
  println(results.stringify())
}
