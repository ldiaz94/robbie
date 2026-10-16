# The command line: every flag, bundled and glued forms, -h and --help,
# and the usage errors, which exit 2.

top=$PWD
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
cd "$tmp"
# with no target robbie shows the listing, whose title starts with ~
HOME=$tmp
export HOME
# robfiles with a task for each target named below, where the flags
# below point
mkdir dir
printf 'task test:\ntask install:\ntask -:\ntask -n:\n' >Robfile
printf 'task test:\ntask install:\n' >dir/file

# run robbie, showing the command, what it printed and its exit status;
# the time a run took changes every time, so it is left out
run() {
	echo "\$ robbie $*"
	{ "$top/build/robbie" "$@" 2>&1; echo "exit $?"; } |
		sed 's/, in [0-9.]*s$/, in (time)/'
}

run
run -i -k -n -p -q
run -iknpq
run -C dir -f file -j 4 cc=gcc test install
run -Cdir -ffile -j4
run -kj 4 test
run -- -n
run - -n
run -x
run -kx
run -j
run -C
run -j 0
run -j 1001
run -j 99999999999999999999
run -j 4x
run -j ''
run -h
run --help
run -kh test
run -C -h
