# `@mutable.Matrix`

このページは、現在の `0.3.0` リポジトリ実装の実際の振る舞いを説明します。平方根を必要とする API は `Luna-Flow/arithmetic.Sqrt` を使用し、`Tolerance` は引き続き `mutable` が定義します。

## 概要

- `@mutable.Matrix` は更新指向です。
- `set`、`swap_rows`、`swap_cols`、`map_inplace`、行/列 view の更新、転置 view の更新は、基底行列をその場で変更します。
- 公開ストレージは全バックエンドで行優先のフラット `Array[T]` です。バックエンドごとの違いは主に実行最適化であり、公開データモデルではありません。
- 公開アクセスは厳密な境界チェックを行います。`get`、`set`、`m[row][col]`、`row_view`、`col_view`、抽出 helper、iterator、転置 view アクセスは、`0xN` や `Nx0` を含めて範囲外を一貫して拒否します。
- `swap_rows(i, i)` と `swap_cols(i, i)` は no-op です。範囲外 index は、偶然の配列アクセスに依存せず明示的に panic します。

## 基本 API

- `Matrix::make(row, col, f)`
  生成関数から行列を構築します。負の次元は panic します。
- `Matrix::new(row, col, elem)`
  `elem` で埋めた行列を構築します。負の次元は panic します。
- `Matrix::from_2d_array(arr)`
  長方形の 2 次元配列から行列を作ります。ragged input は panic します。
- `Matrix::from_array(row, col, data)`
  行優先の平坦配列をその shape で使います。負の次元や要素数不一致は panic します。
- `row()` / `col()`
  保存された shape を返します。
- `get(row, col)` / `set(row, col, elem)`
  明示的な境界チェック付きの高速ランダムアクセスです。
- `m[row][col]`
  `Lens[T]` を使う便宜構文です。読み書き可能ですが、繰り返し bulk work では `row_view`、`col_view`、専用 helper を優先してください。
- `copy()`
  行列を deep copy します。
- `map`, `mapi`
  変換済みの新しい行列を返します。
- `map_inplace`, `map_row_inplace`, `map_col_inplace`
  原地変換を行います。
- `each`, `eachi`, `each_row_col`, `each_row`, `each_col`, `eachi_row`, `eachi_col`
  走査 helper 群です。
- `iter`, `iter_row`, `iter_col`
  境界チェック付き iterator 群です。
- `row_to_array`, `col_to_array`, `row_to_vector`, `col_to_vector`, `to_array`, `to_2d_array`, `to_vector`
  物質化 helper 群です。必要な index は検証されます。
- `transpose()`
  実体化された転置行列を返します。
- `to_transpose()`
  ライブな転置 view を返します。
- `horizontal_combine`, `vertical_combine`
  整合する shape の行列を連結します。

## View と転置

- `row_view(row)` / `col_view(col)`
  基底行列に接続された live view を返します。
- `RowView` と `ColView`
  `get`、`set`、`iter`、`each`、`eachi`、`map_inplace`、`to_array`、`to_vector` を公開します。
- `Transpose`
  ライブな転置 view 上で、行列に近い API 面を提供します。
- `Transpose::swap_rows` / `Transpose::swap_cols`
  基底行列へ委譲し、同じ厳密な境界セマンティクスを持ちます。

## 代数・数値 API

- `+`, `-`, `*`
  行列加算、減算、乗算です。
- `scale(cst)`, `add_constant(cst)`, 単項 `-`
  要素ごとのスカラー変換です。
- `identity(size)`
  単位行列を作ります。負の `size` は panic します。
- `pow(power)`
  正方行列の非負整数冪です。
- `matrix_power(n)`
  `pow(n)` を公開名で包んだ wrapper です。
- `trace()`
  対角成分の総和です。正方行列が必要です。
- `determinant()`
  正方行列の determinant を返します。
- `inverse()`, `is_invertible()`
  逆行列関連 helper です。
- `rank()`
  現行実装のアルゴリズムで rank を返します。
- `reduce_row_elimination()`
  mutable な値の上で row reduction を行います。
- `cholesky_decomposition()`
  対応する数値入力向けの Cholesky 分解です。
- `eigen()`, `power_method()`, `eigen_2x2()`
  現在公開されている eigen 関連 API です。
- `is_square()`, `null()`, `is_symmetric()`, `is_positive_definite()`
  構造・数値 predicate です。
- `mean()`, `variance()`, `std_dev()`, `frobenius_norm()`, `max_element()`, `min_element()`
  集約系の数値 helper です。

## 正しさに関する補足

- 各バックエンドは同じ公開セマンティクスを提供する前提です。現在のリポジトリは `native`、`js`、`wasm`、`wasm-gc` ごとにカーネルファイルを分けていますが、特記がない限りドキュメントとテストは backend-invariant な公開挙動を表します。
- `immut` と `mutable` の間で共有するコードでは、共通の代数 API に依存し、更新セマンティクスまで同一だと仮定しないでください。
