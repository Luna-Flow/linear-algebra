# @mutable.Matrix

このページは現在のリポジトリ実装を基準にしており、`0.2.11` の API 基準として記述されています。

---

## @mutable.Matrix[T]

```moonbit
struct Matrix[T] {
  row : Int
  col : Int
  data : Array[T]
} derive(Eq)
```

### 設計とパフォーマンスに関する注意

- **ネイティブ転置最適化**: Native バックエンドでの行列乗算は、転置ベースの戦略を採用し、大規模な行列に対して単純な手法と比較して **200%以上の高速化** を実現しました。
- **ゼロオーバーヘッド構築**: `Matrix::make` と `Matrix::new` は、初期化中のすべての除算および剰余演算を排除するように書き直されました。
- **ハイブリッド行列乗算**: 他のバックエンドでは、パフォーマンスを最大化するために、`i-j-k`（レジスタ最適化）と `i-k-j`（キャッシュフレンドリー）戦略を自動的に切り替えます。
- **セカンダリユーティリティの高速化**: `mapi` や `each_row_col` などの関数を監査し、除算/剰余のオーバーヘッドを排除しました（最大 60% 高速化）。
- **ゼロコピー転置**: 単位行列ベースの乗算と実体化を最適化しました。

- **バックエンド固有の最適化**: 内部実装は、ターゲットとなるバックエンド（Wasm/JS または Native）に合わせて最適化されており、各エンジンの特性を最大限に引き出します。
- **ランダムアクセス**: 頻繁なランダムアクセス（Random Access）が必要なハイパフォーマンスなシナリオでは、`.get(i, j)` および `.set(i, j, val)` メソッドを直接使用することを強く推奨します。これらは、個々の要素とのやり取りにおいて最速のパスとなるよう設計されています。
- **一括操作**: 最高の最適化効果を得るためには、インデックスを使用した手動ループの代わりに、`.each_row_col()` や `.map_inplace()` などの組み込みツールを優先して使用してください。

- **説明**
  実行性能を重視した可変行列を表します。`0.2.11` では、公開上のストレージモデルは行優先のフラットな `Array[T]` に統一されており、ターゲットごとの差分は主に実行カーネルの最適化側に残ります。

### セマンティクス

- `@mutable.Matrix` は原地更新を前提としています。`set`、`swap_rows`、`swap_cols`、`map_inplace` などの操作は行列自体を直接変更します。
- このパッケージは `RowView`、`ColView`、`Transpose`、行・列の原地変換、分解補助 API などの実行寄り機能を提供し、これらは `immut` と一対一で揃える対象ではありません。
- 2 つのパッケージで共有するコードでは、`make`、`map`、`transpose`、`+`、`-`、`*`、`trace`、各種変換といった共通の代数 API に依存し、アクセサや更新のセマンティクスが完全に同一だと仮定しないでください。
- `RowView` と `ColView` は基底行列に接続されたライブビューです。`to_array()` と `to_vector()` はコピーを実体化し、`get`、`set`、`map_inplace`、`iter`、`each`、`eachi` はリンクされたビュー上で動作します。
- 以前のようなバックエンドごとの主ストレージ差分は、現在ではほぼデータモデル層で吸収されており、残る差分は主に実行最適化にあります。

- **フィールド**
  - `row` - 行列の行数
  - `col` - 行列の列数
  - `data` - 行列のデータ

- **メソッド**

  - **`fn[A] Matrix::make(row, col, f) -> Matrix[A]`**
    - **説明**
        新しい行列を作成し、与えられた関数を使用してデータを初期化します。
    - **パラメータ**
      - `row: Int` - 行数
      - `col: Int` - 列数
      - `f: (Int, Int) -> A` - データを初期化する関数（第 1 引数は行インデックス、第 2 引数は列インデックス）
    - **戻り値**
      `Matrix[A]` - 新しく作成された行列オブジェクト

    - **補足**
      生成関数の戻り値型で結果の行列要素型が決まるため、既存行列の要素型 `T` に縛られません。

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
    - **パフォーマンス上の注意**
      `m[row]` を呼び出すと、新しい `Lens` オブジェクトと 2 つのクロージャが割り当てられます。性能が重要な一括処理では、次を優先してください：
      1. **`row_view(row)`**：`Matrix::row_view(row)` で明示的な行ビューを取得します。
      2. **組み込み行/列ツール**：`each_row`、`map_row_inplace` などを使って `Lens` オーバーヘッドを避けます。
      3. **直接アクセス（推奨）**：単一要素の読み書きには `Matrix::get(row, col)` と `Matrix::set(row, col, value)` を使います。

  ---

  - **`fn[T] Matrix::row_view(self, row) -> RowView[T]`**
    - **説明**
        行全体に対する可変な構造化ビューを作成します。

  ---

  - **`fn[T] Matrix::col_view(self, col) -> ColView[T]`**
    - **説明**
        列全体に対する可変な構造化ビューを作成します。

---

## @mutable.RowView[T]

```moonbit
pub struct RowView[T] { ... }
```

- **説明**
  行列の 1 行に対する可変な構造化ビューです。`Lens` よりも明示的で再利用しやすい行ビュー API として設計されています。

- **メソッド**
  - **`fn[T] length(self) -> Int`**：その行の列数を返します。
  - **`fn[T] get(self, col) -> T` / `op_get`**：行の要素を読み取ります。
  - **`fn[T] set(self, col, elem) -> Unit` / `op_set`**：行の要素を書き換えます。
  - **`fn[T] iter(self) -> Iter[T]`**：左から右へ行を走査します。
  - **`fn[T] to_array(self) -> Array[T]`**：行を配列にコピーします。
  - **`fn[T] to_vector(self) -> Vector[T]`**：行をベクタにコピーします。
  - **`fn[T] each/eachi(self, ...)`**：必要に応じて添字付きで行要素を反復します。
  - **`fn[T] map_inplace(self, f)`**：行全体に原地変換を適用します。

---

## @mutable.ColView[T]

```moonbit
pub struct ColView[T] { ... }
```

- **説明**
  行列の 1 列に対する可変な構造化ビューで、繰り返しの列操作向けです。

- **メソッド**
  - **`fn[T] length(self) -> Int`**：その列の行数を返します。
  - **`fn[T] get(self, row) -> T` / `op_get`**：列の要素を読み取ります。
  - **`fn[T] set(self, row, elem) -> Unit` / `op_set`**：列の要素を書き換えます。
  - **`fn[T] iter(self) -> Iter[T]`**：上から下へ列を走査します。
  - **`fn[T] to_array(self) -> Array[T]`**：列を配列にコピーします。
  - **`fn[T] to_vector(self) -> Vector[T]`**：列をベクタにコピーします。
  - **`fn[T] each/eachi(self, ...)`**：必要に応じて添字付きで列要素を反復します。
  - **`fn[T] map_inplace(self, f)`**：列全体に原地変換を適用します。

  ---

  - **`fn[T, U] Matrix::map(self, f) -> Matrix[U]`**
    - **説明**
        各要素に関数を適用した新しい行列を作成します。

  ---

  - **`fn[T] Matrix::map_inplace(self, f) -> Unit`**
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

  - **`fn[T : Compare + Field + Num] reduce_row_elimination(self) -> Matrix[T]`**
    - **説明**
        体上の Gauss-Jordan 消去により行最簡形へ簡約します。

  ---

  - **`fn[T] horizontal_combine(self, other) -> Matrix[T]`**
    - **説明**
        水平方向に結合します。

  ---

  - **`fn[T] vertical_combine(self, other) -> Matrix[T]`**
    - **説明**
        垂直方向に結合します。

  ---

  - **`fn[T : Compare + Field + Num + Tolerance] determinant(self) -> T`**
    - **説明**
        行列式を計算します。

  ---

  - **`fn[T : Compare] max_element(self) -> T`**
    - **説明**
        行列中の最大要素を返します。

  ---

  - **`fn[T : Compare] min_element(self) -> T`**
    - **説明**
        行列中の最小要素を返します。

  ---

  - **`fn[T : Add + Default] trace(self) -> T`**
    - **説明**
        正方行列のトレースを計算します。非正方行列では実行を中断します。

  ---

  - **`fn[T : Compare + Field + Num + Sqrt + Tolerance] eigen(self) -> (Vector[T], Matrix[T])`**
    - **説明**
        実対称行列の固有値と固有ベクトルを計算します。

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

  - **`fn[T] map_inplace(self : Transpose[T], f : (T) -> T) -> Unit`**
    - **動作**: 元の行列のデータをその場で変更します。

  - **`fn[T] Transpose::op_get(self, row) -> Lens[T]`**
    - **説明**
        転置ビューの指定された行のアクセサを取得します。
    - **パフォーマンス上の注意**
        `t[row]` の呼び出しにはアロケーションのオーバーヘッドが伴います。ループ内で行データを処理する場合は、`let row = t[i]` のように結果をキャッシュすることをお勧めします。
