## Note
## This file is used for rename the generate templates of stochastic running
## Rule can be found at: https://montagu.vaccineimpact.org/contribution/help/model-outputs/201710gavi-6
## Ex: stochastic_burden_est_YF-IC-Garske_yf-routine-gavi_1.csv
## Original: stochastic-burden-template.201710gavi-6.JE_OUCRU-Clapham_standard
## Output should be: stochastic_burden_template_JE-OUCRU-Clapham_je-routine-gavi_1 (look at Quan)
## scenarios: je-routine-gavi, je-routine-no-vaccination, je-campaign-gavi

scenario <- 'je-routine-no-vaccination_'
DataPath <- 'Directory/to/Stochatic/Filled/Template/Scenario'
list_files <- list.files(DataPath)

file.rename(paste0(DataPath, list_files), 
            paste0(DataPath, 
                   'stochastic-burden-template.201710gavi-6.JE_OUCRU-Clapham_standard_', scenario, 1:length(list_files), 
                   '.csv'))
