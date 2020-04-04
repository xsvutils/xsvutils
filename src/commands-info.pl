use strict;
use warnings;
use utf8;

our $true;
our $false;

################################################################################

our %command_options = (
    # なにもしないサブコマンド
    "cat" => {
        "input" => "any",
        "output" => sub {
            # outputが関数の場合はdenyを返してはいけない
            $_[0]->{"connections"}->{"input"}->[2];
        },
    },

    # レコード選択に関するサブコマンド
    "head" => {
        "options" => {
            "-n" => "LINE_COUNT",
        },
        "parameters" => [
                "-n",
        ],
    },
    "limit" => {
        "options" => {
            "-n" => "LINE_COUNT",
        },
        "parameters" => [
                "-n",
        ],
    },
    "offset" => {
        "options" => {
            "-n" => "LINE_COUNT",
        },
        "parameters" => [
                "-n",
        ],
    },
    "range" => {
        "is_internal" => $true,
        "options" => {
            "--start" => "LINE_COUNT",
            "--end" => "LINE_COUNT",
        },
    },
    "where" => {
        "options" => {
            "--col" => "COLUMN",
            "--op" => "OPERATOR",
            "--val" => "VALUE",
        },
        "parameters" => [
            "--col",
            "--op",
            "--val",
        ],
    },
    "filter" => {
        "options" => {
            "--col" => "COLUMN",
            "--op" => "OPERATOR",
            "--val" => "VALUE",
        },
        "parameters" => [
            "--col",
            "--op",
            "--val",
        ],
    },
    "filter-record" => {
        "options" => {
            "--record" => "PERL_CODE",
        },
        "parameters" => [
            "--record",
        ],
    },

    # 列の選択に関するサブコマンド
    "cut" => {
        "exists_help" => $true,
        "options" => {
            "--cols" => "COLUMNS",
        },
        "parameters" => [
            "--cols",
        ],
    },
    "cols" => {
        "exists_help" => $true,
        "options" => {
            "--cols" => "COLUMNS",
            "--head" => "COLUMNS",
            "--last" => "COLUMNS",
            "--remove" => "COLUMNS",
            "--left-update" => "",
            "--right-update" => "",
        },
        "parameters" => [
        ],
    },
    "col" => {
        "options" => {
            "--cols" => "COLUMNS",
            "--col" => "COLUMN",
        },
        "parameters" => [
            "--col",
        ],
    },
    "col-impl" => {
        "is_internal" => $true,
        "options" => {
            "--cols" => "COLUMNS",
            "--col" => "A:COLUMN",
        },
    },

    # その他のデータを加工するコマンド
    "sort" => {
        "options" => {
            "--cols" => "COLUMNS",
            "--col" => "COLUMN",
            "--number" => "",
        },
        "parameters" => [
            "--col",
        ],
    },
    "sort-impl" => {
        "is_internal" => $true,
        "options" => {
            "--col" => "A:COLUMN",
        },
    },
    "join" => {
        "exists_help" => $true,
        "options" => {
            "--other" => "FILE",
            "--inner" => "",
            "--left-outer" => "",
            "--right-outer" => "",
            "--full-outer" => "",
            "--number" => "",
        },
        "parameters" => [
            "--other",
        ],
    },
    "trim-values" => {
    },
    "rename-duplicated-column-name" => {
    },
    "modify-record" => {
        "options" => {
            "--header" => "PERL_CODE",
            "--record" => "PERL_CODE",
        },
        "parameters" => [
            "--header",
            "--record",
        ],
    },
    "concat-cols" => {
        "options" => {
            "--col" => "A:COLUMN",
        },
    },

    # 集計するコマンド
    "wcl" => {
        "exists_help" => $true,
        "output" => "string",
    },
    "header" => {
        "options" => {
            "--comma" => "",
            "--col" => "",
        },
        "output" => "string",
    },
    "meaningful-cols" => {
        "options" => {
            "--comma" => "",
            "--col" => "",
        },
        "output" => "string",
    },
    "summary" => {
        "exists_help" => $true,
        "output" => "text",
    },

    # 入出力のコマンド
    "read-file" => {
        "is_internal" => $true,
        "options" => {
            "-i" => "FILE",
            "--stdin" => "",
        },
        "input" => "deny",
    },
    "write-file" => {
        "is_internal" => $true,
        "options" => {
            "-o" => "FILE",
            "--stdout" => "",
        },
        "input" => "any",
        "output" => "deny",
    },
    "write-terminal" => {
        "is_internal" => $true,
        "options" => {
            "--tsv" => "",
            "--json" => "",
            "--text" => "",
            "--string" => "",
            "--record-number-start" => "LINE_COUNT",
        },
        "input" => "any",
        "output" => "deny",
    },
    "to-esbulk" => {
        "output" => "json",
    },

    # フォーマット変換のコマンド
    "from-csv" => {
        "is_internal" => $true,
        "input" => "csv",
    },
    "from-json" => {
        "is_internal" => $true,
        "options" => {
            "--col" => "A:COLUMN",
        },
        "input" => "json",
    },
);

################################################################################

foreach my $command_name (keys %command_options) {
    my $coi = $command_options{$command_name};
    if (!defined($coi->{"exists_help"})) {
        $coi->{"exists_help"} = $false;
    }
    if (!defined($coi->{"is_internal"})) {
        $coi->{"is_internal"} = $false;
    }
    if (!defined($coi->{"options"})) {
        $coi->{"options"} = {};
    }
    if (!defined($coi->{"parameters"})) {
        $coi->{"parameters"} = [];
    }
    if (!defined($coi->{"input"})) {
        $coi->{"input"} = ["tsv", "lf"];
    } elsif ((ref $coi->{"input"}) eq "") {
        $coi->{"input"} = [$coi->{"input"}, "lf"];
    }
    if (!defined($coi->{"output"})) {
        $coi->{"output"} = ["tsv", "lf"];
    } elsif ((ref $coi->{"output"}) eq "") {
        $coi->{"output"} = [$coi->{"output"}, "lf"];
    }
}

################################################################################

1;
