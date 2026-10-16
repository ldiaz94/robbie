# The listing: robbie with no target shows the tasks, the files with a
# mark on those out of date, and the variables, in columns cut to 80
# characters, since the output is not a terminal.

top=$PWD
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
cd "$tmp"
# the path in the title starts with ~
HOME=$tmp
export HOME

# run robbie, showing the command, what it printed and its exit status;
# the time a run took changes every time, so it is left out
run() {
	echo "\$ robbie $*"
	{ "$top/build/robbie" "$@" 2>&1; echo "exit $?"; } |
		sed 's/, in [0-9.]*s$/, in (time)/'
}

# the robbie example, in a directory holding what it needs; nothing is
# built yet, so both files are out of date
cp "$top/examples/robbie/Robfile" .
mkdir src doc
touch -d '2026-01-01 12:00' src/A.raz src/B.raz README.md doc/robbie.1 doc/robfile.5
run

# robbie made: only the tarball is left to do; a variable set on the
# command line shows in the listing and in the description using it
mkdir build
touch -d '2026-01-01 12:05' build/robbie
run prefix=/opt

# long names, descriptions and inputs are cut to fit, never splitting
# a character; a missing input only marks what needs it; no variables
mkdir sub
cat >sub/rules <<'EOF2'
# Build the documentation for every one of the many supported platforms and languages.
task docs: a-rather-long-input-name another-rather-long-input-name yet-another-one
    true

# Crème brûlée, à la carte: façade, naïveté, smörgåsbord, jalapeño, piñata, déjà vu.
task crème:
    true

task bare: docs

# Made from a file that is not there.
out/a-very-long-file-name-for-a-listing.txt: missing.c
    true
EOF2
run -C sub -f rules

# a robfile with nothing in it but a variable
echo 'x = 1' >empty
run -f empty
