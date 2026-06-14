# `@immut.Matrix`

このページは、現在の `0.3.0` リポジトリ実装の振る舞いを説明します。

## 概要

- `@immut.Matrix` は値セマンティクスです。
- `set`、`swap_rows`、`swap_cols` などの操作は新しい行列を返します。
- 行列は行優先で保持され、基盤には immutable vector 実装を使います。
- 公開インデックスアクセスは厳密な境界チェックを行います。`m[row][col]` と `set(row, col, value)` は、`0xN` や `Nx0` を含めて範囲外なら panic します。
- `swap_rows(i, i)` と `swap_cols(i, i)` は no-op で、元の値をそのまま返します。

## 基本 API

- `Matrix::make(row, col, f)`
  生成関数から行列を作ります。負の次元は panic します。
- `Matrix::new(row, col, elem)`
  `elem` で埋めた行列を作ります。負の次元は panic します。
- `Matrix::from_2d_array(arr)`
  長方形の 2 次元配列から行列を作ります。ragged input は panic します。
- `Matrix::from_array(row, col, data)`
  行優先の平坦 immutable vector から行列を作ります。負の次元や要素数不一致は panic します。
- `row()` / `col()`
  保存されている shape を返します。
- `m[row][col]`
  読み取り専用の便宜アクセスです。行・列の両方を明示的に検証します。
- `set(row, col, elem)`
  指定要素だけ差し替えた新しい行列を返します。境界は明示的に検証されます。
- `map`, `mapi`
  元の行列を変更せずに変換します。
- `transpose()`
  実体化された転置行列を返します。
- `horizontal_combine`, `vertical_combine`
  shape が整合する行列を連結します。
- `iter`, `iter_row`, `iter_col`, `to_array`, `to_2d_array`
  行優先の反復・変換 API です。行・列 iterator は無効な index で panic します。

## 代数演算

- `+`, `-`, `*`
  加算、減算、行列積です。shape 不一致は panic します。
- `scale(cst)`, `add_constant(cst)`, 単項 `-`
  要素ごとのスカラー変換です。
- `identity(size)`
  単位行列を作ります。負の `size` は panic します。
- `trace()`
  対角成分の総和です。正方行列が必要です。
- `determinant()`
  正方行列の determinant を返します。現在の実装では小サイズ特殊化と、大きめ入力向けの elimination を使います。
- `pow(power)`
  正方行列を非負整数冪へ上げます。非正方や負指数は panic します。
- `null()`, `is_square()`
  零行列判定と shape 補助です。
- `adjoint()`
  `Conjugate` を持つ要素型に対する共役転置です。
- `swap_rows(r1, r2)`, `swap_cols(c1, c2)`
  指定した行・列を入れ替えた新しい行列を返します。範囲外は panic、同一 index は no-op です。

## `MatrixFn`

- `MatrixFn` は `Matrix` の遅延・関数型コンパニオンです。
- 非負次元のルールを共有します。
- `MatrixFn::from_2d_array([])` は `0x0` を返します。
- `MatrixFn::from_2d_array([[], ...])` は zero-column shape を保ちます。
- ragged input は早い段階で拒否されます。
- 行アクセス時に row を即時検証し、要素アクセス時には関数バックエンド経由で col も検証されます。

主なメソッド:

- `MatrixFn::make`, `new`, `from_2d_array`
- `map`, `fold`, `zip_with`
- `transpose`, `horizontal_combine`, `vertical_combine`
- `swap_rows`, `swap_cols`
- `identity`, `pow`, `determinant`, `adjoint`

## 正しさに関する補足

- 共有される代数的振る舞いについては、リポジトリ内の consistency tests で `@immut.Matrix` が意味論上の基準点として扱われます。
- mutable パッケージは view や in-place 更新など、実行寄りの追加 API を意図的に公開しており、それらを `immut` に逆投影しないでください。
