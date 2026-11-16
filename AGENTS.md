# Working on robbie

robbie is a small build tool and job runner, written in
[raz](https://raz.lucela.org). It reads a `Robfile`, shows in colour what
can be done in a repository, and makes what is out of date. Read
`CONTRIBUTING.md` first: defects and documentation fixes are offered as
GitHub issues, not pull requests; a fix comes only after the defect is
agreed, you sign off (DCO), and a tool such as an AI model only helps
you, you answer for every line.

## What defines behaviour

The manual pages, `doc/robbie.1` and `doc/robfile.5`, and `README.md`. A
defect is robbie doing other than they say.

## Build and check

    make            # build/robbie, with -Werror
    make test       # test/*.sh against test/*.out, the pages through groff, then robbie's own test task
    make fmt        # src/ is laid out as raz's formatter lays it out

The program builds with the raz named by `RAZVERSION` in the `Makefile`
(0.25.0); `make` warns of any other. `make test` and `make fmt` must
pass. The formatter is `Pretty.raz` from that raz's `tools/`.

The tests run `build/robbie` through a pipe, so they see plain text.
Colour and the interactive mode are not covered: check them by hand on a
terminal and say so in the issue.

## Layout

- `src/`: one module per job, each named with an R: `Rbase`, `Rsig`,
  `Rexpand`, `Rread`, `Rgraph`, `Rterm`, `Rjob`, `Rshow`, `Rwatch`, and
  `Robbie`, the main module.
- `test/`: each `X.sh` prints what it saw and must match `X.out`. A fix
  adds a test here.
- `examples/`: robfiles. Each appears word for word in the manual pages;
  change one, change every copy (`test/self.sh` checks).
- `doc/`: the manual pages, in mdoc(7).

## Conventions

- The project is raz end to end, except the `Makefile`, the manual
  pages, the Markdown documents, robfiles (recipes are shell by nature)
  and the tests in sh. The C library is used for `glob(3)` alone.
- Comment generously; the code is meant to be read top to bottom. Every
  module opens with a block comment (what it does, why it is shaped so,
  what it depends on); every type, field, constant and module variable
  has a comment; every procedure has a header comment (what it does,
  returns and changes); say *why* where the code is not obvious, and
  never repeat the line below. A comment must not hold `*)`.
- Text lives as long as robbie does and is never freed: `Rbase.keep` and
  `Rbase.join` make new strings, and a slice of a robfile's bytes is
  used as it is.
- Follow raz's `STANDARDS.md`.
- A feature or fix is not finished until `doc/robbie.1` or
  `doc/robfile.5` and `README.md` describe it, in the same patch.
