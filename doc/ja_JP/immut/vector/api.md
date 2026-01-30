# @immut.Vector

---

## @immut.Vector[T]

```moonbit
struct Vector[T] {
  data : IArray[T]
} derive(Eq)
```

- **説明**
  不変なベクトルを表します。データは内部的に不変な配列 `IArray[T]` に格納されます。

- **フィールド**
  - `data` - ベクトルの要素を格納する不変な配列。

- **関数とメソッド**

  ---

  - **`fn[T] Vector::from_array(arr : Array[T]) -> Vector[T]`**
    - **説明**
        可変な配列から不変なベクトルを作成します。
    - **パラメータ**
      - `arr`: `Array[T]` - 入力となる可変な配列。
    - **戻り値**
      `Vector[T]` - 配列の要素を含む不変なベクトル。
    - **例**
      ```moonbit
      let v = Vector::from_array([1, 2, 3])
      ```

  ---

  - **`fn[T] Vector::make(n : Int, elem : T) -> Vector[T]`**
    - **説明**
        長さ `n` のベクトルを作成し、すべての要素を `elem` で初期化します。
    - **パラメータ**
      - `n`: `Int` - ベクトルの長さ。
      - `elem`: `T` - 初期値。
    - **戻り値**
      `Vector[T]` - 新しく作成されたベクトル。

  ---

  - **`fn[T] Vector::makei(n : Int, f : (Int) -> T) -> Vector[T]`**
    - **説明**
        長さ `n` のベクトルを作成し、各要素をインデックス関数 `f` で生成します。
    - **パラメータ**
      - `n`: `Int` - ベクトルの長さ。
      - `f`: `(Int) -> T` - インデックスを受け取り要素を返す関数（0 から `n-1`）。
    - **戻り値**
      `Vector[T]` - 生成されたベクトル。

  ---

  - **`fn[T] length(self : Vector[T]) -> Int`**
    - **説明**
        ベクトルの長さ（要素数）を取得します。
    - **パラメータ**
      - `self`: `Vector[T]` - 対象のベクトル。
    - **戻り値**
      `Int` - ベクトルの長さ。

  ---

  - **`fn[T] Vector::op_get(self : Vector[T], i : Int) -> T`**
    - **説明**
        指定したインデックスの要素を取得します。`v[i]` 構文をサポートします。
    - **パラメータ**
      - `self`: `Vector[T]` - 対象のベクトル。
      - `i`: `Int` - インデックス。
    - **戻り値**
      `T` - 指定位置の要素。

  ---

  - **`fn[T] set(self : Vector[T], i : Int, x : T) -> Vector[T]`**
    - **説明**
        インデックス `i` の要素を `x` に置き換えた新しいベクトルを作成します。元のベクトルは変更されません。
    - **パラメータ**
      - `self`: `Vector[T]` - 元のベクトル。
      - `i`: `Int` - 置き換える位置のインデックス。
      - `x`: `T` - 新しい要素。
    - **戻り値**
      `Vector[T]` - 更新された新しいベクトル。

  ---

  - **`fn[T, U] map(self : Vector[T], f : (T) -> U) -> Vector[U]`**
    - **説明**
        ベクトルの各要素に関数 `f` を適用し、その結果を含む新しいベクトルを返します。
    - **パラメータ**
      - `self`: `Vector[T]` - 入力ベクトル。
      - `f`: `(T) -> U` - 変換関数。
    - **戻り値**
      `Vector[U]` - 変換後の新しいベクトル。

  ---

  - **`fn[T : Add] add_constant(self : Vector[T], cst : T) -> Vector[T]`**
    - **説明**
        ベクトルの各要素に定数 `cst` を加算し、新しいベクトルを返します。
    - **パラメータ**
      - `self`: `Vector[T]` - 入力ベクトル。
      - `cst`: `T` - 加算する定数。
    - **戻り値**
      `Vector[T]` - 結果のベクトル。

  ---

  - **`fn[T, U, V] zip_with(self : Vector[T], other : Vector[U], f : (T, U) -> V) -> Vector[V]`**
    - **説明**
        同じ長さの 2 つのベクトルの要素ペアに対し、二項関数 `f` を適用します。
    - **パラメータ**
      - `self`: `Vector[T]` - 1 つ目のベクトル。
      - `other`: `Vector[U]` - 2 つ目のベクトル。
      - `f`: `(T, U) -> V` - 結合関数。
    - **戻り値**
      `Vector[V]` - 結合後の新しいベクトル。

  ---

  - **`fn[T : Add] add(self : Vector[T], other : Vector[T]) -> Vector[T]`**
    - **説明**
        ベクトル加算（要素ごとの加算）。`+` 演算子をサポートします。
    - **パラメータ**
      - `self`: `Vector[T]` - 1 つ目のベクトル。
      - `other`: `Vector[T]` - 2 つ目のベクトル。
    - **戻り値**
      `Vector[T]` - 加算結果のベクトル。

  ---

  - **`fn[T : Mul] mul(self : Vector[T], other : Vector[T]) -> Vector[T]`**
    - **説明**
        ベクトルの要素ごとの積（アダマール積）。`*` 演算子をサポートします。
    - **パラメータ**
      - `self`: `Vector[T]` - 1 つ目のベクトル。
      - `other`: `Vector[T]` - 2 つ目のベクトル。
    - **戻り値**
      `Vector[T]` - 積のベクトル。

  ---

  - **`fn[T : Neg] neg(self : Vector[T]) -> Vector[T]`**
    - **説明**
        ベクトルの符号を反転します。`-v` 構文をサポートします。
    - **パラメータ**
      - `self`: `Vector[T]` - 対象のベクトル。
    - **戻り値**
      `Vector[T]` - 各要素の符号を反転した新しいベクトル。

  ---

  - **`fn[T : Mul] left_scale(self : Vector[T], scalar : T) -> Vector[T]`**
    - **説明**
        ベクトルに左からスカラーを乗算します。
    - **パラメータ**
      - `self`: `Vector[T]` - 元のベクトル。
      - `scalar`: `T` - スカラー値。
    - **戻り値**
      `Vector[T]` - スケーリングされた新しいベクトル。

  ---

  - **`fn[T : Mul] right_scale(self : Vector[T], scalar : T) -> Vector[T]`**
    - **説明**
        ベクトルに右からスカラーを乗算します。
    - **パラメータ**
      - `self`: `Vector[T]` - 元のベクトル。
      - `scalar`: `T` - スカラー値。
    - **戻り値**
      `Vector[T]` - スケーリングされた新しいベクトル。

  ---

  - **`fn[T : One + Mul + Add + Neg] lerp(self : Vector[T], other : Vector[T], alpha : T) -> Vector[T]`**
    - **説明**
        2 つのベクトルの間で線形補間を行います。計算式は `(1 - alpha) * self + alpha * other` です。
    - **パラメータ**
      - `self`: `Vector[T]` - 開始ベクトル (alpha = 0)。
      - `other`: `Vector[T]` - 終了ベクトル (alpha = 1)。
      - `alpha`: `T` - 補間パラメータ。
    - **戻り値**
      `Vector[T]` - 補間結果。

  ---

  - **`fn[T : Add + Mul] lin_comb(scalar_a : T, self : Vector[T], scalar_b : T, other : Vector[T]) -> Vector[T]`**
    - **説明**
        2 つのベクトルの線形結合 `scalar_a * self + scalar_b * other` を計算します。
    - **パラメータ**
      - `scalar_a`: `T` - 1 つ目のベクトルの重み。
      - `self`: `Vector[T]` - 1 つ目のベクトル。
      - `scalar_b`: `T` - 2 つ目のベクトルの重み。
      - `other`: `Vector[T]` - 2 つ目のベクトル。
    - **戻り値**
      `Vector[T]` - 線形結合結果のベクトル。

  ---

  - **`fn[T] to_col_matrix(self : Vector[T]) -> Matrix[T]`**
    - **説明**
        ベクトルを列行列 (n × 1) に変換します。
    - **パラメータ**
      - `self`: `Vector[T]` - 元のベクトル。
    - **戻り値**
      `Matrix[T]` - n 行 1 列の行列。

  ---

  - **`fn[T] to_row_matrix(self : Vector[T]) -> Matrix[T]`**
    - **説明**
        ベクトルを形式的な行行列 (1 × n) に変換します。
    - **パラメータ**
      - `self`: `Vector[T]` - 元のベクトル。
    - **戻り値**
      `Matrix[T]` - 1 行 n 列の行列。

  ---

  - **`fn[T : Zero] scaled_matrix(self : Vector[T]) -> Matrix[T]`**
    - **説明**
        ベクトルの要素を主対角成分とする対角行列を作成します。
    - **パラメータ**
      - `self`: `Vector[T]` - 対角成分のソース。
    - **戻り値**
      `Matrix[T]` - 対角行列。

  ---

  - **`fn[T : Mul] tensor_product(self : Vector[T], other : Vector[T]) -> Matrix[T]`**
    - **説明**
        2 つのベクトルのテンソル積（外積）を計算し、行列を生成します。
    - **パラメータ**
      - `self`: `Vector[T]` - 左操作ベクトル（結果行列の行数を決定）。
      - `other`: `Vector[T]` - 右操作ベクトル（結果行列の列数を決定）。
    - **戻り値**
      `Matrix[T]` - 外積行列。
