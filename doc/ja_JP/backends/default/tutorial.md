# backends/default チュートリアル

リポジトリの参照用密実装を使う場合は、既定バックエンドのラッパー型を使います。

```moonbit
let matrix : DenseMatrix[Int] = DenseMatrix::from_2d_array([
  [1, 2],
  [3, 4],
])
let shape = shape_of(matrix)
```

バックエンド非依存コードでは、具体型ではなく能力を表す補助関数に依存します。

```moonbit
fn[M : @algebra.MatrixShape](matrix : M) -> (Int, Int) {
  shape_of(matrix)
}
```

バックエンド固有のスカラー値を返す積、ノルム、求解、分解は、それが同じ型に閉じた構造演算として表せない限り、バックエンドまたは専用アルゴリズム層に置きます。
