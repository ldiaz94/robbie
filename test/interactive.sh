# The interactive mode itself is tested by hand, on a terminal; here
# only the ways it refuses to start: with a target named, and without
# a terminal, as when its input is not one.

top=$PWD
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
cd "$tmp"
printf 'task hello:\n    echo hello\n' >Robfile

# run robbie, showing the command, what it printed and its exit status;
# the time a run took changes every time, so it is left out
run() {
	echo "\$ robbie $*"
	{ "$top/build/robbie" "$@" 2>&1 </dev/null; echo "exit $?"; } |
		sed 's/, in [0-9.]*s$/, in (time)/'
}

run -i hello
run -i
run -i x=1
