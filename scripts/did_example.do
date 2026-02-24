* ============================================================================
* Basic Difference-in-Differences Analysis
*
* Input:  ${clean}/panel_data.dta
* Output: ${tables}/did_results.tex
*         ${figures}/event_study.pdf
* ============================================================================

clear all
set more off
set varabbrev off

// === PATHS ===
* Assumes master do-file has already set ${root} and derived globals.
* To run standalone, uncomment and edit:
* global root   "/path/to/project"
* global clean  "${root}/data/clean"
* global tables "${root}/output/tables"
* global figures "${root}/output/figures"

// === LOAD DATA ===
use "${clean}/panel_data.dta", clear

// === VERIFY DATA STRUCTURE ===
isid firm_id year
xtset firm_id year
xtdescribe

// Audit missingness in key variables
misstable summarize outcome treated first_treat

// Confirm treatment is time-invariant within units
bysort firm_id: egen _treat_check = sd(treated)
assert _treat_check == 0 | missing(_treat_check)
drop _treat_check

// === CONSTRUCT VARIABLES ===

// Post-treatment indicator: 1 after a unit's first treatment year
gen byte post = (year >= first_treat) if !missing(first_treat)
replace post = 0 if missing(first_treat)
label variable post "Post-treatment period"

// DiD interaction
gen byte treat_post = treated * post
label variable treat_post "Treated x Post (DiD estimator)"

// Event time relative to treatment onset
gen event_time = year - first_treat if !missing(first_treat)
label variable event_time "Years relative to treatment"

// Log outcome for robustness
gen ln_outcome = log(outcome) if outcome > 0 & !missing(outcome)
label variable ln_outcome "Log outcome (dropping zeros)"

// === DESCRIPTIVE STATISTICS ===

// Pre-treatment means by group to eyeball parallel trends
tabstat outcome, by(treated) stat(mean sd n) nototal

// === MAIN ANALYSIS ===

eststo clear

// (1) Naive DiD: treated x post, no fixed effects
eststo m1: reg outcome treat_post treated post, ///
    vce(cluster firm_id)

// (2) TWFE DiD: unit and time FE absorb treated and post
eststo m2: reghdfe outcome treat_post, ///
    absorb(firm_id year) cluster(firm_id)

// (3) Add time-varying controls
eststo m3: reghdfe outcome treat_post x1 x2, ///
    absorb(firm_id year) cluster(firm_id)

// (4) Log outcome for proportional interpretation
eststo m4: reghdfe ln_outcome treat_post x1 x2, ///
    absorb(firm_id year) cluster(firm_id)

// === EVENT STUDY ===

// Bin endpoints and omit t = -1 as reference period
summ event_time
local lo = max(r(min), -5)
local hi = min(r(max), 5)

gen event_time_binned = event_time
replace event_time_binned = `lo' if event_time < `lo' & !missing(event_time)
replace event_time_binned = `hi' if event_time > `hi' & !missing(event_time)

// Estimate with -1 as omitted category
reghdfe outcome ib(-1).event_time_binned, ///
    absorb(firm_id year) cluster(firm_id)

// Visual test of parallel pre-trends
coefplot, keep(*.event_time_binned) vertical ///
    yline(0, lpattern(dash) lcolor(gs8)) ///
    xline(-0.5, lpattern(dash) lcolor(cranberry)) ///
    xtitle("Years relative to treatment") ///
    ytitle("Effect on outcome") ///
    title("Event Study: Parallel Trends and Dynamic Effects") ///
    ciopts(recast(rcap) lcolor(navy)) ///
    mcolor(navy) ///
    note("Reference period: t = -1. Endpoints binned at {`lo', `hi'}.")

graph export "${figures}/event_study.pdf", replace

// === EXPORT RESULTS TABLE ===

esttab m1 m2 m3 m4 using "${tables}/did_results.tex", replace ///
    b(3) se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    label booktabs ///
    title("Difference-in-Differences Estimates") ///
    mtitles("No FE" "TWFE" "Controls" "Log outcome") ///
    keep(treat_post x1 x2) ///
    order(treat_post x1 x2) ///
    stats(N r2_a, ///
        labels("Observations" "Adj. R-squared") ///
        fmt(0 3)) ///
    addnotes("Standard errors clustered at the firm level." ///
             "Columns 1-3: level outcome. Column 4: log outcome.")

// === ALSO EXPORT CSV FOR QUICK INSPECTION ===

esttab m1 m2 m3 m4 using "${tables}/did_results.csv", replace ///
    b(3) se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) label
