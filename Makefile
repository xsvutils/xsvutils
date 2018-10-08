
build: var/makefile
	make --question -f var/makefile build || make -f var/makefile build

gobuild: var/makefile
	make -f var/makefile gobuild

test: build
	bash test/test.sh

var/makefile: FORCE
	bash etc/build-makefile.sh > var/makefile.tmp
	mv var/makefile.tmp var/makefile

FORCE:

