# Watching: robbie -w makes the target, then again when its input
# changes; a robfile that no longer reads is reported and watched; a
# target that needs no file watches only the robfile, and says so; and
# a signal ends the watch with 128 plus the signal.

top=$PWD
tmp=$(mktemp -d)
pid=
trap 'kill $pid 2>/dev/null; rm -rf "$tmp"' EXIT
cd "$tmp"

# job control, so robbie started in the background takes SIGINT, which
# a script's background jobs would otherwise ignore
set -m

# wait up to ten seconds for the log to hold $1 lines saying what is
# watched
await() {
	i=0
	while [ "$(grep -c '^watching' log)" -lt "$1" ] && [ $i -lt 100 ]; do
		sleep 0.1
		i=$((i + 1))
	done
}

# send robbie the signal $1, and show how it ended; a watchdog kills it
# should it not end within ten seconds, so the test can't hang
stop() {
	kill -"$1" $pid
	( sleep 10; kill -KILL $pid ) >/dev/null 2>&1 &
	dog=$!
	wait $pid
	echo "exit $?"
	kill -- -$dog 2>/dev/null
}

# the log, its times left out
show() {
	sed 's/, in [0-9.]*s$/, in (time)/' log
}

cat >Robfile <<'EOF2'
copy: a.txt
    cp a.txt copy
task bare:
    echo bare
EOF2
echo one >a.txt
echo "\$ robbie -q -w copy; a.txt changes; Robfile breaks; SIGINT"
"$top/build/robbie" -q -w copy >log 2>&1 &
pid=$!
await 1
echo two >>a.txt
await 2
echo oops >>Robfile
await 3
stop INT
show
cat copy

sed '$d' Robfile >Robfile.new && mv Robfile.new Robfile
echo "\$ robbie -q -w bare; SIGTERM"
"$top/build/robbie" -q -w bare >log 2>&1 &
pid=$!
await 1
stop TERM
show

echo "\$ robbie -w -n copy"
"$top/build/robbie" -w -n copy 2>&1
echo "exit $?"
echo "\$ robbie -w"
"$top/build/robbie" -w 2>&1
echo "exit $?"
