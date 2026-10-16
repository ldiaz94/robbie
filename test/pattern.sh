# Pattern rules: a '*' in the target makes any name that fits, the '*'
# in its inputs is the stem, and the first pattern whose inputs exist
# or can be made wins; a plain rule wins over any pattern.

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

# objects from C, or from assembler when there is no C; a generated
# C file, made by a pattern too; the directory can change with the
# stem; a plain rule for main.o wins over the patterns
mkdir src
touch a.c b.s gen.y config.h src/lib.c main.c
file Robfile <<'EOF2'
prog: main.o a.o b.o gen.o build/lib.o
    echo link {inputs}
*.o: *.c config.h
    echo cc -c {input} for {stem}
*.o: *.s
    echo as {input} for {stem}
*.c: *.y
    echo yacc {input} to {target}
build/*.o: src/*.c
    echo cc {input} to {target}, stem {stem}
main.o: main.c
    echo plain {target}
EOF2
run -p
run -n prog

# a name only a pattern makes can be named on the command line, and
# made; a stem is never empty, so '.o' fits no '*.o'
run -n x.o
touch x.c
run x.o
run .o

# no pattern whose inputs can be had: the input is missing
file Robfile <<'EOF2'
prog: c.o
*.o: *.c
    cc {input}
EOF2
run -n prog

# a pattern that needs itself is not tried again further down, so the
# search ends; a pattern can be a task
file Robfile <<'EOF2'
*.o: *.o.c
    never
task run-*: *.sh
    sh {input} {stem}
EOF2
run -n z.o
echo 'echo hello from $0 for $1' >hi.sh
run run-hi

# mistakes: {stem} outside a pattern, a pattern with two '*'
file Robfile <<'EOF2'
prog: a.o
    echo {stem}
EOF2
run prog
file Robfile <<'EOF2'
*.*: x
EOF2
run -p
