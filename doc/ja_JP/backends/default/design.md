# backends/default Design

## 責務

- `immut` と `mutable` を default 密 バックエンド として提示します。
- default 密 matrix/vector 型に capability trait を実装します。
- trait-based dispatch を確認する小さな generic 補助メソッド を提供します。

## 非責務

- scalar algebra や arithmetic law を再定義しません。
- 将来 バックエンド に 密 や contiguous storage を要求しません。
- scalar-valued map を core linear algebra trait surface に含めません。

## 拡張モデル

将来の sparse、lazy、static-size、GPU、外部ライブラリ バックエンド は同じ structural trait を直接実装するべきです。`DenseMatrix` や `DenseVector` への変換を必須にしません。
