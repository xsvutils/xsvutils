
# 入力形式(文字コード、改行コード、フォーマット(CSV/TSV)、ヘッダ有無)を推定し、
# UTF-8, LF, TSV, ヘッダありに変換して、別プロセスを子プロセスとして起動しその標準入力に渡し、
# 子プロセスからの標準出力を、またもとの形式に戻して出力する。
# 出力を戻す詳細はオプションで設定可能。
# 
# TODO まだ形式推定・変換はすべて未実装
# 
# foo-process | bash format-wrapper.sh options -- bar-process args ...
# 
# --tsv 入出力フォーマットは推定せずにTSVとみなす
# --out-tsv 出力フォーマットは入力フォーマットによらずTSVとする
# 
# --csv 入出力フォーマットは推定せずにCSVとみなす
# --out-csv 出力フォーマットは入力フォーマットによらずCSVとする
# 
# --deli DELIMITER 入出力フォーマットの区切り文字を指定
# --out-deli DELIMITER 出力フォーマットの区切り文字を指定
# 
# --header 入出力フォーマットはヘッダありとみなす
# --out-header 出力フォーマットはヘッダありとする
# 
# --no-header 入出力フォーマットはヘッダなしとみなす
# --out-no-header 出力フォーマットはヘッダなしとする
# 
# --charset CHARSET 入出力フォーマットの文字コードを指定
# --out-charset CHARSET 出力フォーマットの文字コードを指定
# 
# --out-plain 子プロセスからの出力をいっさい変換せずに出力
# 
# --out-terminal-table 出力フォーマットを端末で見やすい固定長のテーブルに変換して出力
# 
# 以上のオプションのうち、 --out で始まっているものは入力形式とは異なる出力形式にしたい場合に指定する。
# --out のついていないものは、オプションを付けなければ自動推定するが、推定の失敗に備えたい場合に指定するオプション。
# 
# --pager 出力に less を使う

WORKING_DIR=$(mktemp -d)
trap "rm -rf $WORKING_DIR" EXIT

option_pager=
while [ "$#" != 0 ]; do
    if [ "$1" = "--" ]; then
        shift
        break
    elif [ "$1" = "--pager" ]; then
        option_pager=1
    fi
    shift
done

if [ -n "$option_pager" ]; then
    perl $TOOL_DIR/guess-format.pl | exec "$@" | perl $TOOL_DIR/convert-output.pl | less -SRX
else
    perl $TOOL_DIR/guess-format.pl | exec "$@" | perl $TOOL_DIR/convert-output.pl
fi




