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

################################################################################
# parse command line options
################################################################################

sub escape_for_bash {
    my ($str) = @_;
    $str =~ s/'/'"'"'/g;
    return "'" . $str . "'";
}

my $option_help = undef;
my $option_input = undef;
my $option_output = ""; # 空文字列は標準出力の意味

my $option_format = undef;
my $option_input_headers = undef;
my $option_output_format = undef;

my $subcommands = [];
my $subcommand = undef;
my $subcommand_args = [];

my $addcol_name = undef;
my $addcol_value = undef;

while (@ARGV) {
    my $a = shift(@ARGV);
    if ($a eq "--help") {
        $option_help = 1;
    } elsif ($a eq "--tsv") {
        $option_format = "tsv";
    } elsif ($a eq "--csv") {
        $option_format = "csv";
    } elsif ($a eq "cat") {
        push(@$subcommands, [$subcommand, @$subcommand_args]) if (defined($subcommand));
        $subcommand = $a;
        $subcommand_args = [];
    } elsif ($a eq "head") {
        push(@$subcommands, [$subcommand, @$subcommand_args]) if (defined($subcommand));
        $subcommand = $a;
        $subcommand_args = [];
    } elsif ($a eq "cut") {
        push(@$subcommands, [$subcommand, @$subcommand_args]) if (defined($subcommand));
        $subcommand = $a;
        $subcommand_args = [];
    } elsif ($a eq "wcl") {
        push(@$subcommands, [$subcommand, @$subcommand_args]) if (defined($subcommand));
        $subcommand = $a;
        $subcommand_args = [];
    } elsif ($a eq "summary") {
        push(@$subcommands, [$subcommand, @$subcommand_args]) if (defined($subcommand));
        $subcommand = $a;
        $subcommand_args = [];
    } elsif ($a eq "countcols") {
        push(@$subcommands, [$subcommand, @$subcommand_args]) if (defined($subcommand));
        $subcommand = $a;
        $subcommand_args = [];
    } elsif ($a eq "addcol") {
        push(@$subcommands, [$subcommand, @$subcommand_args]) if (defined($subcommand));
        $subcommand = $a;
        $subcommand_args = [];
        $addcol_name = undef;
        $addcol_value = undef;
    } elsif ($a eq "-i") {
        die "option -i needs an argument" unless (@ARGV);
        $option_input = shift(@ARGV);
    } elsif ($a eq "-o") {
        die "option -o needs an argument" unless (@ARGV);
        $option_output = shift(@ARGV);
    } elsif ($a eq "--i-header") {
        die "option --i-header needs an argument" unless (@ARGV);
        $option_input_headers = shift(@ARGV);
    } elsif (!defined($option_input) && -e $a) {
        $option_input = $a;
    } elsif (defined($subcommand)) {
        if ($subcommand eq "head") {
            if ($a eq "-n") {
                die "option -n needs an argument" unless (@ARGV);
                push(@$subcommand_args, $a, shift(@ARGV));
            } elsif ($a =~ /\A-n(0|[1-9][0-9]*)\z/) {
                push(@$subcommand_args, '-n', $1);
            } elsif ($a =~ /\A(0|[1-9][0-9]*)\z/) {
                push(@$subcommand_args, '-n', $a);
            } else {
                die "Unknown argument: $a";
            }
        } elsif ($subcommand eq "cut") {
            if ($a eq "--col" || $a eq "--cols" || $a eq "--columns") {
                die "option $a needs an argument" unless (@ARGV);
                push(@$subcommand_args, '--col', shift(@ARGV));
            } else {
                push(@$subcommand_args, '--col', $a);
            }
        } elsif ($subcommand eq "addcol") {
            if ($a eq "--name") {
                die "option $a needs an argument" unless (@ARGV);
                $addcol_name = shift(@ARGV);
                push(@$subcommand_args, '--name', $addcol_name);
            } elsif ($a eq "--value") {
                die "option $a needs an argument" unless (@ARGV);
                $addcol_value = shift(@ARGV);
                push(@$subcommand_args, '--value', $addcol_value);
            } elsif (!defined($addcol_name)) {
                $addcol_name = $a;
                push(@$subcommand_args, '--name', escape_for_bash($addcol_name));
            } elsif (!defined($addcol_value)) {
                $addcol_value = $a;
                push(@$subcommand_args, '--value', escape_for_bash($addcol_value));
            } else {
                die "Unknown argument: $a";
            }
        } else {
            die "Unknown argument: $a";
        }
    } else {
        die "Unknown argument: $a";
    }
}

push(@$subcommands, [$subcommand, @$subcommand_args]) if (defined($subcommand));

if (!$isInputTty && !defined($option_input) && !$option_help) {
    # 入力がパイプにつながっていて
    # 入力ファイル名が指定されていなくて
    # ヘルプオプションも指定されていない場合は、
    # 標準入力を入力とする。
    $option_input = ""; # stdin
}

if (defined($option_input) && !@$subcommands) {
    # 入力があり、サブコマンドが指定されていない場合は、
    # サブコマンドを cat とする。
    push(@$subcommands, ["cat"]);
}

if ($isOutputTty && $option_output eq "") {
    # 出力が端末の場合
    # TODO オプションで出力フォーマットが指定されていない場合に限定
    $option_output_format = "tty";
} else {
    $option_output_format = "";
}

################################################################################
# help
################################################################################

my $help_stdout = undef;
my $help_stderr = undef;
if ($option_help) {
    $help_stdout = 1;
} elsif (!defined($option_input)) {
    # 入力がない場合は、
    # ヘルプをエラー出力する。
    $help_stderr = 1;
}

if ($help_stdout || $help_stderr) {
    my $help_filepath = $TOOL_DIR . "/help.txt";
    open(IN, '<', $help_filepath) or die $!;
    my @lines = <IN>;
    my $str = join('', @lines);
    close IN;
    if ($help_stdout) {
        print $str;
        exit(0);
    } else {
        print STDERR $str;
        exit(1);
    }
}

################################################################################
# 入出力を stdin, stdout に統一
################################################################################

if ($option_input ne "") {
    # 入力がファイルの場合
    my $data_in;
    open($data_in, '<', $option_input) or die "Cannot open file: $!";
    open(STDIN, '<&=', fileno($data_in));
}

if ($option_output ne "") {
    # 出力がファイルの場合
    my $data_out;
    open($data_out, '>', $option_output) or die "Cannot open file: $!";
    open(STDOUT, '>&=', fileno($data_out));
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

my $head_size = 100 * 4096;
my $head_buf;

sysread(STDIN, $head_buf, $head_size);

my $format;
if (defined($option_format)) {
    $format = $option_format;
} else {
    $format = guess_format($head_buf);
}

################################################################################
# build script
################################################################################

my $main_1_source = "";

if ($format eq "csv") {
    $main_1_source .= " | " if ($main_1_source ne "");
    $main_1_source = "$TOOL_DIR/golang.bin csv2tsv";
}

if (defined($option_input_headers)) {
    my @headers = split(/,/, $option_input_headers);
    for my $h (@headers) {
        unless ($h =~ /\A[_0-9a-zA-Z][-_0-9a-zA-Z]*\z/) {
            die "Illegal header: $h\n";
        }
    }
    my $headers = escape_for_bash(join("\t", @headers));
    if ($main_1_source eq "") {
        $main_1_source = "(printf '%s' $headers; echo; cat)";
    } else {
        $main_1_source = "(printf '%s' $headers; echo; $main_1_source)";
    }
}

my $last_subcommand = undef;
foreach my $t (@$subcommands) {
    $subcommand = shift(@$t);
    $subcommand_args = $t;
    if (defined($last_subcommand) && $last_subcommand eq "wcl") {
        die "subcommand `wcl` must be last`\n";
    }
    if ($subcommand eq "head") {
        $main_1_source .= " | " if ($main_1_source ne "");
        $main_1_source .= "bash $TOOL_DIR/head.sh @$subcommand_args";
    } elsif ($subcommand eq "cut") {
        $main_1_source .= " | " if ($main_1_source ne "");
        $main_1_source .= "perl $TOOL_DIR/cut.pl @$subcommand_args";
    } elsif ($subcommand eq "wcl") {
        $main_1_source .= " | " if ($main_1_source ne "");
        $main_1_source .= "$TOOL_DIR/golang.bin wcl --header @$subcommand_args";
    } elsif ($subcommand eq "summary") {
        $main_1_source .= " | " if ($main_1_source ne "");
        $main_1_source .= "perl $TOOL_DIR/summary.pl @$subcommand_args";
    } elsif ($subcommand eq "countcols") {
        $main_1_source .= " | " if ($main_1_source ne "");
        $main_1_source .= "perl $TOOL_DIR/countcols.pl @$subcommand_args";
    } elsif ($subcommand eq "addcol") {
        $main_1_source .= " | " if ($main_1_source ne "");
        $main_1_source .= "perl $TOOL_DIR/addcol.pl @$subcommand_args";
    }
    $last_subcommand = $subcommand;
}

if ($last_subcommand ne "wcl" && $option_output_format eq "tty") {
    my $table_option = "";
    if ($last_subcommand ne "countcols") {
        $table_option .= " --col-number";
        $table_option .= " --record-number";
    }
    if ($last_subcommand eq "summary") {
        $table_option .= " --max-width 500";
    }
    $main_1_source .= " | " if ($main_1_source ne "");
    $main_1_source .= "perl $TOOL_DIR/table.pl$table_option | less -SRX";
}

$main_1_source = "cat" if ($main_1_source eq "");
$main_1_source .= "\n";

open(my $main_1_out, '>', "$WORKING_DIR/main-1.sh") or die $!;
print $main_1_out $main_1_source;
close($main_1_out);

#print STDERR $main_1_source;

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

    syswrite(STDOUT, $head_buf);
    exec("cat");
}

################################################################################
