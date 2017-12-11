
build: var/makefile
	make -f var/makefile build

gobuild: var/makefile
	make -f var/makefile gobuild

var/makefile: FORCE
	bash etc/build-makefile.sh > var/makefile.tmp
	mv var/makefile.tmp var/makefile

FORCE:

