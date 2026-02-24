* DiD Analysis

clear all
set more off

* Load data
use "/Users/researcher/Dropbox/project/data/panel_data.dta", clear

xtset firm_id year

* Create variables
gen post = (year >= first_treat)
gen treat_post = treated * post
gen event_time = year - first_treat
gen ln_outcome = log(outcome)

* Summary stats
tab treated, sum(outcome)

* Model 1: no FE
reg outcome treat_post treated post, cluster(firm_id)
est store m1

* Model 2: TWFE
areg outcome treat_post i.year, absorb(firm_id) cluster(firm_id)
est store m2

* Model 3: with controls
areg outcome treat_post x1 x2 i.year, absorb(firm_id) cluster(firm_id)
est store m3

* Model 4: log outcome
areg ln_outcome treat_post x1 x2 i.year, absorb(firm_id) cluster(firm_id)
est store m4

* Event study
forvalues t = -5/5 {
    gen d`t' = (event_time == `t')
}
drop d_1

areg outcome d_5 d_4 d_3 d_2 d0 d1 d2 d3 d4 d5 i.year, absorb(firm_id) cluster(firm_id)

coefplot, keep(d*) vertical yline(0) title("Event Study")
graph export "event_study.pdf", replace

* Table
esttab m1 m2 m3 m4 using "did_results.tex", replace se star(* 0.10 ** 0.05 *** 0.01) booktabs title("DiD Results")
