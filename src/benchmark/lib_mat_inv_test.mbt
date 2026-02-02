///|
test "lib_mat_inv" {
  let results = Json::object({})
  let steps = [32, 64, 128]
  for n in steps {
    let rng = PRNG::new(42L)
    let mat = Matrix::make(n, n, fn(i, j) {
      if i == j {
        rng.next() + 100.0
      } else {
        rng.next()
      }
    })
    let summary = single_bench(
      fn() { mat.inverse() |> ignore },
      name="lib_mat_inv scale(\{n})",
    )
    pack(results, "lib_mat_inv scale(\{n})", ToJson::to_json(summary))
  }
  println(results.stringify())
}
