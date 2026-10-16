# Reading a robfile: logical lines, descriptions, variables and
# command-line overrides, seen through -p, and the mistakes robbie
# reports with their line numbers, which exit 2.

top=$PWD
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
cd "$tmp"
ln -s "$top/examples" examples

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

# variables: spacing, reassignment, continuations, and a comment that
# ends in a backslash but doesn't go on
robfile <<'EOF'
cc   =   gcc
flags=-O2
empty =
flags = -g
path = /bin:/usr/bin
list = a \
       b	\
   c
# not continued \
last = x
EOF
run -p
run -p cc=clang new=x 'flags=-O0 -g' empty=
run -p cc=a cc=b

# rules and recipes: which comment becomes a description, tabs and
# spaces, and recipe lines keeping their backslashes for the shell
robfile <<'EOF'
# The top of the file.

# Not a description: a blank line follows.

# The first line of two.
#The description.
all: prog \
     doc
	echo tab
    echo spaces \
        continued
    # a comment for the shell
# a comment at the margin, above nothing
x = 1
# above a variable, so not a description
y = 2
prog: a.c
    cc -o prog a.c

#
doc:
EOF
run -p

# the robbie example reads whole; dwm's needs C files, in comprehension.sh
run -p -C examples/robbie

# mistakes in the robfile, each named by its line
robfile <<'EOF'
x = 1
    echo hi
EOF
run -p
robfile <<'EOF'
a = 1 \
    2
oops
EOF
run -p
robfile <<'EOF'
# fine
my-var = 1
EOF
run -p
robfile <<'EOF'
= 1
EOF
run -p

# mistakes outside it
run -f nothere
run -f .
run -C nothere
run a.b=c
run =x
