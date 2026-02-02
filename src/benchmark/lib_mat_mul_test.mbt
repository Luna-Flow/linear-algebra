///|
test "lib_mat_mul" {
  let results = Json::object({})
  let steps = [8, 16, 32, 64, 96, 128]
  for n in steps {
    let rng = PRNG::new(42L)
    let a = Matrix::make(n, n, fn(_i, _j) { rng.next() })
    let b = Matrix::make(n, n, fn(_i, _j) { rng.next() })
    let summary = single_bench(
      fn() { (a * b) |> ignore },
      name="lib_mat_mul scale(\{n})",
    )
    pack(results, "lib_mat_mul scale(\{n})", ToJson::to_json(summary))
  }
  println(results.stringify())
}
