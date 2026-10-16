# The graph: targets named on the command line, which a rule must make,
# and loops, which are reported whole, a link to a line, and exit 2.

top=$PWD
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
cd "$tmp"
# with no target robbie shows the listing, whose title starts with ~
HOME=$tmp
export HOME

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

# targets: files and tasks, named more than once, a variable among
# them; a diamond, where two inputs share one, is no loop
file Robfile <<'EOF2'
prog: a.o b.o
a.o: a.c common.h
b.o: b.c common.h
common.h: common.in
task test: prog
EOF2
touch a.c b.c common.in
run
run prog test prog
run cc=gcc test

# names no rule makes: a typo, something far from any target, and an
# input, which is a file but not a target
run tset
run nothing
run a.c

# a target that needs itself
file Robfile <<'EOF2'
prog: main.c prog
EOF2
run

# a loop through three rules, reported from where the search entered
# it; it is an error even when the target named is outside it
file Robfile <<'EOF2'
task all: prog
prog: main.o
main.o: main.c gen.h

gen.h: gen.sh
gen.sh: main.o
task other:
EOF2
run
run other
run -p

# a loop through an included file names each rule's own file
file Robfile <<'EOF2'
x: y
include more.rob
EOF2
file more.rob <<'EOF2'
y: x
EOF2
run
