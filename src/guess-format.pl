use strict;
use warnings;
use utf8;

use POSIX qw/mkfifo/;

my $TOOL_DIR = $ENV{"TOOL_DIR"};
my $WORKING_DIR = $ENV{"WORKING_DIR"};

my $answer_filepath = undef;
my $format = undef;
while (@ARGV) {
    my $a = shift(@ARGV);
    if ($a eq "--answer") {
        die unless (@ARGV);
        $answer_filepath = shift(@ARGV);
    } elsif ($a eq "--tsv") {
        $format = "tsv";
    } elsif ($a eq "--csv") {
        $format = "csv";
    } else {
        # TODO
    }
}

if (!defined($answer_filepath)) {
    # die; TODO
}

# 形式を推測するために先頭を少しだけ読み取る
my $buf;
sysread(STDIN, $buf, 1024);

if (!defined($format)) {
    # フォーマット(CSV/TSV)を推測
    if ($buf =~ /\t/) {
        $format = "tsv";
    } elsif ($buf =~ /,/) {
        $format = "csv";
    } else {
        # failed to guess format
        $format = "tsv";
    }
}

if ($format ne "csv") {
    # TSVの場合、
    # 少しだけ読み取った先頭部分を出力し、
    # 残りもそのまま標準入力から標準出力すればよいので cat に任せる。
    syswrite(STDOUT, $buf);
    exec("cat");
}

# CSVの場合

my $fifo_filepath = "$WORKING_DIR/guess-format.fifo";
mkfifo($fifo_filepath, 0700) or die "Cannot make fifo: $!";

# cat を子プロセスとして起動
my $pid = fork();
if (!defined($pid)) {
    die "Cannot fork";
}
if ($pid == 0) {
    # 子プロセスは
    # 少しだけ読み取った先頭部分をfifoに出力し、
    # 残りも cat を使ってそのまま標準入力からfifoに出力する。
    my $fifo_out;
    open($fifo_out, '>', $fifo_filepath) or die "Cannot open file: $!";
    open(STDOUT, '>&=', fileno($fifo_out));
    syswrite(STDOUT, $buf);
    exec("cat");
}

# golang.bin csv2tsv でフォーマット変換
my $fifo_in;
open($fifo_in, '<', $fifo_filepath) or die "Cannot open file: $!";
open(STDIN, '<&=', fileno($fifo_in));
exec("$TOOL_DIR/golang.bin", "csv2tsv");


