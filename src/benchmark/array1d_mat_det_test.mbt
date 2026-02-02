///|
test "array1d_mat_det" {
  let results = Json::object({})
  let steps = [32, 64, 128]
  for n in steps {
    let rng = PRNG::new(42L)
    let size = n * n
    let data = Array::makei(size, fn(idx) {
      let i = idx / n
      let j = idx % n
      if i == j {
        rng.next() + 100.0
      } else {
        rng.next()
      }
    })
    let summary = single_bench(
      fn() { array1d_det(n, data) |> ignore },
      name="array1d_mat_det scale(\{n})",
    )
    pack(results, "array1d_mat_det scale(\{n})", ToJson::to_json(summary))
  }
  println(results.stringify())
}
