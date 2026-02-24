---
name: stata_format
description: Stata code quality rules for readable, replicable applied research. Use when writing or editing do-files, generating Stata code, or reviewing Stata scripts. Produces code that follows conventions from DIME, Gentzkow & Shapiro, and Julian Reif.
metadata:
  audience: applied-economists
  domain: stata-programming
---

# Stata Code Quality Rules

Apply these rules whenever you write, edit, or review Stata code. These are not method recommendations — they are code quality standards that make Stata scripts readable, correct, and replicable regardless of the analysis being performed.

---

## 1. Do-File Structure

Every do-file follows this skeleton:

```stata
* ============================================================================
* [Title]: What this file does in plain language
*
* Input:  [data files read]
* Output: [data files, tables, or figures produced]
* ============================================================================

clear all
set more off
set varabbrev off

// === PATHS ===
* All paths derive from a single root set in the master do-file.
* Never hardcode absolute paths in analysis scripts.

// === LOAD DATA ===
use "${clean}/analysis_sample.dta", clear

// === SECTION 1: Description ===

[code]

// === SECTION 2: Description ===

[code]

// === EXPORT ===

[save/export commands]
```

Rules:
- `version` locks backward compatibility. Use the version the project was developed on.
- `set varabbrev off` prevents silent variable-matching bugs.
- `clear all` and `set more off` appear once, at the top, never mid-script.
- Section headers use `// === NAME ===` for easy navigation.
- The header block documents inputs and outputs so anyone can understand the file's role without reading the code.

---

## 2. Master Do-File

One file runs the entire project from raw data to final output.

```stata
* ============================================================================
* Master Do-File: [Project Title]
* Authors: [Names]
* Created: [Date]
* ============================================================================

version 17
clear all
set more off
set varabbrev off
macro drop _all
set seed 58429       // Set once. Use random.org, not round numbers.

// === ROOT PATH (only line to edit for replication) ===
if "`c(username)'" == "researcher1" {
    global root "/Users/researcher1/Dropbox/project"
}
else {
    global root "[EDIT THIS PATH]"
}

// === DERIVED PATHS ===
global code     "${root}/code"
global raw      "${root}/data/raw"
global clean    "${root}/data/clean"
global tables   "${root}/output/tables"
global figures  "${root}/output/figures"
global logs     "${root}/output/logs"

// === PACKAGES (comment out after first run) ===
/*
ssc install reghdfe, replace
ssc install ftools, replace
ssc install estout, replace
ssc install coefplot, replace
ssc install gtools, replace
*/

// === GRAPH SCHEME ===
set scheme plotplainblind, permanently

// === RUN (toggle 0/1 to skip sections) ===
local 01_clean    = 1
local 02_build    = 1
local 03_analysis = 1
local 04_tables   = 1
local 05_figures  = 1

if `01_clean'    do "${code}/01_clean.do"
if `02_build'    do "${code}/02_build.do"
if `03_analysis' do "${code}/03_analysis.do"
if `04_tables'   do "${code}/04_tables.do"
if `05_figures'  do "${code}/05_figures.do"
```

Rules:
- The `processed/` and `output/` folders should be fully regenerable by running the master do-file.
- Number scripts in execution order: `01_`, `02_`, etc.
- Toggle locals let you re-run individual steps without commenting code.

---

## 3. Paths

```stata
// CORRECT: Forward slashes, quoted, with file extensions
use "${raw}/survey_2024.dta", clear
esttab using "${tables}/table_1.tex", replace

// WRONG: Backslashes, unquoted, missing extensions
use $raw\survey_2024, clear
```

Rules:
- **Always forward slashes**, even on Windows. Backslashes trigger macro-escape behavior (`\n`, `\t` are interpreted).
- **Always quote paths** in double quotes.
- **Always include file extensions** (`.dta`, `.csv`, `.tex`).
- **One root global** in the master file; everything else derives from it.
- **Never hardcode absolute paths** in analysis scripts. If the path doesn't start with `${`, it's probably wrong.

---

## 4. Variable Handling

### Types

```stata
// IDs: Always long or double. Float silently corrupts integers > 16,777,216.
gen long county_fips = .
gen double large_id = .

// When importing CSV with ID columns:
import delimited using "data.csv", asdouble clear
```

### Missing values

Stata treats missing (`.`) as **larger than any number**. This is the single most common source of silent bugs.

```stata
// WRONG: Includes observations where age is missing!
gen elderly = (age > 65)

// CORRECT:
gen elderly = (age > 65) if !missing(age)

// CORRECT alternative:
gen elderly = (age > 65 & !missing(age))
```

Rules:
- Always use `missing(var)` or `!missing(var)` — never `var >= .` or `var == .`
- Every `gen` with an inequality must handle missings explicitly.
- Use `nmissing` or `misstable summarize` to audit missing patterns before analysis.

### Naming

```stata
// Variables: lowercase snake_case
gen ln_wage = log(wage)
gen treat_post = treated * post

// Descriptive loop indices
foreach crop in maize rice wheat {
    ...
}
// Not: foreach i in maize rice wheat
```

### Labels

```stata
// Label every variable you create
label variable ln_wage "Log hourly wage (2020 USD)"
label variable treat_post "Treatment x Post interaction"

// Define and apply value labels for categoricals
label define yesno 0 "No" 1 "Yes"
label values treated yesno
```

---

## 5. Defensive Programming

Verify data properties at every critical step. Assertions that fail loudly are better than bugs that fail silently.

```stata
// Verify unique identifiers before merge
isid firm_id year

// Check merge results — never silently drop
merge m:1 state year using "${clean}/state_controls.dta"
tab _merge
assert _merge != 2    // No orphan records from using data
drop _merge

// Verify observation count hasn't changed unexpectedly
local n_before = _N
[some operation]
assert _N == `n_before'

// Confirm reasonable values
assert inrange(age, 0, 120) if !missing(age)

// Verify panel balance when expected
bysort firm_id: assert _N == 20
```

Rules:
- `isid` before every merge and every sort that matters.
- `tab _merge` after every merge. Handle each `_merge` value explicitly.
- **Never use `merge m:m`**. It does not produce a cross-join — it matches sequentially within groups and produces nonsense. Use `joinby` for true cross-joins.
- `assert` liberally. An assertion that breaks during development saves hours of debugging a wrong result.

---

## 6. Sort Stability

Stata's `sort` randomizes ties differently every run, even with `set seed`.

```stata
// DANGEROUS: Results depend on sort order, which is random
sort firm_id
gen order = _n

// SAFE: Ensure uniqueness or use stable option
isid firm_id year
sort firm_id year

// Or force stability
sort firm_id, stable
```

Rules:
- Never assume sort order is reproducible unless the sort key is unique.
- Use `isid` before any sort where order matters for subsequent operations.
- `set sortseed` (Stata 16+) controls tie-breaking if you cannot ensure uniqueness.
- Stata/MP and Stata/SE may sort ties differently even with the same seed.

---

## 7. Panel Data

```stata
// Declare panel structure once
xtset firm_id year

// CORRECT: Use time-series operators for lags/leads
gen lag_sales = L.sales
gen lead_sales = F.sales
gen growth = D.sales

// WRONG: Row indexing breaks for unbalanced panels
bysort firm_id (year): gen lag_sales = sales[_n-1]  // Skips gaps silently
```

Rules:
- `xtset` before any panel operations.
- **Always use `L.`, `F.`, `D.` operators** — never `[_n-1]` or `[_n+1]` — because row indexing ignores gaps in unbalanced panels.
- Use `xtdescribe` to check panel balance. Use `tsfill` to make gaps explicit.

---

## 8. Estimation Preferences

These are not method recommendations — use whatever estimator your research design calls for. These are implementation preferences for common tasks.

```stata
// Fixed effects: reghdfe over areg or xtreg, fe
// reghdfe handles multi-way FE, drops singletons, and reports correct DoF
reghdfe y x1 x2, absorb(firm_id year) cluster(firm_id)

// IV with fixed effects: ivreghdfe
ivreghdfe y (x_endog = z), absorb(firm_id year) cluster(firm_id)

// Fast data operations: gtools for large datasets
gcollapse (mean) wage (sd) sd_wage = wage, by(industry year)
gegen rank = rank(score), by(group)
gisid firm_id year
```

Rules:
- **`reghdfe`** over `areg` (which doesn't handle multi-way FE or singletons) and `xtreg, fe` (which doesn't cluster correctly by default with multiple FE dimensions).
- **`gtools`** commands (`gcollapse`, `gegen`, `gisid`, `greshape`, `gduplicates`) are 4-100x faster than base equivalents. Use them for datasets over ~100k observations.
- **Store estimates for tables**: `eststo` or `estimates store` after every regression you plan to report.

---

## 9. Commenting

```stata
// WHY comments explain reasoning. WHAT comments restate code.

// GOOD: Explains a non-obvious choice
// Cluster at state level because treatment is assigned at state level
reghdfe y treat, absorb(firm_id year) cluster(state)

// BAD: Restates the command
// Run regression of y on treat
reghdfe y treat, absorb(firm_id year) cluster(state)
```

Rules:
- Use `//` for single-line comments (preferred over `*` at line start because `//` works mid-line and in all contexts).
- Use `/* */` for multi-line blocks.
- Comments explain **why**, not **what**. Self-documenting code (clear variable names, labeled variables) reduces the need for what-comments.
- Don't comment out dead code — delete it. Version control preserves history.

---

## 10. Line Continuation and Formatting

```stata
// Use /// for long commands. Indent continuation lines.
reghdfe ln_wage education experience experience_sq ///
    female i.race i.industry, ///
    absorb(state year) cluster(state)

// Align related commands vertically
gen      employed  = (status == 1) if !missing(status)
replace  employed  = 0 if status == 2
lab var  employed  "Currently employed"

// esttab: one option per line for readability
esttab m1 m2 m3 using "${tables}/main.tex", replace ///
    b(3) se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    label booktabs ///
    title("Main Results") ///
    keep(treat x1 x2) ///
    order(treat x1 x2) ///
    stats(N r2_a, labels("Observations" "Adj. R-squared"))
```

Rules:
- **`///` for continuation**, not `#delimit ;`. Delimiter changes make code harder to read and are a common source of errors.
- Target ~80 characters per line.
- Indent continuation lines by 4 spaces.
- One `esttab`/`coefplot` option per line when there are more than 3 options.

---

## 11. Weights

Stata weight behavior is inconsistent and poorly documented. Know which weight type you need.

| Weight | Meaning | Sums to |
|--------|---------|---------|
| `fweight` | Frequency weight (integer replication) | Sum of weights = effective N |
| `aweight` | Analytic weight (inverse variance) | Normalized internally |
| `pweight` | Probability/sampling weight | Used with `svy:` commands |
| `iweight` | Importance weight (unnormalized) | Raw weighted sum |

Key traps:
- **`collapse (sum) [aw]`** returns a weighted average adjusted by sample size, not a weighted sum. Use `[fw]` or `[iw]` for true weighted sums.
- Observations with zero or missing weights are **silently dropped** from all computations.
- For survey data, always use `svyset` + `svy:` prefix, not manual `pweight`. Manual weighting gives wrong standard errors.

---

## 12. Reproducibility Checklist

When finishing a do-file or project, verify:

- [ ] `version` is set at the top of the master file
- [ ] `set seed` appears once, with a non-round number
- [ ] All paths are relative to a single `${root}` global
- [ ] `set varabbrev off` is set
- [ ] Raw data is never modified — only read
- [ ] Every merge has `tab _merge` and explicit handling
- [ ] Every generated variable with an inequality handles missings
- [ ] IDs are stored as `long` or `double`, not `float`
- [ ] Log files are generated (`log using`)
- [ ] Master do-file runs the entire project end-to-end without errors
