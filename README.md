# xsvutils

Utilities for handling separated value data


## Usage

$ xsvutils [FILENAME] [SUBCOMMAND] [OPTIONS...]


## Example

TSV/CSVファイルを端末に見やすく表示する。

Print tsv/csv data to the terminal.

    $ xsvutils data.tsv
    $ xsvutils data.csv
    $ ssh remote-host cat foo/bar.csv | xsvutils

一部のカラムのみを表示する。

Retrieve specified columns.

    $ xsvutils data.tsv cut foo,col1,col20    # retrieve only 3 columns: foo, col1, col20
    $ xsvutils data.tsv cut foo,col1..col20   # retrieve 21 columns: foo, col1, col2, col3, ... col20

先頭の10レコードのみ表示する。ヘッダ行が含まれるので11行。

    $ xsvutils data.tsv head
    $ xsvutils data.tsv head 10

先頭の10レコードの id, name の2カラムのみを表示する。

    $ xsvutils data.tsv head 10 cut id,name

先頭の10レコードの id, name の2カラムのみをTSV形式でファイルに書き出す。

    $ xsvutils data.tsv head 10 cut id,name > data2.tsv


