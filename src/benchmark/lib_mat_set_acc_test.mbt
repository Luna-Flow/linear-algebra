///|
test "lib_mat_set_acc" {
  let results = Json::object({})
  let steps = [64, 128, 256, 512]
  for n in steps {
    let rng = PRNG::new(42L)
    let mat = Matrix::make(n, n, fn(_i, _j) { rng.next() })
    let summary = single_bench(
      fn() {
        let rows = mat.row()
        let cols = mat.col()
        for i = 0; i < rows; i = i + 1 {
          for j = 0; j < cols; j = j + 1 {
            mat.set(i, j, 1.0)
          }
        }
      },
      name="lib_mat_set_acc scale(\{n})",
    )
    pack(results, "lib_mat_set_acc scale(\{n})", ToJson::to_json(summary))
  }
  println(results.stringify())
}
