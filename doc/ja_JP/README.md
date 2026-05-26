# LINEAR-ALGEBRA

[![img](https://img.shields.io/badge/Maintainer-KCN--judu-violet)](https://github.com/KCN-judu) [![img](https://img.shields.io/badge/Collaborator-CAIMEOX-purple)](https://github.com/CAIMEOX) [![img](https://img.shields.io/badge/License-MIT-blue)](https://github.com/Luna-Flow/linear-algebra/blob/main/LICENSE) ![img](https://img.shields.io/badge/State-active-success)

## v0.2.10 - 統一ストレージと API 整合

**v0.2.10** では、リポジトリのドキュメントとリリースメタデータを現在のパッケージマニフェストに揃えています。

### パッケージの位置づけ

- **`immut`**: 不変・値セマンティクス指向の `Matrix`、`Vector`、`MatrixFn` 型。永続データと明示的な copy-on-update セマンティクスに向いています。
- **`mutable`**: 実行指向の `Matrix` と `Vector` 型。原地更新、`Transpose` ビュー、`RowView` / `ColView` を備え、`js`、`wasm`、`wasm-gc`、`native` 向けの最適化実装を保持します。
- **共有コア、異なる実行モデル**: コンストラクタと中核的な代数演算は両パッケージ間で揃えつつ、更新・アクセスのセマンティクスは意図的に分けています。

### v0.2.10 を特徴づけるもの

- **行列ビュー**: `mutable` は `RowView` と `ColView` を公開し、コピーを実体化せずに構造化された行・列操作を繰り返せます。
- **統一されたフラットストレージ**: `mutable.Matrix` はバックエンドをまたいで共有のフラット `Array[T]` ストレージモデルを採用し、主ストレージの説明をバックエンドごとに分けなくなりました。
- **パッケージ間整合性チェック**: `immut` / `mutable` 間で共有される代数的振る舞いを揃えるための専用テストを追加しました。
- **数値修正**: 可変行列の LU ベースの処理を強化し、pivot permutation の扱いとより広い数値境界ケースを改善しました。
- **不変コアの整合**: `immut.Vector` は最適化された core immutable vector 実装の上に構築され続けており、ライブラリ全体でより統一されたフラットデータ経路を実現しやすくしています。
- **専用 Wasm GC バックエンド**: `mutable` は、従来バックエンドの薄い派生ではない専用の `wasm-gc` バックエンド実装を持つようになりました。
- **数値 trait 境界の整理**: 可変数値 API は `Field` / `Num` / `Tolerance` を中心とした境界へより直接的に整えられ、不変 determinant の制約も簡素化されました。
- **対称固有値経路の高速化**: 実対称行列向けの eigen 経路は現行リリースラインで高速化されています。
- **依存関係更新**: 現在のリポジトリは `Luna-Flow/luna-generic` `0.3.0` と `moonbitlang/quickcheck` `0.14.0` に依存しています。
- **現行 Moon パッケージメタデータ**: このリポジトリは、現在のツールチェインにおける正規のパッケージマニフェストとして `moon.mod` を持っています。
- **リリース確認フロー**: publish workflow は `moon.mod` と完全一致する明示的なバージョン入力を要求し、正規 manifest と release 入力を一致させます。
- **Benchmark ハーネスとダッシュボード**: fixture 駆動の benchmark harness、ローカル web dashboard、任意の Rust baseline、定期実行される GitHub Actions benchmark workflow を備えています。

### API 指針と性能

- **コア代数 API**: `make`、`transpose`、`+`、`-`、`*`、`trace`、行列/ベクトル変換などの共有操作は、`immut` と `mutable` の間で意味論を揃える方針です。
- **ランダムアクセス**: `mutable` で高頻度ランダムアクセスが必要な場合は `.get(i, j)` と `.set(i, j, val)` を優先してください。
- **構造化ビュー**: `mutable` で特定の行・列を繰り返し扱うなら、`matrix[row]` の便宜構文より `row_view()` / `col_view()` を優先してください。
- **公開面**: 内部の分解補助関数は依然として実装詳細です。利用者は文書化された公開行列メソッドを使うべきです。

### 主な機能

- **可変・不変の両対応**: 値指向ワークロードと実行指向ワークロードに分かれた完全な `Matrix` / `Vector` 群。
- **高度な演算**: determinant、inverse、rank、Cholesky decomposition、eigen 関連ルーチン、row elimination、transpose view、行列/ベクトル変換を含みます。
- **共有データモデル + バックエンド最適化カーネル**: `mutable` は Native、Wasm、JS、Wasm GC 向けの最適化実行経路を維持しつつ、コア行列ストレージモデルは統一されています。
- **Benchmark 基盤**: `bench/`、`src/perf_support`、`src/perf_runner` が、バックエンド比較と診断再現のための完全な steady-state benchmark サブシステムを構成しています。
- **正しさ優先**: 不変法則、パッケージ間整合性、determinant/rank/inverse の整合、数値挙動の回帰テストを含むカバレッジを備えています。

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
| `0.2.10` | 2026-05-27 | 現在のパッケージ基準 | 統一フラット mutable ストレージ、行列ビュー、整合性カバレッジ、benchmark 拡張、リリース手順整合 |
| `0.2.9` | 2026-02-03 | mooncakes 公開済み | 以前の `3328195` リリース状態から公開 |
| `0.2.8` | 2026-02-03 | 歴史的基準 | 後続作業のアルゴリズム・安定性比較の基準 |

## 現在のリポジトリのハイライト

- **現在のリリース叙述（0.2.10）**:
  - `mutable.Matrix` は、バックエンドをまたぐ共有フラットストレージモデルを中心に文書化されています。
  - `RowView` / `ColView`、パッケージ間整合性カバレッジ、専用 `wasm-gc` サポート、数値修正が現行メインラインの一部になっています。
  - 対称 eigen の性能改善、trait 境界整理、完全な benchmark harness / dashboard workflow は現行リポジトリ基準の一部です。
  - ドキュメント、リリースチェックリスト、依存関係の説明、benchmark workflow、そして正規の `moon.mod` メタデータ運用は現在の実装状態に整合しています。

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
4. `publish-package` を起動し、`moon.mod` と完全一致するバージョン文字列を workflow 入力へ指定する。

workflow が重複バージョンを報告した場合、そのバージョンは既に登録されています。先に新しいバージョンへ bump してください。

コントリビューション案内は [CONTRIBUTING.md](./CONTRIBUTING.md) を参照してください。
