# API 開発基盤

Ruby 3.4.11 / Bundler 4.0.22。リポジトリルートの ENV/DEVELOPMENT.md も参照。

```
bundle install
bin/check
bin/rails zeitwerk:check
bin/rails server -b 127.0.0.1 -p 3001
```

`GET /up` は DB に触れず 200。`GET /health` は DB 準備状態 (200/503) を返す。
診断以外の API は既定 403。`ENABLE_DIAGNOSTIC_FIXTURES=1` かつ development/test のみ
`POST /fixtures/probes` (`key: fixture-<UUID>`, `outcome: success|failure`) と
`GET /fixtures/probes/:id` が有効。production では同設定でも無効。

事前に提供された許可済み PostgreSQL の DATABASE_URL に対してのみ `bin/rails db:migrate`。
DB 作成・drop/reset は行わない。Solid Queue のテーブルも同じ DB の migration に含める。
別ターミナルで `bin/jobs` を実行。ジョブ投入と検証用レコード保存は同一トランザクション。
key の UNIQUE 制約とロックで再投入を抑止し、完了済みジョブの再実行も無害。

DB 統合テストには専用の TEST_DATABASE_URL が必要。開発 DB と同じ接続先は拒否する。
ホスト別名で同一 DB を指すケースは URL だけでは完全判定できないため、運用上も専用 DB を保証する。
URL の query による接続先上書き、複数 host、socket パスは拒否する。

```
RAILS_ENV=test bin/rails db:migrate
RAILS_ENV=test bin/jobs
# 別ターミナル、同じ TEST_DATABASE_URL:
bin/rails test
```

Rails の自動 schema 維持/fixture cleanup は使わず、テストが作った架空レコードを保持する。
DB がない場合 `bin/check` は実行できるが `bin/rails test` は失敗終了し、統合確認済みとはしない。
`bin/check` の request test は in-process Rack リクエストで HTTP socket startup の代替ではない。

4 AI 処理の adapter はすべて disabled。資料 allowlist は分類境界の単体試験のみで、
実際の個人情報検出・認可・全製品の機密保護を実装したものではない。

## この専用環境で実測したツールチェーン構築

システム Ruby がないため `/workspace/toolchains/ruby` にだけインストールした。
GCC、make、OpenSSL/zlib headers は環境に既存。libyaml 0.2.5 は
[公式 release](https://github.com/yaml/libyaml/releases/tag/0.2.5) の tar.gz を展開して
`./configure --prefix=/workspace/toolchains/ruby`、`make -j4`、`make install`。
Ruby は[公式 3.4.11 配布](https://www.ruby-lang.org/en/news/2026/09/23/ruby-3-4-11-released/)の
`https://cache.ruby-lang.org/pub/ruby/3.4/ruby-3.4.11.tar.gz` を展開し、次を実行した。

```
./configure --prefix=/workspace/toolchains/ruby --disable-install-doc --with-libyaml-dir=/workspace/toolchains/ruby
make -j4
make install
export PATH=/workspace/toolchains/ruby/bin:$PATH
```

取得済み Ruby tar.gz の SHA-256 は公式掲載値
`5c22be44524312b3d433d68739bcc530633b1da5ef8ba0afa0a37680da17d3de` と一致確認済み。
Bundler は `https://rubygems.org/downloads/bundler-4.0.22.gem` を curl で取得し、
`gem install /tmp/bundler.gem --local --no-document` で導入した。

この環境では Bundler の `index.rubygems.org` への自動置換先が 403、公式
`rubygems.org` の compact index は 200 だった。初回 install のみ、次の内容のローカル
一時ファイルを Ruby の `-r` で読み込み、同じ公式 registry の元 URL を使用して解決した。

```ruby
require 'bundler'
require 'bundler/fetcher'
class Bundler::Fetcher::Base
  def fetch_uri = remote_uri
end
```

実行は `RUBYOPT=-r/tmp/bundler-direct.rb BUNDLE_USER_HOME=/workspace/toolchains/bundle-home bundle install`。
これは専用環境で確認した補助手順で、アプリ設定・lock の source・proxy 設定・証明書検証は変更していない。
通常環境は通常の `bundle install` を使用する。この環境でも導入後の通常の `bundle install` は成功した。
HOME が read-only の監査は `bundle exec bundler-audit check --update --database /workspace/toolchains/ruby-advisory-db`
で実行した。DB 不在の実接続チェックは、この構築が成功しても未実施のまま。
