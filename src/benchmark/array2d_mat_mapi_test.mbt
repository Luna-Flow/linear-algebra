///|
test "array2d_mat_mapi" {
  let results = Json::object({})
  let steps = [64, 128, 256, 512]
  for n in steps {
    let rng = PRNG::new(42L)
    let data = Array::makei(n, fn(_i) { Array::makei(n, fn(_j) { rng.next() }) })
    let summary = single_bench(
      fn() { array2d_mat_mapi(n, n, data, fn(_i, _j, x) { x + 1.0 }) |> ignore },
      name="2d_mat_mapi scale(\{n})",
    )
    pack(results, "2d_mat_mapi scale(\{n})", ToJson::to_json(summary))
  }
  println(results.stringify())
}
