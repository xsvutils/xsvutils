use strict;
use warnings;
use utf8;

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

my @originalArgv = @ARGV;
sub degradeMain {
    print STDERR "warning: degrade to v1 (@originalArgv)\n";
    exec("perl", "$TOOL_DIR/main-v1.pl", @originalArgv);
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

sub parseQuery {
    # 2値を返す関数。
    # 1つ目の返り値の例
    # { "commands" => [
    #                  {"command" => "range", "start" => "", "end" => "20"},
    #                  {"command" => "cut", "header" => "id,name"}
    #                 ],
    #   "input" => "",                    # 入力ファイル名、または空文字列は標準入力の意味
    #   "output" => "",                   # 出力ファイル名、または空文字列は標準出力の意味
    #   "format" => "",                   # 入力フォーマット、または空文字列は自動判定の意味
    #   "input_header" => "id,name,desc", # カンマ区切りでのヘッダ名の列、または空文字列はヘッダ行ありの意味
    #   "output_header_flag" => 1,        # 出力にヘッダをつけるかどうか 1 or ''
    #   "output_table" => 1,              # 表形式での出力かどうか 1 or ''
    #   "output_format" => "tsv",         # 出力フォーマット
    #   "last_command" => "head",         # 最後のサブコマンド名
    # }
    # 2つ目は閉じ括弧よりも後ろの残ったパラメータの配列。

    my ($argv) = @_;

    ################################
    # オプション列からコマンド列を抽出する
    ################################

    my $commands = [];
    my $curr_command = undef;
    my $input = undef;
    my $output = undef;
    my $format = undef;
    my $input_header = undef;
    my $output_header_flag = 1;
    my $output_table = 1;
    my $output_format = undef;

    my $last_command = "cat";

    while () {
        my $a;
        if (@$argv) {
            $a = shift(@$argv);
        } else {
            if (defined($curr_command)) {
                $a = "cat";
            } else {
                last;
            }
        }

        if ($a eq ")") {
            if (defined($curr_command)) {
                unshift(@$argv, $a);
                $a = "cat";
            } else {
                last;
            }
        }

        my $next_command = undef;
        my $next_output_table = 1;

        my $command_name = '';
        if (defined($curr_command)) {
            $command_name = $curr_command->{command};
        }

        if ($command_name eq "cut" && ($a eq "--col" || $a eq "--cols" || $a eq "--columns")) {
            die "option $a needs an argument" unless (@$argv);
            die "duplicated option $a" if defined($curr_command->{cols});
            $curr_command->{cols} = shift(@$argv);

        } elsif ($command_name eq "cut" && !defined($curr_command->{cols})) {
            $curr_command->{cols} = $a;

        } elsif ($command_name eq "facetcount" && ($a eq "--multi-value-a")) {
            die "duplicated option $a" if defined($curr_command->{multi_value});
            $curr_command->{multi_value} = "a";

        } elsif ($a eq "--help") {
            $option_help = 1;

        } elsif ($a eq "--explain") {
            $option_explain = 1;

        } elsif ($a eq "cat") {
            $next_command = {command => "cat"};
            $last_command = $a;

        } elsif ($a eq "take" || $a eq "head" || $a eq "limit") {
            degradeMain();

        } elsif ($a eq "drop" || $a eq "offset") {
            degradeMain();

        } elsif ($a eq "where" || $a eq "filter") {
            degradeMain();

        } elsif ($a eq "cut") {
            $next_command = {command => "cut", cols => undef};
            $last_command = $a;

        } elsif ($a eq "insdate") {
            degradeMain();

        } elsif ($a eq "insweek") {
            degradeMain();

        } elsif ($a eq "addconst") {
            degradeMain();

        } elsif ($a eq "addcopy") {
            degradeMain();

        } elsif ($a eq "addlinenum") {
            degradeMain();

        } elsif ($a eq "addlinenum2") {
            degradeMain();

        } elsif ($a eq "addnumsortable") {
            degradeMain();

        } elsif ($a eq "addcross") {
            degradeMain();

        } elsif ($a eq "addmap") {
            degradeMain();

        } elsif ($a eq "uriparams") {
            degradeMain();

        } elsif ($a eq "parseuriparams") {
            degradeMain();

        } elsif ($a eq "update") {
            degradeMain();

        } elsif ($a eq "sort") {
            degradeMain();

        } elsif ($a eq "paste") {
            degradeMain();

        } elsif ($a eq "join") {
            degradeMain();

        } elsif ($a eq "union") {
            degradeMain();

        } elsif ($a eq "wcl") {
            $next_command = {command => "wcl"};
            $last_command = $a;
            $next_output_table = '';

        } elsif ($a eq "header") {
            $next_command = {command => "header"};
            $last_command = $a;
            $next_output_table = '';

        } elsif ($a eq "summary") {
            degradeMain();

        } elsif ($a eq "facetcount") {
            $next_command = {command => "facetcount", multi_value => undef};
            $last_command = $a;
            $next_output_table = '';

        } elsif ($a eq "treetable") {
            degradeMain();

        } elsif ($a eq "crosstable") {
            degradeMain();

        } elsif ($a eq "wordsflags") {
            degradeMain();

        } elsif ($a eq "countcols") {
            degradeMain();

        } elsif ($a eq "--tsv") {
            die "duplicated option: $a" if defined($format);
            $format = "tsv";

        } elsif ($a eq "--csv") {
            die "duplicated option: $a" if defined($format);
            $format = "csv";

        } elsif ($a eq "--o-tsv") {
            die "duplicated option: $a" if defined($output_format);
            $output_format = "tsv";

        } elsif ($a eq "--o-csv") {
            die "duplicated option: $a" if defined($output_format);
            $output_format = "csv";

        } elsif ($a eq "--o-table") {
            die "duplicated option: $a" if defined($output_format);
            $output_format = "table";

        } elsif ($a eq "-i") {
            die "option -i needs an argument" unless (@$argv);
            die "duplicated option: $a" if defined($input);
            $input = shift(@$argv);

        } elsif ($a eq "-o") {
            die "option -o needs an argument" unless (@$argv);
            die "duplicated option: $a" if defined($output);
            $output = shift(@$argv);

        } elsif ($a eq "--i-header") {
            degradeMain();

        } elsif ($a eq "--header") {
            die "option $a needs an argument" unless (@$argv);
            die "duplicated option: $a" if defined($input_header);
            $input_header = shift(@$argv);

        } elsif ($a eq "--o-no-header") {
            $output_header_flag = '';

        } elsif (!defined($input) && -e $a) {
            $input = $a;

        } else {
            die "Unknown argument: $a\n";
        }

        if (defined($next_command)) {
            if (defined($curr_command)) {
                push(@$commands, $curr_command);
            }
            if ($next_command->{command} eq "cat") {
                $curr_command = undef;
            } else {
                $curr_command = $next_command;
            }
            $output_table = $next_output_table;
        }
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
    if (!defined($output_format)) {
        $output_format = "tsv";
    }

    ################################
    # コマンド列を解釈して少し変換する
    ################################

    my $commands2 = [];
    for my $curr_command (@$commands) {
        my $command_name = $curr_command->{command};
=comment
        if ($command_name eq "take") {
            if ($curr_command->{1] eq "") {
                $curr_command->{1] = "10";
            }
            my $f = 1;
            if (@$commands2 && $commands2->[@$commands2 - 1]->[0] eq "range") {
                # 直前のサブコマンドと結合
                my $prev = $commands2->[@$commands2 - 1];
                if ($prev->[1] ne "" && $prev->[2] eq "") {
                    $f = '';
                    $prev->[2] = $prev->[1] + $curr_command->{1];
                }
            }
            if ($f) {
                push(@$commands2, ["range", "", $curr_command->{1]]);
            }
        } elsif ($command_name eq "drop") {
            if ($curr_command->{1] eq "") {
                $curr_command->{1] = "10";
            }
            my $f = 1;
            if (@$commands2 && $commands2->[@$commands2 - 1]->[0] eq "range") {
                # 直前のサブコマンドと結合
                my $prev = $commands2->[@$commands2 - 1];
                if ($prev->[1] eq "" && $prev->[2] ne "") {
                    $f = '';
                    if ($prev->[2] <= $curr_command->{1]) {
                        $prev->[2] = "0"; # drop all records
                    } else {
                        $prev->[1] = $curr_command->{1];
                    }
                }
            }
            if ($f) {
                push(@$commands2, ["range", $curr_command->{1], ""]);
            }
        } elsif ($command_name eq "where") {
            if (@$c <= 1) {
                die "subcommand \`where\` needs --cond option";
            }
            push(@$commands2, $c);
=cut
        if ($command_name eq "cut") {
            if (!defined($curr_command->{cols})) {
                die "subcommand \`cut\` needs --cols option";
            }
            push(@$commands2, $curr_command);
=comment
        } elsif ($command_name eq "insdate") {
            if (!defined($curr_command->{2])) {
                die "subcommand \`insdate\` needs --src option";
            }
            if (!defined($curr_command->{1])) {
                die "subcommand \`insdate\` needs --name option";
            }
            push(@$commands2, ["insdate", $curr_command->{1], $curr_command->{2]]);
        } elsif ($command_name eq "insweek") {
            if (!defined($curr_command->{2])) {
                die "subcommand \`insweek\` needs --src option";
            }
            if (!defined($curr_command->{3])) {
                die "subcommand \`insweek\` needs --start-day option";
            }
            if (!defined($curr_command->{1])) {
                die "subcommand \`insweek\` needs --name option";
            }
            push(@$commands2, ["insweek", $curr_command->{1], $curr_command->{2], $curr_command->{3]]);
        } elsif ($command_name eq "addconst") {
            if (!defined($curr_command->{1])) {
                die "subcommand \`addconst\` needs --name option";
            }
            if (!defined($curr_command->{2])) {
                $curr_command->{2] = "";
            }
            push(@$commands2, ["addconst", $curr_command->{1], $curr_command->{2]]);
        } elsif ($command_name eq "addcopy") {
            if (!defined($curr_command->{1])) {
                die "subcommand \`addcopy\` needs --name option";
            }
            if (!defined($curr_command->{2])) {
                die "subcommand \`addcopy\` needs --src option";
            }
            push(@$commands2, ["addcopy", $curr_command->{1], $curr_command->{2]]);
        } elsif ($command_name eq "addlinenum") {
            if (!defined($curr_command->{1])) {
                die "subcommand \`addlinenum\` needs --name option";
            }
            if (!defined($curr_command->{2])) {
                $curr_command->{2] = 1;
            }
            push(@$commands2, ["addlinenum", $curr_command->{1], $curr_command->{2]]);
        } elsif ($command_name eq "addlinenum2") {
            if (!defined($curr_command->{1])) {
                die "subcommand \`addlinenum2\` needs --name option";
            }
            push(@$commands2, ["addlinenum2", $curr_command->{1]]);
        } elsif ($command_name eq "addnumsortable") {
            if (!defined($curr_command->{1])) {
                die "subcommand \`addnumsortable\` needs --name option";
            }
            if (!defined($curr_command->{2])) {
                die "subcommand \`addnumsortable\` needs --col option";
            }
            push(@$commands2, ["addnumsortable", $curr_command->{1], $curr_command->{2]]);
        } elsif ($command_name eq "removecol") {
            if (!defined($curr_command->{1])) {
                die "subcommand \`removecol\` needs --count option";
            }
            push(@$commands2, ["removecol", $curr_command->{1]]);
        } elsif ($command_name eq "addcross") {
            if (!defined($curr_command->{1])) {
                die "subcommand \`addccross\` needs --name option";
            }
            if (!defined($curr_command->{2])) {
                die "subcommand \`addcross\` needs --cols option";
            }
            push(@$commands2, ["addcross", $curr_command->{1], $curr_command->{2]]);
        } elsif ($command_name eq "addmap") {
            if (!defined($curr_command->{1])) {
                die "subcommand \`addmap\` needs --name option";
            }
            if (!defined($curr_command->{2])) {
                die "subcommand \`addmap\` needs --src option";
            }
            if (!defined($curr_command->{3])) {
                die "subcommand \`addmap\` needs --file option";
            }
            push(@$commands2, ["addmap", $curr_command->{1], $curr_command->{2], $curr_command->{3], $curr_command->{4]]);
        } elsif ($command_name eq "uriparams") {
            if (!defined($curr_command->{1])) {
                die "subcommand \`uriparams\` needs --col option";
            }
            push(@$commands2, ["uriparams", $curr_command->{1], $curr_command->{3], $curr_command->{4]]);
        } elsif ($command_name eq "update") {
            if (!defined($curr_command->{1])) {
                die "subcommand \`update\` needs --index option";
            }
            if (!defined($curr_command->{2])) {
                die "subcommand \`update\` needs --col option";
            }
            if (!defined($curr_command->{3])) {
                die "subcommand \`update\` needs --value option";
            }
            if ($curr_command->{1] !~ /\A(0|[1-9][0-9]*)\z/) {
                die "option --index needs a number argument: '$curr_command->{1]'";
            }
            if ($curr_command->{2] !~ /\A[_0-9a-zA-Z][-_0-9a-zA-Z]*\z/) {
                die "Illegal column name: $curr_command->{2]\n";
            }
            push(@$commands2, ["update", $curr_command->{1], $curr_command->{2], $curr_command->{3]]);
        } elsif ($command_name eq "sort") {
            if (defined($curr_command->{1])) {
                push(@$commands2, @{parseSortParams([split(/,/, $curr_command->{1])])});
            } else {
                push(@$commands2, @{parseSortParams([])});
            }
        } elsif ($command_name eq "paste") {
            if (!defined($curr_command->{1])) {
                die "subcommand \`paste\` needs --right option";
            }
            push(@$commands2, ["paste", $curr_command->{1]]);
        } elsif ($command_name eq "join") {
            if (!defined($curr_command->{1])) {
                die "subcommand \`join\` needs --right option";
            }
            push(@$commands2, ["join", $curr_command->{1], $curr_command->{2]]);
        } elsif ($command_name eq "union") {
            if (!defined($curr_command->{1])) {
                die "subcommand \`union\` needs --right option";
            }
            push(@$commands2, ["union", $curr_command->{1]]);
=cut
        } elsif ($command_name eq "wcl") {
            push(@$commands2, $curr_command);
        } elsif ($command_name eq "header") {
            push(@$commands2, $curr_command);
=comment
        } elsif ($command_name eq "summary") {
            push(@$commands2, ["summary"]);
=cut
        } elsif ($command_name eq "facetcount") {
            if (!defined($curr_command->{multi_value})) {
                $curr_command->{multi_value} = "";
            }
            push(@$commands2, $curr_command);
=comment
        } elsif ($command_name eq "treetable") {
            push(@$commands2, ["treetable", $curr_command->{1], $curr_command->{2]]);
        } elsif ($command_name eq "crosstable") {
            push(@$commands2, ["crosstable", $curr_command->{1], $curr_command->{2]]);
        } elsif ($command_name eq "wordsflags") {
            if (@$c <= 1) {
                die "subcommand \`wordsflags\` needs --flag option";
            }
            push(@$commands2, $c);
        } elsif ($command_name eq "countcols") {
            push(@$commands2, ["countcols"]);
=cut
        } else {
            die $command_name;
        }
    }

    ({"commands" => $commands2,
      "input" => $input,
      "output" => $output,
      "format" => $format,
      "input_header" => $input_header,
      "output_header_flag" => $output_header_flag,
      "output_table" => $output_table,
      "output_format" => $output_format,
      "last_command" => $last_command},
     $argv);
}

my ($command_seq, $tail_argv) = parseQuery(\@ARGV);

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
# named pipe
################################################################################

my $input_pipe_prefix1 = "\$WORKING_DIR/pipe_input_";
my $input_pipe_prefix2 = "$WORKING_DIR/pipe_input_";

my $input_pipe_list = [{"prefetch" => 1,
                        "source" => $command_seq->{input},
                        "format" => $command_seq->{format},
                        "header" => $command_seq->{input_header},
                        "charencoding" => "",
                        "utf8bom" => "0",
                       }];
    # Sample
    # [
    #  {
    #    "prefetch" => 1, # prefetchするかどうか 1 or ''
    #    "source" => "", # 入力ファイル名。0番以外で source が存在する場合に限って後に ircode が作成される
    #    "format" => "", # 入力フォーマット、または空文字列は自動判定の意味
    #    "header" => "", # カンマ区切りでのヘッダ名の列、または空文字列はヘッダ行ありの意味
    #    "charencoding" => "",
    #    "utf8bom" => "0",
    #  }
    # ]

my $statement_list = [];
    # Sample
    # [
    #  {
    #   "input_pipe_id"  => 3,
    #   "output_pipe_id" => 4,
    #   "query" => { "commands" => ... },
    #  }
    # ]

sub extractNamedPipe {
    my ($command_seq) = @_;

    my $commands2 = [];
    for (my $i = 0; $i < @{$command_seq->{commands}}; $i++) {
        my $curr_command = $command_seq->{commands}->[$i];
        push(@$commands2, $curr_command);
    }

    $command_seq->{commands} = $commands2;
}

extractNamedPipe($command_seq);


################################################################################
# guess format
################################################################################

sub prefetch_input_pipe_list {
    for (my $i = 0; $i < @$input_pipe_list; $i++) {
        my $input = $input_pipe_list->[$i];

        unless ($input->{prefetch}) {
            if ($input->{format} eq '') {
                $input->{format} = 'tsv';
            }
            if ($input->{charencoding} eq '') {
                $input->{charencoding} = 'UTF-8';
            }
            $input->{utf8bom} = '0';
            next;
        }

        $input_pipe_list->[$i] = prefetch_input($input, $i);
    }
}

sub prefetch_input {
    my ($input, $pipe_id) = @_;

    my $input_pipe_path = $input->{source}; # empty string if stdin
    my $output_pipe_path = "$input_pipe_prefix2${pipe_id}_0";

    my $format_result_path = "$input_pipe_prefix2${pipe_id}_format";

    mkfifo($output_pipe_path, 0700) or die $!;
    mkfifo($format_result_path, 0700) or die $!;

    my $pid1 = fork;
    if (!defined $pid1) {
        die $!;
    } elsif ($pid1) {
        # parent process

    } else {
        # child process

        if ($input_pipe_path ne '') {
            open(my $out_fh, '<', $input_pipe_path) or die $!;
            open(STDIN, '<&=', fileno($out_fh));
        }

        my @command_line = ("perl", "$TOOL_DIR/format-wrapper.pl");
        if ($input->{format} eq 'tsv') {
            push(@command_line, '--tsv');
        } elsif ($input->{format} eq 'csv') {
            push(@command_line, '--csv');
        }
        if ($input->{charencoding} eq '') {
            # TODO
        }
        push(@command_line, $format_result_path);
        push(@command_line, $output_pipe_path);
        exec(@command_line);
    }

    open(my $format_fh, '<', $format_result_path) or die $!;
    my $format = <$format_fh>;
    close($format_fh);

    if ($format !~ /^format:([^ ]+) charencoding:([^ ]+) utf8bom:([^ ]+)$/) {
        die "failed to guess format $input_pipe_path";
    }
    $input->{format}       = $1;
    $input->{charencoding} = $2;
    $input->{utf8bom}      = $3;

    return $input;
}

prefetch_input_pipe_list();


################################################################################
# subcommand list to intermediate code
################################################################################

sub build_ircode {
    foreach (my $pipe_id = 1; $pipe_id < @$input_pipe_list; $pipe_id++) {
        my $s = $input_pipe_list->[$pipe_id];
        next if ($s->{source} eq '');
        build_ircode_input($s, $pipe_id);
    }
    foreach my $s (@$statement_list) {
        build_ircode_command($s->{query}, $s->{input_pipe_id}, '');
    }
    build_ircode_command($command_seq, '', $isOutputTty);
}

sub build_ircode_input {
    my ($input_pipe, $pipe_id) = @_;

    my $ircode;
    if ($input_pipe->{prefetch}) {
        my $source = escape_for_bash($input_pipe->{source});
        $ircode = [["cmd", "cat $input_pipe_prefix1${pipe_id}_0"]];
    } else {
        my $source = escape_for_bash($input_pipe->{source});
        $ircode = [["cmd", "cat $source"]];
    }

    if ($input_pipe->{utf8bom} eq "1") {
        push(@$ircode, ["cmd", "tail -c+4"]);
    }

    if ($input_pipe->{charencoding} ne "UTF-8") {
        push(@$ircode, ["cmd", "iconv -f $input_pipe->{charencoding} -t UTF-8//TRANSLIT"]);
    }

    if ($input_pipe->{format} eq "csv") {
        push(@$ircode, ["cmd", "\$TOOL_DIR/golang.bin csv2tsv"]);
    }

    if ($input_pipe->{header} ne '') {
        my @headers = split(/,/, $input_pipe->{header});
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

    $input_pipe->{ircode} = ["pipe", $ircode];
}

sub build_ircode_command {
    my ($command_seq, $input_pipe_id, $isOutputTty) = @_;

    my $ircode;
    if ($input_pipe_id eq "") {
        $ircode = [["cmd", "cat"]];
    } else {
        $ircode = [["cmd", "cat ${input_pipe_prefix1}$input_pipe_id"]];
    }

    if ($input_pipe_id eq "") {
        my $input_pipe = $input_pipe_list->[0];

        if ($input_pipe->{utf8bom} eq "1") {
            push(@$ircode, ["cmd", "tail -c+4"]);
        }

        if ($input_pipe->{charencoding} ne "UTF-8") {
            push(@$ircode, ["cmd", "iconv -c -f $input_pipe->{charencoding} -t UTF-8//TRANSLIT"]);
        }

        if ($input_pipe->{format} eq "csv") {
            push(@$ircode, ["cmd", "\$TOOL_DIR/golang.bin csv2tsv"]);
        }

        if ($input_pipe->{header} ne '') {
            my @headers = split(/,/, $input_pipe->{header});
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
    }

    foreach my $curr_command (@{$command_seq->{commands}}) {
        my $command_name = $curr_command->{command};
=comment
        if ($command_name eq "range") {
            my $num1 = $curr_command->{1];
            my $num2 = $curr_command->{2];
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
                    my $arg = escape_for_bash(($num1 + 2) . ',' . ($num2 + 1) . 'p');
                    push(@$ircode, ["cmd", "sed -n -e 1p -e $arg"]);
                }
            }

        } elsif ($command_name eq "where") {
            my $conds = '';
            for (my $i = 1; $i < @$t; $i++) {
                $conds .= ' ' . escape_for_bash($curr_command->{$i]);
            }
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/where.pl$conds"]);

=cut
        if ($command_name eq "cut") {
            my $cols = escape_for_bash($curr_command->{cols});
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/cut.pl --col $cols"]);

=comment
        } elsif ($command_name eq "insdate") {
            my $name  = escape_for_bash($curr_command->{1]);
            my $src = escape_for_bash($curr_command->{2]);
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/insdate.pl --name $name --src $src"]);

        } elsif ($command_name eq "insweek") {
            my $name  = escape_for_bash($curr_command->{1]);
            my $src = escape_for_bash($curr_command->{2]);
            my $start_day = escape_for_bash($curr_command->{3]);
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/insweek.pl --name $name --src $src --start-day $start_day"]);

        } elsif ($command_name eq "addconst") {
            my $name  = escape_for_bash($curr_command->{1]);
            my $value = escape_for_bash($curr_command->{2]);
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/addconst.pl --name $name --value $value"]);

        } elsif ($command_name eq "addcopy") {
            my $name  = escape_for_bash($curr_command->{1]);
            my $src = escape_for_bash($curr_command->{2]);
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/addcopy.pl --name $name --src $src"]);

        } elsif ($command_name eq "addlinenum") {
            my $name  = escape_for_bash($curr_command->{1]);
            my $value = escape_for_bash($curr_command->{2]);
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/addlinenum.pl --name $name --value $value"]);

        } elsif ($command_name eq "addlinenum2") {
            my $name  = escape_for_bash($curr_command->{1]);
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/addlinenum2.pl --name $name"]);

        } elsif ($command_name eq "addnumsortable") {
            my $name  = escape_for_bash($curr_command->{1]);
            my $col = escape_for_bash($curr_command->{2]);
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/addnumsortable.pl --name $name --col $col"]);

        } elsif ($command_name eq "addcross") {
            my $name  = escape_for_bash($curr_command->{1]);
            my $cols = escape_for_bash($curr_command->{2]);
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/addcross.pl --name $name --col $cols"]);

        } elsif ($command_name eq "addmap") {
            my $name  = escape_for_bash($curr_command->{1]);
            my $src = escape_for_bash($curr_command->{2]);
            my $file = escape_for_bash($curr_command->{3]);
            my $option = "";
            if (defined($curr_command->{4])) {
                $option .= " --default ". escape_for_bash($curr_command->{4]);
            }
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/addmap.pl$option --name $name --src $src --file $file"]);

        } elsif ($command_name eq "removecol") {
            my $count  = escape_for_bash($curr_command->{1]);
            my $arg = '-f' . ($count + 1) . '-';
            push(@$ircode, ["cmd", "cut $arg"]);

        } elsif ($command_name eq "uriparams") {
            push(@$ircode, ["cmd", "tail -n+2"]);
            push(@$ircode, ["cmd", "bash \$TOOL_DIR/pre-encode-percent.sh"]);
            my $option = "";
            if ($curr_command->{1] eq "") {
                $option .= " --names";
            } else {
                my $cols = escape_for_bash($curr_command->{1]);
                $option .= " --fields $cols";
            }
            if ($curr_command->{3] eq "b") {
                $option .= " --multi-value-b";
            }
            push(@$ircode, ["cmd", "\$TOOL_DIR/golang.bin uriparams2tsv$option"]);
            if ($curr_command->{2] eq "decode") {
                push(@$ircode, ["cmd", "bash \$TOOL_DIR/decode-percent.sh"]); # TODO $colsもデコードされてしまう問題あり
            }

        } elsif ($command_name eq "update") {
            my $index = escape_for_bash($curr_command->{1]);
            my $column = escape_for_bash($curr_command->{2]);
            my $value = escape_for_bash($curr_command->{3]);
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/update.pl $index:$column=$value"]);

        } elsif ($command_name eq "sort") {
            push(@$ircode, ["cmd", "\$TOOL_DIR/golang.bin fldsort --header"]);

        } elsif ($command_name eq "tee") {
            my $branch = escape_for_bash($curr_command->{1]);
            $branch = "$input_pipe_prefix${branch}";
            push(@$ircode, ["cmd", "tee $branch"]);

        } elsif ($command_name eq "buffer") {
            push(@$ircode, ["cmd", "\$TOOL_DIR/golang.bin buffer"]);
        } elsif ($command_name eq "buffer-debug") {
            push(@$ircode, ["cmd", "\$TOOL_DIR/golang.bin buffer --debug"]);

        } elsif ($command_name eq "paste") {
            my $right = escape_for_bash($curr_command->{1]);
            $right = "$input_pipe_prefix${right}";
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/paste.pl --right $right"]);

        } elsif ($command_name eq "join") {
            my $option = "";
            $option .= " --" . $curr_command->{2];
            my $right = escape_for_bash($curr_command->{1]);
            $right = "$input_pipe_prefix${right}";
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/join.pl$option --right $right"]);

        } elsif ($command_name eq "union") {
            my $right = escape_for_bash($curr_command->{1]);
            $right = "$input_pipe_prefix${right}";
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/union.pl - $right"]);

=cut
        } elsif ($command_name eq "wcl") {
            push(@$ircode, ["cmd", "\$TOOL_DIR/golang.bin wcl --header"]);

        } elsif ($command_name eq "header") {
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/header.pl"]);

=comment
        } elsif ($command_name eq "summary") {
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/summary.pl"]);

=cut
        } elsif ($command_name eq "facetcount") {
            my $option = "";
            if ($curr_command->{multi_value} eq "a") {
                $option .= " --multi-value-a";
            }
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/facetcount.pl$option"]);

=comment
        } elsif ($command_name eq "treetable") {
            my $option = "";
            if (defined($curr_command->{1])) {
                $option .= " --top " . escape_for_bash($curr_command->{1]);
            }
            if ($curr_command->{2] eq "multi-value-a") {
                $option .= " --multi-value-a";
            }
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/treetable.pl$option"]);

        } elsif ($command_name eq "crosstable") {
            my $option = "";
            if (defined($curr_command->{1])) {
                $option .= " --top " . escape_for_bash($curr_command->{1]);
            }
            if ($curr_command->{2] eq "multi-value-a") {
                $option .= " --multi-value-a";
            }
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/crosstable.pl$option"]);

        } elsif ($command_name eq "wordsflags") {
            my $flags = '';
            for (my $i = 1; $i < @$t; $i++) {
                $flags .= ' ' . escape_for_bash($curr_command->{$i]);
            }
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/wordsflags.pl$flags"]);

        } elsif ($command_name eq "countcols") {
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/countcols.pl"]);

=cut
        } else {
            die $command_name;
        }
    }

    $command_seq->{ircode} = ["pipe", $ircode];
}

build_ircode();


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

my $main_1_source = "(\n";

my $isPager = '';
if ($isOutputTty && $command_seq->{output} eq "") {
    $isPager = 1;
}

my $exists_multijob = '';

foreach (my $pipe_id = 0; $pipe_id < @$input_pipe_list; $pipe_id++) {
    my $s = $input_pipe_list->[$pipe_id];
    if (defined($s->{ircode})) {
        if ($s->{source} ne '') {
            $main_1_source = $main_1_source . "    # " . escape_for_bash($s->{source}) . "\n";
        }
        my $lines = irToShellscript($s->{ircode});

        $main_1_source = $main_1_source . "    mkfifo $input_pipe_prefix1${pipe_id}\n";
        $main_1_source = $main_1_source . "    " . join("\n    ", @$lines) . " > $input_pipe_prefix1${pipe_id} &\n\n";

        $exists_multijob = 1;
    } elsif ($pipe_id > 0) {
        $main_1_source = $main_1_source . "    mkfifo $input_pipe_prefix1${pipe_id}\n\n";
    }
}

foreach my $s (@$statement_list) {
    my $output_pipe_id = $s->{output_pipe_id};
    $main_1_source = $main_1_source . "    " . join("\n    ", @{irToShellscript($s->{query}->{ircode})}) . " > $input_pipe_prefix1${output_pipe_id} &\n\n";
    $exists_multijob = 1;
}

if ($exists_multijob) {
    $main_1_source = $main_1_source . "    " . join("\n    ", @{irToShellscript($command_seq->{ircode})}) . " &\n";
    $main_1_source = $main_1_source . "\n    wait\n";
} else {
    $main_1_source = $main_1_source . "    " . join("\n    ", @{irToShellscript($command_seq->{ircode})}) . "\n";
}

$main_1_source = $main_1_source . ")";

{
    my $table_option = "";
    my $last_command = $command_seq->{last_command};
    if ($last_command ne "countcols") {
        $table_option .= " --col-number";
        $table_option .= " --record-number";
    }
    if ($last_command eq "summary") {
        $table_option .= " --max-width 500";
    }

    if ($isPager) {
        $main_1_source = $main_1_source . " | perl \$TOOL_DIR/table.pl$table_option";
        $main_1_source = $main_1_source . " | less -SRX";

    } else {
        if (!$command_seq->{output_header_flag}) {
            $main_1_source = $main_1_source . " | tail -n+2";
        }
        if ($command_seq->{output_format} eq "csv") {
            $main_1_source = $main_1_source . " | perl \$TOOL_DIR/to-csv.pl";
        } elsif ($command_seq->{output_format} eq "table") {
            $main_1_source = $main_1_source . " | perl \$TOOL_DIR/table.pl$table_option";
        }

    }
}

$main_1_source = $main_1_source . "\n";

$main_1_source = "# -v2\n" . $main_1_source;

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

if (1) {
    # 入力を stdin に統一
    my $pipe_id = 0;
    my $pipe_path = "$input_pipe_prefix2${pipe_id}_0";
    open(my $fh, '<', $pipe_path) or die $!;
    open(STDIN, '<&=', fileno($fh));
}

if ($command_seq->{output} ne "") {
    # 出力を stdout に統一
    open(my $data_out, '>', $command_seq->{output}) or die $!;
    open(STDOUT, '>&=', fileno($data_out));
}


################################################################################
# exec script
################################################################################

exec("bash", "$WORKING_DIR/main-1.sh");


################################################################################

