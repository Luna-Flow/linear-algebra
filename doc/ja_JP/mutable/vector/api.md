# `@mutable.Vector`

このページは、現在の `0.4.2` リポジトリ状態における `@mutable.Vector` の API 基準をまとめたものです。

## 概要

- `@mutable.Vector` は、このリポジトリの更新指向ベクトル型です。
- ストレージは `Array[T]` のラッパーなので、インデックス書き込みは内部バッファを直接更新します。
- それでも多くの代数ヘルパーは新しいベクトルを返すため、更新と値変換を使い分けられます。

## 基本 API

- `Vector::from_array(arr)` / `Vector::make(n, elem)` / `Vector::makei(n, f)`
  既存データ、反復値、添字関数からベクトルを作ります。
- `length()`
  ベクトル長を返します。
- `v[i]` / `v[i] = x`
  1 要素を読み書きします。境界挙動は `Array[T]` に従います。
- `copy()`
  現在のベクトルを深く複製します。
- `iter()`
  現在の要素を順番にたどるイテレータを返します。

## 新しいベクトルを返すヘルパー

- `map(f)` / `zip_with(other, f)`
  `self` を変更せず、変換後のベクトルを返します。
- `add_constant(cst)`
  すべての要素へ同じスカラーを加えます。
- `left_scale(scalar)` / `right_scale(scalar)`
  スカラー倍した新しいベクトルを返します。
- `lerp(other, alpha)`
  `(1 - alpha) * self + alpha * other` を計算します。
- `+`、`*`、単項 `-`
  要素ごとの加算、アダマール積、符号反転です。

## インプレースヘルパー

- `map_inplace(f)`
  すべての要素を書き換えます。
- `left_scale_inplace(scalar)` / `right_scale_inplace(scalar)`
  スカラー倍をインプレースで適用します。

## スカラー・行列ヘルパー

- `dot(other)`
  内積を計算します。長さが一致しない場合は中止します。
- `lin_comb(weights, vectors)`
  重み配列と入力ベクトル群から 1 本のベクトルを組み立てるトップレベル補助関数です。空入力、個数不一致、長さ不一致は中止します。
- `to_col_matrix()` / `to_row_matrix()`
  ベクトルを行列形式へ変換します。
- `scaled_matrix()`
  このベクトルを主対角に持つ対角行列を作ります。
- `tensor_product(other)`
  外積を計算して行列を返します。

## 使い分け

- 更新主体のワークロードでは、直接のインデックス操作や `*_inplace` ヘルパーを使います。
- 以前の値を残したい場合や `@immut.Vector` に近い書き方をしたい場合は、新しいベクトルを返すヘルパーを使ってください。
- `backends/default.DenseVector` は、この concrete 実装を包むラッパーです。
  trait 指向の既定バックエンド入口を見たい場合は
  [backends/default API](../../backends/default/api.md) を参照してください。
