///|
test "array1d_mat_mul" {
  let results = Json::object({})
  let steps = [8, 16, 32, 64, 96, 128]
  for n in steps {
    let rng = PRNG::new(42L)
    let size = n * n
    let a = Array::makei(size, fn(_idx) { rng.next() })
    let b = Array::makei(size, fn(_idx) { rng.next() })
    let mut acc = 0.0
    let summary = single_bench(
      fn() {
        let res = array1d_mat_mul(n, a, b)
        if res.length() > 0 {
          acc = acc + res[0]
        }
      },
      name="array1d_mat_mul scale(\{n})",
    )
    ignore(acc)
    pack(results, "array1d_mat_mul scale(\{n})", ToJson::to_json(summary))
  }
  println(results.stringify())
}
