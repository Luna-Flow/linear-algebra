///|
test "lib_mat_mul" {
  let results = Json::object({})
  let steps = [8, 16, 32, 64, 96, 128]
  for n in steps {
    let rng = PRNG::new(42L)
    let a = Matrix::make(n, n, fn(_i, _j) { rng.next() })
    let b = Matrix::make(n, n, fn(_i, _j) { rng.next() })
    let mut acc = 0.0
    let summary = single_bench(
      fn() {
        let c = a * b
        if c.row() > 0 && c.col() > 0 {
          acc = acc + c.get(0, 0)
        }
      },
      name="lib_mat_mul scale(\{n})",
    )
    ignore(acc)
    pack(results, "lib_mat_mul scale(\{n})", ToJson::to_json(summary))
  }
  println(results.stringify())
}
