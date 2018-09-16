use strict;
use warnings;
use utf8;

my $target_pid = $ARGV[0];
my $self_pid = $$;

sub killchildren {
    my ($ppid) = @_;

    kill('STOP', $ppid) if ($ppid != $target_pid);

    open(PS, '-|', "ps --no-headers --ppid $ppid") or die $!;

    while (my $line = <PS>) {
        next if ($line =~ / ps$/);
        next if ($line !~ /^ *([0-9]+) /);
        my $pid = $1;
        next if ($pid == $self_pid);
        killchildren($pid);
    }

    close(PS);

    kill('KILL', $ppid) if ($ppid != $target_pid);
}

killchildren($target_pid);

