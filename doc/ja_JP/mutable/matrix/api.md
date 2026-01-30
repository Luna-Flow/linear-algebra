# @mutable.Matrix

---

## @mutable.Matrix[T]

```moonbit
struct Matrix[T] {
  row : Int
  col : Int
  data : Array[T]
} derive(Eq)
```

- **説明**
  可変な行列を表します。データは 1 次元配列 `data` に格納されます。

- **フィールド**
  - `row` - 行列の行数
  - `col` - 行列の列数
  - `data` - 行列のデータ

- **メソッド**

  - **`fn[T] Matrix::make(row, col, f) -> Matrix[T]`**
    - **説明**
        新しい行列を作成し、与えられた関数を使用してデータを初期化します。
    - **パラメータ**
      - `row: Int` - 行数
      - `col: Int` - 列数
      - `f: (Int, Int) -> T` - データを初期化する関数（第 1 引数は行インデックス、第 2 引数は列インデックス）
    - **戻り値**
      `Matrix[T]` - 新しく作成された行列オブジェクト

  ---

  - **`fn[T] Matrix::new(row, col, elem) -> Matrix[T]`**
    - **説明**
        すべての要素を指定された値で初期化した新しい行列を作成します。
    - **パラメータ**
      - `row: Int` - 行数
      - `col: Int` - 列数
      - `elem: T` - 初期値
    - **戻り値**
      `Matrix[T]` - 新しく作成された行列オブジェクト

  ---

  - **`fn[T] Matrix::from_2d_array(arr) -> Matrix[T]`**
    - **説明**
        2 次元配列から行列を作成します。
    - **パラメータ**
      - `arr: Array[Array[T]]` - 2 次元配列
    - **戻り値**
      `Matrix[T]` - 新しく作成された行列オブジェクト

  ---

  - **`fn[T] row(self) -> Int`**
    - **説明**
        行列の行数を取得します。

  ---

  - **`fn[T] col(self) -> Int`**
    - **説明**
        行列の列数を取得します。

  ---

  - **`fn[T] Matrix::op_get(self, row) -> Lens[T]`**
    - **説明**
        指定された行のアクセサを取得します。行内の要素の読み取りと変更に使用されます。
    - **戻り値**
      `Lens[T]` - 行アクセサオブジェクト

  ---

  - **`fn[T, U] Matrix::map(self, f) -> Matrix[U]`**
    - **説明**
        各要素に関数を適用した新しい行列を作成します。

  ---

  - **`fn[T] Matrix::map_in_place(self, f) -> Unit`**
    - **説明**
        各要素に変換関数をその場で適用し、元の行列を変更します。

  ---

  - **`fn[T] Matrix::copy(self) -> Matrix[T]`**
    - **説明**
        行列の深層コピーを作成します。

  ---

  - **`fn[T] to_transpose(self) -> Transpose[T]`**
    - **説明**
        データをコピーせずに転置ビューに変換します。

  ---

  - **`fn[T] transpose(self) -> Matrix[T]`**
    - **説明**
        転置行列を新しく作成します。

  ---

  - **`fn[T] swap_rows(self, r1, r2) -> Unit`**
    - **説明**
        2 つの行を入れ替えます。

  ---

  - **`fn[T] swap_cols(self, c1, c2) -> Unit`**
    - **説明**
        2 つの列を入れ替えます。

  ---

  - **`fn[T : Mul] scale(self, cst) -> Matrix[T]`**
    - **説明**
        スカラー倍（新しい行列を返す）。

  ---

  - **`fn[T : One + Zero] identity(size) -> Matrix[T]`**
    - **説明**
        単位行列を作成します。

  ---

  - **`fn[T : Compare + Num + Sub + Inverse] reduce_row_elimination(self) -> Matrix[T]`**
    - **説明**
        ガウス消元法により行階段形に簡約します。

  ---

  - **`fn[T] horizontal_combine(self, other) -> Matrix[T]`**
    - **説明**
        水平方向に結合します。

  ---

  - **`fn[T] vertical_combine(self, other) -> Matrix[T]`**
    - **説明**
        垂直方向に結合します。

  ---

  - **`fn[T : SMul[T] + Tolerance[T] + Ord + Neg + Add + Mul + Div + Sqrt[T] + Default] determinant(self) -> T`**
    - **説明**
        行列式を計算します。

  ---

  - **`fn[T : Add + Default] trace(self) -> T`**
    - **説明**
        トレースを計算します。

  ---

  - **`fn[T : SMul[T] + Tolerance[T] + Ord + Neg + Add + Mul + Div + Sqrt[T] + Default] eigen(self) -> (Array[T], Matrix[T])`**
    - **説明**
        固有値と固有ベクトルを計算します。

---

## @mutable.Transpose[T]

```moonbit
pub struct Transpose[T](Matrix[T])
```

- **説明**
  行列の転置ビューです。データをコピーせずに、元の行列に転置された状態でアクセスします。

- **メソッド**

  - **`fn[T] row(self : Transpose[T]) -> Int`**
    - **戻り値**: 行数（元の行列の列数に等しい）。

  - **`fn[T] col(self : Transpose[T]) -> Int`**
    - **戻り値**: 列数（元の行列の行数に等しい）。

  - **`fn[T] transpose(self : Transpose[T]) -> Matrix[T]`**
    - **戻り値**: Transpose は Matrix のビューであるため、再度 transpose を呼び出すと元の `Matrix[T]` が返ります。

  - **`fn[T] materialize(self : Transpose[T]) -> Matrix[T]`**
    - **戻り値**: 物理的に転置されたレイアウトを持つ新しい `Matrix[T]` を作成します。

  - **`fn[T] map_in_place(self : Transpose[T], f : (T) -> T) -> Unit`**
    - **動作**: 元の行列のデータをその場で変更します。
