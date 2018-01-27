
if [ -e var/buffer-test-1-fifo-1 ]; then
    rm var/buffer-test-1-fifo-1
fi
if [ -e var/buffer-test-1-fifo-2 ]; then
    rm var/buffer-test-1-fifo-2
fi

mkfifo var/buffer-test-1-fifo-1
mkfifo var/buffer-test-1-fifo-2

perl ./test/etc/buffer/1-o1.pl < var/buffer-test-1-fifo-1 &

perl ./test/etc/buffer/1-o2.pl < var/buffer-test-1-fifo-2 &

DEBUG=--debug
#DEBUG=

bash ./test/etc/buffer/1-i.sh | ./target/golang.bin buffer $DEBUG var/buffer-test-1-fifo-1 var/buffer-test-1-fifo-2 | head | wc -l &

wait

