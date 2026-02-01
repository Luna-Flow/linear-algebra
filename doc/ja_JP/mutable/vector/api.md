# @mutable.Vector

---

## @mutable.Vector[T]

```moonbit
pub struct Vector[T](Array[T])
```

### 設計とパフォーマンスに関する注意
- **バックエンド固有の最適化**: 行列操作と同様に、ベクトルユーティリティも各ターゲットバックエンド（Wasm/JS および Native）向けに最適化されており、**API の一貫性**を保ちながら最高速度を実現しています。
- **ランダムアクセス**: ランダムなアクセスや変更には、インデックス構文 `v[i]` および `v[i] = x` を直接使用してください。これにより、個々の要素との最も効率的なやり取りが可能になります。
- **一括操作**: 可能な場合は、手動のインデックスループの代わりに、`.map_inplace()` や `.dot()` などの最適化されたメソッドを使用して計算を行ってください。

- **説明**
  可変なベクトルを表します。`Array[T]` をラップしており、インデックスによる要素のアクセスと変更が可能です。

- **関数とメソッド**

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
      - `f`: `(Int) -> T` - インデックスを受け取り要素を返す関数。
    - **戻り値**
      `Vector[T]` - 生成されたベクトル。

  ---

  - **`fn[T] Vector::from_array(arr : Array[T]) -> Vector[T]`**
    - **説明**
        既存の配列をベクトルに変換します。

  ---

  - **`fn[T] length(self : Vector[T]) -> Int`**
    - **説明**
        ベクトルの長さを取得します。

  ---

  - **`fn[T] Vector::op_get(self : Vector[T], i : Int) -> T`**
    - **説明**
        指定したインデックスの要素を取得します。`v[i]` 構文をサポートします。

  ---

  - **`fn[T] Vector::op_set(self : Vector[T], i : Int, x : T) -> Unit`**
    - **説明**
        指定したインデックスに値を設定します。`v[i] = x` 構文をサポートします。

  ---

  - **`fn[T] copy(self : Vector[T]) -> Vector[T]`**
    - **説明**
        ベクトルの深層コピーを作成します。

  ---

  - **`fn[T, U] map(self : Vector[T], f : (T) -> U) -> Vector[U]`**
    - **説明**
        写像による変換を行い、新しいベクトルを返します。

  ---

  - **`fn[T] map_inplace(self : Vector[T], f : (T) -> T) -> Unit`**
    - **説明**
        変換関数をその場で適用し、元のベクトルを変更します。

  ---

  - **`fn[T : Mul] left_scale(self : Vector[T], scalar : T) -> Vector[T]`**
    - **説明**
        左からのスカラー倍（新しいベクトルを返す）: `scalar * x`。

  ---

  - **`fn[T : Mul] right_scale(self : Vector[T], scalar : T) -> Vector[T]`**
    - **説明**
        右からのスカラー倍（新しいベクトルを返す）: `x * scalar`。

  ---

  - **`fn[T : Mul] left_scale_inplace(self : Vector[T], scalar : T) -> Unit`**
    - **説明**
        左からのスカラー倍をその場で行います。

  ---

  - **`fn[T : Mul] right_scale_inplace(self : Vector[T], scalar : T) -> Unit`**
    - **説明**
        右からのスカラー倍をその場で行います。

  ---

  - **`fn[T : Add + Mul] dot(self : Vector[T], other : Vector[T]) -> T`**
    - **描述**
        2 つのベクトルの点積（内積）を計算します。

  ---

  - **`fn[T : Zero] scaled_matrix(self : Vector[T]) -> Matrix[T]`**
    - **説明**
        このベクトルを主対角成分とする対角行列を作成します。

  ---

  - **`fn[T : Mul] tensor_product(self : Vector[T], other : Vector[T]) -> Matrix[T]`**
    - **説明**
        2 つのベクトルのテンソル積（外積）を計算します。
