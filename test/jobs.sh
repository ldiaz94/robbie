# -j: up to n recipes at once, each target only once everything it
# needs is made, and a failure that stops new recipes but waits for
# those already running.

top=$PWD
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
cd "$tmp"

# run robbie, showing the command, what it printed and its exit status;
# the time a run took changes every time, so it is left out
run() {
	echo "\$ robbie $*"
	{ "$top/build/robbie" "$@" 2>&1; echo "exit $?"; } |
		sed 's/, in [0-9.]*s$/, in (time)/'
}

# write standard input to the file $1, and show it with line numbers
file() {
	cat >"$1"
	echo "--- $1"
	awk '{ printf "%2d| %s\n", NR, $0 }' "$1"
}

# a and b each wait up to two seconds for the other to have started,
# so they both succeed only when they run together; all needs both
file Robfile <<'EOF2'
task all: a b
    cat a b
a:
    touch a.on
    for i in 1 2 3 4 5 6 7 8 9 10; do test -e b.on && break; sleep 0.2; done
    test -e b.on
    echo a >{target}
b:
    touch b.on
    for i in 1 2 3 4 5 6 7 8 9 10; do test -e a.on && break; sleep 0.2; done
    test -e a.on
    echo b >{target}
EOF2
run -q -j2 all
rm -f a b a.on b.on

# with one job at a time, b never sees a start, and robbie stops at
# its failure, never starting all
run -q -j1 b a all
rm -f a b a.on b.on

# a failure stops new recipes, but one already running is waited for;
# slow is made even though fast failed while it ran
file Robfile <<'EOF2'
task all: slow fast later
slow:
    sleep 1
    touch {target}
fast:
    false
later: fast
    touch {target}
EOF2
run -q -j2 all
ls slow later 2>&1

# with -k, later is left out, and the rest is made
rm -f slow
run -q -k -j3 all
ls slow 2>&1
