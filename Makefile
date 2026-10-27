# robbie, in raz, built without robbie. The program builds with the raz on
# PATH, which must be the version it is written for, RAZVERSION: make warns
# of any other. Its tarball is on raz's website, at
# download/raz-$(RAZVERSION)-linux-x86_64.tar.gz.
#
#   make              build/robbie
#   make test         every test/*.sh against its .out, the manual pages
#                     through groff, then robbie's own 'test' task
#   make fmt          src/ is laid out as raz's formatter lays it out
#   make install      the program and its manual pages (PREFIX=..., DESTDIR=...)
#   make uninstall    exactly what install put there

RAZ ?= raz
RAZVERSION = 0.25.0
RAZSITE = https://raz.lucelad.workers.dev
# raz's tools, the formatter among them, lie beside its real path
RAZTOOLS = $(dir $(realpath $(shell command -v $(RAZ))))tools

ifneq "$(word 2,$(shell $(RAZ) --version 2>/dev/null))" "$(RAZVERSION),"
$(warning robbie is written for raz $(RAZVERSION), from $(RAZSITE); $(RAZ) is $(or $(shell $(RAZ) --version 2>/dev/null),not found))
endif

PREFIX ?= $(HOME)/.local
BINDIR ?= $(PREFIX)/bin
MANDIR ?= $(PREFIX)/share/man
PAGES = doc/robbie.1 doc/robfile.5
SRC = $(wildcard src/*.raz)

all: build/robbie

build/robbie: $(SRC)
	@mkdir -p build
	$(RAZ) -Werror -o build/robbie src/Robbie.raz

# each test prints what it saw, and must match its .out file; then the
# pages go through groff, whose warnings don't change its exit status, so
# any output at all counts as a failure; last, robbie runs its own test
# task from the Robfile, which must pass as well
test: build/robbie
	@for t in test/*.sh; do \
		sh "$$t" | diff -u "$${t%.sh}.out" - || exit 1; \
	done
	@out=$$(groff -mdoc -ww -z $(PAGES) 2>&1); \
	if [ -n "$$out" ]; then echo "$$out"; exit 1; fi
	@build/robbie -q test >/dev/null
	@echo "test: every test passed"

fmt:
	@mkdir -p build
	$(RAZ) -o build/Pretty $(RAZTOOLS)/Pretty.raz
	@fail=0; for f in $(SRC); do \
		build/Pretty $$f | cmp -s - $$f || { echo "not formatted: $$f"; fail=1; }; \
	done; test $$fail = 0

install: build/robbie
	install -Dm755 build/robbie $(DESTDIR)$(BINDIR)/robbie
	install -Dm644 doc/robbie.1 $(DESTDIR)$(MANDIR)/man1/robbie.1
	install -Dm644 doc/robfile.5 $(DESTDIR)$(MANDIR)/man5/robfile.5

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/robbie $(DESTDIR)$(MANDIR)/man1/robbie.1 \
		$(DESTDIR)$(MANDIR)/man5/robfile.5

clean:
	rm -rf build robbie.tar.gz

.PHONY: all test fmt install uninstall clean
