********************************************************************************
*  Objective: Create Synthetic Capital Metro- and Micro-politan Area Weights   * 
********************************************************************************

/* %%%%%%%%%% Setup %%%%%%%%%% */
clear 
set more off

*Setting Env Variables
global directory: env EmpiricalRentSeeking_Data

*Setting Directory
cd "$directory"


/* %%%%%%%%%% Convert County Population Data to Metro/Micro Level %%%%%%%%%% */
/* %%% Total County Population and by Race and Sex %%% */
insheet using "CountyandMetroLevelData/County_Pop_Race_Gender_2000.csv", clear
drop if origin == 1 | origin == 2
drop origin
*Create fips variable
tostring county, format(%03.0f) replace
egen fips = concat(state county)
destring fips, replace
*Create population variables by race and gender
gen tot_pop_aux = popestimate2000 if sex == 0 & race == 0
bysort fips: egen tot_pop = mean(tot_pop_aux)
drop tot_pop_aux
gen tot_pop_male_aux = popestimate2000 if sex == 1 & race == 0
bysort fips: egen tot_pop_male = mean(tot_pop_male_aux)
drop tot_pop_male_aux
gen tot_pop_wh_aux = popestimate2000 if sex == 0 & race == 1
bysort fips: egen tot_pop_wh = mean(tot_pop_wh_aux)
drop tot_pop_wh_aux
gen tot_pop_bl_aux = popestimate2000 if sex == 0 & race == 2
bysort fips: egen tot_pop_bl = mean(tot_pop_bl_aux)
drop tot_pop_bl_aux
drop popestimate2000 sex race county
duplicates drop fips, force
tempfile county_pop_race_gender
save "`county_pop_race_gender'"
/* %%% Total County Population and by age %%% */
insheet using "CountyandMetroLevelData/County_Pop_Age_2000.csv", clear
drop if sex == 1 | sex == 2
drop sex
*Create fips variable
tostring county, format(%03.0f) replace
egen fips = concat(state county)
destring fips, replace
*Create population variables by age
bysort fips: egen tot_pop_age_25to44_aux = sum(popestimate2000) if agegrp >= 6 & agegrp <= 9
bysort fips: egen tot_pop_age_25to44 = mean(tot_pop_age_25to44_aux)
drop tot_pop_age_25to44_aux
bysort fips: egen tot_pop_age_45to64_aux = sum(popestimate2000) if agegrp >= 10 & agegrp <= 13
bysort fips: egen tot_pop_age_45to64 = mean(tot_pop_age_45to64_aux)
drop tot_pop_age_45to64_aux
bysort fips: egen tot_pop_age_over65_aux = sum(popestimate2000) if agegrp >= 14
bysort fips: egen tot_pop_age_over65 = mean(tot_pop_age_over65_aux)
drop tot_pop_age_over65_aux
drop popestimate2000 agegrp county
duplicates drop fips, force
tempfile county_pop_age
save "`county_pop_age'"
/* %%% County to MSA Crosswalk File %%% */
insheet using "CountyandMetroLevelData/County_to_MSA_Crosswalk.csv", clear
replace msa_code = substr(msa_code, 2, 4)
destring msa_code, replace
drop ctyname
merge 1:1 fips using `county_pop_race_gender', keepusing(tot_pop tot_pop_male tot_pop_wh)
drop if _merge != 3
drop _merge
merge 1:1 fips using `county_pop_age', keepusing(tot_pop_age_25to44 tot_pop_age_45to64 tot_pop_age_over65)
drop if _merge != 3
drop _merge
drop fips
drop if msa_code == .
/* %%% Create Population Variables at the MSA Level */
sort msa_code
rename tot_pop tot_pop_cty
rename tot_pop_male tot_pop_male_cty
rename tot_pop_wh tot_pop_wh_cty
rename tot_pop_age_25to44 tot_pop_age_25to44_cty
rename tot_pop_age_45to64 tot_pop_age_45to64_cty
rename tot_pop_age_over65 tot_pop_age_over65_cty
bysort msa_code: egen tot_pop = sum(tot_pop_cty)
bysort msa_code: egen tot_pop_male = sum(tot_pop_male_cty)
bysort msa_code: egen tot_pop_wh = sum(tot_pop_wh_cty)
bysort msa_code: egen tot_pop_age_25to44 = sum(tot_pop_age_25to44_cty)
bysort msa_code: egen tot_pop_age_45to64 = sum(tot_pop_age_45to64_cty)
bysort msa_code: egen tot_pop_age_over65 = sum(tot_pop_age_over65_cty)
duplicates drop msa_code, force
drop tot_pop_cty tot_pop_male_cty tot_pop_wh_cty tot_pop_age_25to44_cty tot_pop_age_45to64_cty tot_pop_age_over65_cty
gen prop_male = tot_pop_male/tot_pop
gen prop_wh = tot_pop_wh/tot_pop
gen prop_age_25to44 = tot_pop_age_25to44/tot_pop
gen prop_age_45to64 = tot_pop_age_45to64/tot_pop
gen prop_age_over65 = tot_pop_age_over65/tot_pop
drop tot_pop_male tot_pop_wh tot_pop_age_25to44 tot_pop_age_45to64 tot_pop_age_over65
save "CountyandMetroLevelData/MSA_Pop_Age_Race_Gender_2000.dta", replace



/* %%%%%%%%%% Convert County Per Capita Income Data to Metro/Micro Level %%%%%%%%%% */
*Clean data
use "CountyandMetroLevelData/income_pct_counties.dta", clear
drop if year != 2000
drop if PerCapitaIncome == "(NA)" /* None of these counties are in an MSA anyway */
drop year geoname
rename area_fips fips
destring PerCapitaIncome, generate(per_capita_income_cty)
drop PerCapitaIncome
tempfile county_per_capita_income
save "`county_per_capita_income'"
*Merge with MSA crosswalk
insheet using "CountyandMetroLevelData/County_to_MSA_Crosswalk.csv", clear
replace msa_code = substr(msa_code, 2, 4)
destring msa_code, replace
drop ctyname
merge 1:1 fips using `county_per_capita_income', keepusing(per_capita_income_cty)
drop if _merge != 3
drop _merge
drop fips
drop if msa_code == .
sort msa_code
bysort msa_code: egen per_capita_income = mean(per_capita_income_cty)
duplicates drop msa_code, force
drop per_capita_income_cty
save "CountyandMetroLevelData/MSA_Per_Capita_Income_2000.dta", replace



/* %%%%%%%%%% Convert County Unempoloyment and LFP Data to Metro/Micro Level %%%%%%%%%% */
insheet using "CountyandMetroLevelData/County_Unemployment_2000.csv", clear
drop stateabrev area_name
rename civilian_lf civilian_lf_cty
rename employed employed_cty
rename unemployed unemployed_cty
tempfile county_unemployment
save "`county_unemployment'"
*Merge with MSA crosswalk
insheet using "CountyandMetroLevelData/County_to_MSA_Crosswalk.csv", clear
replace msa_code = substr(msa_code, 2, 4)
destring msa_code, replace
drop ctyname
merge 1:1 fips using `county_unemployment', keepusing(civilian_lf_cty unemployed_cty)
drop if _merge != 3
drop _merge
drop fips
drop if msa_code == .
sort msa_code
*Create MSA unemployment rate variable
bysort msa_code: egen civilian_lf = sum(civilian_lf_cty)
bysort msa_code: egen unemployed = sum(unemployed_cty)
duplicates drop msa_code, force
drop civilian_lf_cty unemployed_cty
gen unem_rate = unemployed/civilian_lf
save "CountyandMetroLevelData/MSA_Unemployment_2000.dta", replace



/* %%%%%%%%%% Merge all MSA Data Sets and Identify Capital MSAs %%%%%%%%%% */
use "CountyandMetroLevelData/MSA_Pop_Age_Race_Gender_2000.dta", clear
merge 1:1 msa_code using "CountyandMetroLevelData/MSA_Per_Capita_Income_2000.dta", keepusing(per_capita_income)
drop if _merge != 3
drop _merge
merge 1:1 msa_code using "CountyandMetroLevelData/MSA_Unemployment_2000.dta", keepusing(unem_rate)
drop if _merge != 3
drop _merge
drop if msa_code == 4790
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
gen year = 2000
save "CountyandMetroLevelData/MSA_Predictors_2000.dta", replace



/* %%%%%%%%%% Create Synthetic Capital MSAs %%%%%%%%%% */
*Install ebalance package for entropy balancing
*ssc install ebalance
*Find synthetic weights for each capital MSA using entropy balancing (couldn't use loop because different msas need different tolerance levels)
use "CountyandMetroLevelData/MSA_Predictors_2000.dta", clear
local capital_msas "3386 2794 3806 3078 4090 1974 2554 2010 4522 1206 4652 1426 4410 2690 1978 4582 2318 1294 1230 1258 1446 2962 3346 2714 2762 2574 3070 1618 1818 4594 4214 1058 3958 1390 1814 3642 4142 2542 3930 1790 3818 3498 1242 4162 1274 4006 3650 1662 3154 1694"
foreach i of local capital_msas {
    local predictors "tot_pop per_capita_income"
	ebalance capital_msa `predictors' if capital_msa == 0 | msa_code == `i', targets(1) generate(synth_`i'_weights) keep("CountyandMetroLevelData/Synth_Weight_Data/`i'/bal_table_`i'.dta") replace
}
preserve
keep msa_code capital_msa msa_title synth*
save "CountyandMetroLevelData/Synth_Weight_Data/Predictor_Weights.dta", replace
restore











