# 生成AI研修 講座開発スタジオ — 開発基盤

Next.js の日本語起動画面、Rails API の診断、PostgreSQL / Solid Queue の検証用ジョブを用意しています。製品機能や認証基盤はまだ実装していません。原本は [requirements.md](requirements.md) です。

## 起動

Node 24.21.0、npm 11.19.0、Ruby 3.4.11、Bundler 4.0.22 を使用します。

```sh
cd src/web
npm ci
npm run dev -- --hostname 127.0.0.1 --port 3000
```

別ターミナルで API を起動します。

```sh
cd src/api
bundle install
bin/rails server -b 127.0.0.1 -p 3001
```

ブラウザで [起動画面](http://127.0.0.1:3000) を開きます。自動ログインはありません。診断以外のAPIは既定で閉じています。DB が未設定でも画面と生存確認は応答し、DB は利用不可と表示されます。APIを停止すると画面に接続不可が表示されます。

| API | URL |
| --- | --- |
| 生存確認 | [GET /up](http://127.0.0.1:3001/up) |
| DB準備状態 | [GET /health](http://127.0.0.1:3001/health) |
| 同一オリジンの固定診断経路 | [GET /api/health](http://127.0.0.1:3000/api/health) |

開発/テストの明示fixtureは [API手順](src/api/README.md) に記載しています。AI処理のアダプターは無効です。

## DB・ワーカー・検証

[ENV/DEVELOPMENT.md](ENV/DEVELOPMENT.md) の制約と [API手順](src/api/README.md) に従い、事前に許可された開発DBと別のテストDBを指定します。DBの新規作成や破壊的リセットは行いません。

```sh
cd src/api
bin/rails db:migrate
bin/jobs
```

`bin/jobs` は API と別プロセスで起動します。DB が提供されていない場合、この手順は未検証です。SQLiteやメモリキューへ切り替えません。

ルートで `scripts/check` を実行すると各検査を順番に実行します。DB統合試験は別の `TEST_DATABASE_URL` と稼働中のテストworkerが必要です。未提供なら非ゼロ終了し、全検査成功とは表示しません。個別の実行結果と残事項は [WORK/foundation-validation.md](WORK/foundation-validation.md) に記録します。
