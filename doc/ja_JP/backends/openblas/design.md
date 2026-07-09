# backends/openblas Design

## 責務

- 公開 `@algebra` trait エコシステムに参加できる `native` 専用の具体行列
  バックエンドを提供する
- バックエンド所有の公開型を `BlasMatrix[T]` として保つ
- 行列乗算には OpenBLAS GEMM を使い、それ以外の初期行列面は MoonBit ローカル実装に
  残す
- OpenBLAS のレイアウトやバインディング詳細を、リポジトリ所有 API の内側へ隠す

## なぜラッパーバックエンドなのか

このパッケージは trait 互換のバックエンドラッパーです。

次のものではありません。

- runtime backend selector
- グローバルな backend enum
- 外部 OpenBLAS バインディング型への直接 trait 実装

ラッパーにしている理由は、パッケージが具体行列型を所有し、MoonBit の foreign
trait / foreign type 制約に触れずに `@algebra` trait を実装できるようにするためです。

## 型とターゲットが挙動を決める

現在のバックエンド選択は、次の 2 つで決まります。

- 型の選択
  `@immut.Matrix[T]` と `@default.ImmutableDenseMatrix[T]` は既存の密実装を使い、
  `@openblas.BlasMatrix[T]` は OpenBLAS 対応の行列乗算経路を使います
- ターゲットの選択
  `backends/openblas` は `native` ビルドにだけ参加します

`@immut.Matrix` に対して、実行時に別バックエンドへ切り替える API はありません。

## スカラー戦略

`BLASInnerType` は意図的にバックエンド局所へ閉じた抽象です。このラッパーが本当に
必要とするスカラー差分を表します。

- 正しい GEMM カーネルへの振り分け
- バックエンド検証用の許容誤差の提供

現状、この trait は `Float` と `Double` にしか実装していません。これは現在の
OpenBLAS 行列面と一致しており、誤解を招く無制限ジェネリクスを避けます。

## 操作分担

- `Mul`
  OpenBLAS GEMM に委譲します
- `shape`、`transpose`、`+`、`-`、`neg`
  ローカルの MoonBit 実装のままです

この分担によって、trait 指向の汎用コードに十分な行列面を渡しつつ、「すべての操作が
最初から BLAS ルーチンである」とは装いません。
