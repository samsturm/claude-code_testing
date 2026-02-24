# stata_format — A Claude Code Skill for Better Stata Code

## What is this?

This is a **skill** for Claude Code. When installed, it teaches Claude how to write Stata code the way experienced researchers write it — readable, replicable, and free of the silent bugs that waste hours of debugging time.

You don't need to memorize any rules or change how you work. You just ask Claude to write Stata code the way you normally would, and the code it produces will be better.

## What's a "skill"?

A skill is a small instruction file that gives Claude specialized knowledge about a specific task. Think of it like handing a new research assistant a style guide on their first day — they already know Stata, but now they know *your* standards.

Without the skill, Claude writes Stata code that works but cuts corners:
- Missing values silently included in comparisons
- Hardcoded file paths that break on anyone else's computer
- No data validation checks
- Older commands (`areg`) instead of modern ones (`reghdfe`)
- Tables crammed into one unreadable line

With the skill, Claude follows conventions from DIME/World Bank, Gentzkow & Shapiro, and Julian Reif automatically.

## What does it actually change?

Here's one example. Say you ask Claude to create a treatment indicator:

**Without the skill:**
```stata
gen post = (year >= first_treat)
```
This silently codes observations with missing `first_treat` as `post = 1`, because Stata treats missing as infinity. You won't get an error. You'll just get wrong results.

**With the skill:**
```stata
gen byte post = (year >= first_treat) if !missing(first_treat)
replace post = 0 if missing(first_treat)
label variable post "Post-treatment period"
```

That's the kind of difference that shows up everywhere — merges, panel lags, variable creation, table formatting, path management.

## How to install

### Option 1: Ask Claude to do it (easiest)

Open Claude Code and say:

> "I want to install a Stata skill. Here's the file — please save it to my Claude skills folder."

Then paste the contents of `SKILL.md` from this folder. Claude will save it to the right place (`~/.claude/skills/stata_format/SKILL.md`).

### Option 2: Ask Claude to clone this repo

Open Claude Code and say:

> "Clone the repo https://github.com/samsturm/claude-code_testing.git and copy the Stata skill from .claude/skills/stata_format/ into my global Claude skills folder at ~/.claude/skills/stata_format/"

Claude will handle the git setup, cloning, and file copying for you.

### Option 3: Manual installation

If you prefer to do it yourself:

1. On your computer, navigate to your home folder
2. Find (or create) the folder `.claude/skills/`
3. Create a subfolder called `stata_format`
4. Copy `SKILL.md` into that folder

The final path should be: `~/.claude/skills/stata_format/SKILL.md`

Note: Folders starting with `.` are hidden by default. On Mac, press `Cmd + Shift + .` in Finder to show hidden files.

## How to use

There's nothing to memorize. Once installed, the skill activates automatically whenever you ask Claude to write or edit Stata code. Just work normally:

- "Write me a do-file that cleans and merges these datasets"
- "Run a DiD analysis on this panel data"
- "Create a regression table with these three specifications"
- "Debug this do-file — it's giving me weird results"

The skill teaches Claude the rules. You just ask for what you need.

## What's covered

The skill has 12 sections:

1. **Do-file structure** — headers, setup blocks, section organization
2. **Master do-files** — single-root paths, toggled execution
3. **Path management** — portable, quoted, forward-slash paths
4. **Variable handling** — missing values, ID types, naming, labels
5. **Defensive programming** — assertions, merge checks, data validation
6. **Sort stability** — reproducible ordering
7. **Panel data** — proper lag/lead operators
8. **Estimation preferences** — modern packages (reghdfe, gtools)
9. **Commenting** — why-comments over what-comments
10. **Line formatting** — readable continuation and alignment
11. **Weights** — avoiding silent traps
12. **Reproducibility checklist** — verify before shipping

## FAQ

**Does this change what methods Claude recommends?**
No. The skill is about code *form*, not statistical *methods*. It won't tell you to use DiD instead of IV. It will make sure whichever method you choose is implemented with correct missing-value handling, proper standard errors, and readable formatting.

**Do I need to know how to use the terminal?**
No. Claude Code through the desktop app handles everything. If something needs to be installed (like git or a package), just ask Claude and it will walk you through it.

**Can I modify the rules?**
Yes. The skill is just a text file. Open `SKILL.md` in any text editor and change whatever you want. For example, if your team prefers `*` comments over `//`, just update that section.

**Does this work with Stata 15/16/17?**
Yes. The skill mentions `version 17` as an example, but the rules apply to any modern Stata version. Just change the version number to match your installation.
