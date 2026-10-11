# #1 開発環境の準備

- 原本 `requirements.md` は参照専用です。SHA-256: `0011eef63c753bd6352a26f0cc1df4fb30c5aa698f6818b8dc47d5a8a7b2c4c5`。
- 作業場所: `/workspace/genai-course-studio` の専用環境です。
- 環境構築 #1 と実装 #2 を別ブランチ・別コミットで管理します。#2 は #1 の変更に積み重ねます。
- `rictaworks/context` の `8f1ed19bd075c89a3f445141ba8123591d895b92` にある `setup/Claude/Manager.md`, `ClaudeCode.md`, `CLAUDE.md`, `WF.md`, `DC.md`, `TEST-HARNESS-SAFETY.md`, `docs/*`, `QC10.md`, `OWASP10.md` を確認しました。
- 今回の明示指示を優先し、マージ・デプロイ・外部DB作成・SQLite代替・実OAuth・AI送信は行いません。
- executor の skills カタログは空、`/workspace/.agents` に skills はありません。通常レビュー・セキュリティレビューは記載済みチェックリストをサブエージェントで実施します。未提供スキルの実行済みとは報告しません。
- `DATABASE_URL` と `TEST_DATABASE_URL` は未提供です。実DB・永続キュー試験はブロックされています。環境変数の値は出力していません。
