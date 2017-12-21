use strict;
use warnings;
use utf8;

use Data::Dumper;

use POSIX qw/mkfifo/;

my $TOOL_DIR = $ENV{"TOOL_DIR"};
my $WORKING_DIR = $ENV{"WORKING_DIR"};
my $isInputTty = undef;
if (-t STDIN) {
    $isInputTty = 1;
}
my $isOutputTty = undef;
if (-t STDOUT) {
    $isOutputTty = 1;
}

sub escape_for_bash {
    my ($str) = @_;
    if ($str =~ /\A[-_.=\/0-9a-zA-Z]+\z/) {
        return $str;
    }
    $str =~ s/'/'"'"'/g;
    return "'" . $str . "'";
}

################################################################################
# parse command line options
################################################################################

my $option_help = undef;
my $option_explain = undef;

my $exists_args = '';
$exists_args = 1 if (@ARGV);

sub parseOptionSequence {
    # 2値を返す関数。
    # 1つ目の返り値の例
    # { "commands" => [["head", "20"], ["cut", "id,name"]],
    #   "input" => "", # 入力ファイル名、または空文字列は標準入力の意味
    #   "output" => "", # 出力ファイル名、または空文字列は標準出力の意味
    #   "format" => "", # 入力フォーマット、または空文字列は自動判定の意味
    #   "input_header" => "id,name,desc", # カンマ区切りでのヘッダ名の列、または空文字列はヘッダ行ありの意味
    #   "output_header_flag" => 1, # 出力にヘッダをつけるかどうか 1 or ''
    # }
    # 2つ目は閉じ括弧よりも後ろの残ったパラメータの配列。

    my ($argv) = @_;

    my $commands = [];
    my $curr_command = undef;
    my $input = undef;
    my $output = undef;
    my $format = undef;
    my $input_header = undef;
    my $output_header_flag = 1;

    while (@$argv) {
        my $a = shift(@$argv);
        if ($a eq "--help") {
            $option_help = 1;
        } elsif ($a eq "--explain") {
            $option_explain = 1;

        } elsif ($a eq "cat") {
            push(@$commands, $curr_command) if (defined($curr_command));
            $curr_command = undef;

        } elsif ($a eq "take" || $a eq "head") {
            push(@$commands, $curr_command) if (defined($curr_command));
            $curr_command = ["take", ""];

        } elsif ($a eq "drop") {
            push(@$commands, $curr_command) if (defined($curr_command));
            $curr_command = ["drop", ""];

        } elsif ($a eq "cut") {
            push(@$commands, $curr_command) if (defined($curr_command));
            $curr_command = ["cut", ""];

        } elsif ($a eq "addcol") {
            push(@$commands, $curr_command) if (defined($curr_command));
            $curr_command = ["addcol", undef, undef];

        } elsif ($a eq "wcl") {
            push(@$commands, $curr_command) if (defined($curr_command));
            $curr_command = ["wcl"];

        } elsif ($a eq "summary") {
            push(@$commands, $curr_command) if (defined($curr_command));
            $curr_command = ["summary"];

        } elsif ($a eq "countcols") {
            push(@$commands, $curr_command) if (defined($curr_command));
            $curr_command = ["countcols"];

        } elsif ($a eq "-i") {
            die "option -i needs an argument" unless (@$argv);
            die "duplicated option: $a" if defined($input);
            $input = shift(@$argv);

        } elsif ($a eq "-o") {
            die "option -o needs an argument" unless (@$argv);
            die "duplicated option: $a" if defined($output);
            $output = shift(@$argv);

        } elsif ($a eq "--i-header") {
            die "option --i-header needs an argument" unless (@$argv);
            die "duplicated option: $a" if defined($input_header);
            $input_header = shift(@$argv);

        } elsif ($a eq "--o-no-header") {
            $output_header_flag = '';

        } elsif (!defined($input) && -e $a) {
            $input = $a;

        } elsif (defined($curr_command)) {
            if ($curr_command->[0] eq "take" || $curr_command->[0] eq "drop") {
                my $num = undef;
                if ($a eq "-n") {
                    die "option -n needs an argument" unless (@$argv);
                    $num = shift(@$argv);
                    die "option -n needs a number argument" unless ($num =~ /\A(0|[1-9][0-9]*)\z/);
                } elsif ($a =~ /\A-n(0|[1-9][0-9]*)\z/) {
                    $num = $1;
                } elsif ($a =~ /\A(0|[1-9][0-9]*)\z/) {
                    $num = $a;
                } else {
                    die "Unknown argument: $a";
                }
                if (defined($num)) {
                    if ($curr_command->[1] ne "") {
                        die "duplicated option: $a";
                    }
                    $curr_command->[1] = $num;
                }

            } elsif ($curr_command->[0] eq "cut") {
                if ($a eq "--col" || $a eq "--cols" || $a eq "--columns") {
                    die "option $a needs an argument" unless (@$argv);
                    $curr_command->[1] = shift(@$argv);
                } else {
                    $curr_command->[1] = $a;
                }

            } elsif ($curr_command->[0] eq "addcol") {
                if ($a eq "--name") {
                    die "option $a needs an argument" unless (@$argv);
                    my $addcol_name = shift(@$argv);
                    if (defined($curr_command->[1])) {
                        die "duplicated option: --name";
                    }
                    $curr_command->[1] = $addcol_name;
                } elsif ($a eq "--value") {
                    die "option $a needs an argument" unless (@$argv);
                    my $addcol_value = shift(@$argv);
                    if (defined($curr_command->[1])) {
                        die "duplicated option: --value";
                    }
                    $curr_command->[2] = $addcol_value;
                } elsif (!defined($curr_command->[1])) {
                    my $addcol_name = $a;
                    $curr_command->[1] = $addcol_name;
                } elsif (!defined($curr_command->[2])) {
                    my $addcol_value = $a;
                    $curr_command->[2] = $addcol_value;
                } else {
                    die "Unknown argument: $a";
                }

            }

        } else {
            #die "Unknown argument: $a";
        }
    }

    if (defined($curr_command)) {
        push(@$commands, $curr_command);
    }
    if (!defined($input)) {
        $input = '';
    }
    if (!defined($output)) {
        $output = '';
    }
    if (!defined($format)) {
        $format = '';
    }
    if (!defined($input_header)) {
        $input_header = "";
    }

    my $commands2 = [];
    for my $c (@$commands) {
        if ($c->[0] eq "take") {
            if ($c->[1] eq "") {
                $c->[1] = "10";
            }
            push(@$commands2, ["range", "", $c->[1]]);
        } elsif ($c->[0] eq "drop") {
            if ($c->[1] eq "") {
                $c->[1] = "10";
            }
            push(@$commands2, ["range", $c->[1], ""]);
        } elsif ($c->[0] eq "cut") {
            if ($c->[1] eq "") {
                die "subcommand \`cut\` needs --col option";
            }
            push(@$commands2, ["cut", $c->[1]]);
        } elsif ($c->[0] eq "addcol") {
            if (!defined($c->[1])) {
                die "subcommand \`addcol\` needs --name option";
            }
            if (!defined($c->[2])) {
                $c->[2] = "";
            }
            push(@$commands2, ["addcol", $c->[1], $c->[2]]);
        } elsif ($c->[0] eq "wcl") {
            push(@$commands2, ["wcl"]);
        } elsif ($c->[0] eq "summary") {
            push(@$commands2, ["summary"]);
        } elsif ($c->[0] eq "countcols") {
            push(@$commands2, ["countcols"]);
        } else {
            die $c->[0];
        }
    }

    ({"commands" => $commands2,
      "input" => $input,
      "output" => $output,
      "format" => $format,
      "input_header" => $input_header,
      "output_header_flag" => $output_header_flag},
     $argv);
}

my ($command_seq, $tail_argv) = parseOptionSequence(\@ARGV);

################################################################################
# help
################################################################################

my $help_stdout = undef;
my $help_stderr = undef;
if ($option_help) {
    $help_stdout = 1;
} elsif ($isInputTty && $command_seq->{input} eq "") {
    if ($exists_args) {
        # 入力がない場合は、
        # ヘルプをエラー出力する。
        $help_stderr = 1;
    } else {
        # なにもパラメータがない場合は、 --help を付けたのと同じ扱いとする
        $help_stdout = 1;
    }
}

if ($help_stdout || $help_stderr) {
    my $help_filepath = $TOOL_DIR . "/help.txt";
    if ($help_stderr) {
        open(IN, '<', $help_filepath) or die $!;
        my @lines = <IN>;
        my $str = join('', @lines);
        close IN;
        open(STDOUT, '>&=', fileno(STDERR));
    }
    if ($isOutputTty) {
        exec("less", "-SRXF", $help_filepath);
    } else {
        exec("cat", $help_filepath);
    }
}

################################################################################
# guess format ...
################################################################################

sub guess_format {
    my ($head_buf) = @_;
    if ($head_buf =~ /\t/) {
        return "tsv";
    } elsif ($head_buf =~ /,/) {
        return "csv";
    } else {
        # failed to guess format
        return "tsv";
    }
}

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
            elsif ($b >= 0xE0 && $b <= 0xFC) { $sjis_multi = 1; }
            else                             { $sjis_flag = ''; }
        }
    }
    if (!$utf8_flag && $sjis_flag) {
        return "SHIFT-JIS";
    } else {
        return "UTF-8";
    }
}

sub prefetch_input {
    my ($command_seq) = @_;

    my $head_size = 100 * 4096;
    my $head_buf;

    my $in;
    if ($command_seq->{input} eq '') {
        $in = *STDIN;
    } else {
        open($in, '<', $command_seq->{input}) or die $!;
    }
    $command_seq->{input_handle} = $in;

    sysread($in, $head_buf, $head_size);

    $command_seq->{head_buf} = $head_buf;

    if ($command_seq->{format} eq '') {
        $command_seq->{format} = guess_format($head_buf);
    }

    $command_seq->{charencoding} = guess_charencoding($head_buf);
}

prefetch_input($command_seq);

################################################################################
# subcommand list to intermediate code
################################################################################

sub build_ircode {
    my ($command_seq, $isOutputTty) = @_;

    my $ircode = [["cmd", "cat"]];

    if ($command_seq->{charencoding} ne "UTF-8") {
        push(@$ircode, ["cmd", "iconv -f $command_seq->{charencoding} -t UTF-8"]);
    }

    if ($command_seq->{format} eq "csv") {
        push(@$ircode, ["cmd", "\$TOOL_DIR/golang.bin csv2tsv"]);
    }

    if ($command_seq->{input_header} ne '') {
        my @headers = split(/,/, $command_seq->{input_header});
        for my $h (@headers) {
            unless ($h =~ /\A[_0-9a-zA-Z][-_0-9a-zA-Z]*\z/) {
                die "Illegal header: $h\n";
            }
        }
        my $headers = escape_for_bash(join("\t", @headers));
        $ircode = [["seq",
                    [["cmd", "printf '%s' $headers"],
                     ["cmd", "echo"],
                     ["pipe", $ircode]]]];
    }

    my $last_command = "";
    foreach my $t (@{$command_seq->{commands}}) {
        my $command = $t->[0];
        if ($last_command eq "wcl") {
            die "command `$last_command` must be last`\n";
        } elsif ($last_command eq "summary") {
            die "command `$last_command` must be last`\n";
        } elsif ($last_command eq "countcols") {
            die "command `$last_command` must be last`\n";
        }
        if ($command eq "range") {
            my $num1 = $t->[1];
            my $num2 = $t->[2];
            if ($num1 eq "") {
                if ($num2 eq "") {
                    # nop
                } else {
                    my $arg = escape_for_bash('-n' . ($num2 + 1));
                    push(@$ircode, ["cmd", "head $arg"]);
                }
            } else {
                if ($num2 eq "") {
                    my $arg = escape_for_bash(($num1 + 2) . ',$p');
                    push(@$ircode, ["cmd", "sed -n -e 1p -e $arg"]);
                } else {
                    die; # TODO
                }
            }

        } elsif ($command eq "cut") {
            my $cols = escape_for_bash($t->[1]);
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/cut.pl --col $cols"]);

        } elsif ($command eq "addcol") {
            my $name  = escape_for_bash($t->[1]);
            my $value = escape_for_bash($t->[2]);
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/addcol.pl --name $name --value $value"]);

        } elsif ($command eq "wcl") {
            push(@$ircode, ["cmd", "\$TOOL_DIR/golang.bin wcl --header"]);

        } elsif ($command eq "summary") {
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/summary.pl"]);

        } elsif ($command eq "countcols") {
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/countcols.pl"]);

        } else {
            die $command;
        }
        $last_command = $command;
    }

    my $isPager = '';
    if ($last_command ne "wcl" && $isOutputTty && $command_seq->{output} eq "") {
        $isPager = 1;
    }

    if ($isPager) {
        my $table_option = "";
        if ($last_command ne "countcols") {
            $table_option .= " --col-number";
            $table_option .= " --record-number";
        }
        if ($last_command eq "summary") {
            $table_option .= " --max-width 500";
        }
        push(@$ircode, ["cmd", "perl \$TOOL_DIR/table.pl$table_option"]);
        push(@$ircode, ["cmd", "less -SRX"]);
    }

    if ($last_command ne "wcl" && $command_seq->{output_header_flag} && !$isPager) {
        push(@$ircode, ["cmd", "tail -n+2"]);
    }

    $command_seq->{ircode} = ["pipe", $ircode];
}

build_ircode($command_seq, $isOutputTty);

################################################################################
# intermediate code to shell script
################################################################################

sub irToShellscript {
    my ($code) = @_;
    my $type = $code->[0];
    if ($type eq "pipe") {
        my @cs = @{$code->[1]};
        if (!@cs) {
            [":"];
        } elsif ((scalar @cs) == 1) {
            irToShellscript($cs[0]);
        } else {
            joinShellscriptLines([map { irToShellscript($_) } @cs], "", "", " |", "    ", "    ", " |", "    ", "    ", "");
        }
    } elsif ($type eq "seq") {
        my @cs = @{$code->[1]};
        if (!@cs) {
            [":"];
        } elsif ((scalar @cs) == 1) {
            irToShellscript($cs[0]);
        } else {
            joinShellscriptLines([map { irToShellscript($_) } @cs], "( ", "  ", ";", "  ", "  ", ";", "  ", "  ", " )");
        }
    } elsif ($type eq "cmd") {
        my $script = $code->[1];
        [$script];
    }
}

sub joinShellscriptLines {
    my ($sources, $begin, $begin_b, $end0, $begin1, $begin1_b, $end1, $begin2, $begin2_b, $end) = @_;

    if (@$sources == 0) {
        die;
    } elsif (@$sources == 1) {
        die;
    }

    my $first = shift(@$sources);
    my $last  = pop(@$sources);

    [
     @{joinShellscriptLinesSub($first, $begin, $begin_b, $end0)},
     (map { @{joinShellscriptLinesSub($_, $begin1, $begin1_b, $end1)} } @$sources),
     @{joinShellscriptLinesSub($last,  $begin2, $begin2_b, $end)}
    ];
}

sub joinShellscriptLinesSub {
    my ($sources, $begin, $begin_b, $end) = @_;

    if (@$sources == 0) {
        die;
    }
    if (@$sources == 1) {
        return [$begin . $sources->[0] . $end];
    }

    my $first = shift(@$sources);
    my $last  = pop(@$sources);

    [
     $begin . $first,
     (map { $begin_b . $_ } @$sources),
     $begin_b . $last . $end,
    ];
}

my $main_1_source = join("\n", @{irToShellscript($command_seq->{ircode})}) . "\n";

if ($option_explain) {
    my $view = $main_1_source;
    $view =~ s/^/> /gm;
    print STDERR $view;
}

open(my $main_1_out, '>', "$WORKING_DIR/main-1.sh") or die $!;
print $main_1_out $main_1_source;
close($main_1_out);

################################################################################
# 入出力を stdin, stdout に統一
################################################################################

my $stdin = $command_seq->{input_handle};

if ($stdin ne *STDIN) {
    # 入力がファイルの場合
    open(STDIN, '<&=', fileno($command_seq->{input_handle}));
}

if ($command_seq->{output} ne "") {
    # 出力がファイルの場合
    my $data_out;
    open($data_out, '>', $command_seq->{output}) or die $!;
    open(STDOUT, '>&=', fileno($data_out));
}

################################################################################
# exec script
################################################################################

my $PARENT_READER;
my $CHILD_WRITER;
pipe($PARENT_READER, $CHILD_WRITER);

my $pid1 = fork;
if (!defined $pid1) {
    die;
} elsif ($pid1) {
    # parent process

    close $CHILD_WRITER;
    open(STDIN, '<&=', fileno($PARENT_READER));

    exec("bash", "$WORKING_DIR/main-1.sh");
} else {
    # child process

    close $PARENT_READER;
    open(STDOUT, '>&=', fileno($CHILD_WRITER));

    syswrite(STDOUT, $command_seq->{head_buf});
    exec("cat");
}

################################################################################

