*-------------------------------------------------------------------------------
* Empirical Rent-Seeking
* ------------------------------------------------------------------------------
clear

* Setting Env Variables
global directory: env EmpiricalRentSeeking_Data

* Setting Directory
cd "$directory"

*-------------------------------------------------------------------------------
* Converting excel to dta

forvalues i = 2003/2019 {
	
	insheet using "`i'.annual.singlefile.csv"

* Destringing industry variable
replace industry_code = subinstr(industry_code, "-", "",.)
destring industry_code, replace

* Keeping only MSA and MicroSA areas
keep if substr(area_fips,1,1) =="C"
drop if substr(area_fips,1,2) =="CS"
replace area_fips = subinstr(area_fips, "C", "", 1) 
destring area_fips, replace

* Keeping industry sectors chosen apriori by Sobel and Garret 

keep if /* Traditional, Direct Rent Seeking Industries*/ industry_code == 813211 | industry_code ==  52392 | industry_code == 523991 | industry_code == 52519 | industry_code == 52592 | industry_code == 5411 | industry_code == 81391 | industry_code == 81392 | industry_code == 81393 | industry_code == 81341 | industry_code == 81399 | industry_code == 92115 | industry_code == 81394 | industry_code == 81311 | industry_code == 81341 | industry_code == 81391 | industry_code == 813312 | industry_code == 561599 | industry_code == 81399 | industry_code == 56111 | industry_code == 23 | industry_code == 541611 | industry_code == 541612 | industry_code == 541613 | industry_code == 541614 | industry_code == 54182 | industry_code == 61171 | industry_code == 54169 | industry_code == 54132 | industry_code == 54133 | industry_code == 541618 |/*In-Kind, Direct Rent Seeking Industries*/ industry_code == 56131 | industry_code == 812191 | industry_code == 81293 | industry_code == 53222 | industry_code == 812199 | industry_code == 81299 | industry_code == 72211 | industry_code == 722211 | industry_code == 722212 | industry_code == 722213 | industry_code == 72231 | industry_code == 72232 | industry_code == 71111 | industry_code == 72241 | industry_code == 71391 | industry_code == 71391 | industry_code == 71394 | industry_code == 71399 |/*Indirect Rent Seeking Industries*/ industry_code == 51111 | industry_code == 51112 | industry_code == 51114 | industry_code == 51112 | industry_code == 51113 | industry_code == 511199 | industry_code == 33995 | industry_code == 513111 | industry_code == 513112 | industry_code == 51312 | industry_code == 54181 | industry_code == 54185 | industry_code == 54184 | industry_code == 54183 | industry_code == 54185 | industry_code == 54187 | industry_code == 54189 | industry_code == 51114 | industry_code == 54186 | industry_code == 54171 | industry_code == 54172

save empiricalrentseeking_cleaned`i'.dta, replace
}

clear
use EmpiricalRS_Cleaned2003.dta
forvalues i = 2004/2019 {
	append using EmpiricalRS_Cleaned`i'.dta
}

save using EmpiricalRS_CleanedTotal