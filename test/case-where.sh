
./xsvutils ./test/data/where.tsv where col1 \> 10     > ./var/test/where-1.tsv
./xsvutils ./test/data/where.tsv where col2 gt b      > ./var/test/where-2.tsv
./xsvutils ./test/data/where.tsv where col2 =~ b      > ./var/test/where-3.tsv
./xsvutils ./test/data/where.tsv where col2 =~ 'b\z'  > ./var/test/where-4.tsv
./xsvutils ./test/data/where.tsv grep  'b\z' col2     > ./var/test/where-5.tsv

