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

sub parseSortParams {
    my ($arg) = @_;
    my @args = split(/,/, $arg);
    my $commands = [];
    push(@$commands, ["addlinenum2", ""]);
    my $c = 1;
    while (@args) {
        my $a = pop(@args);
        if ($a =~ /\A([_0-9a-zA-Z][-_0-9a-zA-Z]*):n\z/) {
            push(@$commands, ["addnumsortable", "", $1]);
        } else {
            push(@$commands, ["addcopy", "", $a]);
        }
        $c++;
    }
    push(@$commands, ["sort"]);
    push(@$commands, ["removecol", $c]);
    $commands;
}

sub parseQuery {
    # 2値を返す関数。
    # 1つ目の返り値の例
    # { "commands" => [["range", "", "20"], ["cut", "id,name"]],
    #   "input" => "",                    # 入力ファイル名、または空文字列は標準入力の意味
    #   "output" => "",                   # 出力ファイル名、または空文字列は標準出力の意味
    #   "format" => "",                   # 入力フォーマット、または空文字列は自動判定の意味
    #   "input_header" => "id,name,desc", # カンマ区切りでのヘッダ名の列、または空文字列はヘッダ行ありの意味
    #   "output_header_flag" => 1,        # 出力にヘッダをつけるかどうか 1 or ''
    #   "output_table" => 1,              # TSV形式での出力かどうか 1 or ''
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

    my $last_command = "cat";

    while (@$argv) {
        my $a = shift(@$argv);

        last if ($a eq ")");

        my $next_command = undef;
        my $next_output_table = 1;

        if ($a eq "--help") {
            $option_help = 1;
        } elsif ($a eq "--explain") {
            $option_explain = 1;

        } elsif ($a eq "cat") {
            $next_command = ["cat"];
            $last_command = $a;

        } elsif ($a eq "take" || $a eq "head" || $a eq "limit") {
            $next_command = ["take", ""];
            $last_command = $a;

        } elsif ($a eq "drop" || $a eq "offset") {
            $next_command = ["drop", ""];
            $last_command = $a;

        } elsif ($a eq "filter") {
            $next_command = ["filter"];
            $last_command = $a;

        } elsif ($a eq "cut") {
            $next_command = ["cut", ""];
            $last_command = $a;

        } elsif ($a eq "addconst") {
            $next_command = ["addconst", undef, undef];
            $last_command = $a;

        } elsif ($a eq "addcopy") {
            $next_command = ["addcopy", undef, undef];
            $last_command = $a;

        } elsif ($a eq "addlinenum") {
            $next_command = ["addlinenum", undef, undef];
            $last_command = $a;

        } elsif ($a eq "addlinenum2") {
            $next_command = ["addlinenum2", undef];
            $last_command = $a;

        } elsif ($a eq "addnumsortable") {
            $next_command = ["addnumsortable", undef, undef];
            $last_command = $a;

        } elsif ($a eq "addcross") {
            $next_command = ["addcross", undef, undef];
            $last_command = $a;

        } elsif ($a eq "parseuriparams") {
            $next_command = ["parseuriparams", "", "decode"];
            $last_command = $a;

        } elsif ($a eq "update") {
            $next_command = ["update", undef, undef, undef];
            $last_command = $a;

        } elsif ($a eq "sort") {
            $next_command = ["sort", undef];
            $last_command = $a;

        } elsif ($a eq "paste") {
            $next_command = ["paste", undef];
            $last_command = $a;

        } elsif ($a eq "union") {
            $next_command = ["union", undef];
            $last_command = $a;

        } elsif ($a eq "wcl") {
            $next_command = ["wcl"];
            $last_command = $a;
            $next_output_table = '';

        } elsif ($a eq "header") {
            $next_command = ["header"];
            $last_command = $a;
            $next_output_table = '';

        } elsif ($a eq "summary") {
            $next_command = ["summary"];
            $last_command = $a;
            $next_output_table = '';

        } elsif ($a eq "facetcount") {
            $next_command = ["facetcount"];
            $last_command = $a;
            $next_output_table = '';

        } elsif ($a eq "wordsflags") {
            $next_command = ["wordsflags"];
            $last_command = $a;
            $next_output_table = '';

        } elsif ($a eq "countcols") {
            $next_command = ["countcols"];
            $last_command = $a;
            $next_output_table = '';

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

            } elsif ($curr_command->[0] eq "filter") {
                my $cond = undef;
                if ($a eq "--cond") {
                    die "option $a needs an argument" unless (@$argv);
                    $cond =  shift(@$argv);
                } else {
                    $cond = $a;
                }
                if (defined($cond)) {
                    if ($cond =~ /\A([_0-9a-zA-Z][-_0-9a-zA-Z]*)=(.*)\z/) {
                        push(@$curr_command, $a);
                    } else {
                        die "Unknown condition format: $a\n";
                    }
                }
            } elsif ($curr_command->[0] eq "cut") {
                if ($a eq "--col" || $a eq "--cols" || $a eq "--columns") {
                    die "option $a needs an argument" unless (@$argv);
                    $curr_command->[1] = shift(@$argv);
                } else {
                    $curr_command->[1] = $a;
                }

            } elsif ($curr_command->[0] eq "addconst") {
                if ($a eq "--name") {
                    die "option $a needs an argument" unless (@$argv);
                    my $name = shift(@$argv);
                    if (defined($curr_command->[1])) {
                        die "duplicated option: --name";
                    }
                    $curr_command->[1] = $name;
                } elsif ($a eq "--value") {
                    die "option $a needs an argument" unless (@$argv);
                    my $value = shift(@$argv);
                    if (defined($curr_command->[2])) {
                        die "duplicated option: --value";
                    }
                    $curr_command->[2] = $value;
                } elsif (!defined($curr_command->[1])) {
                    my $name = $a;
                    $curr_command->[1] = $name;
                } elsif (!defined($curr_command->[2])) {
                    my $value = $a;
                    $curr_command->[2] = $value;
                } else {
                    die "Unknown argument: $a";
                }

            } elsif ($curr_command->[0] eq "addcopy") {
                if ($a eq "--name") {
                    die "option $a needs an argument" unless (@$argv);
                    my $name = shift(@$argv);
                    if (defined($curr_command->[1])) {
                        die "duplicated option: --name";
                    }
                    $curr_command->[1] = $name;
                } elsif ($a eq "--src") {
                    die "option $a needs an argument" unless (@$argv);
                    my $src = shift(@$argv);
                    if (defined($curr_command->[2])) {
                        die "duplicated option: --src";
                    }
                    $curr_command->[2] = $src;
                } elsif (!defined($curr_command->[1])) {
                    my $name = $a;
                    $curr_command->[1] = $name;
                } elsif (!defined($curr_command->[2])) {
                    my $src = $a;
                    $curr_command->[2] = $src;
                } else {
                    die "Unknown argument: $a";
                }

            } elsif ($curr_command->[0] eq "addlinenum") {
                if ($a eq "--name") {
                    die "option $a needs an argument" unless (@$argv);
                    my $name = shift(@$argv);
                    if (defined($curr_command->[1])) {
                        die "duplicated option: --name";
                    }
                    $curr_command->[1] = $name;
                } elsif ($a eq "--value") {
                    die "option $a needs an argument" unless (@$argv);
                    my $value = shift(@$argv);
                    if (defined($curr_command->[2])) {
                        die "duplicated option: --value";
                    }
                    $curr_command->[2] = $value;
                } elsif (!defined($curr_command->[1])) {
                    my $name = $a;
                    $curr_command->[1] = $name;
                } elsif (!defined($curr_command->[2])) {
                    my $value = $a;
                    $curr_command->[2] = $value;
                } else {
                    die "Unknown argument: $a";
                }

            } elsif ($curr_command->[0] eq "addlinenum2") {
                if ($a eq "--name") {
                    die "option $a needs an argument" unless (@$argv);
                    my $name = shift(@$argv);
                    if (defined($curr_command->[1])) {
                        die "duplicated option: --name";
                    }
                    $curr_command->[1] = $name;
                } elsif (!defined($curr_command->[1])) {
                    my $name = $a;
                    $curr_command->[1] = $name;
                } else {
                    die "Unknown argument: $a";
                }

            } elsif ($curr_command->[0] eq "addnumsortable") {
                if ($a eq "--name") {
                    die "option $a needs an argument" unless (@$argv);
                    my $name = shift(@$argv);
                    if (defined($curr_command->[1])) {
                        die "duplicated option: --name";
                    }
                    $curr_command->[1] = $name;
                } elsif ($a eq "--col") {
                    die "option $a needs an argument" unless (@$argv);
                    my $col = shift(@$argv);
                    if (defined($curr_command->[2])) {
                        die "duplicated option: --col";
                    }
                    $curr_command->[2] = $col;
                } elsif (!defined($curr_command->[1])) {
                    my $name = $a;
                    $curr_command->[1] = $name;
                } elsif (!defined($curr_command->[2])) {
                    my $col = $a;
                    $curr_command->[2] = $col;
                } else {
                    die "Unknown argument: $a";
                }

            } elsif ($curr_command->[0] eq "addcross") {
                if ($a eq "--name") {
                    die "option $a needs an argument" unless (@$argv);
                    my $name = shift(@$argv);
                    if (defined($curr_command->[1])) {
                        die "duplicated option: --name";
                    }
                    $curr_command->[1] = $name;
                } elsif ($a eq "--col" || $a eq "--cols" || $a eq "--columns") {
                    die "option $a needs an argument" unless (@$argv);
                    my $src = shift(@$argv);
                    if (defined($curr_command->[2])) {
                        die "duplicated option: --cols";
                    }
                    $curr_command->[2] = $src;
                } elsif (!defined($curr_command->[1])) {
                    my $name = $a;
                    $curr_command->[1] = $name;
                } elsif (!defined($curr_command->[2])) {
                    my $cols = $a;
                    $curr_command->[2] = $cols;
                } else {
                    die "Unknown argument: $a";
                }

            } elsif ($curr_command->[0] eq "parseuriparams") {
                if ($a eq "--col" || $a eq "--cols" || $a eq "--columns") {
                    die "option $a needs an argument" unless (@$argv);
                    $curr_command->[1] = shift(@$argv);
                } elsif ($a eq "--no-decode") {
                    $curr_command->[2] = "no-decode";
                } else {
                    $curr_command->[1] = $a;
                }

            } elsif ($curr_command->[0] eq "update") {
                if ($a eq "--index") {
                    die "option $a needs an argument" unless (@$argv);
                    if (defined($curr_command->[1])) {
                        die "duplicated option: --index";
                    }
                    $curr_command->[1] = shift(@$argv);
                } elsif ($a eq "--col") {
                    die "option $a needs an argument" unless (@$argv);
                    if (defined($curr_command->[2])) {
                        die "duplicated option: --col";
                    }
                    $curr_command->[2] = shift(@$argv);
                } elsif ($a eq "--value") {
                    die "option $a needs an argument" unless (@$argv);
                    if (defined($curr_command->[3])) {
                        die "duplicated option: --value";
                    }
                    $curr_command->[3] = shift(@$argv);
                } elsif (!defined($curr_command->[1])) {
                    $curr_command->[1] = $a;
                } elsif (!defined($curr_command->[2])) {
                    $curr_command->[2] = $a;
                } elsif (!defined($curr_command->[3])) {
                    $curr_command->[3] = $a;
                } else {
                    die "Unknown argument: $a";
                }

            } elsif ($curr_command->[0] eq "sort") {
                if ($a eq "--col" || $a eq "--cols" || $a eq "--columns") {
                    die "option $a needs an argument" unless (@$argv);
                    $curr_command->[1] = shift(@$argv);
                } else {
                    $curr_command->[1] = $a;
                }

            } elsif ($curr_command->[0] eq "paste") {
                if ($a eq "--right") {
                    die "option $a needs an argument" unless (@$argv);
                    $curr_command->[1] = shift(@$argv);
                } elsif ($a eq "(") {
                    ($curr_command->[1], $argv) = parseQuery($argv);
                } else {
                    $curr_command->[1] = $a;
                }

            } elsif ($curr_command->[0] eq "union") {
                if ($a eq "--right") {
                    die "option $a needs an argument" unless (@$argv);
                    $curr_command->[1] = shift(@$argv);
                } elsif ($a eq "(") {
                    ($curr_command->[1], $argv) = parseQuery($argv);
                } else {
                    $curr_command->[1] = $a;
                }

            } elsif ($curr_command->[0] eq "wordsflags") {
                if ($a eq "--flag") {
                    die "option $a needs an argument" unless (@$argv);
                    push(@$curr_command, shift(@$argv));
                } else {
                    push(@$curr_command, $a);
                }

            }

        } else {
            die "Unknown argument: $a\n";
        }
        if (defined($next_command)) {
            if (defined($curr_command)) {
                #die "command `$curr_command->[0]` must be last\n" unless ($output_table);
                push(@$commands, $curr_command);
            }
            if ($next_command->[0] eq "cat") {
                $curr_command = undef;
            } else {
                $curr_command = $next_command;
            }
            $output_table = $next_output_table;
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

    ################################
    # コマンド列を解釈して少し変換する
    ################################

    my $commands2 = [];
    for my $c (@$commands) {
        if ($c->[0] eq "take") {
            if ($c->[1] eq "") {
                $c->[1] = "10";
            }
            my $f = 1;
            if (@$commands2 && $commands2->[@$commands2 - 1]->[0] eq "range") {
                # 直前のサブコマンドと結合
                my $prev = $commands2->[@$commands2 - 1];
                if ($prev->[1] ne "" && $prev->[2] eq "") {
                    $f = '';
                    $prev->[2] = $prev->[1] + $c->[1];
                }
            }
            if ($f) {
                push(@$commands2, ["range", "", $c->[1]]);
            }
        } elsif ($c->[0] eq "drop") {
            if ($c->[1] eq "") {
                $c->[1] = "10";
            }
            my $f = 1;
            if (@$commands2 && $commands2->[@$commands2 - 1]->[0] eq "range") {
                # 直前のサブコマンドと結合
                my $prev = $commands2->[@$commands2 - 1];
                if ($prev->[1] eq "" && $prev->[2] ne "") {
                    $f = '';
                    if ($prev->[2] <= $c->[1]) {
                        $prev->[2] = "0"; # drop all records
                    } else {
                        $prev->[1] = $c->[1];
                    }
                }
            }
            if ($f) {
                push(@$commands2, ["range", $c->[1], ""]);
            }
        } elsif ($c->[0] eq "filter") {
            if (@$c <= 1) {
                die "subcommand \`filter\` needs --cond option";
            }
            push(@$commands2, $c);
        } elsif ($c->[0] eq "cut") {
            if ($c->[1] eq "") {
                die "subcommand \`cut\` needs --col option";
            }
            push(@$commands2, ["cut", $c->[1]]);
        } elsif ($c->[0] eq "addconst") {
            if (!defined($c->[1])) {
                die "subcommand \`addconst\` needs --name option";
            }
            if (!defined($c->[2])) {
                $c->[2] = "";
            }
            push(@$commands2, ["addconst", $c->[1], $c->[2]]);
        } elsif ($c->[0] eq "addcopy") {
            if (!defined($c->[1])) {
                die "subcommand \`addcopy\` needs --name option";
            }
            if (!defined($c->[2])) {
                die "subcommand \`addcopy\` needs --src option";
            }
            push(@$commands2, ["addcopy", $c->[1], $c->[2]]);
        } elsif ($c->[0] eq "addlinenum") {
            if (!defined($c->[1])) {
                die "subcommand \`addlinenum\` needs --name option";
            }
            if (!defined($c->[2])) {
                $c->[2] = 1;
            }
            push(@$commands2, ["addlinenum", $c->[1], $c->[2]]);
        } elsif ($c->[0] eq "addlinenum2") {
            if (!defined($c->[1])) {
                die "subcommand \`addlinenum2\` needs --name option";
            }
            push(@$commands2, ["addlinenum2", $c->[1]]);
        } elsif ($c->[0] eq "addnumsortable") {
            if (!defined($c->[1])) {
                die "subcommand \`addnumsortable\` needs --name option";
            }
            if (!defined($c->[2])) {
                die "subcommand \`addnumsortable\` needs --col option";
            }
            push(@$commands2, ["addnumsortable", $c->[1], $c->[2]]);
        } elsif ($c->[0] eq "removecol") {
            if (!defined($c->[1])) {
                die "subcommand \`removecol\` needs --count option";
            }
            push(@$commands2, ["removecol", $c->[1]]);
        } elsif ($c->[0] eq "addcross") {
            if (!defined($c->[1])) {
                die "subcommand \`addccross\` needs --name option";
            }
            if (!defined($c->[2])) {
                die "subcommand \`addcross\` needs --cols option";
            }
            push(@$commands2, ["addcross", $c->[1], $c->[2]]);
        } elsif ($c->[0] eq "parseuriparams") {
            if ($c->[1] eq "") {
                die "subcommand \`parseuriparams\` needs --col option";
            }
            push(@$commands2, ["parseuriparams", $c->[1], $c->[2]]);
        } elsif ($c->[0] eq "update") {
            if (!defined($c->[1])) {
                die "subcommand \`update\` needs --index option";
            }
            if (!defined($c->[2])) {
                die "subcommand \`update\` needs --col option";
            }
            if (!defined($c->[3])) {
                die "subcommand \`update\` needs --value option";
            }
            if ($c->[1] !~ /\A(0|[1-9][0-9]*)\z/) {
                die "option --index needs a number argument: '$c->[1]'";
            }
            if ($c->[2] !~ /\A[_0-9a-zA-Z][-_0-9a-zA-Z]*\z/) {
                die "Illegal column name: $c->[2]\n";
            }
            push(@$commands2, ["update", $c->[1], $c->[2], $c->[3]]);
        } elsif ($c->[0] eq "sort") {
            if (defined($c->[1])) {
                push(@$commands2, @{parseSortParams($c->[1])});
            } else {
                push(@$commands2, ["sort"]);
            }
        } elsif ($c->[0] eq "paste") {
            if (!defined($c->[1])) {
                die "subcommand \`paste\` needs --right option";
            }
            push(@$commands2, ["paste", $c->[1]]);
        } elsif ($c->[0] eq "union") {
            if (!defined($c->[1])) {
                die "subcommand \`union\` needs --right option";
            }
            push(@$commands2, ["union", $c->[1]]);
        } elsif ($c->[0] eq "wcl") {
            push(@$commands2, ["wcl"]);
        } elsif ($c->[0] eq "header") {
            push(@$commands2, ["header"]);
        } elsif ($c->[0] eq "summary") {
            push(@$commands2, ["summary"]);
        } elsif ($c->[0] eq "facetcount") {
            push(@$commands2, ["facetcount"]);
        } elsif ($c->[0] eq "wordsflags") {
            if (@$c <= 1) {
                die "subcommand \`wordsflags\` needs --flag option";
            }
            push(@$commands2, $c);
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
      "output_header_flag" => $output_header_flag,
      "output_table" => $output_table,
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

my $input_pipe_prefix = "\$WORKING_DIR/pipe_input_";
my $input_pipe_prefix2 = "$WORKING_DIR/pipe_input_";

my $input_pipe_list = [{"prefetch" => 1,
                        "source" => $command_seq->{input},
                        "format" => $command_seq->{format},
                        "header" => $command_seq->{input_header},
                        "charencoding" => "",
                       }];
    # Sample
    # [
    #  {
    #    "prefetch" => 1, # prefetchするかどうか 1 or ''
    #    "source" => "", # 入力ファイル名。0番以外で source が存在する場合に限って後に ircode が作成される
    #    "format" => "", # 入力フォーマット、または空文字列は自動判定の意味
    #    "header" => "", # カンマ区切りでのヘッダ名の列、または空文字列はヘッダ行ありの意味
    #    "charencoding" => ""
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
        if ($curr_command->[0] eq "paste" || $curr_command->[0] eq "union") {
            if (ref($curr_command->[1]) eq "HASH") {
                my $subquery = $curr_command->[1];

                if ($subquery->{output} ne "") {
                    die "sub query of subcommand `$curr_command->[0]` must not have output";
                }
                if ($subquery->{output_table} eq "") {
                    die "sub query of subcommand `$curr_command->[0]` must not have a command `$subquery->{last_command}`";
                }
                if ($subquery->{output_header_flag} eq "") {
                    die "sub query of subcommand `$curr_command->[0]` must not have an option --o-no-header";
                }

                extractNamedPipe($subquery);

                if ($subquery->{input} eq "") {
                    my $pipe_id_1 = scalar @$input_pipe_list;
                    push(@$input_pipe_list, {
                        "prefetch" => "",
                        "source" => "",
                        "format" => "tsv",
                        "header" => "",
                        "charencoding" => "UTF-8"});

                    my $pipe_id_2 = scalar @$input_pipe_list;
                    push(@$input_pipe_list, {
                        "prefetch" => "",
                        "source" => "",
                        "format" => "tsv",
                        "header" => "",
                        "charencoding" => "UTF-8"});

                    push(@$statement_list, {
                        "input_pipe_id" => $pipe_id_1,
                        "output_pipe_id" => $pipe_id_2,
                        "query" => $subquery});

                    $curr_command->[1] = $pipe_id_2;

                    push(@{$subquery->{commands}}, ["buffer"]);

                    push(@$commands2, ["tee", $pipe_id_1]);
                    push(@$commands2, ["buffer"]);
                    #push(@$commands2, ["buffer-debug"]);
                    push(@$commands2, $curr_command);
                } else {
                    my $pipe_id_1 = scalar @$input_pipe_list;
                    push(@$input_pipe_list, {
                        "prefetch" => 1,
                        "source" => $subquery->{input},
                        "format" => $subquery->{format},
                        "header" => $subquery->{input_header},
                        "charencoding" => ""});

                    my $pipe_id_2 = scalar @$input_pipe_list;
                    push(@$input_pipe_list, {
                        "prefetch" => "",
                        "source" => "",
                        "format" => "tsv",
                        "header" => "",
                        "charencoding" => "UTF-8"});

                    push(@$statement_list, {
                        "input_pipe_id" => $pipe_id_1,
                        "output_pipe_id" => $pipe_id_2,
                        "query" => $subquery});

                    $curr_command->[1] = $pipe_id_2;

                    push(@$commands2, $curr_command);
                }
            } else {
                if ( ! -e $curr_command->[1]) {
                    die "File not found: $curr_command->[1]";
                }
                my $pipe_id = scalar @$input_pipe_list;
                push(@$input_pipe_list, {
                    "source" => $curr_command->[1],
                    "format" => "",
                    "header" => "",
                    "charencoding" => ""});
                $curr_command->[1] = $pipe_id;

                push(@$commands2, $curr_command);
            }
        } else {
            push(@$commands2, $curr_command);
        }
    }

    $command_seq->{commands} = $commands2;
}

extractNamedPipe($command_seq);

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
    if (!$utf8_flag && $sjis_flag) {
        return "SHIFT-JIS";
    } else {
        return "UTF-8";
    }
}

sub prefetch_input {
    my $head_size = 100 * 4096;

    for (my $i = 0; $i < @$input_pipe_list; $i++) {
        my $input = $input_pipe_list->[$i];

        unless ($input->{prefetch}) {
            if ($input->{format} eq '') {
                $input->{format} = 'tsv';
            }
            if ($input->{charencoding} eq '') {
                $input->{charencoding} = 'UTF-8';
            }
            next;
        }

        my $head_buf;

        my $in;
        if ($input->{source} eq '') {
            $in = *STDIN;
        } else {
            open($in, '<', $input->{source}) or die $!;
        }
        $input->{handle} = $in;

        sysread($in, $head_buf, $head_size);

        $input->{head_buf} = $head_buf;

        if ($input->{format} eq '') {
            $input->{format} = guess_format($head_buf);
        }

        if ($input->{charencoding} eq '') {
            $input->{charencoding} = guess_charencoding($head_buf);
        }
    }
}

prefetch_input();

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
        $ircode = [["cmd", "cat $input_pipe_prefix${pipe_id}_0"]];
    } else {
        my $source = escape_for_bash($input_pipe->{source});
        $ircode = [["cmd", "cat $source"]];
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
        $ircode = [["cmd", "cat ${input_pipe_prefix}$input_pipe_id"]];
    }

    if ($input_pipe_id eq "") {
        my $stdin_pipe = $input_pipe_list->[0];

        if ($stdin_pipe->{charencoding} ne "UTF-8") {
            push(@$ircode, ["cmd", "iconv -f $stdin_pipe->{charencoding} -t UTF-8//TRANSLIT"]);
        }

        if ($stdin_pipe->{format} eq "csv") {
            push(@$ircode, ["cmd", "\$TOOL_DIR/golang.bin csv2tsv"]);
        }

        if ($stdin_pipe->{header} ne '') {
            my @headers = split(/,/, $stdin_pipe->{header});
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

    foreach my $t (@{$command_seq->{commands}}) {
        my $command = $t->[0];
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
                    my $arg = escape_for_bash(($num1 + 2) . ',' . ($num2 + 1) . 'p');
                    push(@$ircode, ["cmd", "sed -n -e 1p -e $arg"]);
                }
            }

        } elsif ($command eq "filter") {
            my $conds = '';
            for (my $i = 1; $i < @$t; $i++) {
                $conds .= ' ' . escape_for_bash($t->[$i]);
            }
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/filter.pl$conds"]);

        } elsif ($command eq "cut") {
            my $cols = escape_for_bash($t->[1]);
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/cut.pl --col $cols"]);

        } elsif ($command eq "addconst") {
            my $name  = escape_for_bash($t->[1]);
            my $value = escape_for_bash($t->[2]);
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/addconst.pl --name $name --value $value"]);

        } elsif ($command eq "addcopy") {
            my $name  = escape_for_bash($t->[1]);
            my $src = escape_for_bash($t->[2]);
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/addcopy.pl --name $name --src $src"]);

        } elsif ($command eq "addlinenum") {
            my $name  = escape_for_bash($t->[1]);
            my $value = escape_for_bash($t->[2]);
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/addlinenum.pl --name $name --value $value"]);

        } elsif ($command eq "addlinenum2") {
            my $name  = escape_for_bash($t->[1]);
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/addlinenum2.pl --name $name"]);

        } elsif ($command eq "addnumsortable") {
            my $name  = escape_for_bash($t->[1]);
            my $col = escape_for_bash($t->[2]);
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/addnumsortable.pl --name $name --col $col"]);

        } elsif ($command eq "addcross") {
            my $name  = escape_for_bash($t->[1]);
            my $cols = escape_for_bash($t->[2]);
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/addcross.pl --name $name --col $cols"]);

        } elsif ($command eq "removecol") {
            my $count  = escape_for_bash($t->[1]);
            my $arg = '-f' . ($count + 1) . '-';
            push(@$ircode, ["cmd", "cut $arg"]);

        } elsif ($command eq "parseuriparams") {
            my $cols = escape_for_bash($t->[1]);
            push(@$ircode, ["cmd", "tail -n+2"]);
            if ($t->[2] eq "no-decode") {
                push(@$ircode, ["cmd", "bash \$TOOL_DIR/no-decode-percent.sh"]);
            } else {
                push(@$ircode, ["cmd", "bash \$TOOL_DIR/decode-percent.sh"]);
            }
            push(@$ircode, ["cmd", "\$TOOL_DIR/golang.bin uriparams2tsv --fields $cols"]);

        } elsif ($command eq "update") {
            my $index = escape_for_bash($t->[1]);
            my $column = escape_for_bash($t->[2]);
            my $value = escape_for_bash($t->[3]);
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/update.pl $index:$column=$value"]);

        } elsif ($command eq "sort") {
            push(@$ircode, ["cmd", "\$TOOL_DIR/golang.bin fldsort --header"]);

        } elsif ($command eq "tee") {
            my $branch = escape_for_bash($t->[1]);
            $branch = "$input_pipe_prefix${branch}";
            push(@$ircode, ["cmd", "tee $branch"]);

        } elsif ($command eq "buffer") {
            push(@$ircode, ["cmd", "\$TOOL_DIR/golang.bin buffer"]);
        } elsif ($command eq "buffer-debug") {
            push(@$ircode, ["cmd", "\$TOOL_DIR/golang.bin buffer --debug"]);

        } elsif ($command eq "paste") {
            my $right = escape_for_bash($t->[1]);
            $right = "$input_pipe_prefix${right}";
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/paste.pl --right $right"]);

        } elsif ($command eq "union") {
            my $right = escape_for_bash($t->[1]);
            $right = "$input_pipe_prefix${right}";
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/union.pl - $right"]);

        } elsif ($command eq "wcl") {
            push(@$ircode, ["cmd", "\$TOOL_DIR/golang.bin wcl --header"]);

        } elsif ($command eq "header") {
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/header.pl"]);

        } elsif ($command eq "summary") {
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/summary.pl"]);

        } elsif ($command eq "facetcount") {
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/facetcount.pl"]);

        } elsif ($command eq "wordsflags") {
            my $flags = '';
            for (my $i = 1; $i < @$t; $i++) {
                $flags .= ' ' . escape_for_bash($t->[$i]);
            }
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/wordsflags.pl$flags"]);

        } elsif ($command eq "countcols") {
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/countcols.pl"]);

        } else {
            die $command;
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

        $main_1_source = $main_1_source . "    mkfifo $input_pipe_prefix${pipe_id}\n";
        $main_1_source = $main_1_source . "    " . join("\n    ", @$lines) . " > $input_pipe_prefix${pipe_id} &\n\n";

        $exists_multijob = 1;
    } elsif ($pipe_id > 0) {
        $main_1_source = $main_1_source . "    mkfifo $input_pipe_prefix${pipe_id}\n\n";
    }
}

foreach my $s (@$statement_list) {
    my $output_pipe_id = $s->{output_pipe_id};
    $main_1_source = $main_1_source . "    " . join("\n    ", @{irToShellscript($s->{query}->{ircode})}) . " > $input_pipe_prefix${output_pipe_id} &\n\n";
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
    if ($isPager) {
        my $last_command = $command_seq->{last_command};
        my $table_option = "";
        if ($last_command ne "countcols") {
            $table_option .= " --col-number";
            $table_option .= " --record-number";
        }
        if ($last_command eq "summary") {
            $table_option .= " --max-width 500";
        }
        $main_1_source = $main_1_source . " | perl \$TOOL_DIR/table.pl$table_option";
        $main_1_source = $main_1_source . " | less -SRX";
    }

    if (!$command_seq->{output_header_flag} && !$isPager) {
        $main_1_source = $main_1_source . " | tail -n+2";
    }
}
$main_1_source = $main_1_source . "\n";

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

my $stdin = $input_pipe_list->[0]->{handle};

if ($stdin ne *STDIN) {
    # 入力がファイルの場合
    open(STDIN, '<&=', fileno($input_pipe_list->[0]->{handle}));
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

sub write_head_buf {
    my ($input_pipe, $pipe_id) = @_;

    my $pipe_path = "$input_pipe_prefix2${pipe_id}_0";
    mkfifo($pipe_path, 0700) or die $!;

    my $pid1 = fork;
    if (!defined $pid1) {
        die $!;
    } elsif ($pid1) {
        # parent process

    } else {
        # child process

        open(my $fh, '>', $pipe_path) or die $!;
        open(STDOUT, '>&=', fileno($fh));

        open(STDIN, '<&=', fileno($input_pipe->{handle}));

        syswrite(STDOUT, $input_pipe->{head_buf});
        exec("cat");
    }
}

for (my $i = 1; $i < @$input_pipe_list; $i++) {
    next unless $input_pipe_list->[$i]->{prefetch};
    write_head_buf($input_pipe_list->[$i], $i);
}

my $PARENT_READER;
my $CHILD_WRITER;
pipe($PARENT_READER, $CHILD_WRITER);

my $pid1 = fork;
if (!defined $pid1) {
    die $!;
} elsif ($pid1) {
    # parent process

    close $CHILD_WRITER;
    open(STDIN, '<&=', fileno($PARENT_READER));

    exec("bash", "$WORKING_DIR/main-1.sh");
} else {
    # child process

    close $PARENT_READER;
    open(STDOUT, '>&=', fileno($CHILD_WRITER));

    syswrite(STDOUT, $input_pipe_list->[0]->{head_buf});
    exec("cat");
}

################################################################################

