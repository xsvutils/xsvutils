use strict;
use warnings;
use utf8;

my $TOOL_DIR = $ENV{"TOOL_DIR"};
my $isInputTty = undef;
if (-t STDIN) {
    $isInputTty = 1;
}
my $isOutputTty = undef;
if (-t STDOUT) {
    $isOutputTty = 1;
}

my $subcommand = undef;
my $option_help = undef;
my $option_input = undef;
my $option_output = undef;

my $option_output_format = undef;

my $subcommand_args = [];

while (@ARGV) {
    my $a = shift(@ARGV);
    if ($a eq "--help") {
        $option_help = 1;
    } elsif ($a eq "hello") {
        $subcommand = $a;
    } elsif ($a eq "dummy") {
        $subcommand = $a;
    } elsif ($a eq "-i") {
        die "option -i needs an argument" unless (@ARGV);
        $option_input = shift(@ARGV);
    } elsif ($a eq "-o") {
        die "option -o needs an argument" unless (@ARGV);
        $option_output = shift(@ARGV);
    } else {
        push(@$subcommand_args, $a);
    }
}

if (!$isInputTty && !defined($option_input) && !$option_help) {
    # 入力がパイプにつながっていて
    # 入力ファイル名が指定されていなくて
    # ヘルプオプションも指定されていない場合は、
    # 標準入力を入力とする。
    $option_input = ""; # stdin
}

if (defined($option_input) && !defined($subcommand)) {
    # 入力があり、サブコマンドが指定されていない場合は、
    # サブコマンドを cat とする。
    $subcommand = "cat";
}

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
    open(IN, '<', $help_filepath) or die "Cannot open $help_filepath";
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

if ($isOutputTty) {
    # 出力が端末の場合
    # TODO オプションで出力フォーマットが指定されていない場合に限定
    $option_output_format = "tty";
}

if ($subcommand eq "cat") {
    # TODO
    if ($option_input eq "") {
        exec("cat");
    } else {
        exec("cat", $option_input);
    }
} elsif ($subcommand eq "hello") {
    #exec("$TOOL_DIR/golang.bin", "hello");
    if ($option_output_format eq "tty") {
        exec("bash", "$TOOL_DIR/less-wrapper.sh", "/tmp/xsvutils-golang.bin", "hello");
    } else {
        exec("/tmp/xsvutils-golang.bin", "hello");
    }
} elsif ($subcommand eq "dummy") {
    exec("bash", "$TOOL_DIR/dummy.sh");
}


