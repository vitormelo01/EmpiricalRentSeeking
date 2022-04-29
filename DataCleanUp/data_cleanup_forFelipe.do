clear
cd "C:\Users\vitor\OneDrive\Combined_CON_Research\Data"
use pos2020.dta

keep if prvdr_ctgry_cd == 1
keep if ssa_state_cd == 1

keep city_name prvdr_num st_adr state_cd ssa_state_cd fips_cnty_cd cbsa_urbn_rrl_ind cbsa_cd

save Hospitals_Alabama_2020, replace