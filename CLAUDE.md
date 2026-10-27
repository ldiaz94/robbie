# Working on robbie

robbie is a small build tool and job runner, written in raz. It reads a
`Robfile`, shows in colour what can be done in a repository, and makes
what is out of date. It was ported from Free Pascal (`~/lib/robbie`, now
frozen: never work there).

`PLAN.md` is the design and the work queue. Read it before changing
anything, and work through it one checkpoint at a time as it describes.
The language is defined by raz's report (`man raz`,
`~/r/raz/doc/raz.md`, the library `~/r/raz/doc/raz-lib.md`); the program
builds with the raz on PATH, of the version `RAZVERSION` in the Makefile
says.

## Setup and checks

    make            # build/robbie
    make test       # test/*.sh against test/*.out, the pages through groff,
                    # then build/robbie's own test task
    make fmt        # src/ is laid out as raz's formatter lays it out
    make install    # PREFIX=$(HOME)/.local, DESTDIR honoured

`make test` and `make fmt` must pass before every commit. The tests run
`build/robbie` through a pipe, so they see plain text; colour and the
interactive mode are checked by hand, on a terminal (or a pseudo-terminal
driven by a script), and the commit message says so.

## Exceptions to raz-only

The project is raz end to end, except for:

- the `Makefile`, which builds robbie without robbie;
- the manual pages, in mdoc(7): `doc/robbie.1` and `doc/robfile.5`;
- the Markdown documents: `README.md`, `PLAN.md`, `TODO.md`,
  `RAZ-NOTES.md` and this file;
- robfiles: `Robfile` and everything under `examples/`;
- the tests: `test/*.sh` and their expected output, `test/*.out`, kept in
  sh as the Pascal robbie had them, so the port is held to the same text.

Recipes inside a robfile are shell by nature; that is part of the robfile
exception, not a new one. The C library is used for `glob(3)` alone.

## Code style

- Modules keep the Pascal units' jobs, each named with an R: `Rbase`,
  `Rsig`, `Rexpand`, `Rread`, `Rgraph`, `Rterm`, `Rjob`, `Rshow`,
  `Rwatch`, and `Robbie`, the main module. `PLAN.md` says what each does.
- Comment heavily; this codebase is meant to be read top to bottom:
  - every module opens with a block comment: what it does, why it is
    shaped that way, what it depends on and how it fits with the others;
  - every type, record field, constant and module variable has a comment;
  - every procedure has a header comment: what it does, what it returns,
    what it changes;
  - wherever the code is not obvious, a comment says *why*;
  - no comment just repeats the line under it. Aim for roughly one comment
    line per two or three lines of code. A comment must not hold `*)`.
- Text lives as long as robbie does and is never freed: `Rbase.keep` and
  `Rbase.join` make new strings, and a slice of a robfile's bytes is used
  as it is.
- What raz lacks, or makes awkward, goes in `RAZ-NOTES.md`, for raz's
  owner; it is not worked around quietly.

## Documentation rules

A feature is not finished until `doc/robbie.1` or `doc/robfile.5`
describes it, in the same commit. The robfiles in `examples/` must appear
word for word in the docs, as `PLAN.md` explains under **The examples**;
change one, change every copy (`test/self.sh` checks).

## Commits

Author `Luis <42945842+ldiaz94@users.noreply.github.com>`, unsigned
(`--no-gpg-sign`), no attribution trailer. Push to `main` of
`ldiaz94/robbie`. No pull requests unless asked.
