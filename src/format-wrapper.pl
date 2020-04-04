use strict;
use warnings;
use utf8;

my $XSVUTILS_HOME = $ENV{"XSVUTILS_HOME"};

my $format = "";
my $charencoding = "";
my $utf8bom = "";
my $newline = "";

my $format_result_path = undef;
my $input_path = undef;
my $output_path = undef;

my $pipe_mode = '';

while (@ARGV) {
    my $a = shift(@ARGV);
    if ($a eq "--tsv") {
        $format = "tsv";
    } elsif ($a eq "--csv") {
        $format = "csv";
    } elsif ($a eq "--ltsv") {
        $format = "ltsv";
    } elsif ($a eq "--pipe") {
        # pipeモードを強制する
        # このオプションがない場合は状況によってfileモードまたはpipeモードになる
        $pipe_mode = 1;
    } elsif ($a eq "-i") {
        die "option $a needs an argument" unless (@ARGV);
        $input_path = shift(@ARGV);
    } elsif ($a eq "-o") {
        die "option $a needs an argument" unless (@ARGV);
        $output_path = shift(@ARGV);
    } elsif (!defined($format_result_path)) {
        $format_result_path = $a;
    } else {
        die "Unknown argument: $a";
    }
}

#die "format-wrapper.pl requires argument" unless defined $format_result_path;

my $head_size = 100 * 4096;

my $head_buf = "";

my $in = *STDIN;
if (!defined($input_path)) {
    $in = *STDIN;
} else {
    open($in, '<', $input_path) or die $!;
}

my $left_size = $head_size;
my $exists_lf = '';
my $gzip_flag = '';
my $xz_flag = '';
while () {
    if ($left_size <= 0) {
        last;
    }
    my $head_buf2;
    my $l = sysread($in, $head_buf2, $left_size);
    if ($l == 0) {
        last;
    }
    if (!$exists_lf && $head_buf2 =~ /[\r\n]/) {
        $exists_lf = 1;
    }
    $head_buf .= $head_buf2;
    if ($left_size >= $head_size - 2) {
        if ($head_buf =~ /\A\x1F\x8B/) {
            $gzip_flag = 1;
            last;
        }
    }
    if ($left_size >= $head_size - 6) {
        if ($head_buf =~ /\A\xFD\x37\x7A\x58\x5A\x00/) {
            $xz_flag = 1;
            last;
        }
    }
    $left_size -= $l;
}

if ($gzip_flag || $xz_flag) {
    my $READER1;
    my $WRITER1;
    pipe($READER1, $WRITER1);

    my $pid1 = fork;
    if (!defined $pid1) {
        die $!;
    } elsif ($pid1) {
        # parent process
        # 読み込み済みの入力を標準出力し、残りはcatする
        close $READER1;
        open(STDOUT, '>&=', fileno($WRITER1));
        syswrite(STDOUT, $head_buf);
        exec("cat");
    }
    # child1 process
    close $WRITER1;
    open(STDIN, '<&=', fileno($READER1));

    my $READER2;
    my $WRITER2;
    pipe($READER2, $WRITER2);

    my $pid2 = fork;
    if (!defined $pid2) {
        die $!;
    } elsif ($pid2) {
        # parent(child1) process
        # gunzip or xz のプロセスをexecする
        close $READER2;
        open(STDOUT, '>&=', fileno($WRITER2));
        if ($xz_flag) {
            exec("xz", "-c", "-d");
        } else {
            exec("gunzip", "-c");
        }
    }
    # child2 process
    close $WRITER2;
    open(STDIN, '<&=', fileno($READER2));

    my @options = ();
    if ($format eq "tsv") {
        push(@options, "--tsv");
    } elsif ($format eq "csv") {
        push(@options, "--csv");
    } elsif ($format eq "ltsv") {
        push(@options, "--ltsv");
    }
    if (defined($format_result_path)) {
        push(@options, $format_result_path);
    }
    if (defined($output_path)) {
        push(@options, "-o");
        push(@options, $output_path);
    }

    exec("perl", "$XSVUTILS_HOME/src/format-wrapper.pl", @options);
}

sub guess_format {
    my ($head_buf) = @_;
    my $first_line;
    if ($head_buf =~ /\A([^\n]*)\n/s) {
        $first_line = $1;
    } else {
        $first_line = $head_buf;
    }
    if ($first_line =~ /\t/) {
        return "tsv";
    } elsif ($first_line =~ /\A\{/) {
        return "json";
    } elsif ($first_line =~ /,/) {
        return "csv";
    } else {
        # failed to guess format
        return "text";
    }
}

# 文字コードを自動判別する。
# いまのところ、 UTF-8 / SHIFT-JIS のみ
sub guess_charencoding {
    my ($head_buf) = @_;
    my $len = length($head_buf);
    my $utf8_multi = 0;
    my $utf8_flag = 1;
    my $sjis_multi = 0;
    my $sjis_flag = 1;
    for (my $i = 0; $i < $len; $i++) {
        my $b = ord(substr($head_buf, $i, 1));
        if ($utf8_multi > 0) {
            if    ($b >= 0x80 && $b < 0xC0)  { $utf8_multi--; }
            else                             { $utf8_multi = 0; $utf8_flag = ''; }
        } else {
            if    ($b < 0x80)                { ; }
            elsif ($b >= 0xC2 && $b < 0xE0)  { $utf8_multi = 1; }
            elsif ($b >= 0xE0 && $b < 0xF0)  { $utf8_multi = 2; }
            elsif ($b >= 0xF0 && $b < 0xF8)  { $utf8_multi = 3; }
            else                             { $utf8_flag = ''; }
        }
        if ($sjis_multi > 0) {
            if    ($b >= 0x40 && $b <= 0x7E) { $sjis_multi = 0; }
            elsif ($b >= 0x80 && $b <= 0xFC) { $sjis_multi = 0; }
            else                             { $sjis_multi = 0; $sjis_flag = ''; }
        } else {
            if    ($b <= 0x7F)               { ; }
            elsif ($b >= 0x81 && $b <= 0x9F) { $sjis_multi = 1; }
            elsif ($b >= 0xA0 && $b <= 0xDF) { ; }
            elsif ($b >= 0xE0 && $b <= 0xFC) { $sjis_multi = 1; }
            elsif ($b >= 0xFD && $b <= 0xFF) { ; }
            else                             { $sjis_flag = ''; }
        }
    }
    $utf8bom = '0';
    if (!$utf8_flag && $sjis_flag) {
        return ($head_buf, "cp932", $utf8bom);
    } else {
        if ($len >= 3) {
            if (substr($head_buf, 0, 3) eq "\xEF\xBB\xBF") {
                # BOM in UTF-8
                $utf8bom = '1';
                $head_buf = substr($head_buf, 3);
            }
        }
        return ($head_buf, "UTF-8", $utf8bom);
    }
}

sub guess_newline {
    my ($head_buf) = @_;
    if ($head_buf =~ /(\r\n?|\n)/) {
        if ($1 eq "\r\n") {
            return "dos";
        } elsif ($1 eq "\r") {
            return "mac";
        }
    }
    return "unix";
}

if ($format eq '') {
    $format = guess_format($head_buf);
}

if ($charencoding eq '') {
    ($head_buf, $charencoding, $utf8bom) = guess_charencoding($head_buf);
}

if ($newline eq '') {
    $newline = guess_newline($head_buf);
}

my $mode;
if ($pipe_mode) {
    $mode = "pipe";
} elsif (defined($input_path) && -f $input_path) {
    $mode = "file";
} else {
    $mode = "pipe";
}

if ($charencoding ne "UTF-8") {
    $mode = "pipe";
}

# フォーマットの推定結果を出力
if (defined($format_result_path)) {
    open(my $format_result_fh, '>', $format_result_path) or die $!;
    print $format_result_fh "format:$format charencoding:$charencoding utf8bom:$utf8bom newline:$newline mode:$mode\n";
    close($format_result_fh);
}

if ($mode eq "file") {
    exit(0);
}

if (defined($output_path)) {
    open(my $output_fh, '>', $output_path) or die $!;
    open(STDOUT, '>&=', fileno($output_fh));
}

if ($charencoding ne "UTF-8") {
    # cp932

    my $READER1;
    my $WRITER1;
    pipe($READER1, $WRITER1);

    my $pid1 = fork;
    if (!defined $pid1) {
        die $!;
    } elsif (!$pid1) {
        # child1 process
        close $READER1;
        open(STDOUT, '>&=', fileno($WRITER1));
        syswrite(STDOUT, $head_buf);
        exec("cat");
    } else {
        # parent process
        close $WRITER1;
        open(STDIN, '<&=', fileno($READER1));
        exec("iconv", "-f", $charencoding, "-t", "UTF-8//TRANSLIT");
    }
}

# 先読みした内容を出力
syswrite(STDOUT, $head_buf);

# 残りの入力をそのまま出力
exec("cat");

