# @immut.Matrix

---

## @immut.Matrix[T]

```moonbit
struct Matrix[T] {
  row : Int
  col : Int
  data : IArray[T]
} derive(Eq)
```

- **説明**
  不変な行列を表します。データは行優先順序で不変な配列 `IArray[T]` に格納されます。

- **フィールド**
  - `row` - 行列の行数。
  - `col` - 行列の列数。
  - `data` - 行列の要素を格納する不変な配列。

- **関数とメソッド**

  ---

  - **`fn[T] Matrix::make(row : Int, col : Int, f : (Int, Int) -> T) -> Matrix[T]`**
    - **説明**
        新しい行列を作成し、与えられた関数 `f(row_index, col_index)` を使用してデータを初期化します。
    - **パラメータ**
      - `row`: `Int` - 行数。
      - `col`: `Int` - 列数。
      - `f`: `(Int, Int) -> T` - 初期化関数。
    - **戻り値**
      `Matrix[T]` - 新しく作成された行列。

  ---

  - **`fn[T] Matrix::new(row : Int, col : Int, elem : T) -> Matrix[T]`**
    - **説明**
        新しい行列を作成し、すべての要素を指定した値 `elem` で初期化します。
    - **パラメータ**
      - `row`: `Int` - 行数。
      - `col`: `Int` - 列数。
      - `elem`: `T` - 初期値。
    - **戻り値**
      `Matrix[T]` - 新しく作成された行列。

  ---

  - **`fn[T] Matrix::from_2d_array(arr : Array[Array[T]]) -> Matrix[T]`**
    - **説明**
        2 次元配列から不変な行列を作成します。
    - **パラメータ**
      - `arr`: `Array[Array[T]]` - 入力となる 2 次元配列。
    - **戻り値**
      `Matrix[T]` - 生成された行列。

  ---

  - **`fn[T] row(self : Matrix[T]) -> Int`**
    - **説明**
        行列の行数を取得します。

  ---

  - **`fn[T] col(self : Matrix[T]) -> Int`**
    - **説明**
        行列の列数を取得します。

  ---

  - **`fn[T] Matrix::op_get(self : Matrix[T], row : Int) -> Indexed[T]`**
    - **説明**
        行列の指定した行のアクセサを取得します。`m[row][col]` 構文をサポートします。

  ---

  - **`fn[T] set(self : Matrix[T], i : Int, j : Int, elem : T) -> Matrix[T]`**
    - **説明**
        (i, j) 位置の要素を `elem` に置き換えた新しい行列を作成します。元の行列は変更されません。

  ---

  - **`fn[T, U] map(self : Matrix[T], f : (T) -> U) -> Matrix[U]`**
    - **説明**
        行列の各要素に関数 `f` を適用します。

  ---

  - **`fn[T, U] mapi(self : Matrix[T], f : (Int, Int, T) -> U) -> Matrix[U]`**
    - **説明**
        行列の各要素に行・列インデックス付きの関数 `f` を適用します。

  ---

  - **`fn[T : Add] add(self : Matrix[T], other : Matrix[T]) -> Matrix[T]`**
    - **説明**
        行列の加算。`+` 演算子をサポートします。

  ---

  - **`fn[T : Mul + Add] mul(self : Matrix[T], other : Matrix[T]) -> Matrix[T]`**
    - **説明**
        行列の乗算。`*` 演算子をサポートします。

  ---

  - **`fn[T : Neg] neg(self : Matrix[T]) -> Matrix[T]`**
    - **説明**
        行列の各要素の符号を反転します。`-m` 構文をサポートします。

  ---

  - **`fn[T : Mul] scale(self : Matrix[T], cst : T) -> Matrix[T]`**
    - **説明**
        行列の各要素をスカラー倍します。

  ---

  - **`fn[T : One + Zero] Matrix::identity(size : Int) -> Matrix[T]`**
    - **説明**
        指定されたサイズの単位行列を作成します。

  ---

  - **`fn[T : Conjugate] adjoint(self : Matrix[T]) -> Matrix[T]`**
    - **説明**
        行列の随伴（複素共役転置）を計算します。

  ---

  - **`fn[T] transpose(self : Matrix[T]) -> Matrix[T]`**
    - **説明**
        行列の転置を計算します。

  ---

  - **`fn[T : Add + Zero] trace(self : Matrix[T]) -> T`**
    - **説明**
        正方行列のトレースを計算します。

  ---

  - **`fn[T : Mul + Add + One + Neg + Zero] determinant(self : Matrix[T]) -> T`**
    - **説明**
        正方行列の行列式を計算します（余因子展開を使用）。

  ---

  - **`fn[T : Semiring] pow(self : Matrix[T], power : Int) -> Matrix[T]`**
    - **説明**
        行列の整数乗を計算します。

  ---

  - **`fn[T] horizontal_combine(self : Matrix[T], other : Matrix[T]) -> Matrix[T]`**
    - **説明**
        行数が等しい 2 つの行列を水平方向に結合します。

  ---

  - **`fn[T] vertical_combine(self : Matrix[T], other : Matrix[T]) -> Matrix[T]`**
    - **説明**
        列数が等しい 2 つの行列を垂直方向に結合します。

  ---

  - **`fn[T] swap_rows(self : Matrix[T], r1 : Int, r2 : Int) -> Matrix[T]`**
    - **説明**
        行列の 2 つの行を入れ替え、新しい行列を返します。

  ---

  - **`fn[T] swap_cols(self : Matrix[T], c1 : Int, c2 : Int) -> Matrix[T]`**
    - **説明**
        行列の 2 つの列を入れ替え、新しい行列を返します。

---

## @immut.MatrixFn[T]

```moonbit
struct MatrixFn[T] {
  data : (Int, Int) -> T
  grid : (Int, Int)
}
```

- **説明**
  遅延評価を使用する行列の実装です。要素は関数によって動的に生成されるため、メモリ消費を抑えることができます。

- **フィールド**
  - `data` - (row, col) 位置の要素を計算する関数。
  - `grid` - 行列の次元（行数、列数）。

- **関数とメソッド**

  ---

  - **`fn[T] MatrixFn::make(row : Int, col : Int, f : (Int, Int) -> T) -> MatrixFn[T]`**
    - **説明**
        生成関数 `f` に基づいて関数行列を作成します。

  ---

  - **`fn[T : Default] MatrixFn::new(row : Int, col : Int) -> MatrixFn[T]`**
    - **説明**
        すべての要素がデフォルト値である関数行列を作成します。

  ---

  - **`fn[T] op_get(self : MatrixFn[T], i : Int) -> Indexed[T]`**
    - **説明**
        指定した行のアクセサを取得します。

  ---

  - **`fn[T, U] map(self : MatrixFn[T], f : (T) -> U) -> MatrixFn[U]`**
    - **説明**
        写像関数 `f` を通じて行列を変換します。

  ---

  - **`fn[T] map_row(self : MatrixFn[T], row : Int, f : (T) -> T) -> MatrixFn[T]`**
    - **説明**
        特定の行に対してのみ変換を適用します。

  ---

  - **`fn[T] map_col(self : MatrixFn[T], col : Int, f : (T) -> T) -> MatrixFn[T]`**
    - **説明**
        特定の列に対してのみ変換を適用します。

  ---

  - **`fn[T] transpose(self : MatrixFn[T]) -> MatrixFn[T]`**
    - **説明**
        行列の転置ビュー（データの移動なし）を返します。
