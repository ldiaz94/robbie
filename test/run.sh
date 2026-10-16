# Running recipes: each one a script for sh -e, echoed first, with
# robbie's own placeholders filled in; -n, -q and -k, failures, and the
# exit statuses.

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

# a program from two sources through a generated header; a recipe sees
# a variable's final value, and the shell's own ${...} and $ untouched
file Robfile <<'EOF2'
cc = cc
prog: a.o b.o
    cat {inputs} >{target}
    echo "made {target} from {input} and the rest; newer: {newer}"
a.o: a.c gen.h
    cat {inputs} >{target}
b.o: b.c gen.h
    cat {inputs} >{target}
gen.h:
    n=3
    echo "#define N ${n}" >{target}

# a multi-line script: the loop spans lines, and cd carries on
task show: prog
    for f in {inputs}; do
        echo "$f: $(wc -c <$f)"
    done
    cd /
    pwd
task flags:
    echo {cc}
cc = {cc} -O2
EOF2
at '2026-01-01 12:00' a.c b.c
run prog
cat prog

# nothing out of date: nothing to do, and nothing printed
run prog

# one source changed: {newer} names only the inputs made again
at '2026-01-01 12:05' gen.h a.o b.o prog
at '2026-01-01 12:10' b.c
run prog

# a task: every input is newer, and the shell script runs whole
run show
run flags

# -q runs without echoing; -n echoes without running, filling in the
# placeholders, and counts what would be made as newer
run -q gen.h show
rm gen.h
run -n prog
test -e gen.h || echo "gen.h still missing"
run -nq prog
run -q prog

# the first failing command stops a recipe, and a failed recipe stops
# robbie with status 1
file Robfile <<'EOF2'
task all: bad good after
bad:
    echo first
    false
    echo never
good:
    touch {target}
after: bad
    touch {target}
task killed:
    kill -9 $$
EOF2
run all
test -e good || echo "good not made"

# -k makes whatever doesn't need what failed
run -k all
ls good after 2>&1
run killed

# a missing input stops robbie before anything runs, unless -k: then
# the rest is made, and robbie exits 2
file Robfile <<'EOF2'
task all: one two
one: nowhere.c
    touch {target}
two:
    touch {target}
EOF2
run all
run -k all

# a typo in any recipe stops robbie before anything runs, even one
# that isn't asked for; robbie's own names still belong to recipes
file Robfile <<'EOF2'
task all:
    touch ran
task other:
    echo {tagret}
EOF2
run all
test -e ran || echo "nothing ran"
file Robfile <<'EOF2'
task all:
    echo {input}
x = {target}
EOF2
run all

# a name=value operand sets the variable and goes into the recipe's
# environment as well, so {DESTDIR} and "$DESTDIR" agree; one set in
# the environment alone is only the shell's
file Robfile <<'EOF2'
DESTDIR =
task install:
    echo "[{DESTDIR}] [$DESTDIR]"
EOF2
run -q install DESTDIR=pkg
DESTDIR=env run -q install
