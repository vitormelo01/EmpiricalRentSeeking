********************************************************************************
*   Objective: Create Measures of Rent Seeking Activity in each Capital MSA    * 
********************************************************************************

/* %%%%%%%%%% Setup %%%%%%%%%% */
clear 
set more off

*Setting Env Variables
global directory: env EmpiricalRentSeeking_Data

*Setting Directory
cd "$directory"


/* %%%%%%%%%% Create balanced county panel %%%%%%%%%% */
*(we think observations are missing because there were no establishments within certain industries and counties)
forvalues i = 2005/2020 {
    import excel using "EmploymentandEstablishment_Data/balanced_panel_aux.xlsx", sheet("`i'") firstrow clear
	tempfile bal_pan_`i'
	save "`bal_pan_`i''"
}
import excel using "EmploymentandEstablishment_Data/balanced_panel_aux.xlsx", sheet("2004") firstrow clear
forvalues i = 2005/2020 {
    append using "`bal_pan_`i''"
}
save "EmploymentandEstablishment_Data/balanced_panel_aux.dta", replace
*Merge with Establishment data
use "EmploymentandEstablishment_Data/CountyRS_Total.dta", clear
rename area_fips fips
drop own_code agglvl_code size_code qtr annual_avg_emplvl-oty_avg_annual_pay_pct_chg
bysort fips industry_code year: egen tot_estabs_cty = sum(annual_avg_estabs)
egen cty_ind_year = group(fips industry_code year)
duplicates drop cty_ind_year, force
drop annual_avg_estabs cty_ind_year disclosure_code
drop if industry_code == 52519 | industry_code == 52592 | industry_code == 92115 /* not used in Hall and Ross */
merge m:m fips industry_code year using "EmploymentandEstablishment_Data/balanced_panel_aux.dta"
drop if _merge == 1
drop _merge
sort fips industry_code year
replace tot_estabs_cty = 0 if tot_estabs_cty == .
save "EmploymentandEstablishment_Data/CountyRS_Balanced.dta", replace


/* %%%%%%%%%% Create balanced MSA panel %%%%%%%%%% */
*Merge with MSA crosswalk
insheet using "CountyandMetroLevelData/County_to_MSA_Crosswalk.csv", clear
replace msa_code = substr(msa_code, 2, 4)
destring msa_code, replace
drop ctyname
merge 1:m fips using "EmploymentandEstablishment_Data/CountyRS_Balanced.dta"
drop if _merge != 3
drop _merge
drop fips
drop if msa_code == .
sort msa_code industry_code year
*Number of establishments at MSA level
bysort msa_code industry_code year: egen tot_estabs_msa = sum(tot_estabs_cty)
egen msa_ind_year = group(msa_code industry_code year)
duplicates drop msa_ind_year, force
drop tot_estabs_cty msa_ind_year
save "EmploymentandEstablishment_Data/MSA_RS_Tot_Estabs.dta", replace


/* %%%%%%%%%% Test to make sure calculation of synthetic outcomes are correct %%%%%%%%%% */
use "CountyandMetroLevelData/MSA_Predictors_2000.dta", clear
local capital_msas "3386"
foreach i of local capital_msas {
    local predictors "tot_pop per_capita_income"
	ebalance capital_msa `predictors' if capital_msa == 0 | msa_code == `i', targets(1) generate(synth_`i'_weights)
}
replace synth_3386_weights = . if msa_code == 3386
gen weighted_tot_pop = tot_pop*synth_3386_weights
bysort year: egen synth_3386_tot_pop = sum(weighted_tot_pop) /* Note: value matches the output of ebalance command */


/* %%%%%%%%%% Capital/Synthtic MSA Ratios by State, Year, and Industry Code (Hall and Ross codes) - # of Establishments %%%%%%%%%% */
use "EmploymentandEstablishment_Data/MSA_RS_Tot_Estabs.dta", clear
*Merge with predictor weight data
merge m:1 msa_code using "CountyandMetroLevelData/Synth_Weight_Data/Predictor_Weights.dta"
drop if _merge != 3
drop _merge
*Create synthetic capital MSAs by year and industry code
local capital_msas "3386 2794 3806 3078 4090 1974 2554 2010 4522 1206 4652 1426 4410 2690 1978 4582 2318 1294 1230 1258 1446 2962 3346 2714 2762 2574 3070 1618 1818 4594 4214 1058 3958 1390 1814 3642 4142 2542 3930 1790 3818 3498 1242 4162 1274 4006 3650 1662 3154 1694"
foreach i of local capital_msas {
	replace synth_`i'_weights = . if msa_code == `i'
	gen weighted_tot_estabs_`i' = tot_estabs_msa*synth_`i'_weights
	bysort industry_code year: egen synth_`i'_tot_estabs = sum(weighted_tot_estabs_`i')
}
*Create ratio of capital MSA/Synthetic capital MSA by industry and year
gen rs_ratio_tot_estabs = tot_estabs_msa/synth_3386_tot_estabs if msa_code == 3386
local capital_msas2 "2794 3806 3078 4090 1974 2554 2010 4522 1206 4652 1426 4410 2690 1978 4582 2318 1294 1230 1258 1446 2962 3346 2714 2762 2574 3070 1618 1818 4594 4214 1058 3958 1390 1814 3642 4142 2542 3930 1790 3818 3498 1242 4162 1274 4006 3650 1662 3154 1694"
foreach i of local capital_msas2 {
	replace rs_ratio_tot_estabs = tot_estabs_msa/synth_`i'_tot_estabs if msa_code == `i'
}
*Restrict data to only capital MSAs and relevant variables
sort msa_code industry_code year 
drop if capital_msa == 0
drop capital_msa-synth_1694_tot_estabs
gen synthetic_tot_estabs_msa = tot_estabs_msa/rs_ratio_tot_estabs /* this creates just one variable for the synthetic capital MSAs */
order synthetic_tot_estabs_msa, before(rs_ratio_tot_estabs)
save "rs_ratios_tot_estabs.dta", replace






*Capital MSA Indicator
gen byte capital_msa = 0
replace capital_msa = 1 if msa_code == 3386 | msa_code == 2794 | msa_code == 3806 | msa_code == 3078 | msa_code == 4090 ///
 | msa_code == 1974 | msa_code == 2554 | msa_code == 2010 | msa_code == 4522 | msa_code == 1206 | msa_code == 4652 ///
 | msa_code == 1426 | msa_code == 4410 | msa_code == 2690 | msa_code == 1978 | msa_code == 4582 | msa_code == 2318 ///
 | msa_code == 1294 | msa_code == 1230 | msa_code == 1258 | msa_code == 1446 | msa_code == 2962 | msa_code == 3346 ///
 | msa_code == 2714 | msa_code == 2762 | msa_code == 2574 | msa_code == 3070 | msa_code == 1618 | msa_code == 1818 ///
 | msa_code == 4594 | msa_code == 4214 | msa_code == 1058 | msa_code == 3958 | msa_code == 1390 | msa_code == 1814 ///
 | msa_code == 3642 | msa_code == 4142 | msa_code == 2542 | msa_code == 3930 | msa_code == 1790 | msa_code == 3818 ///
 | msa_code == 3498 | msa_code == 1242 | msa_code == 4162 | msa_code == 1274 | msa_code == 4006 | msa_code == 3650 ///
 | msa_code == 1662 | msa_code == 3154 | msa_code == 1694

 
 *Rent seeking industry indicators (according to Hall and Ross) - Traditional Direct, In-kind Direct, Indirect, and all
gen byte hr_trad_direct_rs = 0
replace hr_trad_direct_rs = 1 if industry_code == 23 | industry_code == 5411 | industry_code == 52392 ///
 | industry_code == 54132 | industry_code == 54133 | industry_code == 54169 | industry_code == 54182 ///
 | industry_code == 56111 | industry_code == 61171 | industry_code == 81311 | industry_code == 81341 ///
 | industry_code == 81391 | industry_code == 81392 | industry_code == 81393 | industry_code == 81394 ///
 | industry_code == 81399 | industry_code == 523991 | industry_code == 541611 | industry_code == 541612 ///
 | industry_code == 541613 | industry_code == 541614 | industry_code == 541618 | industry_code == 561599 ///
 | industry_code == 813211 | industry_code == 813312
gen byte hr_inkind_direct_rs = 0
replace hr_inkind_direct_rs = 1 if industry_code == 53222 | industry_code == 56131 | industry_code == 71111 ///
 | industry_code == 71391 | industry_code == 71394 | industry_code == 71399 | industry_code == 72211 ///
 | industry_code == 72231 | industry_code == 72232 | industry_code == 72241 | industry_code == 81293 ///
 | industry_code == 81299 | industry_code == 722211 | industry_code == 722212 | industry_code == 722213 ///
 | industry_code == 812191 | industry_code == 812199
gen byte hr_indirect_rs = 0
replace hr_indirect_rs = 1 if industry_code == 33995 | industry_code == 51111 | industry_code == 51112 ///
 | industry_code == 51113 | industry_code == 51114 | industry_code == 51223 | industry_code == 54171 ///
 | industry_code == 54172 | industry_code == 54181 | industry_code == 54183 | industry_code == 54184 ///
 | industry_code == 54185 | industry_code == 54186 | industry_code == 54187 | industry_code == 54189 ///
 | industry_code == 511199
gen byte hr_rs = (hr_trad_direct_rs == 1 | hr_inkind_direct_rs == 1 | hr_indirect_rs == 1)