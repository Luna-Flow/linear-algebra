# `linear-algebra/error`

このページは現在の `0.4.1` リポジトリにおける
`Luna-Flow/linear-algebra/error` の公開 API を説明します。

## 役割

`error` は検査付き線形代数 API で使う構造化エラー型を提供します。呼び出し側は中止メッセージを解析せずに、形状エラー、入力領域のエラー、特異行列、未対応バックエンド、下位の算術エラーを区別できます。

## `LinearAlgebraErrorKind`

```moonbit
pub enum LinearAlgebraErrorKind {
  DimensionMismatch
  IndexOutOfBounds
  NegativeDimension
  InvalidLength
  RaggedRows
  NonSquareMatrix
  NegativeExponent
  EmptyMatrix
  SingularMatrix
  NonConvergence
  UnsupportedBackend
  ArithmeticFailure(@arithmetic.ArithmeticError)
} derive(Eq)
```

失敗の種類を表す列挙型です。`ArithmeticFailure` は上流の
`Luna-Flow/arithmetic.ArithmeticError` を保持します。

## `LinearAlgebraError`

```moonbit
pub struct LinearAlgebraError {
  kind : LinearAlgebraErrorKind
  message : String
} derive(Eq)
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
- `is_arithmetic_failure()`

これらのメソッドは、エラー値を分解せずに検査付き API の代表的な失敗を処理するためのものです。

## 使用例

```moonbit
match matrix.inverse() {
  Ok(inv) => inv
  Err(err) => {
    if err.is_singular_matrix() {
      abort("matrix is singular")
    }
    abort("matrix inverse failed")
  }
}
```

## 境界

このパッケージはエラー値だけを定義します。行列アルゴリズム、数値的な回復戦略、ログ出力、表示形式の方針は扱いません。
