# CHANGELOG

To see version information, `xsvutils --version`.

To see compatibility information, `xsvutils help compatibility`.

## v8 -> v9 (Unreleased)

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


## commit log

### version 0.9 (-v9) (Unreleased)
- add `cutidx` subcommand on `--jvm`
- add `stridx` subcommand on `--jvm`
- reimplement `filter`, `where` subcommands on `--jvm`
- add `--stridx` option of `filter` `where` subcommands on `--jvm`
- support creating big stridx file
- add `--install-rt` global option

### version 0.8 (-v8) (2018/09/26)
- kill child processes on exit
- stop printing progress on `wcl`
- add `--jvm` option
- reimplement `cut`, `update`, `wcl` subcommands on `--jvm`
- fix vertical lines

### version 0.7 (-v7) (2018/09/12)
- add `--remove` option of `cols` subcommand
- add `--sjis` option of `uriparams` subcommand
- highlight header row

### version 0.6 (-v6) (2018/08/06)
- add `-v` option of `grep` subcommand
- fix a bug of handling division by zero on `facetcount` subcommand
- improve handling empty input
- add `inslinenum` subcommand
- add `expandmultivalue` subcommand
- allow URL format on `uriparams` subcommand
- change column name of `uriparams --name-list`
- fix a bug of handling empty line on `--o-diffable`

### version 0.5 (-v5) (2018/07/16)
- add support input of xz file
- `-` means stdin
- add input file name validation
- remove -v4 option of `rmnoname` subcommand
- add `assemblematrix` subcommand
- fix a bug of parameter parsing of `insconst`
- add sorting in reverse on `sort` subcommand
- remove auto degradation to v1
- add `=~`, `!~` operator of `filter`, `where` subcommands
- add `grep` subcommand

### version 0.4 (-v4) (2018/07/10)
- support -v1,-v2,-v3,-v4

### version 0.3.4 (2018/06/30)
- add `ratio` subcommand
- add `-b`, `-w` options of `diff` subcommand
- add `--o-chart` option as output format

### version 0.3.3 (2018/05/27)
- add `rmnoname` subcommand
- add `insunixtime` subcommand
- add `--last` option of `cols` subcommand

### version 0.3.2 (2018/05/21)
- add `mergecols` subcommand

### version 0.3.1 (2018/05/07)
- add java version of facetcount
- remove display of progress of facetcount, treetable, ...

### version 0.3.0 (2018/04/23)
- change default parse from v1 to v2

### version 0.2.7 (-v3) (2018/04/22)
- add `diff` subcommand on v2
- enable output csv format on terminal
- add facetcount ratio2 column
- add `filter`, `where` subcommand on v2
- change --o-diffable format
- add some subcommands from v1 to v2
- add `insmap` subcommand on v2
- add `-v2` option of `groupsum` subcommand

### version 0.2.6 (2018/04/09)
- add support LTSV format on v2
- make `uriparams` slightly fast

### version 0.2.5 (2018/04/08)
- fix a bug of removing temp files on `sort` subcommand
- fix a bug of output of `uriparams --name-list`

### version 0.2.4 (2018/03/30)
- add support subquery of `tee` subcommand on v2
- add `insconst` subcommand on v2
- add --o-diffable option on v2
- add `cols` subcommand on v2
- add some subcommands from v1 to v2
- fix a bug of handling empty file on `join` subcommand
- add --left-update, --right-update options on `cols` subcommand

### version 0.2.3 (2018-03-11)
- add support CR, CRLF
- add some subcommands from v1 to v2
- add --src, --dst options of inshour, insdate subcommand on v2
- rename subcommand name `insdeltasec` to `inssecinterval`
- remove `addlinenum2` subcommand
- add `inscopy` subcommand on v2
- change `sort` subcommand without parameters
- remove `addnumsortable` subcommand
- add support input of gz file on v2
- add `tee` subcommand on v2

### version 0.2.2 (2018-03-07)
- add `inshour` subcommand on v2
- add --weight option on `facetcount` subcommand on v2
- fix a bug on `join` subcommand

### version 0.2.1 (2018-02-27)
- add --version option
- split help document
- add some subcommands from v1 to v2
- add `insdeltasec` subcommand on v2
- add `groupsum` subcommand on v2

### version 0.2.0 (2018-02-25)
- add -v1, -v2 options
- add some subcommands from v1 to v2

### version 0.1.1 (2018-02-18)
- fix a bug of ratio of summary
- add number comparation operators of subcommand `where`

### version 0.1.0 (2018-02-12)
- initial version

