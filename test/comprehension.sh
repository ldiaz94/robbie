# Comprehensions: {want for pattern} over the files on disk, and
# {want for pattern in name} over the words of a placeholder, leaving
# out words that don't fit; and the dwm example, read in a directory
# holding a few C files.

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

# the dwm example, word for word: every .c on disk gives a .o, which
# the pattern makes
mkdir dwm
cp "$top/examples/dwm/Robfile" dwm/
touch dwm/dwm.c dwm/drw.c dwm/util.c dwm/config.h
run -p -C dwm
run -n -C dwm dwm

# over a variable's words, leaving out what doesn't fit; the directory
# can change; in a value, a rule and a recipe, where robbie's own
# placeholders can be the list; next to plain placeholders and shell
# braces, which pass through
mkdir src
touch src/a.c src/b.c
file Robfile <<'EOF2'
sources = main.c util.c README notes.c.txt
objects = {build/*.o for *.c in sources}
task show: {*.h for src/*.c}
    echo {objects}
    echo {*.d for *.h in inputs} and {target}
    echo {{*.x for *.y} ${HOME+set} { echo shell; }
    echo {*.o for *.c in sources}
*.h:
    true
EOF2
run -p
run -n show

# not comprehensions, so left alone: no '*' in either part, a blank
# just inside a brace, a word other than 'for' or 'in'
file Robfile <<'EOF2'
task show:
    echo {x for y} { *.o for *.c} {*.o fore *.c} {*.o for *.c on x}
EOF2
run -n show

# mistakes: a glob that matches nothing, an unknown name, a pattern
# with two '*'
file Robfile <<'EOF2'
objects = {*.o for *.cc}
EOF2
run -p
file Robfile <<'EOF2'
sources = a.c
objects = {*.o for *.c in sorces}
EOF2
run -p
file Robfile <<'EOF2'
objects = {*.o for *.*}
EOF2
run -p
