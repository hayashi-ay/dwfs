# 概要

Dockerの練習としてdebianのイメージからWordPressを構築したのでその際に参考にしたリンクなどを備忘としてまとめておきます。

## how to setup

```bash
# .envファイルを作成する。必要に応じて値を変える。
cp .env.example .env

# ディレクトリを作成
mkdir -p $HOME/data
mkdir -p $HOME/data/database
mkdir -p $HOME/data/website

# 証明証の作成
#openssl version
#> OpenSSL 3.0.5 5 Jul 2022 (Library: OpenSSL 3.0.5 5 Jul 2022)

openssl genpkey -algorithm RSA -out nginx/ssl/server.key
openssl req -x509 -key nginx/ssl/server.key -out nginx/ssl/server.cert -subj "/C=JA/ST=Tokyo/L=Minato/O=Hayapenguin/CN=local.hayapenguin.com"

# dnsの設定。直接/etc/hostsを書き換えてもよい。
grep -q local.hayapenguin.com /etc/hosts || sudo echo "127.0.0.1 local.hayapenguin.com" | sudo tee -a /etc/hosts
docker compose up
```

https://local.hayapenguin.com/にアクセスできる。
自己証明書の警告が出るので無視をする。Chromeなどでは`this is unsafe`とタイプすれば良い。

## 参考実装
- https://github.com/MariaDB/mariadb-docker
- https://github.com/nginxinc/docker-nginx
- https://github.com/docker-library/php
- https://github.com/docker-library/wordpress

主にmariadbとnginxの公式のDockerfileを参考にしました。
テンプレートのDockerfileがあり、バージョンごとに可変な部分をパラメータとして与えて自動生成しています。
見る場合はテンプレートの方ではなく、生成物の方が良いと思います。

```
# mariadb-dockerの構造。説明に必要ない部分は除外している
.
├── 10.9 -- 各バージョンごとのDockerfile
│   ├── Dockerfile
│   ├── docker-entrypoint.sh
│   └── healthcheck.sh
├── Dockerfile.template -- テンプレート
├── docker-entrypoint.sh -- テンプレート
├── generate-stackbrew-library.sh
├── healthcheck.sh -- テンプレート
└── update.sh -- 自動生成用スクリプト
```

## Docker全般
- https://docs.docker.com/engine/api/latest/
docker engineのAPI
- https://docs.docker.com/engine/reference/builder/
dockerfileの構文について
- https://docs.docker.com/compose/compose-file
docker compose

Docker EngineのAPIドキュメントを見てどういったことができるのかを大まかに把握して、Dockerfile, compose-fileのドキュメントを見て実際にDockerfile, compose.yamlでどう書くかを調べる感じで進めました。
dockerに限らずクライアントとバックエンドに分かれているサービスでバックエンドのAPIが公開されている場合は、クライアントツール側のドキュメントを読むよりバックエンドAPIのドキュメントを読む方が目的に早く到達できる所感があります。

### Dockerfileのベストプラクティス
- https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- https://sysdig.com/blog/dockerfile-best-practices/
セキュリティ周りでのtipsが書かれている。
- https://github.com/hadolint/hadolint
Dockerfileの静的解析ツール。
- https://hadolint.github.io/hadolint/
hadolintをオンラインで実行可能なページ。

### Shell Form vs Exec Form
- https://stackoverflow.com/questions/47904974/what-are-shell-form-and-exec-form
- https://emmer.dev/blog/docker-shell-vs.-exec-form/

RUN, ENTRYPOINT, CMDでそれぞれShell FormまたはExec Formを使うべきかの参考にしました。

### network
- https://docs.docker.com/network/
- https://docs.docker.com/compose/networking/
- https://docs.docker.com/network/bridge/

### volume
- https://docs.docker.com/storage/volumes/
- https://man7.org/linux/man-pages/man8/mount.8.html
mountシステムコールのmanページ。
- https://github.com/moby/moby/blob/master/volume/local/local_unix.go#L32
mobyの実装。
- https://github.com/util-linux/util-linux/tree/master/libmount
mountシステムコールの実装。

localマウントする際の`driver_opts`がドキュメントに特に記述もないけれど、みんなが`type:none, o: bind`を使っているのが不思議で調べました。
unixに詳しい人がハック的な感じで使った解決策が広く広まったみたいな感じに思えます。

```bash
volumes:
  website:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: "${VOLUME_PATH}/website"
```

### env
- https://docs.docker.com/compose/environment-variables/
- https://docs.docker.com/compose/envvars-precedence/

Dockerでは複数の場所、タイミングでenvを指定できるので、最終的にどのenv値が適用されているが分かりづらかったです。

## nginx
- https://nginx.org/en/docs/
公式のドキュメント。
- https://nginx.org/en/docs/dirindex.html
ディレクティブ一覧ページ。
- https://www.nginx.com/resources/wiki/start/topics/tutorials/config_pitfalls/
設定のべからず集。

nginxのディレクティブの設定はモジュールごとに分かれている記述されていますが、どのディレクティブがどのモジュールに属しているかが分かりにくいのでディレクティブ一覧ページから探すのが良いと思います。

### FastCGI
- https://www.nginx.com/resources/wiki/start/topics/examples/phpfcgi/
公式のサンプル。
- https://www.ietf.org/rfc/rfc3875
CGIのRFC。
- https://fastcgi-archives.github.io/
FastCGIの情報のバックアップサイト。

FastCGIについては公式のサンプルだけで充分でした。
一応CGIプログラムがどのような値が渡ってくることを期待しているのかを把握するためにCGIのRFCも軽く目を通しました。

### SSL/TLS
https://nginx.org/en/docs/http/configuring_https_servers.html
公式の記事。
- https://qiita.com/TakahikoKawasaki/items/4c35ac38c52978805c69
Authleteの川崎によるX.509証明証についての記事。
- https://www.rfc-editor.org/rfc/rfc5280
X.509証明証についてのRFC。
- https://www.openssl.org/docs/manmaster/man1/openssl.html
OpenSSLのman。
- https://www.libressl.org/
MacOSで標準で入ってるSSL/TLSソフトウェア。

SSL/TLSについても公式の記事だけで充分でした。
あまり証明証周りについても調べました。
証明証の作成にopensslを使ったのですが、今思うとMacOS標準で入っているLibreSSLでも良かったかもです。

## mariadb
- https://mariadb.com/kb/en/
公式のドキュメント。
- https://salsa.debian.org/mariadb-team/mariadb-10.5
debianのMariaDB10.5の公式レポジトリ。

mariadbの公式ドキュメントはかなり分かりづらいので読むのを断念しました。
その他のネット検索で出てくる記事も有益なものが見つけれなかったので先述のmariadbのDockerライブラリの実装を参考にしました。
またaptでのインストール前後で行われている処理も確認しにいきました。mariadb-10.5レポジトリの`debian/mariadb-server-10.5.preinst`や`debian/mariadb-server-10.5.postinst`あたりをみました。

## WordPress
- https://wp-cli.org/

WordPressの構築はWP-CLIで行いました。公式ドキュメントがしっかり書かれているのでほかは特に参考にしませんでした。

## php-fpm
- https://php-fpm.org/
- https://www.php.net/manual/en/install.fpm.php

一応リンクは貼っていますが、あまりドキュメントを参考にしませんでした。
aptでインストールしてくる際にあるwww.confにあるコメントを見ながら必要に応じて設定値を変えました。

## bash
- https://www.gnu.org/savannah-checkouts/gnu/bash/manual/bash.html
GNU版bashのドキュメント。
- https://sipb.mit.edu/doc/safe-shell/
- https://github.com/koalaman/shellcheck
shellの静的解析ツール。

Dockerfileやdocker-entrypoint.shなどでシェルスクリプトを書く機会が多かったので参考にしました。

## Makefile
- https://www.gnu.org/software/make/manual/make.html#toc-Overview-of-make
GNU版makeのドキュメント。
- https://zenn.dev/canalun/articles/7d31ba0fb12be2
Makefileでenvを読み込む方法について。

元々は初期化処理をMakefileの中で書いていて.envを読み込みたかったので参考にしました。結局/etc/hostsを書き換えたりちゃんとわかっていないと危ない処理が結構多かったのでMakefileからは削除して手順をREADME.mdに移行するのにあたって不要になりました。
