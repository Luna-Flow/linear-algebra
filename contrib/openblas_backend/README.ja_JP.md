# OpenBLAS バックエンド（一時撤回）

[English](./README.md) | [简体中文](./README.zh_CN.md)

このディレクトリは旧 `Luna-Flow/linear-algebra/backends/openblas` パッケージを保存しています。
`Float` / `Double` 向けの `BlasMatrix[T]` と `BlasVector[T]` を提供していた native 専用の
OpenBLAS バックエンドです。`src/` の外にあるため、モジュールと一緒にビルド・テスト・公開は
**されません**。リポジトリの他の部分には影響しません。

## 撤回の理由

このバックエンドは `Kaida-Amethyst/openblas` `0.1.3`（最新公開版）に依存しています。
このパッケージは MoonBit 0.10 で削除された `typealias` 構文を `cblas/cblas.mbt` の
86、97、220 行付近で使っており、native ビルドが構文解析で失敗します。そのため
モジュール全体の `moon check --target all` が失敗し、`src/doc_*` ドキュメントパッケージも
native 専用になっていました。撤回により、ドキュメントを含む残りの全パッケージが
`wasm-gc`、`js`、`native`、`wasm` でビルド・テストできます。上流の修正版はまだありません。

## 内容

- `src/`: MoonBit 0.10 移行後のソース（`extends.mbt`、`openblas_wbtest.mbt`、`moon.pkg` を含む）。
- `doc/{en_US,zh_CN,ja_JP}/`: 旧 `doc/<locale>/backends/openblas/*` ページ（撤回中と明記）。
- `openblas_0.1.3_typealias.patch`: 3 つの宣言を `pub type Alias = Target` に書き換えるパッチ。

ローカルでパッチを当てた `0.1.3` で検証済みです。native チェックで警告なし、
native テスト 15 件とドキュメントのコンパイル例 12 件がすべて成功しました。

## 再有効化の手順

1. `mv contrib/openblas_backend/src src/backends/openblas`
2. MoonBit 0.10 でコンパイルできる `Kaida-Amethyst/openblas` を `moon.mod` に再追加する。
3. ドキュメントを `doc/<locale>/backends/openblas/` に戻す。`src/doc_*` に
   `backends/openblas` を再追加せず、native 専用の別ドキュメントパッケージで公開することを推奨します。
4. CI（`libopenblas-dev` のインストールと `moon test src/backends/openblas --target native`）を戻す。
5. README、`doc/*/README.md`、`doc/*/container/*`、`CHANGELOG.md` を更新する。

ローカルで試す場合は、依存の取得後に次を実行します（ローカル実験専用）:
`patch .mooncakes/Kaida-Amethyst/openblas/cblas/cblas.mbt < contrib/openblas_backend/openblas_0.1.3_typealias.patch`

## 別の公開先

バックエンドを `openblas.mbt` プロジェクトに引き渡し、バインディングと `linear-algebra`
連携を一緒に公開する選択肢もあります。
