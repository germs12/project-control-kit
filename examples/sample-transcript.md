# Sample transcript — roadmap call (fictional)

Test fixture for the distillation step. It deliberately contains one settled
decision, one suggestion that was never agreed to, one ambiguous maybe-decision,
one owned action item, one hard constraint, and one open question. A correct
run commits only what `expected-output.md` says it should.

---

[00:00] Jordan: OK, main thing today is storage. I know we prototyped on
SQLite but with the multi-user sync stuff it's creaking.

[01:12] Sam: Yeah. I looked at Postgres and Turso this week. Postgres is
boring and fine and we both know it. Turso's edge story is cool but it's
another vendor.

[02:05] Jordan: Let's just do Postgres. Boring is a feature.

[02:10] Sam: Agreed. Postgres it is. I'll take migrating the schema — should
have a script by Friday.

[03:40] Sam: While I'm in there, I think we should also add dark mode. People
keep asking.

[03:55] Jordan: Mmm, let's not open that can today.

[05:20] Jordan: One thing we do have to respect — the beta list goes out
October 1st, so whatever we do lands before that. Hard date, I already
announced it.

[06:30] Sam: What are we doing about pricing tiers? Free plus one paid, or
three tiers like everyone else?

[06:45] Jordan: Honestly I keep flip-flopping. Maybe two? I don't know. Let's
think on it.

[07:30] Sam: Fine, parking it. Oh — and maybe we rename the CLI from "dds" to
something pronounceable? Kidding. Sort of.
