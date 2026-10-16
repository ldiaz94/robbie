# Placeholders in variable values, seen through -p: filling in, adding
# to a variable, the doubled brace, the braces that belong to the shell,
# and the mistakes, with their suggestions, which exit 2.

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

# filling in, in the order of the file, and adding to a variable
robfile <<'EOF'
cc = cc
flags = -O2
flags = {flags} -g
cmd = {cc} {flags}{flags}
cc = tcc
late = {cc}
EOF
run -p
# a value from the command line is used, and is not expanded itself
run -p cc=clang 'flags={cc}'

# the doubled brace, and braces that are not placeholders
robfile <<'EOF'
x = 1
print = awk '{{print}' {{x} {{{x}
shell = ${HOME} ${x} a{x}b
braces = { print $1 } {a,b} {} {1x} {x-y} { x} {x {x
EOF
run -p

# unknown names, with and without a suggestion
robfile <<'EOF'
fpc = fpc -O2
build = {fcp} robbie.pas
EOF
run -p
robfile <<'EOF'
y = 1
z = {x}
EOF
run -p
robfile <<'EOF'
a = {a} more
EOF
run -p
robfile <<'EOF'
out = {tagret}
EOF
run -p

# robbie's own placeholders, which mean nothing in a variable, and
# can't be variable names
robfile <<'EOF'
out = {target}
EOF
run -p
robfile <<'EOF'
inputs = a b
EOF
run -p
run -p stem=x

# long values, which move the pool many times over while being built:
# 64 bytes doubled twelve times is 256 kB, and every copy is whole
{
	echo "a = 0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
	i=0
	while [ $i -lt 12 ]; do echo 'a = {a}{a}'; i=$((i + 1)); done
} >Robfile
echo "--- a Robfile doubling a twelve times"
echo "\$ robbie -p | awk ..."
"$top/build/robbie" -p | awk '{ n = gsub(/0123456789abcdef/, "")
	print length($0), n }'
