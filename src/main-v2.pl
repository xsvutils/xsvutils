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

my @originalArgv = @ARGV;
sub degradeMain {
    #print STDERR "warning: degrade to v1 (@originalArgv)\n";
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
# parse command line options for help
################################################################################

my $option_help = undef;
my $help_document = undef;

sub getHelpFilePath {
    my ($help_name) = @_;

    if ($help_name eq "limit") {
        $help_name = "head";
    }

    if ($help_name eq "main") {
        return "$TOOL_DIR/help-main.txt";
    } elsif ($help_name eq "notfound") {
        return "$TOOL_DIR/help-notfound.txt";
    } elsif (-e "$TOOL_DIR/help-cmd-${help_name}.txt") {
        return "$TOOL_DIR/help-cmd-${help_name}.txt";
    } elsif (-e "$TOOL_DIR/help-guide-${help_name}.txt") {
        return "$TOOL_DIR/help-guide-${help_name}.txt";
    } else {
        return undef;
    }
}

sub parseQueryForHelp {
    my ($argv) = @_;
    my @argv = @$argv;
    $argv = \@argv;
    if (@argv == 1) {
        if ($argv[0] eq "help" || $argv[0] eq "--help") {
            $option_help = 1;
        } elsif ($argv[0] eq "--version") {
            $option_help = 1;
            $help_document = "version";
        }
    } elsif (@argv == 2) {
        if ($argv[0] eq "help" || $argv[0] eq "--help") {
            my $a2 = $argv[1];
            if (getHelpFilePath($a2)) {
                $option_help = 1;
                $help_document = $a2;
            } else {
                $option_help = 1;
                $help_document = "notfound";
            }
        } elsif ($argv[1] eq "help" || $argv[1] eq "--help") {
            my $a2 = $argv[0];
            if (getHelpFilePath($a2)) {
                $option_help = 1;
                $help_document = $a2;
            } else {
                $option_help = 1;
                $help_document = "notfound";
            }
        }
    }
}

parseQueryForHelp(\@ARGV);


################################################################################
# parse command line options
################################################################################

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

    my ($argv, $subqueryCommandName, $inputOk, $outputOk) = @_;
    my @argv = @$argv;

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

    my @command_name_list = qw/
        cat
        head limit drop offset
        where filter
        cut cols
        inshour insdate insweek inssecinterval inscopy insconst
        addconst addcopy addlinenum addcross addmap uriparams parseuriparams
        update sort paste join union
        wcl header summary countcols facetcount treetable crosstable wordsflags groupsum
        tee
    /;

    while () {
        my $a;
        if (@$argv) {
            $a = shift(@$argv);
        } else {
            if (defined($curr_command)) {
                $a = "--cat";
            } else {
                last;
            }
        }

        if ($a eq "]") {
            if (defined($curr_command)) {
                unshift(@$argv, $a);
                $a = "--cat";
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

        if (($command_name eq "head" || $command_name eq "limit") && $a eq "-n") {
            die "option $a needs an argument" unless (@$argv);
            die "duplicated option $a" if defined($curr_command->{count});
            my $a2 = shift(@$argv);
            die "Illegal option argument: $a2" unless ($a2 =~ /\A(0|[1-9][0-9]*)\z/);
            $curr_command->{count} = $a2;

        } elsif (($command_name eq "head" || $command_name eq "limit") && $a =~ /\A-n(0|[1-9][0-9]*)\z/) {
            my $a2 = $1;
            die "duplicated option -n" if defined($curr_command->{count});
            $curr_command->{count} = $a2;

        } elsif (($command_name eq "head" || $command_name eq "limit") && !defined($curr_command->{count}) && $a =~ /\A(0|[1-9][0-9]*)\z/) {
            die "duplicated option -n" if defined($curr_command->{count});
            $curr_command->{count} = $a;

        } elsif ($command_name eq "offset" && $a eq "-n") {
            die "option $a needs an argument" unless (@$argv);
            die "duplicated option $a" if defined($curr_command->{count});
            my $a2 = shift(@$argv);
            die "Illegal option argument: $a2" unless ($a2 =~ /\A(0|[1-9][0-9]*)\z/);
            $curr_command->{count} = $a2;

        } elsif ($command_name eq "offset" && $a =~ /\A-n(0|[1-9][0-9]*)\z/) {
            my $a2 = $1;
            die "duplicated option -n" if defined($curr_command->{count});
            $curr_command->{count} = $a2;

        } elsif ($command_name eq "offset" && !defined($curr_command->{count}) && $a =~ /\A(0|[1-9][0-9]*)\z/) {
            die "duplicated option -n" if defined($curr_command->{count});
            $curr_command->{count} = $a;

        } elsif (($command_name eq "cut" || $command_name eq "cols") && ($a eq "--col" || $a eq "--cols" || $a eq "--columns")) {
            die "option $a needs an argument" unless (@$argv);
            die "duplicated option $a" if defined($curr_command->{cols});
            $curr_command->{cols} = shift(@$argv);

        } elsif ($command_name eq "cut" && !defined($curr_command->{cols}) && $a !~ /\A-/) {
            if (!defined($input) && -e $a) {
                die "ambiguous parameter: $a, use --cols or -i";
            }
            if (grep {$_ eq $a} @command_name_list) {
                die "ambiguous parameter: $a, use --cols";
            }
            $curr_command->{cols} = $a;

        } elsif ($command_name eq "cols" && $a eq "--head") {
            die "option $a needs an argument" unless (@$argv);
            die "duplicated option $a" if defined($curr_command->{head});
            $curr_command->{head} = shift(@$argv);

        } elsif ($command_name eq "cols" && $a eq "--left-update") {
            die "duplicated option $a" if defined($curr_command->{update});
            $curr_command->{update} = "left";

        } elsif ($command_name eq "cols" && $a eq "--right-update") {
            die "duplicated option $a" if defined($curr_command->{update});
            $curr_command->{update} = "right";

        } elsif (($command_name eq "inshour" || $command_name eq "insdate" || $command_name eq "inssecinterval" || $command_name eq "inscopy") && $a eq "--src") {
            die "option $a needs an argument" unless (@$argv);
            die "duplicated option $a" if defined($curr_command->{src});
            $curr_command->{src} = shift(@$argv);

        } elsif ($command_name eq "insconst" && $a eq "--value") {
            die "option $a needs an argument" unless (@$argv);
            die "duplicated option $a" if defined($curr_command->{value});
            $curr_command->{value} = shift(@$argv);

        } elsif (($command_name eq "inshour" || $command_name eq "insdate" || $command_name eq "inssecinterval" || $command_name eq "inscopy" || $command_name eq "insconst") && $a eq "--dst") {
            die "option $a needs an argument" unless (@$argv);
            die "duplicated option $a" if defined($curr_command->{dst});
            $curr_command->{dst} = shift(@$argv);

        } elsif (($command_name eq "inshour" || $command_name eq "insdate" || $command_name eq "inssecinterval" || $command_name eq "inscopy") && !defined($curr_command->{src}) && $a !~ /\A-/) {
            if (!defined($input) && -e $a) {
                die "ambiguous parameter: $a, use --src or -i";
            }
            if (grep {$_ eq $a} @command_name_list) {
                die "ambiguous parameter: $a, use --src";
            }
            $curr_command->{src} = $a;

        } elsif ($command_name eq "insconst" && !defined($curr_command->{value}) && $a !~ /\A-/) {
            if (!defined($input) && -e $a) {
                die "ambiguous parameter: $a, use --value or -i";
            }
            if (grep {$_ eq $a} @command_name_list) {
                die "ambiguous parameter: $a, use --value";
            }
            $curr_command->{value} = $a;

        } elsif (($command_name eq "inshour" || $command_name eq "insdate" || $command_name eq "inssecinterval" || $command_name eq "inscopy" || $command_name eq "insconst") && !defined($curr_command->{dst}) && $a !~ /\A-/) {
            if (!defined($input) && -e $a) {
                die "ambiguous parameter: $a, use --dst or -i";
            }
            if (grep {$_ eq $a} @command_name_list) {
                die "ambiguous parameter: $a, use --dst";
            }
            $curr_command->{dst} = $a;

        } elsif (($command_name eq "uriparams" || $command_name eq "--uriparams") && ($a eq "--name" || $a eq "--names")) {
            die "option $a needs an argument" unless (@$argv);
            die "duplicated option $a" if defined($curr_command->{names});
            $curr_command->{names} = shift(@$argv);

        } elsif (($command_name eq "uriparams" || $command_name eq "--uriparams") && ($a eq "--name-list")) {
            die "duplicated option $a" if defined($curr_command->{names});
            $curr_command->{names} = "";

        } elsif (($command_name eq "uriparams") && ($a eq "--col")) {
            die "option $a needs an argument" unless (@$argv);
            die "duplicated option $a" if defined($curr_command->{col});
            $curr_command->{col} = shift(@$argv);

        } elsif (($command_name eq "uriparams" || $command_name eq "--uriparams") && ($a eq "--no-decode")) {
            die "duplicated option $a" if defined($curr_command->{decode});
            $curr_command->{decode} = "";

        } elsif (($command_name eq "uriparams" || $command_name eq "--uriparams") && ($a eq "--multi-value-a")) {
            die "duplicated option $a" if defined($curr_command->{multi_value});
            $curr_command->{multi_value} = "a";

        } elsif (($command_name eq "uriparams" || $command_name eq "--uriparams") && ($a eq "--multi-value-b")) {
            die "duplicated option $a" if defined($curr_command->{multi_value});
            $curr_command->{multi_value} = "b";

        } elsif ($command_name eq "uriparams" && !defined($curr_command->{col}) && $a !~ /\A-/) {
            $curr_command->{col} = $a;

        } elsif ($command_name eq "uriparams" && !defined($curr_command->{names}) && $a !~ /\A-/) {
            $curr_command->{names} = $a;

        } elsif ($command_name eq "sort" && ($a eq "--col" || $a eq "--cols" || $a eq "--columns")) {
            die "option $a needs an argument" unless (@$argv);
            die "duplicated option $a" if defined($curr_command->{cols});
            $curr_command->{cols} = shift(@$argv);

        } elsif ($command_name eq "sort" && !defined($curr_command->{cols}) && $a !~ /\A-/) {
            if (!defined($input) && -e $a) {
                die "ambiguous parameter: $a, use --cols or -i";
            }
            if (grep {$_ eq $a} @command_name_list) {
                die "ambiguous parameter: $a, use --cols";
            }
            $curr_command->{cols} = $a;

        } elsif ($command_name eq "paste" && $a eq "--right") {
            degradeMain();

        } elsif ($command_name eq "paste" && $a eq "--file") {
            die "option $a needs an argument" unless (@$argv);
            die "duplicated option $a" if defined($curr_command->{file});
            $curr_command->{file} = shift(@$argv);

        } elsif ($command_name eq "paste" && $a eq "[") {
            die "duplicated option $a" if defined($curr_command->{file});
            ($curr_command->{file}, $argv) = parseQuery($argv, "paste", 1, '');

        } elsif ($command_name eq "paste" && defined($input) && !defined($curr_command->{file}) && $a !~ /\A-/) {
            $curr_command->{file} = $a;

        } elsif ($command_name eq "facetcount" && ($a eq "--multi-value-a")) {
            die "duplicated option $a" if defined($curr_command->{multi_value});
            $curr_command->{multi_value} = "a";

        } elsif ($command_name eq "facetcount" && ($a eq "--weight")) {
            $curr_command->{weight} = 1;

        } elsif ($command_name eq "treetable" && $a eq "--top") {
            die "option $a needs an argument" unless (@$argv);
            die "duplicated option $a" if defined($curr_command->{top});
            $curr_command->{top} = shift(@$argv);

        } elsif ($command_name eq "treetable" && $a eq "--multi-value-a") {
            $curr_command->{multi_value} = "a";

        } elsif ($command_name eq "crosstable" && $a eq "--top") {
            die "option $a needs an argument" unless (@$argv);
            die "duplicated option $a" if defined($curr_command->{top});
            $curr_command->{top} = shift(@$argv);

        } elsif ($command_name eq "crosstable" && $a eq "--multi-value-a") {
            $curr_command->{multi_value} = "a";

        } elsif ($command_name eq "tee" && $a eq "--file") {
            die "option $a needs an argument" unless (@$argv);
            die "duplicated option $a" if defined($curr_command->{file});
            $curr_command->{file} = shift(@$argv);

        } elsif ($command_name eq "tee" && $a eq "[") {
            die "duplicated option $a" if defined($curr_command->{file});
            ($curr_command->{file}, $argv) = parseQuery($argv, "tee", '', 1);

        } elsif ($command_name eq "tee" && defined($input) && !defined($curr_command->{file}) && $a !~ /\A-/) {
            $curr_command->{file} = $a;

        } elsif ($a eq "--explain") {
            $option_explain = 1;

        } elsif ($a eq "--cat" || $a eq "cat") {
            $next_command = {command => "cat"};
            $last_command = $a;

        } elsif ($a eq "head" || $a eq "limit") {
            $next_command = {command => $a, count => undef};
            $last_command = $a;

        } elsif ($a eq "offset") {
            $next_command = {command => $a, count => undef};
            $last_command = $a;

        } elsif ($a eq "where" || $a eq "filter") {
            degradeMain();

        } elsif ($a eq "cut") {
            $next_command = {command => "cut", cols => undef};
            $last_command = $a;

        } elsif ($a eq "cols") {
            $next_command = {command => "cols", cols => undef, head => undef, update => undef};
            $last_command = $a;

        } elsif ($a eq "inshour") {
            $next_command = {command => "inshour", src => undef, dst => undef};
            $last_command = $a;

        } elsif ($a eq "insdate") {
            $next_command = {command => "insdate", src => undef, dst => undef};
            $last_command = $a;

        } elsif ($a eq "insweek") {
            degradeMain();

        } elsif ($a eq "inssecinterval") {
            $next_command = {command => "inssecinterval", src => undef, dst => undef};
            $last_command = $a;

        } elsif ($a eq "inscopy") {
            $next_command = {command => "inscopy", src => undef, dst => undef};
            $last_command = $a;

        } elsif ($a eq "insconst") {
            $next_command = {command => "insconst", value => undef, dst => undef};
            $last_command = $a;

        } elsif ($a eq "addconst") {
            degradeMain();

        } elsif ($a eq "addcopy") {
            degradeMain();

        } elsif ($a eq "addlinenum") {
            degradeMain();

        } elsif ($a eq "addcross") {
            degradeMain();

        } elsif ($a eq "addmap") {
            degradeMain();

        } elsif ($a eq "uriparams") {
            $next_command = {command => "uriparams", col => undef, names => undef,
                             decode => undef, multi_value => undef};
            $last_command = $a;

        } elsif ($a eq "--uriparams") {
            $next_command = {command => "--uriparams", names => undef,
                             decode => undef, multi_value => undef};
            $last_command = $a;

        } elsif ($a eq "parseuriparams") {
            degradeMain();

        } elsif ($a eq "update") {
            degradeMain();

        } elsif ($a eq "sort") {
            $next_command = {command => "sort", cols => undef};
            $last_command = $a;

        } elsif ($a eq "paste") {
            $next_command = {command => "paste", file => undef, "rule" => undef};
            $last_command = $a;

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
            $next_command = {command => "summary"};
            $last_command = $a;
            $next_output_table = '';

        } elsif ($a eq "countcols") {
            $next_command = {command => "countcols"};
            $last_command = $a;
            $next_output_table = '';

        } elsif ($a eq "facetcount") {
            $next_command = {command => "facetcount", multi_value => undef, weight => ''};
            $last_command = $a;
            $next_output_table = '';

        } elsif ($a eq "treetable") {
            $next_command = {command => "treetable", top => undef, multi_value => undef};
            $last_command = $a;
            $next_output_table = '';

        } elsif ($a eq "crosstable") {
            $next_command = {command => "crosstable", top => undef, multi_value => undef};
            $last_command = $a;
            $next_output_table = '';

        } elsif ($a eq "wordsflags") {
            degradeMain();

        } elsif ($a eq "groupsum") {
            $next_command = {command => "groupsum"};
            $last_command = $a;
            $next_output_table = '';

        } elsif ($a eq "tee") {
            $next_command = {command => "tee", file => undef};
            $last_command = $a;

        } elsif ($a eq "--tsv") {
            die "sub query of `$subqueryCommandName` must not have input option" if (!$inputOk);
            die "duplicated option: $a" if defined($format);
            $format = "tsv";

        } elsif ($a eq "--csv") {
            die "sub query of `$subqueryCommandName` must not have input option" if (!$inputOk);
            die "duplicated option: $a" if defined($format);
            $format = "csv";

        } elsif ($a eq "--o-tsv") {
            die "sub query of `$subqueryCommandName` must not have output option" if (!$outputOk);
            die "duplicated option: $a" if defined($output_format);
            $output_format = "tsv";

        } elsif ($a eq "--o-csv") {
            die "sub query of `$subqueryCommandName` must not have output option" if (!$outputOk);
            die "duplicated option: $a" if defined($output_format);
            $output_format = "csv";

        } elsif ($a eq "--o-table") {
            die "sub query of `$subqueryCommandName` must not have output option" if (!$outputOk);
            die "duplicated option: $a" if defined($output_format);
            $output_format = "table";

        } elsif ($a eq "--o-diffable") {
            die "sub query of `$subqueryCommandName` must not have output option" if (!$outputOk);
            die "duplicated option: $a" if defined($output_format);
            $output_format = "diffable";

        } elsif ($a eq "-i") {
            die "sub query of `$subqueryCommandName` must not have input option" if (!$inputOk);
            die "option -i needs an argument" unless (@$argv);
            die "duplicated option: $a" if defined($input);
            $input = shift(@$argv);

        } elsif ($a eq "-o") {
            die "sub query of `$subqueryCommandName` must not have output option" if (!$outputOk);
            die "option -o needs an argument" unless (@$argv);
            die "duplicated option: $a" if defined($output);
            $output = shift(@$argv);

        } elsif ($a eq "--i-header") {
            degradeMain();

        } elsif ($a eq "--header") {
            die "sub query of `$subqueryCommandName` must not have input option" if (!$inputOk);
            die "option $a needs an argument" unless (@$argv);
            die "duplicated option: $a" if defined($input_header);
            $input_header = shift(@$argv);

        } elsif ($a eq "--o-no-header") {
            die "sub query of `$subqueryCommandName` must not have output option" if (!$outputOk);
            $output_header_flag = '';

        } else {
            if ($inputOk && !defined($input)) {
                if (-e $a) {
                    $input = $a;
                } else {
                    die "Not found: $a\n";
                }
            } else {
                die "Unknown argument: $a\n";
            }
        }

        if (defined($next_command)) {
            if (defined($curr_command)) {
                if ($curr_command->{command} eq "uriparams") {
                    if (!defined($curr_command->{col})) {
                        die "subcommand \`uriparams\` needs --col option";
                    }
                    if (!defined($curr_command->{names})) {
                        die "subcommand \`uriparams\` needs --names option";
                    }
                    unshift(@$argv, $a);
                    unshift(@$argv, "]");
                    if (defined($curr_command->{multi_value}) && $curr_command->{multi_value} eq "b") {
                        unshift(@$argv, "--multi-value-b");
                    }
                    if (defined($curr_command->{decode}) && $curr_command->{decode} eq "") {
                        unshift(@$argv, "--no-decode");
                    }
                    if ($curr_command->{names} eq "") {
                        unshift(@$argv, "--name-list");
                    } else {
                        unshift(@$argv, $curr_command->{names});
                        unshift(@$argv, "--name");
                    }
                    unshift(@$argv, "--uriparams");
                    unshift(@$argv, $curr_command->{col});
                    unshift(@$argv, "--col");
                    unshift(@$argv, "cut");
                    unshift(@$argv, "[");
                    unshift(@$argv, "paste");
                    $curr_command = undef;
                    next;
                }
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

        if ($command_name eq "head" || $command_name eq "limit") {
            if ($command_name eq "head" && !defined($curr_command->{count})) {
                $curr_command->{count} = 10;
            }
            if (!defined($curr_command->{count})) {
                die "subcommand \`limit\` needs -n option";
            }
            my $f = 1;
            if (@$commands2 && $commands2->[@$commands2 - 1]->{command} eq "_range") {
                # 直前のサブコマンドと結合
                my $prev = $commands2->[@$commands2 - 1];
                if ($prev->{start} ne "" && $prev->{end} eq "") {
                    $f = '';
                    $prev->{end} = $prev->{start} + $curr_command->{count};
                }
            }
            if ($f) {
                push(@$commands2, {command => "_range", start => "", end => $curr_command->{count}});
            }

        } elsif ($command_name eq "offset") {
            if (!defined($curr_command->{count})) {
                die "subcommand \`offset\` needs -n option";
            }
            my $f = 1;
            if (@$commands2 && $commands2->[@$commands2 - 1]->{command} eq "_range") {
                # 直前のサブコマンドと結合
                my $prev = $commands2->[@$commands2 - 1];
                if ($prev->{start} eq "" && $prev->{end} ne "") {
                    $f = '';
                    if ($prev->{end} <= $curr_command->{count}) {
                        $prev->{end} = "0"; # drop all records
                    } else {
                        $prev->{start} = $curr_command->{count};
                    }
                }
            }
            if ($f) {
                push(@$commands2, {command => "_range", start => $curr_command->{count}, end => ""});
            }

=comment
        } elsif ($command_name eq "where") {
            if (@$c <= 1) {
                die "subcommand \`where\` needs --cond option";
            }
            push(@$commands2, $c);
=cut
        } elsif ($command_name eq "cut") {
            if (!defined($curr_command->{cols})) {
                die "subcommand \`cut\` needs --cols option";
            }
            push(@$commands2, {command => "cols", cols => $curr_command->{cols}, head => undef, update => ""});

        } elsif ($command_name eq "cols") {
            if (!defined($curr_command->{update})) {
                $curr_command->{update} = "";
            }
            push(@$commands2, $curr_command);

        } elsif ($command_name eq "inshour") {
            if (!defined($curr_command->{src})) {
                die "subcommand \`inshour\` needs --src option";
            }
            if (!defined($curr_command->{dst})) {
                die "subcommand \`inshour\` needs --dst option";
            }
            push(@$commands2, $curr_command);

        } elsif ($command_name eq "insdate") {
            if (!defined($curr_command->{src})) {
                die "subcommand \`insdate\` needs --src option";
            }
            if (!defined($curr_command->{dst})) {
                die "subcommand \`insdate\` needs --dst option";
            }
            push(@$commands2, $curr_command);

=comment
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

=cut
        } elsif ($command_name eq "inssecinterval") {
            if (!defined($curr_command->{src})) {
                die "subcommand \`inssecinterval\` needs --src option";
            }
            if (!defined($curr_command->{dst})) {
                die "subcommand \`inssecinterval\` needs --dst option";
            }
            push(@$commands2, $curr_command);

        } elsif ($command_name eq "inscopy") {
            if (!defined($curr_command->{src})) {
                die "subcommand \`inscopy\` needs --src option";
            }
            if (!defined($curr_command->{dst})) {
                die "subcommand \`inscopy\` needs --dst option";
            }
            push(@$commands2, $curr_command);

        } elsif ($command_name eq "insconst") {
            if (!defined($curr_command->{value})) {
                die "subcommand \`insconst\` needs --value option";
            }
            if (!defined($curr_command->{dst})) {
                die "subcommand \`insconst\` needs --dst option";
            }
            push(@$commands2, $curr_command);

=comment
        } elsif ($command_name eq "addconst") {
            if (!defined($curr_command->{1])) {
                die "subcommand \`addconst\` needs --name option";
            }
            if (!defined($curr_command->{2])) {
                $curr_command->{2] = "";
            }
            push(@$commands2, ["addconst", $curr_command->{1], $curr_command->{2]]);
        } elsif ($command_name eq "addlinenum") {
            if (!defined($curr_command->{1])) {
                die "subcommand \`addlinenum\` needs --name option";
            }
            if (!defined($curr_command->{2])) {
                $curr_command->{2] = 1;
            }
            push(@$commands2, ["addlinenum", $curr_command->{1], $curr_command->{2]]);
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
=cut
        } elsif ($command_name eq "--uriparams") {
            if (!defined($curr_command->{names})) {
                die "subcommand \`uriparams\` needs --names option";
            }
            if (!defined($curr_command->{decode})) {
                $curr_command->{decode} = 1;
            }
            if (!defined($curr_command->{multi_value})) {
                $curr_command->{multi_value} = "a";
            }
            push(@$commands2, $curr_command);

=comment
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
=cut

        } elsif ($command_name eq "sort") {
            if (defined($curr_command->{cols})) {
                push(@$commands2, @{parseSortParams([split(/,/, $curr_command->{cols})])});
            } else {
                push(@$commands2, @{parseSortParams([])});
            }

        } elsif ($command_name eq "paste") {
            if (!defined($curr_command->{file})) {
                die "subcommand \`paste\` needs --file option";
            }
            push(@$commands2, $curr_command);

=comment
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

        } elsif ($command_name eq "summary") {
            push(@$commands2, $curr_command);

        } elsif ($command_name eq "countcols") {
            push(@$commands2, $curr_command);

        } elsif ($command_name eq "facetcount") {
            if (!defined($curr_command->{multi_value})) {
                $curr_command->{multi_value} = "";
            }
            push(@$commands2, $curr_command);

        } elsif ($command_name eq "treetable") {
            if (defined($curr_command->{top})) {
                my @topCount = split(/,/, $curr_command->{top});
                foreach my $c (@topCount) {
                    if ($c !~ /\A(0|[1-9][0-9]*)\z/) {
                        die "Illegal argument of --top option: $curr_command->{top}";
                    }
                }
            }
            if (!defined($curr_command->{multi_value})) {
                $curr_command->{multi_value} = "";
            }
            push(@$commands2, $curr_command);

        } elsif ($command_name eq "crosstable") {
            if (defined($curr_command->{top})) {
                my @topCount = split(/,/, $curr_command->{top});
                foreach my $c (@topCount) {
                    if ($c !~ /\A(0|[1-9][0-9]*)\z/) {
                        die "Illegal argument of --top option: $curr_command->{top}";
                    }
                }
            }
            if (!defined($curr_command->{multi_value})) {
                $curr_command->{multi_value} = "";
            }
            push(@$commands2, $curr_command);

=comment
        } elsif ($command_name eq "wordsflags") {
            if (@$c <= 1) {
                die "subcommand \`wordsflags\` needs --flag option";
            }
            push(@$commands2, $c);

=cut
        } elsif ($command_name eq "groupsum") {
            push(@$commands2, $curr_command);

        } elsif ($command_name eq "tee") {
            if (!defined($curr_command->{file})) {
                die "subcommand \`tee\` needs --file option";
            }
            push(@$commands2, $curr_command);

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

sub parseSortParams {
    my ($args) = @_;
    my @args = @$args;
    my $commands = [];
    my $c = 0;
    if (@args) {
        push(@$commands, {command => "_addlinenum2"});
        $c++;
    }
    while (@args) {
        my $a = pop(@args);
        if ($a =~ /\A([_0-9a-zA-Z][-_0-9a-zA-Z]*):n\z/) {
            push(@$commands, {command => "_addnumsortable", src => $1, dst => ""});
        } else {
            push(@$commands, {command => "inscopy", src => $a, dst => ""});
        }
        $c++;
    }
    push(@$commands, {command => "sort"});
    if ($c > 0) {
        push(@$commands, {command => "removecol", count => $c});
    }
    $commands;
}

my ($command_seq, $tail_argv);
if ($option_help) {
    ($command_seq, $tail_argv) = (undef, undef);
} else {
    ($command_seq, $tail_argv) = parseQuery(\@ARGV, "", 1, 1);
}


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
    if (!$help_document) {
        $help_document = "main";
    }
    my $help_filepath = getHelpFilePath($help_document);
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
                        "newline" => "",
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
    #    "newline" => "unix",
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
        my $command_name = $curr_command->{command};
        if ($command_name eq "paste" ||
            $command_name eq "join" ||
            $command_name eq "union") {
            if (ref($curr_command->{file}) eq "HASH") {
                my $subquery = $curr_command->{file};

                extractNamedPipe($subquery);

                if ($subquery->{input} eq "") {
                    my $pipe_id_1 = scalar @$input_pipe_list;
                    push(@$input_pipe_list, {
                        "prefetch" => "",
                        "source" => "",
                        "format" => "tsv",
                        "header" => "",
                        "charencoding" => "UTF-8",
                        "utf8bom" => "",
                        "newline" => ""});

                    my $pipe_id_2 = scalar @$input_pipe_list;
                    push(@$input_pipe_list, {
                        "prefetch" => "",
                        "source" => "",
                        "format" => "tsv",
                        "header" => "",
                        "charencoding" => "UTF-8",
                        "utf8bom" => "",
                        "newline" => ""});

                    push(@$statement_list, {
                        "input_pipe_id" => $pipe_id_1,
                        "output_pipe_id" => $pipe_id_2,
                        "query" => $subquery});

                    $curr_command->{file_pipe_id} = $pipe_id_2;

                    push(@{$subquery->{commands}}, {command => "buffer"});

                    push(@$commands2, {command => "tee", file_pipe_id => $pipe_id_1});
                    push(@$commands2, {command => "buffer"});
                    push(@$commands2, $curr_command);
                } else { # unless ($subquery->{input} eq "")
                    my $pipe_id_1 = scalar @$input_pipe_list;
                    push(@$input_pipe_list, {
                        "prefetch" => 1,
                        "source" => $subquery->{input},
                        "format" => $subquery->{format},
                        "header" => $subquery->{input_header},
                        "charencoding" => "",
                        "utf8bom" => "",
                        "newline" => ""});

                    my $pipe_id_2 = scalar @$input_pipe_list;
                    push(@$input_pipe_list, {
                        "prefetch" => "",
                        "source" => "",
                        "format" => "tsv",
                        "header" => "",
                        "charencoding" => "UTF-8",
                        "utf8bom" => "",
                        "newline" => ""});

                    push(@$statement_list, {
                        "input_pipe_id" => $pipe_id_1,
                        "output_pipe_id" => $pipe_id_2,
                        "query" => $subquery});

                    $curr_command->{file_pipe_id} = $pipe_id_2;

                    push(@$commands2, $curr_command);
                }

            } else { # unless (ref($curr_command->{file}) eq "HASH")
                if ( ! -e $curr_command->{file}) {
                    die "File not found: $curr_command->{file}";
                }
                my $pipe_id = scalar @$input_pipe_list;
                push(@$input_pipe_list, {
                    "prefetch" => 1,
                    "source" => $curr_command->{file},
                    "format" => "",
                    "header" => "",
                    "charencoding" => "",
                    "utf8bom" => "",
                    "newline" => ""});
                $curr_command->{file_pipe_id} = $pipe_id;

                push(@$commands2, $curr_command);
            }

        } elsif ($command_name eq "tee") {
            if (ref($curr_command->{file}) eq "HASH") {
                my $subquery = $curr_command->{file};

                extractNamedPipe($subquery);

                die "sub query of `$command_name` must have output option" if ($subquery->{output} eq "");

                my $pipe_id_1 = scalar @$input_pipe_list;
                push(@$input_pipe_list, {
                    "prefetch" => "",
                    "source" => "",
                    "format" => "tsv",
                    "header" => "",
                    "charencoding" => "UTF-8",
                    "utf8bom" => "",
                    "newline" => ""});

                push(@$statement_list, {
                    "input_pipe_id" => $pipe_id_1,
                    "output_pipe_id" => undef,
                    "query" => $subquery});

                $curr_command->{file_pipe_id} = $pipe_id_1;

                push(@$commands2, $curr_command);
            } else { # unless (ref($curr_command->{file}) eq "HASH")
                push(@$commands2, $curr_command);
            }

        } else { # other command
            push(@$commands2, $curr_command);
        }
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
            $input->{newline} = 'unix';
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

    $format =~ s/\n\z//g;
    if ($format !~ /\Aformat:([^ ]+) charencoding:([^ ]+) utf8bom:([^ ]+) newline:([^ ]+)\z/) {
        die "failed to guess format $input_pipe_path";
    }
    $input->{format}       = $1;
    $input->{charencoding} = $2;
    $input->{utf8bom}      = $3;
    $input->{newline}      = $4;

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

    push(@$ircode, @{build_ircode_input_format($input_pipe)});

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

        push(@$ircode, @{build_ircode_input_format($input_pipe)});

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

        if ($command_name eq "_range") {
            my $start = $curr_command->{start};
            my $end = $curr_command->{end};
            if ($start eq "") {
                if ($end eq "") {
                    # nop
                } else {
                    my $arg = escape_for_bash('-n' . ($end + 1));
                    push(@$ircode, ["cmd", "head $arg"]);
                }
            } else {
                if ($end eq "") {
                    my $arg = escape_for_bash(($start + 2) . ',$p');
                    push(@$ircode, ["cmd", "sed -n -e 1p -e $arg"]);
                } else {
                    my $arg = escape_for_bash(($start + 2) . ',' . ($end + 1) . 'p');
                    push(@$ircode, ["cmd", "sed -n -e 1p -e $arg"]);
                }
            }

=comment
        } elsif ($command_name eq "where") {
            my $conds = '';
            for (my $i = 1; $i < @$t; $i++) {
                $conds .= ' ' . escape_for_bash($curr_command->{$i]);
            }
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/where.pl$conds"]);

=cut
        } elsif ($command_name eq "cols") {
            my $option = "";
            if (defined($curr_command->{cols})) {
                $option .= " --col " . escape_for_bash($curr_command->{cols});
            }
            if (defined($curr_command->{head})) {
                $option .= " --head " . escape_for_bash($curr_command->{head});
            }
            if ($curr_command->{update} eq "left") {
                $option .= " --left-update";
            } elsif ($curr_command->{update} eq "right") {
                $option .= " --right-update";
            }
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/cut.pl$option"]);

        } elsif ($command_name eq "inshour") {
            my $src = escape_for_bash($curr_command->{src});
            my $dst = escape_for_bash($curr_command->{dst});
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/insdate.pl hour --name $dst --src $src"]);

        } elsif ($command_name eq "insdate") {
            my $src = escape_for_bash($curr_command->{src});
            my $dst = escape_for_bash($curr_command->{dst});
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/insdate.pl date --name $dst --src $src"]);

=comment
        } elsif ($command_name eq "insweek") {
            my $name  = escape_for_bash($curr_command->{1]);
            my $src = escape_for_bash($curr_command->{2]);
            my $start_day = escape_for_bash($curr_command->{3]);
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/insweek.pl --name $name --src $src --start-day $start_day"]);

=cut
        } elsif ($command_name eq "inssecinterval") {
            my $src = escape_for_bash($curr_command->{src});
            my $dst = escape_for_bash($curr_command->{dst});
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/inssecinterval.pl --src $src --dst $dst"]);

        } elsif ($command_name eq "inscopy") {
            my $src = escape_for_bash($curr_command->{src});
            my $dst = escape_for_bash($curr_command->{dst});
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/addcopy.pl --name $dst --src $src"]);

        } elsif ($command_name eq "insconst") {
            my $value = escape_for_bash($curr_command->{value});
            my $dst = escape_for_bash($curr_command->{dst});
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/addconst.pl --name $dst --value $value"]);

=comment
        } elsif ($command_name eq "addconst") {
            my $name  = escape_for_bash($curr_command->{1]);
            my $value = escape_for_bash($curr_command->{2]);
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/addconst.pl --name $name --value $value"]);

        } elsif ($command_name eq "addlinenum") {
            my $name  = escape_for_bash($curr_command->{1]);
            my $value = escape_for_bash($curr_command->{2]);
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/addlinenum.pl --name $name --value $value"]);
=cut
        } elsif ($command_name eq "_addlinenum2") {
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/addlinenum2.pl --name ''"]);

        } elsif ($command_name eq "_addnumsortable") {
            my $name  = escape_for_bash($curr_command->{dst});
            my $col = escape_for_bash($curr_command->{src});
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/addnumsortable.pl --name $name --col $col"]);

=comment
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
=cut

        } elsif ($command_name eq "removecol") {
            my $count  = escape_for_bash($curr_command->{count});
            my $arg = '-f' . ($count + 1) . '-';
            push(@$ircode, ["cmd", "cut $arg"]);

        } elsif ($command_name eq "--uriparams") {
            push(@$ircode, ["cmd", "tail -n+2"]);
            push(@$ircode, ["cmd", "bash \$TOOL_DIR/pre-encode-percent.sh"]);
            my $option = "";
            if ($curr_command->{names} eq "") {
                $option .= " --names";
            } else {
                my $names = escape_for_bash($curr_command->{names});
                $option .= " --fields $names";
            }
            if ($curr_command->{multi_value} eq "b") {
                $option .= " --multi-value-b";
            }
            push(@$ircode, ["cmd", "\$TOOL_DIR/golang.bin uriparams2tsv$option"]);
            if ($curr_command->{decode}) {
                push(@$ircode, ["cmd", "bash \$TOOL_DIR/decode-percent.sh"]); # TODO $colsもデコードされてしまう問題あり
            }

=comment
        } elsif ($command_name eq "update") {
            my $index = escape_for_bash($curr_command->{1]);
            my $column = escape_for_bash($curr_command->{2]);
            my $value = escape_for_bash($curr_command->{3]);
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/update.pl $index:$column=$value"]);
=cut

        } elsif ($command_name eq "sort") {
            push(@$ircode, ["cmd", "\$TOOL_DIR/golang.bin fldsort --header"]);

        } elsif ($command_name eq "tee") {
            my $file;
            if (defined($curr_command->{file_pipe_id})) {
                my $file_pipe_id = escape_for_bash($curr_command->{file_pipe_id});
                $file = "$input_pipe_prefix1${file_pipe_id}";
            } else {
                $file = escape_for_bash($curr_command->{file});
            }
            push(@$ircode, ["cmd", "tee $file"]);

        } elsif ($command_name eq "buffer") {
            push(@$ircode, ["cmd", "\$TOOL_DIR/golang.bin buffer"]);

        } elsif ($command_name eq "buffer-debug") {
            push(@$ircode, ["cmd", "\$TOOL_DIR/golang.bin buffer --debug"]);

        } elsif ($command_name eq "paste") {
            my $file_pipe_id = escape_for_bash($curr_command->{file_pipe_id});
            my $file = "$input_pipe_prefix1${file_pipe_id}";
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/paste.pl --right $file"]);

=comment
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

        } elsif ($command_name eq "summary") {
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/summary.pl"]);

        } elsif ($command_name eq "countcols") {
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/countcols.pl"]);

        } elsif ($command_name eq "facetcount") {
            my $option = "";
            if ($curr_command->{multi_value} eq "a") {
                $option .= " --multi-value-a";
            }
            if ($curr_command->{weight}) {
                $option .= " --weight";
            }
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/facetcount.pl$option"]);

        } elsif ($command_name eq "treetable") {
            my $option = "";
            if (defined($curr_command->{top})) {
                $option .= " --top " . escape_for_bash($curr_command->{top});
            }
            if ($curr_command->{multi_value} eq "a") {
                $option .= " --multi-value-a";
            }
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/treetable.pl$option"]);

        } elsif ($command_name eq "crosstable") {
            my $option = "";
            if (defined($curr_command->{top})) {
                $option .= " --top " . escape_for_bash($curr_command->{top});
            }
            if ($curr_command->{multi_value} eq "a") {
                $option .= " --multi-value-a";
            }
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/crosstable.pl$option"]);

=comment
        } elsif ($command_name eq "wordsflags") {
            my $flags = '';
            for (my $i = 1; $i < @$t; $i++) {
                $flags .= ' ' . escape_for_bash($curr_command->{$i]);
            }
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/wordsflags.pl$flags"]);

=cut
        } elsif ($command_name eq "groupsum") {
            my $option = "";
            push(@$ircode, ["cmd", "perl \$TOOL_DIR/groupsum.pl$option"]);

        } else {
            die "Bug: $command_name";
        }
    }

    $command_seq->{ircode} = ["pipe", $ircode];
}

sub build_ircode_input_format {
    my ($input_pipe) = @_;
    my $ircode = [];
    if ($input_pipe->{utf8bom} eq "1") {
        push(@$ircode, ["cmd", "tail -c+4"]);
    }

    if ($input_pipe->{newline} eq "dos" && $input_pipe->{format} ne "csv") {
        push(@$ircode, ["cmd", "sed 's/\\r\$//g'"]);
    } elsif ($input_pipe->{newline} eq "mac") {
        push(@$ircode, ["cmd", "sed 's/\\r/\\n/g'"]);
    }

    if ($input_pipe->{charencoding} ne "UTF-8") {
        push(@$ircode, ["cmd", "iconv -f $input_pipe->{charencoding} -t UTF-8//TRANSLIT"]);
    }

    if ($input_pipe->{format} eq "csv") {
        push(@$ircode, ["cmd", "\$TOOL_DIR/golang.bin csv2tsv"]);
    }

    return $ircode;
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

sub appendOutputCode {
    my ($command_seq, $isOutputTty) = @_;
    my $main_1_source = "";

    my $table_option = "";
    my $last_command = $command_seq->{last_command};
    if ($last_command ne "countcols") {
        $table_option .= " --col-number";
        $table_option .= " --record-number";
    }
    if ($last_command eq "summary") {
        $table_option .= " --max-width 500";
    }

    my $isPager = '';
    if ($isOutputTty && $command_seq->{output} eq "") {
        $isPager = 1;
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
        } elsif ($command_seq->{output_format} eq "diffable") {
            $main_1_source = $main_1_source . " | perl \$TOOL_DIR/to-diffable.pl";
        }
    }
    return $main_1_source;
}

my $main_1_source = "(\n";

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
    $main_1_source = $main_1_source . "    " . join("\n    ", @{irToShellscript($s->{query}->{ircode})});
    if (defined($output_pipe_id)) {
        $main_1_source = $main_1_source . " > $input_pipe_prefix1${output_pipe_id}";
    } elsif (defined($s->{query}->{output})) {
        $main_1_source = $main_1_source . appendOutputCode($s->{query}, '');
        $main_1_source = $main_1_source . " > " . escape_for_bash($s->{query}->{output});
    } else {
        die;
    }
    $main_1_source = $main_1_source . " &\n\n";
    $exists_multijob = 1;
}

if ($exists_multijob) {
    $main_1_source = $main_1_source . "    " . join("\n    ", @{irToShellscript($command_seq->{ircode})}) . " &\n";
    $main_1_source = $main_1_source . "\n    wait\n";
} else {
    $main_1_source = $main_1_source . "    " . join("\n    ", @{irToShellscript($command_seq->{ircode})}) . "\n";
}

$main_1_source = $main_1_source . ")";

$main_1_source = $main_1_source . appendOutputCode($command_seq, $isOutputTty);

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

{
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
