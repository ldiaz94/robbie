# Rules and tasks, seen through -p: targets, inputs and descriptions
# with their placeholders filled in, recipes keeping their shape, and
# the mistakes in a rule's first line, which exit 2.

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

# write standard input to Robfile, and show it with line numbers
robfile() {
	cat >Robfile
	echo "--- Robfile"
	awk '{ printf "%2d| %s\n", NR, $0 }' Robfile
}

# files and tasks, and 'task' as the name of a file
robfile <<'EOF'
out = build
docs = a.1 b.5

# Everything in {out}.
{out}/prog: main.c {docs}
    cc -o {target} {inputs}
task   check  :   {out}/prog
# A file called task.
task:
empty:
EOF
run -p
run -p out=bin

# recipes keep their indentation beyond the first line's, and the
# blank lines between their lines, but not those before or after
robfile <<'EOF'
task loop:

	for f in *; do
		echo "$f"

	done
		echo deeper than the first line

task heredoc:
    cat <<END
    one

    three
    END
    # a comment for the shell
# a comment at the margin, dropped

    echo after the comment

task spaces:
        echo eight
    echo four
        echo eight again
EOF
run -p

# mistakes in a rule's first line
robfile <<'EOF'
prog: a.c
    cc a.c
task prog:
EOF
run -p
robfile <<'EOF'
x = prog
prog:
{x}:
EOF
run -p
robfile <<'EOF'
none =
{none}: a
EOF
run -p
robfile <<'EOF'
: a
EOF
run -p
robfile <<'EOF'
two = a b
{two}: c
EOF
run -p
robfile <<'EOF'
a b: c
EOF
run -p
robfile <<'EOF'
prog: {target}.c
EOF
run -p
robfile <<'EOF'
prog: {srcs}
EOF
run -p
robfile <<'EOF'
prefix = /usr

# Install into {prefx}.
task install:
EOF
run -p
