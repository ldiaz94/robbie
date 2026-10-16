# Globs in inputs: a word with a '*' is the files it matches, sorted,
# each input once; '?', '[' and '\' are only letters; a glob that
# matches nothing is an error.

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

mkdir src
touch b.c a.c main.c .hidden.c notes.txt 'x?.c' 'y[1].c' src/one.c src/two.c

# a glob, sorted, hidden files left out; main.c named first and
# matched again is one input; globs through a variable and in a
# directory; -p shows the inputs as written
file Robfile <<'EOF2'
srcs = src/*.c
task all: main.c *.c
    echo {inputs}
task sub: {srcs} notes.txt
    echo {inputs}
task odd: x?.c y[1].c
    echo {inputs}
task wild: *[1].c
    echo {inputs}
EOF2
run -p
run all sub odd wild

# a glob is looked at again on every run
touch c.c
run -q all

# a glob that matches nothing is an error, even in a rule not asked
# for, since it is nearly always a typo
file Robfile <<'EOF2'
task all:
    echo all
prog: *.cc
    link
EOF2
run all
run -p
