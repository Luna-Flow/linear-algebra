# `@immut.Vector`

このページは、現在の `0.4.7` リポジトリ状態における `@immut.Vector` の API 基準をまとめたものです。

## 概要

- `@immut.Vector` は、このリポジトリの値指向ベクトル型です。
- 公開型はパッケージ別名 `VecLib[T]` としても利用できます。
- ストレージは、core の不変ベクトル別名 `VecCore[T]` を土台にしています。
- `set`、`map`、`left_scale`、`right_scale` などの操作は常に新しいベクトルを返します。
- このパッケージはインプレース更新や公開 `dot()` ヘルパーを持ちません。

## 基本 API

- `Vector::from_array(arr)`
  可変 `Array[T]` からベクトルを構築します。
- `Vector::make(n, elem)` / `Vector::makei(n, f)`
  定数ベクトルまたは添字から生成するベクトルを作ります。
- `length()`
  ベクトル長を返します。
- `v[i]`
  1 要素を読み取ります。境界挙動は基底の不変ベクトル契約に従います。
- `set(i, x)`
  指定位置だけを差し替えた新しいベクトルを返します。
- `iter()`
  要素を順番にたどるイテレータを返します。

## 値を返す変換

- `map(f)` / `zip_with(other, f)`
  元の値を変えずに、変換後の新しいベクトルを返します。
- `add_constant(cst)`
  全要素に同じスカラーを加えます。
- `left_scale(scalar)` / `right_scale(scalar)`
  スカラー倍した新しいベクトルを返します。
- `lerp(other, alpha)`
  `(1 - alpha) * self + alpha * other` を計算します。
- `+`、`*`、単項 `-`
  要素ごとの加算、アダマール積、符号反転です。
- `lin_comb(scalar_a, self, scalar_b, other)`
  2 本のベクトルの線形結合を作るトップレベル補助関数です。

共有される要素ごとの演算で長さが一致しない場合は、基底ベクトルの契約に従って中止します。

## 行列変換

- `to_col_matrix()` / `to_row_matrix()`
  ベクトルを `n x 1` または `1 x n` の行列へ物化します。
- `scaled_matrix()`
  このベクトルを主対角に持つ対角行列を作ります。
- `tensor_product(other)`
  外積を計算して行列を返します。

## 使い分け

- 明示的な値セマンティクスが重要なら `@immut.Vector` を使います。
- インプレース更新や公開 `dot()` ヘルパーが必要なら `@mutable.Vector` を使ってください。
- `backends/default.ImmutableDenseVector` は、この concrete 実装を包む
  ラッパーです。trait 指向の既定バックエンド入口を見たい場合は
  [backends/default API](../../backends/default/api.md) を参照してください。
