# `@mutable.Matrix`

このページは、現在の `0.4.5` リポジトリ状態における `@mutable.Matrix` の API 基準をまとめたものです。平方根を必要とする API は `Luna-Flow/arithmetic.Sqrt` を使用し、`Tolerance` は引き続き `mutable` が定義します。

## 概要

- `@mutable.Matrix` は、このリポジトリの実行指向行列型です。
- `set`、`swap_rows`、`swap_cols`、`map_inplace`、行/列ビューの更新、転置ビューの更新は、基底行列をその場で変更します。
- 公開ストレージは全バックエンドで行優先のフラット `Array[T]` です。バックエンドごとの違いは主に実行最適化であり、公開データモデルではありません。
- 公開アクセスは厳密な境界チェックを行います。`get`、`set`、`m[row][col]`、`row_view`、`col_view`、抽出用メソッド、イテレータ、転置ビューのアクセスは、`0xN` や `Nx0` を含めて範囲外を一貫して拒否します。
- `swap_rows(i, i)` と `swap_cols(i, i)` は何もしない操作です。範囲外インデックスは、偶然の配列アクセスに依存せず明示的に停止します。

## 基本 API

- `Matrix::make(row, col, f)`
  生成関数から行列を構築します。負の次元では停止します。
- `Matrix::new(row, col, elem)`
  `elem` で埋めた行列を構築します。負の次元では停止します。
- `Matrix::from_2d_array(arr)`
  長方形の 2 次元配列から行列を作ります。行ごとの長さが揃わない入力では停止します。
- `Matrix::from_array(row, col, data)`
  行優先の平坦配列を指定された形状で使います。負の次元や要素数不一致では停止します。
- `row()` / `col()`
  保存された形状を返します。
- `get(row, col)` / `set(row, col, elem)`
  明示的な境界チェック付きの高速ランダムアクセスです。
- `m[row][col]`
  `Lens[T]` を使う便宜構文です。読み書き可能ですが、繰り返し処理では `row_view`、`col_view`、専用メソッドを優先してください。
- `copy()`
  行列を深くコピーします。
- `map`, `mapi`
  変換済みの新しい行列を返します。
- `map_inplace`, `map_row_inplace`, `map_col_inplace`
  その場で変換します。
- `each`, `eachi`, `each_row_col`, `each_row`, `each_col`, `eachi_row`, `eachi_col`
  走査用メソッド群です。
- `iter`, `iter_row`, `iter_col`
  境界チェック付きイテレータ群です。
- `row_to_array`, `col_to_array`, `row_to_vector`, `col_to_vector`, `to_array`, `to_2d_array`, `to_vector`
  配列やベクトルへ変換するメソッド群です。必要なインデックスは検証されます。
- `transpose()`
  実体化された転置行列を返します。
- `to_transpose()`
  元の行列に接続された転置ビューを返します。
- `horizontal_combine`, `vertical_combine`
  形状が整合する行列を連結します。

## ビューと転置

- `row_view(row)` / `col_view(col)`
  元の行列に接続されたビューを返します。
- `RowView` と `ColView`
  `get`、`set`、`iter`、`each`、`eachi`、`map_inplace`、`to_array`、`to_vector` を公開します。
- `Transpose`
  元の行列に接続された転置ビュー上で、行列に近い API を提供します。
- `Transpose::swap_rows` / `Transpose::swap_cols`
  基底行列へ委譲し、同じ厳密な境界セマンティクスを持ちます。

## 代数・数値 API

- `+`, `-`, `*`
  行列加算、減算、乗算です。
- `scale(cst)`, `add_constant(cst)`, 単項 `-`
  要素ごとのスカラー変換です。
- `identity(size)`
  単位行列を作ります。負の `size` では中止します。
- `pow(power)`
  正方行列の非負整数冪を検査付きで計算します。
- `matrix_power(n)`
  `pow(n)` の検査付き公開別名です。
- `trace()`
  対角成分の総和を検査付きで計算します。正方行列が必要で、`Result[..., LinearAlgebraError]` を返します。
- `determinant()`
  正方行列の行列式を検査付きで計算します。
- `inverse()`, `is_invertible()`
  逆行列関連の検査付きメソッドです。特異行列の逆行列は `Err` を返します。
- `mul_vec(vector)`
  行列ベクトル積を検査付きで計算します。形状が合わない場合は `Err` を返します。
- `mean()`, `variance()`, `std_dev()`, `max_element()`, `min_element()`
  集約値を検査付きで計算します。空行列では `Err` を返します。
- `unchecked_trace()`, `unchecked_determinant()`, `unchecked_inverse()`, `unchecked_is_invertible()`, `unchecked_pow()`, `unchecked_matrix_power()`, `unchecked_mul_vec()`, `unchecked_mean()`, `unchecked_variance()`, `unchecked_std_dev()`, `unchecked_max_element()`, `unchecked_min_element()`
  従来の abort または `Option` を返す挙動を残します。
- `rank()`
  現行実装のアルゴリズムで行列の階数を返します。
- `reduce_row_elimination()`
  可変行列の値に対して行基本変形を行います。
- `cholesky_decomposition()`
  対応する数値入力向けの Cholesky 分解です。
- `eigen()`, `power_method()`
  現在公開されている固有値関連 API です。実装内部の 2x2 特化ヘルパーは公開インターフェイスではありません。
- `is_square()`, `null()`, `is_symmetric()`, `is_positive_definite()`
  構造や数値性を判定する述語です。
- `frobenius_norm()`
  対応する要素型向けの、検査付きでない集約メソッドです。

## 使い分け

- 各バックエンドは同じ公開セマンティクスを提供する前提です。現在のリポジトリは `native`、`js`、`wasm`、`wasm-gc` ごとにカーネルファイルを分けていますが、特記がない限りドキュメントとテストはバックエンドに依存しない公開挙動を表します。
- `immut` と `mutable` の間で共有するコードでは、共通の代数 API に依存し、更新セマンティクスまで同一だと仮定しないでください。
- `backends/default.DenseMatrix` は、この concrete 実装を包むラッパーです。
  trait 指向の既定バックエンド入口を見たい場合は
  [backends/default API](../../backends/default/api.md) を参照してください。
