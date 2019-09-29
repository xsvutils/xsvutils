# xsvutils

A set of command line utilities for handling tabular data files.  
CSVファイルやTSVファイルをCUIで扱うツール。

https://www.slideshare.net/suzuki-navi/xsvutils-overview

## Usage

    $ xsvutils [FILENAME] [SUBCOMMAND] [OPTIONS...]

To see help documents,

    $ xsvutils --help
    $ xsvutils --help usage
    $ xsvutils --help list

## Example

Print tsv/csv data to the terminal.  
TSV/CSVファイルを端末に見やすく表示する。

    $ xsvutils data.tsv
    $ xsvutils data.csv
    $ xsvutils data.csv.gz                       # gz or xz format is supported
    $ ssh remote-host cat foo/bar.csv | xsvutils

端末への出力例

    |    | 1      | 2        | 3            |
    |    | code   | name     | kana         |
    | 1  | 010006 | 北海道   | ホッカイドウ |
    | 2  | 020001 | 青森県   | アオモリケン |
    | 3  | 030007 | 岩手県   | イワテケン   |
    | 4  | 040002 | 宮城県   | ミヤギケン   |
    | 5  | 050008 | 秋田県   | アキタケン   |

Retrieve specified columns.  
一部のカラムのみを表示する。

    $ xsvutils data.tsv cut foo,col1,col20    # retrieve only 3 columns: foo, col1, col20
    $ xsvutils data.tsv cut foo,col1..col20   # retrieve 21 columns: foo, col1, col2, col3, ... col20

先頭の10レコードのみ表示する。ヘッダ行が含まれるので11行。

    $ xsvutils data.tsv head
    $ xsvutils data.tsv head 10

先頭の10レコードの id, name の2カラムのみを表示する。

    $ xsvutils data.tsv head 10 cut id,name

先頭の10レコードの id, name の2カラムのみをTSV形式でファイルに書き出す。

    $ xsvutils data.tsv head 10 cut id,name > data2.tsv

ヘッダ行のない3カラムからなるファイルに対して、カラム名をオプションで指定してから、
name, id の2カラムのみを表示する。2カラムは元ファイルから順番を入れ替える。

    $ xsvutils data.tsv --header id,name,comment cut name,id

レコード数を数える。ヘッダ行は含まない。

    $ xsvutils data.tsv wcl

ヘッダにあるカラム名の一覧を表示する。

    $ xsvutils data.tsv header


## Install

    $ git clone https://github.com/xsvutils/xsvutils.git
    $ cd xsvutils
    $ make
    $ cp xsvutils ~/bin/    # copy xsvutils to your $PATH


## License

This software is released under the MIT License, see LICENSE.txt.

