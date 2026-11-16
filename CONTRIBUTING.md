# Contributing to robbie

robbie is a small build tool and job runner, written in [raz](https://raz.lucela.org). It is small on
purpose: every feature must earn its lines. What helps most is finding
where it does other than its manual page and `README.md` say.

## What is welcome

- **Defect reports.** robbie doing other than its documentation says, a
  crash, a wrong result, a wrong message.
- **Defect fixes**, for such a defect.
- **Documentation.** A mistake or an unclear passage in the manual
  pages or the `README.md`.

New features are unlikely to be accepted.

## How

Everything goes through GitHub issues. Pull requests are not taken.

A report gives:

- the commit you built robbie from (`git log -1 --format=%h`), and
  `raz --version`;
- the smallest Robfile that shows the defect;
- what it does, and what you expected, with the place in the
  documentation that says so.

A fix is offered only after the defect is agreed in its issue. It:

- mends one thing, with a test in `test/`;
- passes `make test` and `make fmt`;
- builds with `-Werror` against the raz the Makefile's `RAZVERSION`
  names, and keeps raz's style (`STANDARDS.md` in raz): plain code a
  beginner can follow, a comment saying why;
- updates the manual page and the `README.md` when it changes what
  robbie does;
- carries a `Signed-off-by:` line (`git commit -s`), certifying the
  [Developer Certificate of Origin](https://developercertificate.org/).

Every patch is reviewed before it is applied, and may be rewritten.

## Tools, AI included

A tool, an AI model among them, may help write a report or a patch. You
are its author: you must have read and understood every line, and be
able to answer for it in review. Reports and patches made by a tool on
its own are closed.

## Licence

robbie is under the ISC licence (`LICENSE`), and so is every contribution.
