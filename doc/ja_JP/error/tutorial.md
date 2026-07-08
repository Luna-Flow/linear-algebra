# error Tutorial

`Result[..., @error.LinearAlgebraError]` を返す checked 線形代数 API を呼ぶときは
`linear-algebra/error` を使います。

```moonbit
match matrix.inverse() {
  Ok(inv) => inv
  Err(err) => {
    if err.is_non_square_matrix() {
      abort("inverse requires a square matrix")
    }
    if err.is_singular_matrix() {
      abort("matrix is singular")
    }
    abort(err.message)
  }
}
```

呼び出し側が特定の失敗から回復できる場合は、`is_dimension_mismatch`、
`is_negative_exponent`、`is_empty_matrix` などの判定メソッドを使います。
`message` は診断、ログ、最後のフォールバックエラーに使い、制御フローの判断のために
解析しないでください。

`ArithmeticFailure` は、下位の算術パッケージから伝播したスカラー算術エラーの境界として扱います。
呼び出し側が意味のある数値的な回復判断をできる場合だけ、個別に処理してください。
