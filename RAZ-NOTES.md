# What raz lacks, or makes awkward

Found while porting robbie from Free Pascal, for raz's owner. Each says
what was wanted, what robbie does instead, and how much it cost.

## The library

- **Sys can't say whether a signal is ignored.** A program started in
  the background by a script, or under nohup, finds SIGINT ignored, and
  robbie, like a shell, must leave it so rather than catch it. `Sys.handle`
  and `Sys.ignore` set an action but don't give the old one back. robbie
  asks the kernel itself, in `Rsig.linux.raz`, 20 lines and its one
  `SYSCALL`. `Sys.ignored(sig): BOOL`, or `handle` and `ignore` giving the
  action they replaced, would do.
- **A program spawn starts loses the signals its parent ignores.**
  `Sys.spawn` gives the child every signal as it is at first, SIG_IGN
  included, where `execve` keeps an ignored one ignored. So a recipe of a
  robbie run under nohup is not under nohup itself, as it was in Pascal.
  robbie lives with it. A `Program` field to keep the ignored signals, as
  a shell's children do, would mend it.
- **A noted signal can come just before the wait it should break.**
  robbie waits for its recipes with `Sys.wait`, and takes SIGTERM with
  `Sys.handle`, which makes the wait fail with -4. A signal that comes
  after robbie last asked `Sys.came` but before the wait starts is noted
  and breaks nothing, so robbie passes it on only when the next recipe
  ends. The window is a few instructions wide; the Pascal handler passed
  the signal on itself and had none. `Sys.catch` closes it for one fd,
  but has no way to be undone, which the interactive mode needs between
  runs. A wait for a child or a caught signal, whichever comes first,
  would close it.
- **No glob.** robbie's globs come from the C library's `glob(3)`, which
  makes robbie a program that uses C, for 30 lines of declarations and
  calls; the struct is padded past its two fields robbie reads, as its
  layout differs between C libraries. A `Files.glob`, sorted, with `*`
  alone a wildcard, would let robbie be a static program.

