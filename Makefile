
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

.PHONY: rust
rust:
	cd etc && cargo update
	cargo check --manifest-path=etc/Cargo.toml --target-dir=var/rust-target
	cargo fix --allow-dirty --allow-staged --manifest-path=etc/Cargo.toml --target-dir=var/rust-target
	cargo clippy --all --manifest-path=etc/Cargo.toml --target-dir=var/rust-target
	cd etc && cargo fmt
	cargo test --manifest-path=etc/Cargo.toml --target-dir=var/rust-target
