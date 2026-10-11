# 開発基盤の検証記録

2026年10月11日（JST）。#1 / #2 の draft 向け記録です。全起動成功・全受入条件完了を意味しません。

## 順序と境界

計画→失敗テスト→実装→成功テストの順です。APIは未実装 `material_policy` の LoadError、Webは未実装 `app/api/health/route` のimport失敗を確認してから実装しました。架空データ以外を投入していません。`requirements.md` のSHA-256は `0011eef63c753bd6352a26f0cc1df4fb30c5aa698f6818b8dc47d5a8a7b2c4c5` と一致します。

## 実測結果

| 検査 | 結果 |
| --- | --- |
| Node 24.21.0 / npm 11.19.0 | 実行成功、Node配布物の公式SHA-256一致です。 |
| Ruby 3.4.11 | 専用環境内でソース構築に成功しました。 |
| Web `npm ci` | 成功しました。 |
| Web lint / typecheck / build | すべて成功しました。 |
| Web unit | 6件成功しました。 |
| Web browser smoke | Chromiumによる4件が成功しました。 |
| Web `npm audit` | 脆弱性0件です。 |
| API `bundle install` | 89 gems導入、Gemfile.lock固定に成功しました。 |
| API `bin/check` | DB不要の9件・27 assertions、失敗/エラー/skip 0です。 |
| API RuboCop / zeitwerk | 29ファイル違反0件、autoload成功です。 |
| Brakeman 8.1.0 | warning/error 0件です。 |
| Bundler audit | 脆弱性0件、advisory DB `a6847b0651a702488f5844081e848dd1ec9dbf1d` です。 |
| 実HTTP | Web200、Rails /up200、Rails readiness503、Web proxy503、fixture403です。 |
| `scripts/check` 最終実行 | DB検査以外は成功、DB URL未提供の拒否で終了コード1です。 |
| PostgreSQL migration・再実行 | DB未提供のため未実施です。 |
| PostgreSQL永続化・重複投入・別worker成功/失敗 | DB未提供のため未実施です。 |

Webブラウザ試験の1件は実際の開発サーバーと `/api/health` を使います。API未起動とAPI起動済み/DBなしの両方で実行済みです。他の3件はAPI切断・DB未設定・DB準備済みの表示を明示的にシミュレーションしたものです。DB接続成功の証拠にはしません。Chromium配布の取得は403だったため、既存の `/usr/bin/chromium` を使用しました。

初回の開発依存監査で `eslint-config-next` 経由の脆弱な依存が見つかり、不要なpresetを外してTypeScriptとReact hooksのlintへ変更しました。最終監査は0件です。ブラウザbundleに内部API URLやDB変数が含まれないことも検査しています。

## 通常レビュー・セキュリティレビュー

環境差分のレビューで、ルートのignoreがネストしたRails秘密鍵に効かない問題を発見しました。再帰パターンへ修正し、`git check-ignore` で確認後、独立再レビューで重大な問題なしとなりました。コードの通常レビューとその後の独立セキュリティレビューでも重大な問題は見つかりませんでした。DB実行による保証は含みません。

利用可能な開発skillの実体はありませんでした。サブエージェントが参照リポジトリの通常レビュー・セキュリティチェックリストを使用しました。skill実行済みとは扱いません。

## ブラウザだけの確認手順

1. 開発担当がREADMEのWeb/APIコマンドで起動します。公開デプロイはしません。
2. ブラウザで `http://127.0.0.1:3000` を開き、「講座開発スタジオ」と外部AI送信が無効である説明を確認します。
3. 現状はDBがないため、DBの未設定・接続不可とworker未検証が表示されます。
4. 開発担当がAPIを停止し、ブラウザの「状態を再確認」を押すとAPI接続不可になります。
5. APIを再起動し、同じボタンでDB未設定の状態に戻ることを確認します。
6. `http://127.0.0.1:3001/up` はAPI稼働時200、`http://127.0.0.1:3000/api/health` はDB未提供時503です。ブラウザの開発者ツールのネットワーク欄で確認できます。

診断fixtureの結果は有効化済みの開発/テスト環境で `/fixtures/probes/:id` に表示されます。実ジョブ成功/失敗のブラウザ確認は、許可済みDBと別workerが提供されてからです。

## 阻害要因

許可済み `DATABASE_URL` と別の `TEST_DATABASE_URL` が未提供です。DBやworkerを代替せず、DB検査は非ゼロで拒否します。CIもDBがない状態を全成功にはしません。Next.jsは10月14日の公式セキュリティ更新予告があるため、本番公開前の再確認が必要です。今回マージ・公開・実OAuth・AI送信は行いません。

## 実行中に修正した検査環境の問題

最初の一括実行では、手動HTTP検証のNext.jsが3000番に残りブラウザテストが拒否されました。自分で起動したプロセスを終了して再実行し成功しています。またBundler auditの既定保存先は読み取り専用のHOMEだったため、チェック入口でignoredな `src/api/tmp/ruby-advisory-db` を明示し、再実行して成功しました。最終の一括検査はDB未提供による拒否だけが非ゼロです。

最初のgem取得は環境のプロキシが `index.rubygems.org` を403にしたため、Bundlerの当該プロセスだけ取得先を公式 `rubygems.org` のcompact indexに保ちました。ネットワーク設定・TLS検証・lockfileの公式sourceは変更していません。実行後の通常 `bundle install` は成功しました。

コミット前にレビュー済みstaged treeと一致することを確認するローカルhookを設置しました。ローカルmerge hookも今回のマージ禁止を守るため終了コード1にしています。これらは本環境の補助であり、GitHubの権限やbranch protectionを変更していません。

Next.jsが生成した `src/web/AGENTS.md` と同梱TypeScript手順に従い、`next-env.d.ts` はignoreし、型検査を `next typegen && tsc --noEmit` にしました。変更後のtypecheck/lintも成功しています。

## CI起動パスの修正

初回CI run `38123856372` は `ruby/setup-ruby` がAPIの作業ディレクトリから `.ruby-version` を開き、ENOENTで停止しました。npm ci / browser / scripts/checkはskipされていました。ルートでバージョンを読み、出力値をsetup-rubyへ渡すように修正しました。Gemfileの作業ディレクトリはsrc/apiのままです。

回帰テスト `test/workflow_test.rb` は実workflowの読み取りコマンドを実行して、ルートの固定版とaction入力の結線、Gemfile.lockの存在を検証します。修正前1件失敗、修正後1件7 assertions成功、APIのRuboCop規約でも違反0です。`scripts/check` に組み込みました。DB検証をskip成功に変える修正は行っていません。

次のCI run `38124103223` ではRuby setup、npm ci、Chromium準備、Web/ブラウザ検査、APIテスト、監査が成功しました。Zeitwerkで別の起動順序不具合（Bundler前にDB安全チェックがdefault uri 1.0.4を読み、lockの1.1.2と衝突）が判明しました。`bin/rails` と `bin/jobs` は最初にconfig/bootを読み、その後でDB安全チェックを実行するよう修正しました。Rails環境やDB接続より前の拒否は維持します。

`test/api_boot_test.rb` は実entrypointの子プロセスをTracePointで観測します。Bundler初期化順と、DB未設定の拒否を確認し、REDからGREEN（1件10 assertions）になりました。Zeitwerk、API9件27 assertions、変更ファイルlintも成功しました。
