# Signals: SIGTERM is passed on to every recipe running, robbie waits
# for them, removes the targets they had begun to write, and dies of
# the signal. A failed recipe's half-made target goes too.

top=$PWD
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
cd "$tmp"

# write standard input to the file $1, and show it with line numbers
file() {
	cat >"$1"
	echo "--- $1"
	awk '{ printf "%2d| %s\n", NR, $0 }' "$1"
}

# wait up to five seconds for each file named to exist
await() {
	for f; do
		i=0
		while [ ! -e "$f" ] && [ $i -lt 50 ]; do sleep 0.1; i=$((i + 1)); done
	done
}

# half has begun its file, old has not touched its own, and a task
# has no file; all three are running when the signal comes, and last
# is never started
file Robfile <<'EOF2'
task all: half old busy last
half:
    echo partial >{target}
    touch half.on
    exec sleep 10
old: old.c
    touch old.on
    exec sleep 10
task busy:
    touch busy.on
    exec sleep 10
last: half
    touch {target}
EOF2
touch -d '2026-01-01 12:00' old
touch -d '2026-01-01 12:05' old.c
echo "\$ robbie -q -j3 all, then SIGTERM"
"$top/build/robbie" -q -j3 all >log 2>&1 &
pid=$!
await half.on old.on busy.on
kill -TERM $pid
wait $pid
echo "exit $?"
cat log
ls half old last 2>&1

# a recipe that fails after writing its target leaves nothing behind;
# one that fails before is reported the same, and removes nothing
file Robfile <<'EOF2'
task all: early late
early:
    false
late:
    echo partial >{target}
    false
EOF2
echo "\$ robbie -q -k all"
{ "$top/build/robbie" -q -k all 2>&1; echo "exit $?"; } | sed 's/, in [0-9.]*s$/, in (time)/'
ls late 2>&1
