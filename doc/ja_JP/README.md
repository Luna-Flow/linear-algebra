# LINEAR-ALGEBRA

[![img](https://img.shields.io/badge/Maintainer-KCN--judu-violet)](https://github.com/KCN-judu) [![img](https://img.shields.io/badge/Collaborator-CAIMEOX-purple)](https://github.com/CAIMEOX) [![img](https://img.shields.io/badge/License-MIT-blue)](https://github.com/Luna-Flow/linear-algebra/blob/main/LICENSE) ![img](https://img.shields.io/badge/State-active-success)

## v0.2.11 - パフォーマンス、Benchmark、API 整合

このドキュメントは、`0.2.10` 以降に入った変更を反映した、次期 **v0.2.11** の内容を説明します。

### パッケージの位置づけ

- **`immut`**: 不変・値セマンティクス指向の `Matrix`、`Vector`、`MatrixFn` 型。永続データと明示的な copy-on-update セマンティクスに向いています。
- **`mutable`**: 実行指向の `Matrix` と `Vector` 型。原地更新、`Transpose` ビュー、`RowView` / `ColView` を備え、`js`、`wasm`、`wasm-gc`、`native` 向けの最適化実装を保持します。
- **共有コア、異なる実行モデル**: コンストラクタと中核的な代数演算は両パッケージ間で揃えつつ、更新・アクセスのセマンティクスは意図的に分けています。

### v0.2.11 を特徴づけるもの

- **行列ビュー**: `mutable` は `RowView` と `ColView` を公開し、コピーを実体化せずに構造化された行・列操作を繰り返せます。
- **統一されたフラットストレージ**: `mutable.Matrix` はバックエンドをまたいで共有のフラット `Array[T]` ストレージモデルを採用し、主ストレージの説明をバックエンドごとに分けなくなりました。
- **パッケージ間整合性チェック**: `immut` / `mutable` 間で共有される代数的振る舞いを揃えるための専用テストを追加しました。
- **数値修正**: 可変行列の LU ベースの処理を強化し、pivot permutation の扱いとより広い数値境界ケースを改善しました。
- **不変コアの整合**: `immut.Vector` は最適化された core immutable vector 実装の上に構築され続けており、ライブラリ全体でより統一されたフラットデータ経路を実現しやすくしています。
- **専用 Wasm GC バックエンド**: `mutable` は、従来バックエンドの薄い派生ではない専用の `wasm-gc` バックエンド実装を持つようになりました。
- **数値 trait 境界の整理**: 可変数値 API は `Field` / `Num` / `Tolerance` を中心とした境界へより直接的に整えられ、不変 determinant の制約も簡素化されました。
- **対称固有値経路の高速化**: 実対称行列向けの eigen 経路は現行リリースラインで高速化されています。
- **mutable カーネルの継続最適化**: `0.2.10` の統一ストレージ以降も、各バックエンドの繰り返し行列処理の実行オーバーヘッドをさらに削減しました。
- **依存関係更新**: 現在のリポジトリは `Luna-Flow/luna-generic` `0.3.0` と `moonbitlang/quickcheck` `0.14.0` に依存しています。
- **現行 Moon パッケージメタデータ**: このリポジトリは、現在のツールチェインにおける正規のパッケージマニフェストとして `moon.mod` を持っています。
- **リリース確認フロー**: publish workflow は `moon.mod` に書かれたバージョンを直接読み取り、正規 manifest と release メタデータを一致させます。
- **Benchmark ハーネスとダッシュボード**: fixture 駆動の benchmark harness、ランタイム fixture 読み込み、より豊富なレポート、ローカル web dashboard、そしてローカルまたは臨時比較向けの任意の Rust baseline を備えています。

### API 指針と性能

- **コア代数 API**: `make`、`transpose`、`+`、`-`、`*`、`trace`、行列/ベクトル変換などの共有操作は、`immut` と `mutable` の間で意味論を揃える方針です。
- **ランダムアクセス**: `mutable` で高頻度ランダムアクセスが必要な場合は `.get(i, j)` と `.set(i, j, val)` を優先してください。
- **構造化ビュー**: `mutable` で特定の行・列を繰り返し扱うなら、`matrix[row]` の便宜構文より `row_view()` / `col_view()` を優先してください。
- **厳密な境界チェック**: 公開された行列・ビュー・転置ビューのアクセサは、`0xN` や `Nx0` を含めて範囲外インデックスを一貫して拒否します。
- **MatrixFn の整合性**: `immut.MatrixFn` も具象行列と同じく、負の次元を拒否し、空行列の意味論を共有します。
- **公開面**: 内部の分解補助関数は依然として実装詳細です。利用者は文書化された公開行列メソッドを使うべきです。

### 主な機能

- **可変・不変の両対応**: 値指向ワークロードと実行指向ワークロードに分かれた完全な `Matrix` / `Vector` 群。
- **高度な演算**: determinant、inverse、rank、Cholesky decomposition、eigen 関連ルーチン、row elimination、transpose view、行列/ベクトル変換を含みます。
- **共有データモデル + バックエンド最適化カーネル**: `mutable` は Native、Wasm、JS、Wasm GC 向けの最適化実行経路を維持しつつ、コア行列ストレージモデルは統一されています。
- **Benchmark 基盤**: `bench/`、`src/perf_support`、`src/perf_runner` が、バックエンド比較と診断再現のための完全な steady-state benchmark サブシステムを構成しています。
- **正しさ優先**: 不変法則、パッケージ間整合性、determinant/rank/inverse の整合、数値挙動の回帰テストを含むカバレッジを備えています。

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

let det = m.determinant()
let maybe_inv = m.inverse()
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

## バージョン履歴

| バージョン | 日付 | 状態 | 説明 |
| --- | --- | --- | --- |
| `0.2.11` | 2026-05-27 | 次期リリース基準 | mutable カーネル性能改善、専用 wasm-gc バックエンド、benchmark/レポート拡張、API/文書整合 |
| `0.2.10` | 2026-05-27 | 前回リリース基準 | 統一フラット mutable ストレージ、行列ビュー、整合性カバレッジ、benchmark 拡張、リリース手順整合 |
| `0.2.9` | 2026-02-03 | mooncakes 公開済み | 以前の `3328195` リリース状態から公開 |
| `0.2.8` | 2026-02-03 | 歴史的基準 | 後続作業のアルゴリズム・安定性比較の基準 |

## 現在のリポジトリのハイライト

- **現在のリリース叙述（0.2.11）**:
  - `mutable.Matrix` は `0.2.10` の共有フラットストレージを土台に、バックエンドカーネル最適化と専用 `wasm-gc` 実装を重ねた形で整理されています。
  - 公開数値 API は `Field` / `Num` / `Tolerance` に揃えられ、不変 determinant のドキュメントも簡素化後の制約へ更新されています。
  - benchmark スタックは、ランタイム fixture 読み込み、拡張 case メタデータ、詳細な summary 出力、ローカル dashboard、任意の Rust 比較、`perf_runner` による診断再現を含みます。
  - リリースチェックリスト、benchmark 文書、パッケージ概要、多言語 README は `0.2.11` のリリースストーリーに整合しています。

- **アルゴリズムと安定性（0.2.8）**:
  - determinant、inverse、rank、eigen 関連機能を支える LU / QR 分解サポートを追加しました。
  - determinant と rank の挙動を、より安定した消去ベース実装へ寄せました。

- **Native 最適化（0.2.7）**:
  - Native 行列乗算に転置 + dot-product 戦略を導入し、素朴実装より 2 倍超の高速化を実現しました。
  - `make`、`new`、`transpose` を最適化し、ホットループ中の高価な整数除算を取り除きました。

- **性能刷新（0.2.4）**:
  - `mapi`、`each_row_col` などの補助ユーティリティを最適化しました。
  - ハイブリッド行列乗算とベクトル線形結合の性能を改善しました。

- **その他の修正と改名**:
  - `map_row()` / `map_col()` -> `map_row_inplace()` / `map_col_inplace()`
  - `eachij()` -> `each_row_col()`
  - `0x0` 行列の determinant 挙動を修正しました。
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
4. `publish-package` を起動する。workflow は `moon.mod` に書かれたバージョンをそのまま使う。

workflow が重複バージョンを報告した場合、そのバージョンは既に登録されています。先に新しいバージョンへ bump してください。

コントリビューション案内は [CONTRIBUTING.md](./CONTRIBUTING.md) を参照してください。
