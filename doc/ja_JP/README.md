# LINEAR-ALGEBRA

[![img](https://img.shields.io/badge/Maintainer-KCN--judu-violet)](https://github.com/KCN-judu) [![img](https://img.shields.io/badge/Collaborator-CAIMEOX-purple)](https://github.com/CAIMEOX) [![img](https://img.shields.io/badge/License-Apache%202.0-blue)](https://github.com/Luna-Flow/linear-algebra/blob/main/LICENSE) ![img](https://img.shields.io/badge/State-active-success)

## v0.4.0 - 検査付き行列 API と階層化された能力

このドキュメントは現在の **v0.4.0** リポジトリ状態を説明します。本リリースでは、失敗し得る行列操作を
`Result[..., LinearAlgebraError]` で返す検査付き API にし、バックエンド非依存のアルゴリズムに向けた能力層を追加しました。

### 破壊的変更

mooncakes 上の最新公開版は `0.3.0` なので、これらの互換性のない公開 API 変更は `0.4.0` として扱います。

- `immut.Matrix` の `matmul`、`trace`、`determinant`、`pow` は
  `Result[..., LinearAlgebraError]` を返します。
- `mutable.Matrix` の `trace`、`determinant`、`inverse`、`is_invertible`、
  `mul_vec`、`pow`、`matrix_power`、`mean`、`variance`、`std_dev`、
  `max_element`、`min_element` は `Result[..., LinearAlgebraError]` を返します。
- 従来の abort する挙動と、`inverse` の従来の `Option` 戻り値は、対応する
  `unchecked_*` メソッドに残しています。
- 移行時、前提条件を呼び出し側で保証できる箇所では `.unwrap()` または
  対応する `unchecked_*` を使えます。外部入力を扱うコードでは `Err` を明示的に処理してください。

### レイヤードアーキテクチャ

- **`arithmetic`**: 線形代数向けの操作能力層です。`Luna-Flow/luna-generic` と `Luna-Flow/arithmetic` のスカラー操作 trait を再利用し、必要に応じて「この操作が使える」ことだけを表す小さな trait を追加します。
- **`algebra`**: 数学的構造を表す層です。既存の Luna Flow 代数構造を再公開し、`AdditiveVector`、`TransposeMatrix`、`FloatingScalarOps` などの線形代数向け trait を追加します。
- **`backends/default`**: 既定の密行列・密ベクトルバックエンドです。このパッケージが所有する `DenseVector` / `DenseMatrix` と `ImmutableDenseVector` / `ImmutableDenseMatrix` を提供し、内部では `mutable` と `immut` の実装を使います。
- **`error`**: 検査付き API 共通のエラー型です。形状不一致、負の指数、空行列、特異行列、未対応バックエンドなどを表します。
- **trait 駆動アルゴリズム**: バックエンド非依存コードは、具体的な行列/ベクトル型ではなく、`MatrixShape`、`AdditiveVector`、`VecMulVector`、`TransposeMatrix`、`MatMulMatrix` のような最小限の能力に依存します。

内積やノルムのように、ベクトルや行列からスカラーを得る操作は、具体的なバックエンドまたは専用アルゴリズムの責務です。中核の構造 trait 層には含めません。

既定の密実装はあくまで一つのバックエンドであり、エコシステムの中心ではありません。アルゴリズムは具体的な密行列/密ベクトル型ではなく、線形代数 trait に依存するべきです。

### パッケージの位置づけ

- **`immut`**: 不変・値セマンティクス指向の `Matrix`、`Vector`、`MatrixFn` 型。永続データと明示的な copy-on-update セマンティクスに向いています。
- **`mutable`**: 実行指向の `Matrix` と `Vector` 型。原地更新、`Transpose` ビュー、`RowView` / `ColView` を備え、`js`、`wasm`、`wasm-gc`、`native` 向けの最適化実装を保持します。
- **`arithmetic` / `algebra`**: 線形代数の上位能力を表す層です。既定の密バックエンドには依存しません。
- **`backends/default`**: `immut` と `mutable` を既定バックエンドの入口としてまとめます。
- **共有コア、異なる実行モデル**: コンストラクタと中核的な代数演算は両パッケージ間で揃えつつ、更新・アクセスのセマンティクスは意図的に分けています。

### v0.4.0 を特徴づけるもの

- **検査付き行列契約**: 形状、指数、空行列、特異行列などの実行時エラーを `LinearAlgebraError` で表します。
- **従来挙動の明示化**: `unchecked_*` メソッドは従来の abort する挙動を残します。`unchecked_inverse` は従来の `Option` 戻り値を保ちます。
- **公開エラーパッケージ**: `linear-algebra/error` は `LinearAlgebraError`、`LinearAlgebraErrorKind`、コンストラクタ、`is_*` 判定メソッドを提供します。
- **共有平方根能力**: 数値行列 API はパッケージ固有の trait ではなく `Luna-Flow/arithmetic.Sqrt` を使用し、`mutable` はその trait を公開再エクスポートします。
- **対象側の整数埋め込み**: 汎用整数変換は `IntegralHomomorphism::from_integral` を使用し、現在の `Luna-Flow/luna-generic` モデルに従います。
- **エコシステム指向の制約**: カスタムスカラー型は Luna Flow 共通 trait を一度実装すれば、互換性のある各パッケージで利用できます。
- **バックエンド整合**: Native、JS、Wasm、Wasm GC は同じ算術能力と明示的な trait 呼び出しを使用します。
- **互換性境界**: `Tolerance` は本リリースでも `mutable` に属し、まだ `arithmetic` へ移行していません。

### API 指針と性能

- **コア代数 API**: `make`、`transpose`、`+`、`-`、`*`、`trace`、行列/ベクトル変換などの共有操作は、`immut` と `mutable` の間で意味論を揃える方針です。
- **ランダムアクセス**: `mutable` で高頻度ランダムアクセスが必要な場合は `.get(i, j)` と `.set(i, j, val)` を優先してください。
- **構造化ビュー**: `mutable` で特定の行・列を繰り返し扱うなら、`matrix[row]` の便宜構文より `row_view()` / `col_view()` を優先してください。
- **厳密な境界チェック**: 公開された行列・ビュー・転置ビューのアクセサは、`0xN` や `Nx0` を含めて範囲外インデックスを一貫して拒否します。
- **MatrixFn の整合性**: `immut.MatrixFn` も具象行列と同じく、負の次元を拒否し、空行列の意味論を共有します。
- **公開面**: 内部の分解補助関数は依然として実装詳細です。利用者は文書化された公開行列メソッドを使うべきです。

### 主な機能

- **可変・不変の両対応**: 値指向ワークロードと実行指向ワークロードに分かれた完全な `Matrix` / `Vector` 群。
- **高度な演算**: 行列式、逆行列、rank、Cholesky 分解、固有値関連ルーチン、行基本変形、転置ビュー、行列/ベクトル変換を含みます。
- **共有データモデル + バックエンド最適化カーネル**: `mutable` は Native、Wasm、JS、Wasm GC 向けの最適化実行経路を維持しつつ、コア行列ストレージモデルは統一されています。
- **Benchmark 基盤**: `bench/`、`src/perf_support`、`src/perf_runner` が、バックエンド比較と診断再現のための完全な steady-state benchmark サブシステムを構成しています。
- **正しさ優先**: 不変法則、パッケージ間整合性、行列式/rank/inverse の整合、数値挙動の回帰テストを含むカバレッジを備えています。
- **監査可能な公開契約**: 境界挙動、swap セマンティクス、benchmark fixture、ドキュメントの整合性が、以前より明示的に追跡されるようになりました。

### Benchmark 関連パッケージ

- **`perf`**: `moon bench` 用の benchmark エントリパッケージです。
- **`perf_support`**: fixture メタデータ、case レジストリ、ランタイムローダー、benchmark 実行補助 API を提供します。
- **`perf_runner`**: 単一 case の診断、サンプリング、結果再現に使うランナーです。

### クイックスタート

```moonbit
let imm = @immut.Matrix::from_2d_array([[1, 2], [3, 4]])
let imm_updated = imm.set(0, 1, 9)

let m = @mutable.Matrix::from_2d_array([[1.0, 2.0], [3.0, 4.0]])
m.set(0, 1, 9.0)

let det = m.determinant().unwrap()
let inv = m.inverse().unwrap()
let row0 = m.row_view(0).to_array()
```

### ドキュメント

完全な API ドキュメントは [mooncakes.io](https://mooncakes.io/docs/Luna-Flow/linear-algebra) で参照できます。

多言語ドキュメント:

- 🇺🇸 **English** (`doc/en_US`)
- 🇨🇳 **简体中文** (`doc/zh_CN`)
- 🇯🇵 **日本語** (`doc/ja_JP`)

多言語 README:

- 🇺🇸 [README.md](../../README.md)
- 🇨🇳 [README.md](../zh_CN/README.md)
- 🇯🇵 [README.md](./README.md)

新規パッケージのドキュメント入口:

- [arithmetic API](./arithmetic/api.md)
- [algebra API](./algebra/api.md)
- [backends/default API](./backends/default/api.md)
- [error API](./error/api.md)

## バージョン履歴

| バージョン | 日付 | 状態 | 説明 |
| --- | --- | --- | --- |
| `0.4.0` | 2026-07-07 | 現在のリポジトリ版 | 検査付き行列 API、構造化された線形代数エラー、階層化された能力パッケージ、既定バックエンドのラッパー型を導入 |
| `0.3.0` | 2026-06-14 | mooncakes 公開済み | 共有 `arithmetic.Sqrt`、現行 `luna-generic` 同型写像、統一された数値能力を採用 |
| `0.2.12` | 2026-06-06 | mooncakes 公開済み | 厳密境界契約の統一、意味論上の正しさ修正、benchmark 診断拡張、文書/監査の刷新 |
| `0.2.11` | 2026-05-27 | 前回リリース基準 | mutable カーネル性能改善、専用 wasm-gc バックエンド、benchmark/レポート拡張、API/文書整合 |
| `0.2.10` | 2026-05-27 | 前回リリース基準 | 統一フラット mutable ストレージ、行列ビュー、整合性カバレッジ、benchmark 拡張、リリース手順整合 |
| `0.2.9` | 2026-02-03 | mooncakes 公開済み | 以前の `3328195` リリース状態から公開 |
| `0.2.8` | 2026-02-03 | 歴史的基準 | 後続作業のアルゴリズム・安定性比較の基準 |

## 現在のリポジトリのハイライト

- **現在のリリース叙述（0.4.0）**:
  - 実行時条件で失敗し得る行列操作は `Result[..., LinearAlgebraError]` を返します。
  - 従来の行列操作の挙動は明示的な `unchecked_*` メソッドに残しています。
  - `linear-algebra/error` は検査付き API 共通のエラー語彙を文書化します。
  - `arithmetic`、`algebra`、`backends/default` は、汎用アルゴリズム向けの新しい trait 階層を提供します。

- **前回リリース叙述（0.3.0）**:
  - 平方根を必要とする行列アルゴリズムは共有 `arithmetic.Sqrt` を要求します。
  - `mutable.Sqrt` は `arithmetic.Sqrt` の公開再エクスポートであり、旧パッケージ固有 trait とスカラー実装は削除されました。
  - 整数 fixture と変換補助関数は対象側 `IntegralHomomorphism::from_integral` を使用します。
  - カスタム数値型は linear-algebra 固有 trait ではなく `luna-generic` と `arithmetic` の共有能力を実装します。

- **以前のリリース叙述（0.2.12）**:
  - 公開行列、ビュー、転置ビューのアクセサは、ゼロ行・ゼロ列の形状を含む明示的な境界契約を強制します。
  - `immut.Matrix` と `mutable.Matrix` は値と更新の違いを保ちながら、共通の正しさに関する意味論を揃えています。
  - Benchmark 診断と正しさ監査は `0.2.12` の公開面に対応します。

- **以前のリリース叙述（0.2.11）**:
  - `mutable.Matrix` は `0.2.10` の共有フラットストレージを土台に、バックエンドカーネル最適化と専用 `wasm-gc` 実装を重ねた形で整理されています。
  - 公開数値 API は `Field` / `Num` / `Tolerance` に揃えられ、不変行列式のドキュメントも簡素化後の制約へ更新されています。
  - benchmark スタックは、ランタイム fixture 読み込み、拡張 case メタデータ、詳細な summary 出力、ローカル dashboard、任意の Rust 比較、`perf_runner` による診断再現を含みます。
  - リリースチェックリスト、benchmark 文書、パッケージ概要、多言語 README は `0.2.11` のリリースストーリーに整合しています。

- **アルゴリズムと安定性（0.2.8）**:
  - 行列式、逆行列、rank、固有値関連機能を支える LU / QR 分解サポートを追加しました。
  - 行列式と rank の挙動を、より安定した消去ベース実装へ寄せました。

- **Native 最適化（0.2.7）**:
  - Native 行列乗算に転置 + dot-product 戦略を導入し、素朴実装より 2 倍超の高速化を実現しました。
  - `make`、`new`、`transpose` を最適化し、ホットループ中の高価な整数除算を取り除きました。

- **性能刷新（0.2.4）**:
  - `mapi`、`each_row_col` などの補助ユーティリティを最適化しました。
  - ハイブリッド行列乗算とベクトル線形結合の性能を改善しました。

- **その他の修正と改名**:
  - `map_row()` / `map_col()` -> `map_row_inplace()` / `map_col_inplace()`
  - `eachij()` -> `each_row_col()`
  - `0x0` 行列の行列式の挙動を修正しました。
  - ベクトルと行列の相互変換時のコピー挙動を修正しました。

## 開発

よく使うローカルコマンド:

```bash
moon fmt
moon check
moon test --enable-coverage
./run_test.sh
```

`run_test.sh` は `mutable` パッケージを `wasm-gc`、`js`、`native`、`wasm` で実行します。

## リリースチェックリスト

publish workflow を起動する前に:

1. `moon.mod` を目標リリースバージョンへ bump する。
2. `README.md` を更新し、リリースノートとバージョン履歴をパッケージ内容に一致させる。
3. `moon check` と `./run_test.sh` を実行する。
4. `publish-パッケージ` を起動する。workflow は `moon.mod` に書かれたバージョンをそのまま使う。

workflow が重複バージョンを報告した場合、そのバージョンは既に登録されています。先に新しいバージョンへ bump してください。

コントリビューション案内は [CONTRIBUTING.md](./CONTRIBUTING.md) を参照してください。
