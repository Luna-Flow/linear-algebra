///|
test "array1d_mat_rank" {
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
      fn() { array1d_rank(n, n, data) |> ignore },
      name="array1d_mat_rank scale(\{n})",
    )
    pack(results, "array1d_mat_rank scale(\{n})", ToJson::to_json(summary))
  }
  println(results.stringify())
}
