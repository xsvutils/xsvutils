# CHANGELOG

To see version information, `xsvutils --version`.

To see compatibility information, `xsvutils help compatibility`.

## v14 -> v20 (2020/04/30)

### 設計変更

大幅に設計が変わりました。シングルバイナリではなくなりました。
その代わりmakeすることなく、ソースをgit cloneするだけで実行できるようになりました。
一部の機能のみ使用前にバイナリのビルドが必要となります。
詳しくは `xsvutils help install` を見てください。

2019年9月ごろはメンテのしづらくなっていた main.pl に替わる新しいパーサを開発しようとし、
その準備としてJVM削除などの更新をしていました。
しかし、それも過剰に複雑になってしまい更新が止まってしまいましたので、
当時の更新のうち意味のある修正のみでv14をリリースしました。
そして再度設計を見直したのが今回のv20のリリースです。

設計を大幅に変更するにあたって、いったん全機能を無効にした上で再構築しています。
再構築後にまだ復活していないサブコマンドも多くあります。
互換性を崩す仕様変更も多いです。

サブコマンドのパラメータやオプションの仕様は
互換性を崩してでもサブコマンド間でできるだけ統一するように変更し、
パーサの実装をできるだけ単純化しました。

サブコマンド間の内部でのデータ形式としてTSV以外も扱えるようになりました。
v20では一部はJSONを扱っています。

サブコマンド間での協調動作の実装もしやすくなりました。
v20ではoffsetなどと最後のテーブル形式出力は協調します。

-v14 のような旧バージョンを動作させるオプションは使えますが、事前にビルドが必要です。
詳しくは `xsvutils help install` を見てください。


### 仕様変更箇所

設計変更の経緯のため機能的な変更点も非常に多い。
わかっている変更点は以下の通り。
他にも変更箇所のある可能性はある。

以下のサブコマンドが追加された。
- offset-random
- filter-record
- col
- ins-concat
- uniq
- trim-values
- rename-duplicated-column-name
- modify-record
- jq
- meaningful-cols
- sum
- average
- chart-bar

以下のサブコマンドはたぶんオプションなどの仕様が変更された。他にもあるかもしれない。
いずれも -vo オプションを使えば旧バージョンの仕様になる。
- head
- limit
- offset
- cols
- sort
- join
- header
- summary

以下のサブコマンドが削除された。ただし再設計による無効化でありいずれ有効化する想定。
いずれも -vo オプションを使えば旧バージョンの仕様で動作する。
- grep
- rmnoname
- mergecols
- insunixtime
- insdate
- inshour
- inssecinterval
- inscopy
- inslinenum
- insmap
- insconst
- uriparams
- update
- paste
- union
- diff
- expandmultivalue
- assemblematrix
- countcols
- facetcount
- treetable
- crosstable
- ratio
- groupsum
- tee

filter,where のカラム名に日本語名が使えるようになった。

offsetなどを使ったときのテーブル形式出力の行番号表示が変わった。

JSONフォーマットでの入力を扱えるようになった。

LTSVフォーマットの入力のサポートと --ltsv が削除された。
ただし再設計による無効化でありいずれ有効化する想定。

--o-chart, --o-chart2 は廃止された。

--o-table, --o-diffable はいったん廃止された。
ただし再設計による無効化でありいずれ有効化する想定。

--header はいったん廃止された。
ただし再設計による無効化でありいずれ有効化する想定。


## v13 -> v14 (2020/04/16)

出力オプション `--o-chart2` が追加された。

実行時のJava依存の機能が削除され、 --install-rt, --jvm は廃止された。

以下のコマンドが廃止された。
- cutidx
- stridx


## v12 -> v13 (2019/08/13)

-v12 --install のバグを解決し -v13 --install はできるようにした。
-v12 --install 自体は解決できない。

~/.xsvutils/repos-build の中のソースを手動修正してある場合でも強制的に上書きして
-vXX --install を実行できるようにした。

git clone 以外の方法でソースをダウンロードしてきた場合にビルドできない問題を解消したつもり。

入力の文字コードがSJISの場合にiconvでの指定を SHIFT-JIS から cp932 に変更した。


## v11 -> v12 (2019/07/17)

以下のサブコマンドが追加された。
- mcut

以下のコマンドがRustでの実装に置き換わり、高速化された。
- insconst

insconst に依存していた sort コマンドも高速化となった。

CSVからTSVへの変換がGo言語からRustでの実装に置き換わり、CSVファイルの読み込みが高速化された。

--install-rt はJavaが必要となるまでは実行しなくてもいいように変更した。

[追記]
-v12 --install にはバグがありビルドできない。 -v13 --install を使うこと。


## v10 -> v11 (2019/06/29)

Rustソースのビルド時にOSの共有オブジェクトへの動的リンクをなくして、バイナリのポータビリティを改善した。

GithubのレポジトリのURLを変更した。

sbtがインストールできないバグを修正した。


## v9 -> v10 (2018/12/03)

以下のコマンドがRustでの実装に置き換わり、高速化された。
- cut
- uriparams

src/install-openjdk.sh でJavaインストールできないバグを修正した。


## v8 -> v9 (2018/10/14)

※ `-v9` は v10 で修正された src/install-openjdk.sh のバグにより動かないかもしれない。

以下のコマンドが追加された。
- cutidx (--jvm のみ)
- stridx (--jvm のみ)

以下のコマンドを --jvm にて対応した。
- filter
- where

以下のオプションが追加された。
- filter コマンドの --stridx (--jvm のみ)
- where コマンドの --stridx (--jvm のみ)

--install-rt の仕組みによりJavaをシステムインストールのものからxsvutils自身の管理に変更した。


## v7 -> v8 (2018/09/26)

xsvutils 異常終了時に子プロセスが残ってしまうことがある問題を改善した。

以下のコマンドの進捗表示を廃止した。
- wcl

コマンドラインパーサのScalaでの再実装を目指して実験的に --jvm オプションを追加した。

以下のコマンドを --jvm にて対応した。
- cut
- update
- wcl

端末へのテーブル表示時に罫線の表示に罫線素片を利用するようにした。
また、行の先頭と末尾に罫線を表示しないようにした。


## v6 -> v7 (2018/09/12)

以下のオプションが追加された。
- cols コマンドの --remove
- uriparams コマンドの --sjis

端末へのテーブル表示時に途中にあるヘッダ行を反転表示するように変更した。


## v5 -> v6 (2018/08/06)

以下のコマンドが追加された。
- inslinenum
- expandmultivalue

以下のオプションが追加された。
- grep コマンドの -v

uriparamsの入力に `?...` や `http://.../...?...` の形式を許容するように変更した。

uriparams --name-list で生成するカラム名をオプション名に合わせて `names` から `name-list` に変更した。

エラーのハンドリングを少し強化した。

`--o-diffable` での空行でのバグを修正した。


## v4 -> v5 (2018/07/16)

以下のコマンドが追加された。
- assemblematrix
- grep

入力ファイルの圧縮フォーマットとしてxzがサポートされた。

標準入力を明示的に指定するための `-` が追加された。

sort コマンドで数値の逆順ソートの機能が追加された。

filter, where コマンドに `=~`, `!~` 演算子が追加された。

insconst のパラメータの順序がもとに戻った。 (see `xsvutils help insconst`)

以下のコマンドが削除された。
- insweek        (use -v1)
- addconst       (use insconst)
- addcopy        (use inscopy)
- addlinenum     (use -v1)
- addcross       (use -v1)
- addmap         (use insmap)
- parseuriparams (use uriparams)
- wordsflags     (use -v1)

以下のオプションが廃止された。
- --i-header     (use --header)
- paste, join, unin コマンドの --right オプション (use --file)


## 0.2.7 -> v4

以下のコマンドが追加された。
- mergecols
- rmnoname
- insunixtime
- ratio

以下のオプションが追加された。
- --o-chart
- cols コマンドの --last
- diff コマンドの -b, -w

互換性を維持するための -v1, -v2, -v3, -v4 オプションの仕組みが追加された。

insconst のパラメータの順序が逆になってしまった。 (see `xsvutils help insconst`)

