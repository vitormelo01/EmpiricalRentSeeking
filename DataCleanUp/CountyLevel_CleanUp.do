cd "C:\Users\vitor\OneDrive\Research_Resources\EmpiricalRentSeeking_Resources\Data\EmploymentandEstablishment_Data"

insheet using "2020.annual.singlefile.csv"

/*
forvalues i = 2004/2020 {
    
	clear
	insheet using "`i'.annual.singlefile.csv"
	save `i'.annual.singlefile.dta
	
	
}

*/


forvalues i = 2004/2020 {
    
clear	
use `i'.annual.singlefile.dta
drop if substr(area_fips,1,1) =="C"
drop if substr(area_fips,1,1) =="U"
destring area_fips, replace


replace industry_code = subinstr(industry_code, "-", "",.)
destring industry_code, replace

keep if /* Traditional, Direct Rent Seeking Industries*/ industry_code == 813211 | industry_code ==  52392 | industry_code == 523991 | industry_code == 52519 | industry_code == 52592 | industry_code == 5411 | industry_code == 81391 | industry_code == 81392 | industry_code == 81393 | industry_code == 81341 | industry_code == 81399 | industry_code == 92115 | industry_code == 81394 | industry_code == 81311 | industry_code == 81341 | industry_code == 81391 | industry_code == 813312 | industry_code == 561599 | industry_code == 81399 | industry_code == 56111 | industry_code == 23 | industry_code == 541611 | industry_code == 541612 | industry_code == 541613 | industry_code == 541614 | industry_code == 54182 | industry_code == 61171 | industry_code == 54169 | industry_code == 54132 | industry_code == 54133 | industry_code == 541618 |/*In-Kind, Direct Rent Seeking Industries*/ industry_code == 56131 | industry_code == 812191 | industry_code == 81293 | industry_code == 53222 | industry_code == 812199 | industry_code == 81299 | industry_code == 72211 | industry_code == 722211 | industry_code == 722212 | industry_code == 722213 | industry_code == 72231 | industry_code == 72232 | industry_code == 71111 | industry_code == 72241 | industry_code == 71391 | industry_code == 71391 | industry_code == 71394 | industry_code == 71399 |/*Indirect Rent Seeking Industries*/ industry_code == 51111 | industry_code == 51112 | industry_code == 51114 | industry_code == 51112 | industry_code == 51113 | industry_code == 511199 | industry_code == 33995 | industry_code == 513111 | industry_code == 513112 | industry_code == 51312 | industry_code == 54181 | industry_code == 54185 | industry_code == 54184 | industry_code == 54183 | industry_code == 54185 | industry_code == 54187 | industry_code == 54189 | industry_code == 51114 | industry_code == 54186 | industry_code == 54171 | industry_code == 54172
	
	save county_rentseeking`i'.dta, replace
}

* Appending all files
clear
use county_rentseeking2004.dta
forvalues i = 2005/2020 {
	append using county_rentseeking`i'.dta
}


*Saving clean data for years 2004-2017
save CountyRS_Total.dta, replace

clear
use CountyRS_Total.dta
