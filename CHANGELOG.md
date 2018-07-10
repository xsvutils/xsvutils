# CHANGELOG

To see version information, `xsvutils --version`.

To see compatibility information, `xsvutils help compatibility`.

## version 0.5 (Unreleased)

## version 0.4 (2018/07/10)
- support -v1,-v2,-v3,-v4

## version 0.3.4 (2018/06/30)
- add `ratio` subcommand
- add `-b`, `-w` options of `diff` subcommand
- add `--o-chart` option as output format

## version 0.3.3 (2018/05/27)
- add `rmnoname` subcommand
- add `insunixtime` subcommand
- add `--last` option of `cols` subcommand

## version 0.3.2 (2018/05/21)
- add `mergecols` subcommand

## version 0.3.1 (2018/05/07)
- add java version of facetcount
- remove display of progress of facetcount, treetable, ...

## version 0.3.0 (2018/04/23)
- change default parse from v1 to v2

## version 0.2.7 (2018/04/22)
- add `diff` subcommand on v2
- enable output csv format on terminal
- add facetcount ratio2 column
- add `filter`, `where` subcommand on v2
- change --o-diffable format
- add some subcommands from v1 to v2
- add `insmap` subcommand on v2
- add `-v2` option of `groupsum` subcommand

## version 0.2.6 (2018/04/09)
- add support LTSV format on v2
- make `uriparams` slightly fast

## version 0.2.5 (2018/04/08)
- fix a bug of removing temp files on `sort` subcommand
- fix a bug of output of `uriparams --name-list`

## version 0.2.4 (2018/03/30)
- add support subquery of `tee` subcommand on v2
- add `insconst` subcommand on v2
- add --o-diffable option on v2
- add `cols` subcommand on v2
- add some subcommands from v1 to v2
- fix a bug of handling empty file on `join` subcommand
- add --left-update, --right-update options on `cols` subcommand

## version 0.2.3 (2018-03-11)
- add support CR, CRLF
- add some subcommands from v1 to v2
- add --src, --dst options of inshour, insdate subcommand on v2
- rename subcommand name `insdeltasec` to `inssecinterval`
- remove `addlinenum2` subcommand
- add `inscopy` subcommand on v2
- change `sort` subcommand without parameters
- remove `addnumsortable` subcommand
- add support input of gz file on v2
- add `tee` subcommand on v2

## version 0.2.2 (2018-03-07)
- add `inshour` subcommand on v2
- add --weight option on `facetcount` subcommand on v2
- fix a bug on `join` subcommand

## version 0.2.1 (2018-02-27)
- add --version option
- split help document
- add some subcommands from v1 to v2
- add `insdeltasec` subcommand on v2
- add `groupsum` subcommand on v2

## version 0.2.0 (2018-02-25)
- add -v1, -v2 options
- add some subcommands from v1 to v2

## version 0.1.1 (2018-02-18)
- fix a bug of ratio of summary
- add number comparation operators of subcommand `where`

## version 0.1.0 (2018-02-12)
- initial version

