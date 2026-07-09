# backends/default チュートリアル

## 小さなケース: 既定の密バックエンドを使いつつ、アルゴリズムは固定しない

```moonbit check
///|
fn[M : @algebra.MatrixShape] matrix_shape(matrix : M) -> (Int, Int) {
  @default.shape_of(matrix)
}

///|
test "shape_of dispatches through MatrixShape" {
  let matrix : @default.DenseMatrix[Int] = @default.DenseMatrix::from_2d_array([
    [1, 2],
    [3, 4],
  ])
  let (rows, cols) = matrix_shape(matrix)
  inspect(rows, content="2")
  inspect(cols, content="2")
}
```

この例は、既定バックエンド層をどう使うべきかを表しています。

1. `DenseMatrix` で、すぐ使える具体的な密行列を作る。
2. それを `MatrixShape` だけを要求する補助関数へ渡す。
3. `@default.shape_of` で、具体ラッパー型と公開 trait ベースの見方をつなぐ。

こうしておくと、利用者には使いやすい既定バックエンドを渡しつつ、
新しいアルゴリズムは他バックエンドへ持ち運びやすくなります。

## 推奨フロー

1. まずリポジトリ既定の参照実装を使いたいなら、`DenseMatrix`、`DenseVector`、`ImmutableDenseMatrix`、`ImmutableDenseVector` から始めます。
2. 再利用したいアルゴリズムは `MatrixShape` のような `algebra` trait に依存させます。
3. 具体ストレージや具体バックエンドの選択は、できるだけ外側の境界に残します。

## 実践ガイド

- そのまま使える公開の密実装が必要なときは、default backend のラッパー型を使います。
- スカラー値を返す積、ノルム、求解戦略、分解戦略のようなバックエンド特化の挙動は、同種の構造演算として表せない限り、バックエンド層または専用アルゴリズム層に置きます。
- `backends/default` は橋渡しの層であって、汎用線形代数コードの唯一の置き場ではありません。
