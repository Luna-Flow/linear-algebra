///|
test "lib_mat_mapi" {
  let results = Json::object({})
  let steps = [64, 128, 256, 512]
  for n in steps {
    let rng = PRNG::new(42L)
    let mat = Matrix::make(n, n, fn(_i, _j) { rng.next() })
    let summary = single_bench(
      fn() { mat.mapi(fn(_i, _j, x) { x + 1.0 }) |> ignore },
      name="lib_mat_mapi scale(\{n})",
    )
    pack(results, "lib_mat_mapi scale(\{n})", ToJson::to_json(summary))
  }
  println(results.stringify())
}
