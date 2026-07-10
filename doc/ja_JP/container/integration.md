# Luna-Flow エコシステムへの接続

外部ライブラリは、実際の意味に合う能力だけを選んで提供します。接続は一括適合ではなく、
内部ストレージを公開する必要もありません。

## 構造能力の境界を選ぶ

| レベル | 提供する能力 | 参加できる役割 |
|---|---|---|
| 0 | なし | 独自 API を使う独立型 |
| 1 | `VectorReadOps` または `MatrixReadOps` | map、変換、転置の入力 |
| 2 | `VectorBuildOps` または `MatrixBuildOps` | map、変換、転置の出力 |
| 3 | 対応する read と build | ジェネリック変換の入力と出力 |
| 4P | 永続編集辞書 | 検査付き copy-on-replacement 値 |
| 4M | 可変編集辞書 | 検査付き原地更新対象 |

4P と 4M は所有権モデルで決まる選択肢であり、両方を実装するための段階ではありません。
ビューは read と可変編集だけを持ち、build を持たないことが自然です。外部ハンドルは
read のみ、生成専用コンテナは build のみでも構いません。

## アルゴリズムが要求する能力

| アルゴリズム | 入力 | 出力 | スカラー |
|---|---|---|---|
| `vector_map` | `VectorReadOps[V1, A]` | `VectorBuildOps[V2, B]` | `A` から `B` へ変更可 |
| `matrix_map` | `MatrixReadOps[M1, A]` | `MatrixBuildOps[M2, B]` | `A` から `B` へ変更可 |
| `vector_convert` | `VectorReadOps[V1, T]` | `VectorBuildOps[V2, T]` | `T` を保持 |
| `matrix_convert` | `MatrixReadOps[M1, T]` | `MatrixBuildOps[M2, T]` | `T` を保持 |
| `matrix_transpose` | `MatrixReadOps[M1, T]` | `MatrixBuildOps[M2, T]` | `T` を保持 |

read は構築、編集、算術、連続メモリ、安価なランダムアクセスを意味しません。
build は読み戻しを意味しません。編集辞書は resize、insert、delete、疎要素削除を
意味しません。

## 数学能力は独立している

`algebra` は加算、転置、行列積などを記述し、`container` は観測と構築を記述します。
外部型はそれぞれを独立に選べます。container のみなら代数法則を主張せずデータ変換へ
参加でき、algebra のみなら要素を公開せず閉じた数学演算を提供できます。

container 接続のためだけに広いスカラー trait を実装しないでください。数学 trait は、
型がその演算と法則を本当に満たす場合だけ追加します。

## アダプタの所有者

1. 型を所有するライブラリが `container` への依存を受け入れられるなら、そこで辞書
   factory を公開します。
2. 双方に直接依存を置きたくない場合は、小さな bridge パッケージが所有します。
3. `Luna-Flow/linear-algebra` 本体には、このリポジトリで管理する実装のアダプタだけを
   置きます。

これにより中核へ任意バックエンド依存が蓄積しません。factory の制約は、バックエンドが
本当に必要とするスカラー能力だけに限定します。

## 完全な外部アダプタ例

この例は行優先配列を所有しますが、その意味は操作辞書だけから公開します。転置先には
Luna の immutable 行列を使い、実際の異種実装境界を検証します。

```moonbit check
///|
struct EcosystemOwnedMatrix[T] {
  rows : Int
  cols : Int
  data : Array[T]
}

///|
fn[T] ecosystem_owned_matrix_read_ops() -> @container.MatrixReadOps[
  EcosystemOwnedMatrix[T],
  T,
] {
  @container.MatrixReadOps::new(matrix => (matrix.rows, matrix.cols), (
    matrix,
    row,
    col,
  ) => {
    guard row >= 0 && row < matrix.rows && col >= 0 && col < matrix.cols else {
      return Err(
        @la_error.LinearAlgebraError::index_out_of_bounds(
          "Matrix index out of bounds",
        ),
      )
    }
    Ok(matrix.data[row * matrix.cols + col])
  })
}

///|
fn[T] ecosystem_owned_matrix_build_ops() -> @container.MatrixBuildOps[
  EcosystemOwnedMatrix[T],
  T,
] {
  @container.MatrixBuildOps::new((rows, cols, initializer) => {
    guard rows >= 0 && cols >= 0 else {
      return Err(
        @la_error.LinearAlgebraError::negative_dimension(
          "Matrix dimensions must be non-negative",
        ),
      )
    }
    Ok({
      rows,
      cols,
      data: Array::makei(rows * cols, index => {
        initializer(index / cols, index % cols)
      }),
    })
  })
}

///|
test "external container adapters preserve actual matrix semantics" {
  let source : EcosystemOwnedMatrix[Int] = (ecosystem_owned_matrix_build_ops().tabulate)(
    2,
    3,
    (row, col) => row * 10 + col,
  ).unwrap()
  let target : @immut.Matrix[Int] = @container.matrix_transpose(
    source,
    ecosystem_owned_matrix_read_ops(),
    @container_adapters.immutable_matrix_build_ops(),
  ).unwrap()
  inspect(target, content="|0, 10|\n|1, 11|\n|2, 12|")
  match (ecosystem_owned_matrix_read_ops().get)(source, -1, 0) {
    Err(error) => inspect(error.is_index_out_of_bounds(), content="true")
    Ok(_) => fail("negative row must fail")
  }
  let degenerate : EcosystemOwnedMatrix[Int] = (ecosystem_owned_matrix_build_ops().tabulate)(
    0,
    3,
    (_, _) => 0,
  ).unwrap()
  debug_inspect((degenerate.rows, degenerate.cols), content="(0, 3)")
}
```

バックエンドは負の次元、`0xN` / `Nx0`、不正座標、所有権規則を自身で保証します。

## 接続チェックリスト

- 実際のストレージと所有権に合う辞書だけを選ぶ。
- 検査付きアクセスと構築で panic しない。
- 境界 index、空・退化形状、initializer の座標順をテストする。
- 永続編集では元の値の保持、可変編集では失敗時に部分変更がないことを確認する。
- 対応方向ごとに map または変換を少なくとも 1 つテストする。
- remote access、展開、疎行列 materialization などのコストを文書化する。

将来の最適化 kernel 辞書は追加の opt-in 能力であり、read/build の前提にはしません。
