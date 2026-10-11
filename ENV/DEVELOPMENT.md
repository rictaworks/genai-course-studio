# 開発環境

2026年10月11日（JST）に公式情報・配布レジストリを確認しています。対象は Issue #1 の開発基盤です。製品機能、公開、デプロイは対象外です。

## 採用構成と固定バージョン

| 用途 | バージョン | 選定根拠 |
| --- | --- | --- |
| Node.js | 24.21.0 LTS | [公式配布一覧](https://nodejs.org/dist/index.json)で LTS と配布物を確認しています。 |
| npm | 11.19.0 | Node.js 24.21.0 同梱版を使用します。 |
| Next.js | 16.4.0 | [npm 公式レジストリ](https://registry.npmjs.org/next/16.4.0)で配布を確認しています。Node.js 要件は 20.9.0 以上です。 |
| React / React DOM | 19.3.0 | [React 公式ブログ](https://react.dev/blog)とレジストリで安定版を確認しています。 |
| Ruby | 3.4.11 | [公式ダウンロード](https://www.ruby-lang.org/en/downloads/)で通常保守対象の安定系列を選んでいます。 |
| Rails API | 8.1.4 | [RubyGems](https://rubygems.org/gems/rails/versions/8.1.4)で配布を確認しています。[保守方針](https://rubyonrails.org/maintenance)上、8.1 系は2027年10月10日までセキュリティ修正対象です。 |
| Active Job / Solid Queue | Rails 同梱 / 1.7.0 | [Solid Queue](https://rubygems.org/gems/solid_queue/versions/1.7.0)を独立 worker プロセスで動かします。 |
| Bundler | 4.0.22 | [RubyGems](https://rubygems.org/gems/bundler/versions/4.0.22)で確認しています。Ruby 3.2 以上、RubyGems 3.4.1 以上が必要です。 |
| PostgreSQL | 18.6 | [公式保守表](https://www.postgresql.org/support/versioning/)の最新18系です。系列の保守期限は2030年11月14日です。サーバーは本環境に追加していません。 |

Node.js はこの専用環境の `/workspace/toolchains/node` に配置し、公式 SHA-256 との照合を実施しています。Ruby と gem の導入・実行結果は検証記録で区別します。バージョンの配布確認は、アプリ起動や DB 接続の成功を意味しません。

## セキュリティ情報の確認

- [Node.js 2026年7月の修正](https://nodejs.org/en/blog/vulnerability/july-2026-security-releases)は24.18.1で提供されています。採用版はこの修正後です。
- [Next.js 2026年9月22日の修正](https://nextjs.org/blog/nextjs-security-update-september-22-2026)は `next/og` の Node.js ImageResponse に関する RCE を16.3.6で修正しています。16.4.0は影響範囲外です。
- [React Server Components の追加修正](https://react.dev/blog/2025/12/11/denial-of-service-and-source-code-exposure-in-react-server-components)では古い修正版にも追加更新が必要とされています。React / Next.js の両方を固定し、依存監査を実行します。
- [Rails Active Storage の重大な修正](https://github.com/rails/rails/security/advisories/GHSA-xr9x-r78c-5hrm)は8.1.3.1で提供されています。8.1.4を採用し、この基盤では画像変換を実装しません。
- [Ruby resolv の修正](https://www.ruby-lang.org/en/news/2026/08/27/multiple-vulnerabilities-in-resolv/)は0.7.2です。古い同梱版に依存しないよう依存解決と監査で確認します。
- [PostgreSQL の脆弱性一覧](https://www.postgresql.org/support/security/)にある最新修正を含む18.6を指定しています。
- [Solid Queue の公式 advisory 一覧](https://github.com/rails/solid_queue/security/advisories)には確認時点で公開 advisory がありません。これは脆弱性が存在しないことの保証ではありません。

## 実行範囲とデータベース

`rictaworks/context/setup/Claude/DC.md` に従い、開発コンテナへ DB / Redis を同居させず、Docker デーモン・DinD・DooD を追加しません。本作業では外部 DB の新規作成、有料サービス、本番資格情報、OAuth 権限、ネットワーク設定変更を行いません。

既存の許可済み開発 PostgreSQL に接続できる場合のみ、環境変数で接続先を渡します。資格情報や実 URL は文書・ログ・コミットへ保存しません。開発用とテスト用の DB は分離します。DB が提供されていない場合、DB migration・永続化・キュー実行の統合テストは阻害要因として明記します。モックによるテストを DB 起動成功として扱いません。

外部 AI、ストレージ、認証は無効アダプターを使用します。実サービスへの要求を開始するキーは設定しません。

## ワークフロー

Issue #1（環境構築）を先行し、Issue #2（最小 scaffold）をその上に積みます。`requirements.md` を変更しません。通常レビューとセキュリティレビューの結果、実行できた検査と未実行の検査を PR に記録します。今回の明示された承認範囲に従い、Draft PR までとし、マージ・Issue close・デプロイは実施しません。

専用環境の `/workspace/.agents` は空で、リポジトリにも `.agents/skills` はありませんでした。指定された開発・レビュー skill の実体を取得できないため、サブエージェントで既存の workflow / security-review 規則を読み、実施内容と制約を記録します。

## 環境変数（値は記載しません）

| 変数 | 用途 |
| --- | --- |
| DATABASE_URL | 事前に許可された開発 PostgreSQL への接続です。未設定なら準備状態が503になります。 |
| TEST_DATABASE_URL | 開発DBと異なる許可済みテストDBです。DB試験に必須です。 |
| ENABLE_DIAGNOSTIC_FIXTURES | 明示した開発・テスト用fixtureの有効化です。本番では利用できません。 |
| SECRET_KEY_BASE | 将来の本番ランタイム用です。この作業では本番シークレットを発行しません。 |

`.env.example` は項目の説明用です。シェルに必要な値を安全に設定し、ログやコミットに出力しないでください。起動コマンドはシェルに設定された環境変数を使用します。

## 専用環境で確認したツール導入

Node.js公式の `v24.21.0/node-v24.21.0-linux-x64.tar.xz` を取得し、同じ配布ディレクトリの `SHASUMS256.txt` と照合して展開しました。この環境では次の操作が実行済みです。

```sh
export PATH=/workspace/toolchains/node/bin:$PATH
node --version  # v24.21.0
npm --version   # 11.19.0
```

Ruby 3.4.11 は #1 時点では構築中でした（#2 作業で構築・公式SHA-256照合が完了しました）。アプリの install/start コマンドと実測結果は後続 #2 の記録に追記します。#1 時点では Web/API/worker の起動完了を主張しません。

[Next.js 10月14日セキュリティ更新予告](https://nextjs.org/blog/upcoming-nextjs-security-update-october-2026)について、確認日の10月11日時点では詳細未公表です。本番公開前には公式 advisory と修正版を再確認する必要があります。本作業では公開しません。

## #2 実際の依存導入・起動手順

専用環境では Node と Ruby を `/workspace/toolchains/` 以下に導入しました。Ruby は公式ソースから構築し、OS全体へ依存を追加していません。

```sh
export PATH=/workspace/toolchains/node/bin:/workspace/toolchains/ruby/bin:$PATH
export npm_config_cache=/workspace/npm-cache
cd /workspace/genai-course-studio/src/web
npm ci
npm run dev -- --hostname 127.0.0.1 --port 3000
```

API は別ターミナルで `src/api` から `bundle install` と `bin/rails server -b 127.0.0.1 -p 3001` を使用します。正確な実行結果は [検証記録](../WORK/foundation-validation.md) に記載しています。

ブラウザテストは `src/web` で `npm run test:e2e` を実行します。本環境は Playwright のブラウザ配布へのアクセスが403となったため、既存 Chromium に `PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH=/usr/bin/chromium` を設定して成功しました。ネットワーク設定を変更していません。

DBが提供された場合だけ、開発DBへ `bin/rails db:migrate` を実行し、別ターミナルで `bin/jobs` を起動します。テスト側は別の `TEST_DATABASE_URL` を設定し、`RAILS_ENV=test bin/rails db:migrate` の後に別ターミナルで `RAILS_ENV=test bin/jobs` を起動し、`bin/rails test` を実行します。再実行時にDB作成やresetは不要です。fixture試験の架空レコードは保持します。

`DATABASE_URL` / `TEST_DATABASE_URL` は現在未提供のため、上記DB手順の実行・migration再実行・永続化・別worker成功/失敗試験は未検証です。CIもこれらを成功扱いせず、`scripts/check` のDB検査が非ゼロになります。

Ruby構築とこの環境で必要だった初回Bundler取得手順は [API開発基盤](../src/api/README.md) に記録しています。Ruby archive SHA-256は公式の `5c22be44524312b3d433d68739bcc530633b1da5ef8ba0afa0a37680da17d3de` と一致しました。
