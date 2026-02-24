**Subject: Try this — makes Claude write much better Stata code**

Hi everyone,

I've been experimenting with Claude Code and built something I think you'll find useful. It's a small file called a "skill" that teaches Claude how to write Stata code the way we actually want it — with proper missing-value handling, portable paths, data validation, readable formatting, and modern packages like `reghdfe`.

**What it does:** When you ask Claude to write Stata code, it normally produces code that runs but cuts corners. This skill fixes that. It follows coding standards from DIME/World Bank, Gentzkow & Shapiro, and Julian Reif — the same conventions you see in top journal replication packages.

**One quick example of the difference:**

Without the skill, Claude writes:
```stata
gen post = (year >= first_treat)
```

That looks fine, but it silently codes every observation with a missing `first_treat` as treated, because Stata treats missing values as infinity. No error, just wrong results.

With the skill:
```stata
gen byte post = (year >= first_treat) if !missing(first_treat)
replace post = 0 if missing(first_treat)
label variable post "Post-treatment period"
```

That kind of improvement happens across the board — merges get validation checks, paths become portable across machines, tables become readable, and the code follows a consistent structure.

**How to set it up:**

1. If you don't have Claude Code yet, download the Claude desktop app from [claude.ai/download](https://claude.ai/download). Claude Code is built into it — you don't need to install anything else separately.

2. Open Claude Code and paste this message:

   > "I want to install a Stata skill for Claude Code. Please create the folder ~/.claude/skills/stata_format/ and save the following as SKILL.md in that folder."

   Then paste the contents of the SKILL.md file (attached / linked below).

   If Claude needs to install git or any other tools along the way, just say yes — it will walk you through it.

3. That's it. From now on, whenever you ask Claude to write Stata code, it will follow these conventions automatically. You don't need to reference the skill or do anything special — just ask for what you need normally.

**You don't need to know anything about terminals, git, or programming tools.** Claude handles all of that. If it asks you to approve something (like installing a tool), just read what it says and approve if it makes sense.

The skill file and a README with more details are in my repo here:
https://github.com/samsturm/claude-code_testing

Look in `.claude/skills/stata_format/` — there's a README.md that explains everything, and the SKILL.md file itself.

If you want to see the before/after difference in action, ask Claude to "write me a do-file for a basic DiD analysis" with and without the skill installed. The difference is obvious.

Happy to help anyone get set up — just let me know.

Best,
Sam
