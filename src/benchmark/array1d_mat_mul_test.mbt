///|
test "array1d_mat_mul" {
  let results = Json::object({})
  let steps = [8, 16, 32, 64, 96, 128]
  for n in steps {
    let rng = PRNG::new(42L)
    let size = n * n
    let a = Array::makei(size, fn(_idx) { rng.next() })
    let b = Array::makei(size, fn(_idx) { rng.next() })
    let summary = single_bench(
      fn() { array1d_mat_mul(n, a, b) |> ignore },
      name="array1d_mat_mul scale(\{n})",
    )
    pack(results, "array1d_mat_mul scale(\{n})", ToJson::to_json(summary))
  }
  println(results.stringify())
}
