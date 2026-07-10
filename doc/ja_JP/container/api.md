# コンテナ能力 API

`container` パッケージは、ジェネリックコードが線形コンテナを観測、
構築、編集する方法を表します。数学的法則や密行列レイアウトは要求しません。

## 実験的ステータス

`container` は実験的機能です。read/build モデルは実際の相互運用実験に利用できますが、
操作レコードのフィールド、編集能力、エラー契約、汎用アルゴリズムのシグネチャは、
互換性なく変更される可能性があります。検査付きデータ交換と構造変換の層として使い、
互換性の安定した公開境界や高性能数値カーネル API としては扱わないでください。

## 能力レコード

- `VectorReadOps[V, T]`: 長さと検査付き `get`。
- `MatrixReadOps[M, T]`: 形状と検査付き `get`。
- `VectorBuildOps[V, T]`: 検査付き `tabulate` 構築。
- `MatrixBuildOps[M, T]`: 行列座標を受け取る検査付き `tabulate` 構築。
- `VectorPersistentEditOps` / `MatrixPersistentEditOps`: 新しい値を返す置換。
- `VectorMutableEditOps` / `MatrixMutableEditOps`: その場で変更する置換。

各レコードには `new` コンストラクタがあります。不正な座標は
`IndexOutOfBounds`、負の形状は `NegativeDimension` を返します。

## ジェネリックアルゴリズム

`vector_map`、`matrix_map`、`vector_convert`、`matrix_convert`、
`matrix_transpose` を公開します。変換元と変換先の型は異なって構いません。
`map` は要素型も変更できます。`0xN` と `Nx0` の形状は保持されます。

## リポジトリアダプタ

`container/adapters` は immutable/mutable のベクトルと行列、既定の 4 種類の
密ラッパー、行・列・転置ビューを接続します。ビューは構築能力を持ちません。
OpenBLAS は native 限定の read/build のみを公開し、永続編集は公開しません。
