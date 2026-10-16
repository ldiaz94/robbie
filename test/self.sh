# robbie makes robbie: the Robfile at the top of the repository is the
# robbie example, word for word, and so are its copies in robfile.5 and
# README.md, so what the docs show is what is used. The Makefile's test
# target then checks that './robbie test' passes too; it can't be done
# here, where it would run this test again, and so on for ever.

cmp Robfile examples/robbie/Robfile && echo "Robfile is the example"

# the literal block after the page's first sentence of EXAMPLES, with
# mdoc's \e turned back into a backslash
awk '/^The robfile that builds robbie itself:/ { f = 1; getline; next }
	f && /^\.Ed/ { exit }
	f' doc/robfile.5 | sed 's/\\e/\\/g' |
	cmp - Robfile && echo "robfile.5 shows it"

# the fenced block after the tour's first line
awk '/^This is robbie.s own `Robfile`:/ { f = 1; getline; getline; next }
	f && /^```/ { exit }
	f' README.md |
	cmp - Robfile && echo "README.md shows it"
