# Out of date: which recipes -n shows, and in what order. A file is
# made when it is missing, older than an input, or needs something
# that is made; a task always is. Times are set with touch -d, to the
# nanosecond where it matters.

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

# set the time of each file after $1 to $1
at() {
	t=$1
	shift
	touch -d "$t" "$@"
	echo "# $* at $t"
}

file Robfile <<'EOF2'
prog: a.o b.o
    link prog
a.o: a.c common.h
    compile a
b.o: b.c common.h
    compile b
common.h: common.in
    generate common.h

# a task with no recipe: always out of date, with nothing to show
task all: prog

task test: prog
    run tests
stamp: stamp.in test
    note the stamp
EOF2

# nothing made yet: all of it, each input before what needs it, and
# common.h once although two rules need it
at '2026-01-01 12:00' a.c b.c common.in
run -n prog

# everything newer than what it needs: nothing to do
at '2026-01-01 12:01' common.h
at '2026-01-01 12:02' a.o b.o
at '2026-01-01 12:03' prog
run -n prog
run -n all

# a task always runs, and so does a file that needs one
at '2026-01-01 12:00' stamp.in
at '2026-01-01 12:05' stamp
run -n test
run -n stamp

# one source changed: only what depends on it
at '2026-01-01 12:04' b.c
run -n prog

# a header changed: through common.h, both objects and the program;
# goals named twice, or needed by another goal, are made once
at '2026-01-01 12:04' common.in
run -n prog a.o prog

# a target missing in the middle: it and what needs it
at '2026-01-01 12:04' common.h b.c common.in
at '2026-01-01 12:05' a.o b.o
at '2026-01-01 12:06' prog
rm a.o
run -n prog

# as old as its input is up to date; a nanosecond older is not
at '2026-01-01 12:05:00.000000005' a.o a.c
run -n a.o
at '2026-01-01 12:05:00.000000004' a.o
run -n a.o

# a missing input no rule makes names the rule that needs it, even
# when the target itself is there; it is an error only when a goal
# needs it
rm b.c
run -n prog
run -n a.o
