# `linear-algebra/algebra`

このページは現在の `0.4.0` リポジトリにおける
`Luna-Flow/linear-algebra/algebra` の公開 API を説明します。

## 役割

`algebra` は線形代数の構造を表す trait を提供します。各バックエンドパッケージは、自分が所有する具体データ型に対してこれらの trait を実装します。trait は必要最小限の能力ごとに分かれているため、汎用アルゴリズムが意図せずアダマール積、行列積、または厳密な浮動小数点体の法則に依存することを避けられます。

## 再公開されるスカラー/代数 trait

- `Zero`、`One`、`Conjugate`
- `AddMonoid`、`AddGroup`
- `MulMonoid`、`MulGroup`
- `Semiring`、`Ring`、`Field`
- `Integral`、`Nat`、`Num`
- `NatHomomorphism`、`IntegralHomomorphism`
- `Abs`、`ApproxEq`、`Sqrt`

これらは上流パッケージでの意味を保ちます。`algebra` は法則を再定義しません。

## 形状 trait

```moonbit
pub(open) trait MatrixShape {
  fn shape(Self) -> (Int, Int)
}

pub(open) trait VectorShape {
  fn length(Self) -> Int
}
```

`MatrixShape` は二次元の形状を観測できる値、`VectorShape` は長さを観測できるベクトル状の値を表します。これらは代数演算の存在を主張しません。

## `AdditiveVector`

```moonbit
pub(open) trait AdditiveVector: VectorShape + Add + Neg + Sub {}
```

加法的な線形構造を持つベクトル状の値を表します。要素ごとの乗算、内積、ノルム、大域的な零元は要求しません。

アルゴリズムがアダマール積を本当に必要とする場合だけ、次の trait を使います。

```moonbit
pub(open) trait VecMulVector: AdditiveVector + Mul {}
```

## `TransposeMatrix`

```moonbit
pub(open) trait TransposeMatrix: MatrixShape {
  fn transpose(Self) -> Self
}
```

形状と同じ型への転置を持つ行列状の値を表します。行列積は要求しません。動的な矩形行列の乗算は、実行時の形状が適合する場合にだけ定義される部分操作だからです。この trait は密な保存形式、連続メモリ、直接インデックス、可変操作を要求しません。

必要な演算があるアルゴリズムだけ、より強い trait を使います。

```moonbit
pub(open) trait AdditiveMatrix: TransposeMatrix + Add + Neg + Sub {}
pub(open) trait MatMulMatrix: AdditiveMatrix + Mul {}
```

## より強い代数 trait

これらの任意 trait は、`luna-generic` の大域的な単位元を正しく提供できる型向けです。

- `AdditiveVectorGroup: AdditiveVector + AddGroup`
- `VecMulSemiringVector: VecMulVector + Semiring`
- `VecMulRingVector: VecMulVector + Ring`
- `SquareMatrixSemiring: MatMulMatrix + Semiring`
- `SquareMatrixRing: MatMulMatrix + Ring`

動的な矩形行列や実行時長のベクトルは、型レベルの表現が必要な形状と単位元を本当に固定している場合を除き、通常これらの強い trait を実装しません。

## `FloatingScalarOps`

```moonbit
pub(open) trait FloatingScalarOps: Field + Num + ApproxEq {}
```

数値アルゴリズム向けの浮動小数点スカラー操作能力です。継承している `Field` は既存の Luna Flow エコシステムにおける操作上の依存であり、IEEE 浮動小数点値が厳密な体の法則を満たすという主張ではありません。現在は `Float` と `Double` に実装されています。

## 境界

スカラー値を返す積、`norm`、内積 trait はここに置きません。中核の `algebra` パッケージは、最小構造と同じ型に閉じた演算のためのパッケージです。
