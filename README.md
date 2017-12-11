# xsvutils
Utilities for handling separated value data

## Usage
    $ xsvutils [FILENAME] [SUBCOMMAND] [OPTIONS...]

## Example

Print tsv/csv data to the terminal.

    $ xsvutils data.tsv
    $ xsvutils data.csv
    $ ssh remote-host cat foo/bar.csv | xsvutils

Retrieve specified columns.

    $ xsvutils data.tsv cut --col foo,col1,col20    # retrieve only 3 columns: foo, col1, col20
    $ xsvutils data.tsv cut --col foo,col1..col20   # retrieve 21 columns: foo, col1, col2, col3, ... col20

