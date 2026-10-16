# include: reading another robfile in place, with its name expanded and
# taken from the directory robbie runs in, and the mistakes, which name
# the file and line they are in and exit 2.

top=$PWD
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
cd "$tmp"
mkdir sub

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

# an include in the middle: its variables and rules join the rest, in
# order, and it ends the rule above it; the included file includes
# another, named from the top directory, not from sub
file Robfile <<'EOF'
dir = sub
cc = cc

prog: main.c
    {cc} -o prog main.c
include   {dir}/rules.rob
# After the include.
task test: prog
    ./prog
EOF
file sub/rules.rob <<'EOF'
cc = {cc} -Wall
# Made in sub.
lib.a: lib.c
    ar rc lib.a lib.o
include common.rob
EOF
file common.rob <<'EOF'
common = yes
EOF
run -p
run -p cc=gcc

# 'include' is a keyword only when a file name follows it
file Robfile <<'EOF'
include = x
include: a
EOF
run -p

# mistakes: in an included file, a missing file, a loop, no name
file Robfile <<'EOF'
include sub/bad.rob
EOF
file sub/bad.rob <<'EOF'
x = 1
    echo stray
EOF
run -p
file Robfile <<'EOF'
prog:
include common.rob
    echo stray
EOF
run -p
file Robfile <<'EOF'
include nothere.rob
EOF
run -p
file Robfile <<'EOF'
include a.rob
EOF
file a.rob <<'EOF'
include ./Robfile
EOF
run -p
file Robfile <<'EOF'
include ./Robfile
EOF
run -p
file Robfile <<'EOF'
none =
include {none}
EOF
run -p
file Robfile <<'EOF'
include sub/dup.rob
prog:
EOF
file sub/dup.rob <<'EOF'

prog: main.c
EOF
run -p
