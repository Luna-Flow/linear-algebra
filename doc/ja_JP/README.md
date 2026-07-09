# Luna-Flow/linear-algebra

この README は現在のリポジトリ基準である **v0.4.4** に対応しています。

`mutable` の数値 API は共有の `Luna-Flow/arithmetic.Sqrt` 能力を使い、
整数埋め込みは `Luna-Flow/luna-generic.IntegralHomomorphism` に従います。
現行リリースでは `Tolerance` は引き続き `mutable` パッケージに属します。
実行時に失敗し得る行列操作は、現在は検査付き
`Result[..., LinearAlgebraError]` API を使います。従来の abort する挙動と
`Option` 戻り値は、明示的な `unchecked_*` メソッドに残しています。

`0.4.4` 基準は、検査付き `0.4.x` API 表面と `0.4.2` で導入した
パック済み行列乗算経路を維持しつつ、パッケージとリポジトリの metadata を
現在の trait 指向のプロジェクト位置づけへ揃えたものです。

過去のリリースノートと履歴は [CHANGELOG.md](../../CHANGELOG.md) を参照してください。

## レイヤードアーキテクチャ

- **`arithmetic`**: 線形代数向けの操作能力層です。
  `Luna-Flow/luna-generic` と `Luna-Flow/arithmetic` のスカラー操作 trait を
  再利用し、必要に応じて操作可否だけを表す trait を補います。
- **`algebra`**: 数学的構造の能力層です。線形代数が自前で持つ構造 trait だけを
  定義します。
- **`backends/default`**: 参照用の密バックエンド層です。可変の密ラッパー
  `DenseVector` / `DenseMatrix` と、不変の密ラッパー
  `ImmutableDenseVector` / `ImmutableDenseMatrix` を公開します。
- **`error`**: 検査付き線形代数 API の共有エラー語彙です。形状、指数、空行列、
  特異行列、バックエンド関連エラーを扱います。
- **trait 駆動アルゴリズム**: バックエンド非依存コードは、
  `MatrixShape`、`AdditiveVector`、`VecMulVector`、`TransposeMatrix`、
  `MatMulMatrix` のような最小限の必要能力に依存するべきです。

内積やノルムのように、ベクトルや行列をスカラー的な量へ写す能力は、
バックエンドまたはアルゴリズムの詳細です。中核の構造 trait 層には含めません。

既定の密実装はあくまで 1 つのバックエンドであり、エコシステムの中心ではありません。
アルゴリズムは具体的な密行列・密ベクトル型ではなく、最小限の線形代数 trait に
依存するべきです。

このリポジトリは、より上位の数学ライブラリ、幾何ライブラリ、solver 風
ライブラリのための線形代数基盤として位置付けています。分野固有の solve、
回帰、最適化ワークフローは、これらの trait、バックエンドラッパー、
具体的な行列/ベクトル型の上に作る下流パッケージへ置く想定です。

具体的な `immut` / `mutable` の行列・ベクトル型は、
`backends/default` が包む実装本体です。`DenseVector` と `DenseMatrix` は
`@mutable.Vector` と `@mutable.Matrix` を包み、`ImmutableDenseVector` と
`ImmutableDenseMatrix` は `@immut.Vector` と `@immut.Matrix` を包みます。

## 読者ガイド

- **一般的なアプリケーション開発者**:
  [mutable](./mutable/matrix/api.md) と [immut](./immut/matrix/api.md) から
  読み始めてください。これらは業務ツール、ユーティリティ、数値処理、
  小さなゲーム、可視化ロジックのようなアプリケーションコード向けの具体 API です。
- **数学ライブラリ / 汎用アルゴリズム開発者**:
  次の順番で読むのがおすすめです。
  [arithmetic](./arithmetic/api.md) ->
  [algebra](./algebra/api.md) ->
  [backends/default](./backends/default/api.md) ->
  [immut / mutable](./immut/matrix/api.md)。
  まず操作能力、次に構造能力、その次に既定バックエンドのラッパー、最後に
  具体実装へ進みます。より上位のアプリケーションライブラリ、幾何パッケージ、
  solver 系パッケージをこの上に構築する場合の推奨入口でもあります。

## ドキュメント入口

- **`immut` 具体 API**:
  [immut/matrix API](./immut/matrix/api.md),
  [immut/matrix tutorial](./immut/matrix/tutorial.md),
  [immut/vector API](./immut/vector/api.md),
  [immut/vector tutorial](./immut/vector/tutorial.md)
- **`mutable` 具体 API**:
  [mutable/matrix API](./mutable/matrix/api.md),
  [mutable/matrix tutorial](./mutable/matrix/tutorial.md),
  [mutable/vector API](./mutable/vector/api.md),
  [mutable/vector tutorial](./mutable/vector/tutorial.md)
- **能力層とバックエンド層**:
  [arithmetic API](./arithmetic/api.md),
  [algebra API](./algebra/api.md),
  [backends/default API](./backends/default/api.md),
  [error API](./error/api.md)

## 下流での利用例

- **[`Luna-Flow/geometry3d`](https://github.com/Luna-Flow/geometry3d)**:
  `Luna-Flow/linear-algebra` の上に構築された、MoonBit 用のコンパクトな
  3D 幾何基盤です。その上で core 幾何、camera/view 数学、
  バックエンド非依存レンダリング、TUI / Canvas / GSAP バックエンドを
  提供します。
  [英語ドキュメント](https://github.com/Luna-Flow/geometry3d/blob/main/doc/en_US/README.md)
  は具体的な下流利用例として読みやすい入口です。

## 抽象層を使うための設定

抽象能力層を使ってバックエンド非依存コードを書きたい場合は、前提になる上流抽象
パッケージを明示的に追加してください。

```sh
moon add Luna-Flow/linear-algebra@0.4.4
moon add Luna-Flow/luna-generic@0.3.3
moon add Luna-Flow/arithmetic@0.2.2
```

推奨される `moon.pkg` の import 例:

```moonbit
import {
  "Luna-Flow/linear-algebra/algebra",
  "Luna-Flow/linear-algebra/arithmetic" @la_arithmetic,
  "Luna-Flow/luna-generic" @lf_alg,
  "Luna-Flow/arithmetic" @lf_arith,
}
```

`@algebra` は線形代数の構造 trait、`@la_arithmetic` は線形代数向けの操作 trait、
`@lf_alg` は共有の上流代数抽象、`@lf_arith` は共有の上流算術型を指します。

## リポジトリの位置づけ

可変と不変の両方の実行モデルを備えた行列・ベクトル基盤です。

## ドキュメント構成

- `README.md` はリポジトリの説明と現行基準をまとめます。
- `doc_standard.md` は文書契約をまとめます。
- 各モジュールやサブシステム配下には `api.md`、`tutorial.md`、`design.md` を置きます。

## モジュール概要

- **`immut/matrix`**: 実装は `src/immut`
- **`immut/vector`**: 実装は `src/immut`
- **`mutable/matrix`**: 実装は `src/mutable`
- **`mutable/vector`**: 実装は `src/mutable`
- **`arithmetic`**: 実装は `src/arithmetic`
- **`algebra`**: 実装は `src/algebra`
- **`backends/default`**: 実装は `src/backends/default`
- **`error`**: 実装は `src/error`
