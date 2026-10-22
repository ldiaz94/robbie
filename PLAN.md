# robbie — plan

A small build tool and job runner, written in raz. The name comes from the
Polish *robić*, "to do, to make": you tell robbie what to make, and it makes
it.

This file is the design, and the work queue. The queue took robbie from an
empty directory to 1.0, which is done; what is left is the roadmap at the
end, for reading Makefiles. Every checkpoint is small, leaves the tree
building and its tests passing, and ends in its own commit, so work can
stop after any checkpoint and pick up again later.

robbie was written in Free Pascal (`~/lib/robbie`, now frozen) and
ported to raz on 2026-10-16, a module for each unit, its behaviour, its
tests and its manual pages kept as they were.

**The ticks in this file are the only record of progress.** Changing `[ ]`
to `[x]` is part of finishing a checkpoint and goes in the same commit.

## Why it exists

make has one great idea: a file saying what depends on what, and a program
that does only the work that is out of date. Around that idea it built a
notation nobody can read without the manual open: `$@`, `$<`, `$^`, `$?`,
`$$`, tab-only recipes, `.PHONY`. robbie keeps the idea and writes it in
words. A robfile should be readable by someone who has never seen one.

It is also the front door to a repository. Type `robbie` in a directory and
you see, in colour, everything you can do there: what each task is for, and
which files are out of date. `robbie -i` lets you pick a task and run it.

## Ethos

- The house rules apply: raz only, apart from the exceptions listed in
  `CLAUDE.md`, with raz's own library and, for `glob(3)` alone, the C
  library. What raz lacks, or makes awkward, goes in `RAZ-NOTES.md`, for
  raz's owner, rather than being worked around quietly.
- A feature has to pull its weight. When in doubt, leave it out and write
  it down under **Not now**.
- **Placeholders are words.** Anything that appears in a robfile is spelt
  out: `{target}`, not `$@`. If a name needs explaining, rename it.
- **Loads of comments.** This is a codebase for reading:
  - Every module opens with a block comment. It says what the module does,
    why it is shaped the way it is, and how it fits with the others.
  - Every type, record field, constant and global has a comment.
  - Every procedure has a header comment covering what it does, what it
    returns and what it changes. Say who owns any memory it hands out.
  - Wherever the code does something that isn't obvious, a comment says
    *why*: a timestamp edge case, a terminal quirk, a signal race.
  - A comment never just repeats the line under it. As a rough guide, there
    should be about one line of comment for every two or three lines of
    code.

## The robfile

A whole robfile, showing every feature:

```
# Build and test robbie.

fpc = fpc -O2 -Xs
prefix = /usr/local

# The program itself.
robbie: *.pas
    {fpc} robbie.pas

# Object files for the library, one per source.
build/*.o: src/*.pas
    {fpc} -FUbuild {input}

# Run the test suite.
task test: robbie
    for t in test/*.sh; do sh "$t"; done

# Install into {prefix}.
task install: robbie
    install -Dm755 robbie "$DESTDIR{prefix}/bin/robbie"
```

The rules, all of them:

- **Rules.** `name: inputs` followed by an indented recipe. Tabs or spaces
  both work. The whole recipe runs as one script with `/bin/sh -e -c`, not a
  shell per line as in make. So a `for` loop can span lines, a `cd` carries
  on to the lines after it, and the first failing command stops the recipe.
  A `\` at the end of a line continues it on the next, as in sh.
- **Files and tasks.** A plain rule makes a file, and runs only when the
  file is missing or older than one of its inputs. A rule starting with
  `task` has no file, and always runs when it is asked for. That replaces
  `.PHONY`.
- **Descriptions.** A `#` comment on the line just above a rule is its
  description, and shows up in the listing. Other comments are ignored.
- **Variables.** `name = value`, and nothing else. The value is expanded
  when the line is read, so `flags = {flags} -g` appends and order is
  predictable. `name=value` on the command line overrides the file.
- **Placeholders.** `{name}` is replaced in rules and recipes:

  | Placeholder | Means |
  |-------------|-------|
  | `{target}`  | the file or task being made |
  | `{input}`   | its first input |
  | `{inputs}`  | all its inputs |
  | `{newer}`   | the inputs newer than the target |
  | `{stem}`    | what `*` matched in a pattern rule |
  | `{var}`     | any variable |
  | `{*.o for *.c}` | a `.o` for each `.c` file on disk |
  | `{*.o for *.c in sources}` | a `.o` for each word of `{sources}` ending in `.c` |

  The last two are list comprehensions, in Python's word order. The `*`
  means what it means in a pattern rule, the matching part of the name, so
  the directory can change too: `{build/*.o for src/*.c}`. Words that don't
  fit the pattern are left out. A comprehension names files that don't
  exist yet, which a glob can't.

  An unknown name is an error, so a typo is caught. Only a simple name in
  braces is a placeholder, so shell code such as `awk '{ print $1 }'` and
  `${HOME}` passes through untouched. Write `{{` to get a literal `{`.
- **`$` belongs to the shell.** robbie never touches it: no `$$`.
- **Globs and patterns.** A `*` in an input is a glob (`*.pas`). A `*` in
  the *target* makes a pattern rule. It matches any file that fits, and the
  `*` in each input stands for the same text, `{stem}`.
- **`include file`** reads another robfile in place.

**Not now:** functions, conditionals, recursive calls, arguments to tasks
beyond `name=value`, and looking for a robfile in parent directories.

## The examples

Two complete robfiles live in `examples/`. They are the reference for the
format, and they must appear in the documentation word for word:

- `examples/robbie/Robfile` is robbie's own build: variables, a file rule
  with a glob, `{target}` and `{inputs}`, a multi-line recipe with shell
  `${...}` passing through, tasks, and a description using `{prefix}`.
- `examples/dwm/Robfile` is a C program: a pattern rule and
  `{*.o for *.c}`.

Where they go:

- `robfile.5`, under EXAMPLES: both, in full.
- `robbie.1`, under EXAMPLES: the listing that `robbie` prints for
  `examples/robbie`.
- `README.md`: the robbie example, and its listing, as the
  thirty-second tour.

A test runs `robbie -p -C examples/...` on each, so the examples can't
drift away from what robbie actually reads. If a checkpoint changes the
format, it updates the examples and every copy of them in the same commit.

## Command line

    robbie [-iknpqw] [-C dir] [-f file] [-j n] [name=value ...] [target ...]

    (no target)  show the listing: tasks, files, variables
    -i           interactive: pick a task from the listing and run it
    -C dir       change to dir first
    -f file      read file instead of Robfile
    -j n         run up to n recipes at once (default 1)
    -k           keep going: after an error, make whatever doesn't depend on it
    -n           print the recipes without running them
    -p           print the rules and variables as robbie read them (for tests)
    -q           quiet: don't echo recipe lines
    -w           watch: make the targets again whenever a file they need changes

It exits 0 on success, 1 when a recipe failed, and 2 when the robfile has
an error or robbie is used wrongly. Messages include the file and line:
`robbie: Robfile:12: unknown placeholder {tagret}; did you mean {target}?`.

## The look

Colour only goes to a terminal. It is off when `NO_COLOR` is set, and off
when output is a pipe, so scripts and tests see plain text.

**The listing** (`robbie` with no target):

```
 robbie  ~/lib/robbie/Robfile

 tasks
   test      Run the test suite.                   ← robbie
   install   Install into /usr/local.              ← robbie

 files
 ● robbie    The program itself.                   ← *.pas
   build/*.o Object files for the library, one per source.

 variables
   fpc = fpc -O2 -Xs      prefix = /usr/local
```

Names are bold, tasks and files each get their own colour, and inputs are
dim. A yellow `●` marks a file that is out of date. The columns line up and
long descriptions are cut at the terminal width.

**Running:** each target starts with a coloured `▸ name` header. Recipe
lines are echoed dim, a failure is red and names the robfile line of the
recipe that failed, and the run ends with one summary line: what was made,
what was already up to date, and how long it took.

**Interactive** (`-i`): the listing, with a cursor.

- `↑`/`↓` or `j`/`k` move the cursor. Typing letters filters the list.
- `Enter` runs the target. `n` shows what would run without running it.
- `q` or `Esc` quits.

After a run, robbie waits for a key and goes back to the list. The `●`
marks and the last result are updated. The terminal is always restored,
even after Ctrl-C.

## Design

The modules are in `src/`, each named with an R, since raz's module names
are one space with its library's. From the bottom up:

| Module          | Job |
|-----------------|-----|
| `Rbase.raz`     | A place in a robfile, and the messages that name one: `report`, and `fatal`, which reports and stops robbie. Text: `join`, `keep`, `num`. Text lives as long as robbie does and is never freed, so a slice of a robfile's bytes is used as it is. |
| `Rsig.linux.raz`| Whether a signal is ignored, which `Sys` can't say: the one system call robbie makes itself. |
| `Rexpand.raz`   | The variables, and placeholders: finds `{name}`, looks it up, suggests the closest name when there is no match. Also stems, comprehensions and globs, through the C library's `glob(3)`. |
| `Rread.raz`     | Reads a robfile and its includes into rules and recipe lines. Records the file and line for every error. |
| `Rgraph.raz`    | Nodes and edges. Reads timestamps (nanoseconds included), expands globs, matches pattern rules, finds loops, and decides what is out of date. |
| `Rterm.raz`     | The terminal: is it one, its size, colour escapes, raw mode, reading keys, and the signals robbie takes. Nothing else touches escape codes. |
| `Rjob.raz`      | Runs recipes. Each recipe goes to `/bin/sh -e -c` as one script, through `Sys.spawn` and `Sys.wait`, with up to `-j` running at once. Handles SIGINT and SIGTERM, removes half-made files, and prints the run's headers and summary. |
| `Rshow.raz`     | What the user sees of a robfile: the listing, and the interactive loop. |
| `Rwatch.raz`    | `-w`: runs each round in a copy of robbie made by `Sys.fork`, which sends back on a pipe the files to watch, then looks at their times and sizes every 300 ms until one changes. |
| `Robbie.raz`    | The main module: flags, finding the robfile, exit status. |

A module can't import one that imports it, so where two Pascal units used
each other one side moved: the variables went from `read` to `Rexpand`,
and a run's header and summary from `show` to `Rjob`.

Errors are reported by `Rbase.fatal(where, parts)`, whose message is a list
of strings, joined as Pascal's `+` joined them. A procedure that can fail
returns a result that says so, or the program stops right there.

## Documentation

| File         | What |
|--------------|------|
| `doc/robbie.1`  | The command: every flag, the listing and the interactive keys, exit statuses, environment (`NO_COLOR`), and EXAMPLES with the listing for `examples/robbie`. |
| `doc/robfile.5` | The file format: rules, tasks, descriptions, variables, placeholders, comprehensions, globs, patterns, `include`, a table translating make's notation, and EXAMPLES with both robfiles in full. |
| `README.md`  | What it is, how to build and install it, a thirty-second tour using the robbie example, and the origin of the name. |

Both pages are mdoc(7) and must pass `groff -mdoc -ww -z`. A feature that
isn't on its man page is not finished.

## Testing

`make test` runs every `test/*.sh` in a fresh scratch directory. Each script
sets up its files (using `touch -d` for timestamps), runs `robbie`, and
prints the result. The output is compared with the matching `test/*.out`.
Since output is a pipe, the tests see plain text. Colour and the interactive
mode are checked by hand, and the commit message says so. After that, both
man pages go through groff. Last, `make test` checks that `build/robbie
test` passes too, and `test/self.sh` that the Robfile at the top is the robbie
example, word for word, as are its copies in the docs.

## How to work through this plan

1. Read `~/.claude/CLAUDE.md`, `CLAUDE.md` and this file. Run
   `git log --oneline -5`, then find the first unticked checkpoint.
   Don't skip ahead.
2. Do only what that checkpoint says. Anything else goes in `TODO.md`.
3. Every change in behaviour gets a test in `test/`.
4. Every change a user can see updates `doc/robbie.1` or `doc/robfile.5` in the
   same commit.
5. `make && make test && make fmt` must pass; raz builds with `-Werror`.
6. Tick the checkpoint and commit the code, docs and tick together. If you
   stop partway, add an indented `Progress:` line to the checkpoint instead
   of ticking it.

**Stop and ask** when a checkpoint is marked **DECISION**, when the design
here doesn't fit the code, or when a checkpoint grows past about 300
changed lines.

---

## 1.0: done

Tagged `v1.0` on 2026-09-28. The phases that got there, in order: the
skeleton (Makefile, flags, project rules), reading (lines, variables,
placeholders, rules, `include`), making (the graph, out of date, running
recipes, a robfile for arno), globs, patterns and comprehensions, `-j` and
signals, the look (listing, run headers, interactive mode, resizing), and
1.0 itself (robbie makes robbie, the pages, a read-through). `git log
v1.0` has the details, one checkpoint per commit.

Along the way `name=value` operands also went into the recipes'
environment, so `robbie install DESTDIR=pkg` works as it does with make.

---

# The roadmap: Makefiles

robbie was written to replace make's notation, not make. Most repositories
that could use it already have a Makefile, and writing a robfile by hand
takes minutes, with the table under **Coming from make** in `robfile.5`.
Everything below is optional. Each phase has to earn its place against
that table, and the answer may be to stop.

The ground rules, whatever is built:

- **One language in the core.** make's notation never reaches `Rread`,
  `Rgraph` or `Rjob`. It is translated into a robfile first, in a
  module of its own (`Rmake`), and robbie reads the result like any other.
- **Report, never guess.** Anything the translator can't turn into a
  robfile that means the same thing is reported with the Makefile's line
  number, and the line goes into the output as a comment, so nothing is
  lost silently. A Makefile with anything reported converts with exit
  status 1, so a script can tell.
- **Readable output.** What comes out should look written by hand:
  descriptions from the comments above rules, variables before rules,
  make's order otherwise kept.
- **GNU make is the dialect.** BSD make's `.if` and `${.TARGET}` are
  reported like anything else unknown.

## Phase M1: translation

- [ ] **M1.1 DECISION: convert or read directly.**
  - **Convert (recommended).** `robbie -m [Makefile]` prints a robfile on
    standard output, to be kept: `robbie -m > Robfile`. robbie stays one
    language, and you get a file to read and edit.
  - **Read directly.** With no robfile, robbie translates `Makefile` in
    memory and runs the result. More convenient, but make's notation
    becomes part of robbie for good, and the "report, never guess" rule
    has no good way to show its reports on every run.
  - Or stop here, and leave it to the table in `robfile.5`.
- [ ] **M1.2 The plain subset.** `Rmake`: joined `\` lines, comments
  (the one above a rule becomes its description), `X = y`, `X := y`,
  `X += y` (becoming `X = {X} y`), `X ?= y` (a plain `X = y`, since the
  command line overrides anyway), rules with tab-indented recipes,
  `.PHONY` into `task`, `$(X)` and `${X}` into `{X}`, `$$` into `$`, and
  `$@`, `$<`, `$^`, `$?`, `$*` into the placeholders. A literal `{` in the
  Makefile becomes `{{`. Anything else is reported.
- [ ] **M1.3 Recipe lines.** make runs a shell per line, robbie one script.
  The two differ only when a line changes the shell's state (`cd`,
  `export`, `set`, an assignment), since `sh -e` already stops at the
  first failing line. Wrap such a line in `( ... )`, which keeps make's
  meaning, and say so in a comment. `@` at the start of a line is dropped
  (`-q` does its job); `-` becomes `|| true` at the end of the line.
- [ ] **M1.4 Tested against real Makefiles.** Convert
  `~/lib/arno/Makefile` and `~/lib/concha/Makefile`. Check that the
  result does the same work as make, and compare it with arno's Robfile,
  written by hand before 1.0. Fix what the comparison shows.

## Phase M2: the common extensions

Only what shows up in real Makefiles, in order of how often.

- [ ] **M2.1 Patterns.** `%.o: %.c` into `*.o: *.c`. Static pattern rules,
  `$(OBJ): %.o: %.c`, into a plain pattern rule when every target in
  `$(OBJ)` fits it, and reported when not.
- [ ] **M2.2 Lists.** `$(wildcard *.c)` into `*.c` in inputs; in a
  variable, where a glob is not expanded, `{*.c for *.c}`.
  `$(X:.c=.o)` and `$(patsubst %.c,%.o,$(X))` into
  `{*.o for *.c in X}`. Other functions (`addprefix`, `filter`,
  `foreach`, `notdir`, `dir`, `basename`, `sort`) are reported, with a
  hint where a comprehension would do.
- [ ] **M2.3 Several targets.** `a b: c` becomes one rule for each target,
  as make means it. make's grouped targets, `a b &: c`, are one recipe
  making both, which a robfile can't say; report them.
- [ ] **M2.4 includes.** `include f` stays as it is when `f` is converted
  too; the caller is told which files to convert. `-include` and
  `sinclude`, which may be missing, are reported.

## Phase M3: the rest, probably never

Each of these is a real part of make, and each would drag make's model
into robbie. They stay reported unless a real repository needs one, and
even then the first answer is to change the Makefile.

- **Conditionals.** `ifeq`, `ifdef` and friends. The converter could
  resolve them for the environment it runs in, but that bakes one
  machine's answer into a file meant for all.
- **`$(shell ...)`.** Nothing is run at read time in a robfile. Where the
  output is only used in recipes, it can move into them as `$(...)`, as
  the robbie example does with gcc.
- **Recursive make.** `$(MAKE) -C sub` becomes `robbie -C sub` only once
  `sub` has a robfile; the converter can list those it would need.
- **Order-only inputs** (`| dir`). robbie would need a kind of input that
  doesn't count for being out of date. A recipe's `mkdir -p` does the
  job.
- **`export`, `.ONESHELL`, `.SUFFIXES`, double-colon rules, target-specific
  variables, `.DEFAULT_GOAL`, `$(eval)`, `define`.** Reported, full stop.
