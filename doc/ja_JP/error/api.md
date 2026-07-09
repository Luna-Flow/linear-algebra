# `linear-algebra/error`

このページは、現在の `0.4.4` リポジトリにおける
`Luna-Flow/linear-algebra/error` の公開 API 基準をまとめたものです。

## 役割

`error` は検査付き線形代数 API で使う構造化エラー型を提供します。呼び出し側は中止メッセージを解析せずに、形状エラー、入力領域のエラー、特異行列、未対応バックエンド、予約済みだが未実装のバックエンド、下位の算術エラーを区別できます。

## `LinearAlgebraErrorKind`

```moonbit check
///|
test "LinearAlgebraErrorKind distinguishes failure categories" {
  let kind = @la_error.LinearAlgebraError::singular_matrix("matrix is singular").kind
  let label = match kind {
    @la_error.LinearAlgebraErrorKind::SingularMatrix => "singular"
    _ => "other"
  }
  inspect(label, content="singular")
}
```

失敗の種類を表す列挙型です。`ArithmeticFailure` は上流の
`Luna-Flow/arithmetic.ArithmeticError` を保持します。

## `LinearAlgebraError`

```moonbit check
///|
test "LinearAlgebraError stores kind and message" {
  let err = @la_error.LinearAlgebraError::singular_matrix("matrix is singular")
  inspect(err.is_singular_matrix(), content="true")
  inspect(err.message, content="matrix is singular")
}
```

機械的に判定できる種類と、人が読むためのメッセージを保持します。

## コンストラクタ

- `LinearAlgebraError::dimension_mismatch(message)`
- `LinearAlgebraError::index_out_of_bounds(message)`
- `LinearAlgebraError::negative_dimension(message)`
- `LinearAlgebraError::invalid_length(message)`
- `LinearAlgebraError::ragged_rows(message)`
- `LinearAlgebraError::non_square_matrix(message)`
- `LinearAlgebraError::negative_exponent(message)`
- `LinearAlgebraError::empty_matrix(message)`
- `LinearAlgebraError::singular_matrix(message)`
- `LinearAlgebraError::non_convergence(message)`
- `LinearAlgebraError::unsupported_backend(message)`
- `LinearAlgebraError::backend_not_impl(message)`
- `LinearAlgebraError::arithmetic_failure(error)`

## 判定メソッド

- `is_dimension_mismatch()`
- `is_index_out_of_bounds()`
- `is_negative_dimension()`
- `is_invalid_length()`
- `is_ragged_rows()`
- `is_non_square_matrix()`
- `is_negative_exponent()`
- `is_empty_matrix()`
- `is_singular_matrix()`
- `is_non_convergence()`
- `is_unsupported_backend()`
- `is_backend_not_impl()`
- `is_arithmetic_failure()`

これらのメソッドは、エラー値を分解せずに検査付き API の代表的な失敗を処理するためのものです。

`unsupported_backend` と `backend_not_impl` は同じではありません。
前者はサポート契約の外にあるバックエンドを表し、後者は
`BlasBackend` のように API 上は予約済みでも、現在のリポジトリ状態ではまだ実装に接続されていないことを表します。

## 使用例

```moonbit check
///|
test "checked callers can branch on structured linear-algebra errors" {
  let matrix = @mutable.Matrix::from_2d_array([[1.0, 2.0], [2.0, 4.0]])
  let status = match matrix.inverse() {
    Ok(_) => "ok"
    Err(err) => if err.is_singular_matrix() { "singular" } else { "other" }
  }
  inspect(status, content="singular")
}
```

## 境界

このパッケージはエラー値だけを定義します。行列アルゴリズム、数値的な回復戦略、ログ出力、表示形式の方針は扱いません。
