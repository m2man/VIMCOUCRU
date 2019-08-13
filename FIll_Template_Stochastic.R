# --- NOTE ---
# This file is used to fill in the form of central burden
# input is the result after running Create_Burden
# ---------- #

cat('===== START [Fill_Template_Stochastic.R] =====\n')

## Get directory of the script (this part only work if source the code, wont work if run directly in the console)
## This can be set manually !!! -->setwd('bla bla bla')
script.dir <- dirname(sys.frame(1)$ofile)
script.dir <- paste0(script.dir, '/')
setwd(script.dir)

## Create folder to store the result (will show warnings if the folder already exists --> but just warning, no problem)
dir.create(file.path('Generate/Template_Stochastic/'), showWarnings = TRUE)
Savepath <- 'Generate/Template_Stochastic/'

## ===== Load file =====
start_year_column <- 4 # index of column (year) in NaivePop dataframe (start from column 4: X1950, X1951, ...) 

naive.list <- readRDS('Generate/Burden_Stochastic/Naive_Burden_Stochastic.Rds') # Burden in Naive scenario
routine.list <- readRDS('Generate/Burden_Stochastic/Routine_Burden_Stochastic.Rds') # Burden in Routine scenario
campaign.list <- readRDS('Generate/Burden_Stochastic/Campaign_Burden_Stochastic.Rds') # Burden in Campaign scenario
template.naive <- read.csv('Data/Burden_Template/stochastic-burden-template.201710gavi-6.JE_OUCRU-Clapham_standard.csv') # Template to fill in
Cohort.Origin <- read.csv('Data/Population/naive_pop_1950_2100.csv') # Population data
NaivePop.Origin <- read.csv('Generate/Susceptible_Population/NaivePop_All.csv') # Susceptible Pop in Naive scenario
colnames(NaivePop.Origin) <- c('country', colnames(NaivePop.Origin)[-1])

Folder.FOI <- 'Generate/FOI_Distribution/' # Folder containing FOI distribution result

# Read template paras in stochastic run
# template.paras <- read.csv('Data/Burden_Template/stochastic_template_params.csv') <-- look at the file to know the format, then create the dataframe by yourself
colname_string <- c('run_id', '<symptomatic_rate>', '<deaths_rate>', '<disability_rate>', '<lambda>:<BGD>',
                    '<lambda>:<BTN>', '<lambda>:<KHM>', '<lambda>:<CHN>', '<lambda_1>:<IND>', '<lambda_2>:<IND>',
                    '<lambda_3>:<IND>', '<lambda_1>:<IDN>', '<lambda_2>:<IDN>', '<lambda>:<PRK>', '<lambda>:<LAO>',
                    '<lambda>:<MMR>', '<lambda>:<NPL>', '<lambda>:<PAK>', '<lambda>:<PNG>', '<lambda>:<PHL>',
                    '<lambda>:<LKA>', '<lambda>:<TLS>', '<lambda>:<VNM>')
template.paras <- data.frame(matrix(ncol = length(colname_string), nrow = 0))
colnames(template.paras) <- colname_string

# paras.col.countries has the same order with colnames(template.paras)
paras.col.countries <- c('BGD', 'BTN', 'KHM', 'CHN', 'IND.Low', 'IND.Medium', 'IND.High', 
                         'IDN.Low', 'IDN.High', 'PRK', 'LAO', 'MMR', 'NPL', 'PAK', 'PNG', 
                         'PHL', 'LKA', 'TLS', 'VNM')

## ===== Set up symptomatic, Mortality and Disability rate =====
set.seed(114) # make sure the sampling is the same all the time we run the file
PSym <- runif(1600, 1/500, 1/250)
PMor <- runif(1600, 0.1, 0.3) 
PDis <- runif(1600, 0.3, 0.5)

## ===== Set up 200 samples for Stochastics ====
set.seed(911)
numb_of_file <- 200 # Sample numb_of_file values
idx_stochastic <- sample(1:1600, numb_of_file) # Sample from 1600 simulations of FOI distribution

## ===== Load FOI Posterior and store in a list =====
cat('Filling template parameters ...\n')

FOI_list <- rep(list(list()), length(paras.col.countries)) # create list of list
for (idx_FOI_list in 1 : length(FOI_list)){
    Rstan.Posterior <- readRDS(paste0(Folder.FOI, 'FOI_Posterior_', paras.col.countries[idx_FOI_list], '.Rds'))
    if (class(Rstan.Posterior) == 'list'){ ## have FOI Rstan result
        # cat('### Found Rstan FOI ###\n')
        FOI.Posterior <- Rstan.Posterior$lambda
        rm(Rstan.Posterior)
    }else{ ## do not have FOI Rstan --> run random distribution
        # cat('### CANT Found Rstan FOI --> Random as lnorm! ###\n')
        FOI.Posterior <- Rstan.Posterior
        rm(Rstan.Posterior)
    }
    FOI_list[[idx_FOI_list]] <- FOI.Posterior
}

# ===== Filling in parameter templates for each run id =====
for (idx_row in 1 : numb_of_file){ 
    template.paras[[2]][idx_row] <- PSym[idx_stochastic[idx_row]] # symptomatic_rate
    template.paras[[3]][idx_row] <- PMor[idx_stochastic[idx_row]] # deaths_rate
    template.paras[[4]][idx_row] <- PDis[idx_stochastic[idx_row]] # disability_rate
    for (i in 1 : length(FOI_list)){ # FOI for each regions
        template.paras[[i + 4]][idx_row] <- FOI_list[[i]][idx_stochastic[idx_row]] 
    }
}

rm(FOI_list)
cat('Filling template parameters [DONE]\n')

# Save file
write.csv(template.paras, file = paste0(Savepath, 'Template_Stochastic_Parameters.csv'), row.names=FALSE)

# ===== FILL UP TEMPLATES FOR EACH RUN ID ====
regions_vec <- names(naive.list[['cases']]) # take the name of regions
regions_in_countries_vec <- substr(regions_vec, 1, 3) # Take the ISO code
countries_vec <- unique(as.character(template.naive.origin$country)) # unique ISO code


## ----- Process for each run_id -----
for (idx_run_id in 1 : length(idx_stochastic)){ # for each run id from 1 to 200 (numb_of_file)
    cat('========== RUNID:', idx_run_id, '==========\n')
    template.naive <- template.naive.origin
    template.naive$run_id <- idx_run_id
    template.routine <- template.naive
    template.campaign <- template.naive
    
    ## ----- Process for each country -----
    for (idx_country in 1 : length(countries_vec)){
        country_name <- countries_vec[idx_country]
        cat('===== Processing:', country_name, '=====\n')
        idx_region <- which(regions_in_countries_vec %in% country_name)
        # Check if only 1 region in the country or more than 1 subregions
        # If more than 1 subregions --> Take the sum of all subregions
        # Also take the list of selected run id at selected region (through idx_run_id and idx_region)
        if (length(idx_region) == 1){ ## Entire Country (or only 1 region in the country)
            naive.cases.country <- naive.list[['cases']][[idx_region]][[idx_run_id]]
            naive.deaths.country <- naive.list[['deaths']][[idx_region]][[idx_run_id]]
            naive.DALYs.country <- naive.list[['DALYs']][[idx_region]][[idx_run_id]]
            routine.cases.country <- routine.list[['cases']][[idx_region]][[idx_run_id]]
            routine.deaths.country <- routine.list[['deaths']][[idx_region]][[idx_run_id]]
            routine.DALYs.country <- routine.list[['DALYs']][[idx_region]][[idx_run_id]]
            campaign.cases.country <- campaign.list[['cases']][[idx_region]][[idx_run_id]]
            campaign.deaths.country <- campaign.list[['deaths']][[idx_region]][[idx_run_id]]
            campaign.DALYs.country <- campaign.list[['DALYs']][[idx_region]][[idx_run_id]]
            # naive.pop.country <- NaivePop.Origin[which(NaivePop.Origin$country == regions_vec[idx_region]), ]
        }else{ ## Country has more than 1 subregions --> find cumalative
            for (idx_idx_region in 1 : length(idx_region)){
                selected_idx_region <- idx_region[idx_idx_region]
                if (idx_idx_region == 1){ # if the first region --> Assign to variable
                    naive.cases.country <- naive.list[['cases']][[selected_idx_region]][[idx_run_id]]
                    naive.deaths.country <- naive.list[['deaths']][[selected_idx_region]][[idx_run_id]]
                    naive.DALYs.country <-  naive.list[['DALYs']][[selected_idx_region]][[idx_run_id]]
                    routine.cases.country <- routine.list[['cases']][[selected_idx_region]][[idx_run_id]]
                    routine.deaths.country <- routine.list[['deaths']][[selected_idx_region]][[idx_run_id]]
                    routine.DALYs.country <-  routine.list[['DALYs']][[selected_idx_region]][[idx_run_id]]
                    campaign.cases.country <- campaign.list[['cases']][[selected_idx_region]][[idx_run_id]]
                    campaign.deaths.country <- campaign.list[['deaths']][[selected_idx_region]][[idx_run_id]]
                    campaign.DALYs.country <-  campaign.list[['DALYs']][[selected_idx_region]][[idx_run_id]]
                    # naive.pop.country <- NaivePop.Origin[which(NaivePop.Origin$country == regions_vec[selected_idx_region]), ]
                }else{ # From the 2nd subregion --> take the sum of the current region and sum of all previous regions
                    end_year_column <- ncol(naive.cases.country)
                    naive.cases.country[, start_year_column : end_year_column] <- naive.cases.country[, start_year_column : end_year_column] + naive.list[['cases']][[selected_idx_region]][[idx_run_id]][, start_year_column : end_year_column]
                    naive.deaths.country[, start_year_column : end_year_column] <- naive.deaths.country[, start_year_column : end_year_column] + naive.list[['deaths']][[selected_idx_region]][[idx_run_id]][, start_year_column : end_year_column]
                    naive.DALYs.country[, start_year_column : end_year_column] <- naive.DALYs.country[, start_year_column : end_year_column] + naive.list[['DALYs']][[selected_idx_region]][[idx_run_id]][, start_year_column : end_year_column]
                    routine.cases.country[, start_year_column : end_year_column] <- routine.cases.country[, start_year_column : end_year_column] + routine.list[['cases']][[selected_idx_region]][[idx_run_id]][, start_year_column : end_year_column]
                    routine.deaths.country[, start_year_column : end_year_column] <- routine.deaths.country[, start_year_column : end_year_column] + routine.list[['deaths']][[selected_idx_region]][[idx_run_id]][, start_year_column : end_year_column]
                    routine.DALYs.country[, start_year_column : end_year_column] <- routine.DALYs.country[, start_year_column : end_year_column] + routine.list[['DALYs']][[selected_idx_region]][[idx_run_id]][, start_year_column : end_year_column]
                    campaign.cases.country[, start_year_column : end_year_column] <- campaign.cases.country[, start_year_column : end_year_column] + campaign.list[['cases']][[selected_idx_region]][[idx_run_id]][, start_year_column : end_year_column]
                    campaign.deaths.country[, start_year_column : end_year_column] <- campaign.deaths.country[, start_year_column : end_year_column] + campaign.list[['deaths']][[selected_idx_region]][[idx_run_id]][, start_year_column : end_year_column]
                    campaign.DALYs.country[, start_year_column : end_year_column] <- campaign.DALYs.country[, start_year_column : end_year_column] + campaign.list[['DALYs']][[selected_idx_region]][[idx_run_id]][, start_year_column : end_year_column]
                    # naive.pop.country[, start_year_column : end_year_column] <- naive.pop.country[, start_year_column : end_year_column] + NaivePop.Origin[which(NaivePop.Origin$country == regions_vec[selected_idx_region]), start_year_column : end_year_column]
                }
                naive.cases.country$country <- country_name
                naive.deaths.country$country <- country_name
                naive.DALYs.country$country <- country_name
                routine.cases.country$country <- country_name
                routine.deaths.country$country <- country_name
                routine.DALYs.country$country <- country_name
                campaign.cases.country$country <- country_name
                campaign.deaths.country$country <- country_name
                campaign.DALYs.country$country <- country_name
                # naive.pop.country$country <- country_name
            }
        }
        
        # Find row index of selected country in the template dataframe
        idx_row_template <- which(template.campaign$country %in% country_name)
        
        # 3 templates for 3 scenarios
        template.country.naive <- template.naive[idx_row_template, ]
        template.country.routine <- template.routine[idx_row_template, ]
        template.country.campaign <- template.campaign[idx_row_template, ]
        
        # Take cohort information  of the selected country from Cohort dataframe
        Cohort.country <- Cohort.Origin[which(Cohort.Origin$country == country_name),]
        
        # Find min_year and max_year in the template and find the column index in naive.case.country dataframe
        minyear <- min(template.country.naive$year)
        maxyear <- max(template.country.naive$year)
        year.col.min <- paste0('X', minyear)
        year.col.max <- paste0('X', maxyear)
        year.idx.min <- which(colnames(naive.cases.country) %in% year.col.min)
        year.idx.max <- which(colnames(naive.cases.country) %in% year.col.max)
        
        # Do the same for Cohort dataframe
        year.idx.min.cohort <- which(colnames(Cohort.country) %in% year.col.min)
        year.idx.max.cohort <- which(colnames(Cohort.country) %in% year.col.max)
        
        # Extract age group in template dataframe
        agegroup_vec <- unique(template.country.naive$age)
        
        # Run for each age group
        for (idx_agegroup in 1 : length(agegroup_vec)){
            agegroup <- agegroup_vec[idx_agegroup]
            
            # Find row index of selected age group in template, burden, and cohort dataframe
            idx_row_agegroup_template <- which(template.country.naive$age == agegroup)
            idx_row_agegroup_list <- which(naive.cases.country$age_from == agegroup)
            idx_cohort.country <- which(Cohort.country$age_from == agegroup)
            
            # Fill in the template with burden (cases, deaths, dalys) and cohort size at selected year and selected age group
            template.country.naive$cases[idx_row_agegroup_template] <- as.numeric(naive.cases.country[idx_row_agegroup_list, year.idx.min : year.idx.max])
            template.country.naive$deaths[idx_row_agegroup_template] <- as.numeric(naive.deaths.country[idx_row_agegroup_list, year.idx.min : year.idx.max])
            template.country.naive$dalys[idx_row_agegroup_template] <- as.numeric(naive.DALYs.country[idx_row_agegroup_list, year.idx.min : year.idx.max])
            ## Fill the cohort with the susceptible population in the Naive scenario --> Uncomment the following line (and comment the next 3 line)
            # template.country.naive$cohort_size[idx_row_agegroup_template] <- as.numeric(naive.pop.country[idx_row_agegroup_list, year.idx.min : year.idx.max])
            ## Fill the cohort with original data from Population data
            template.country.naive$cohort_size[idx_row_agegroup_template] <- as.numeric(Cohort.country[idx_cohort.country, year.idx.min.cohort : year.idx.max.cohort])
            
            template.country.routine$cases[idx_row_agegroup_template] <- as.numeric(routine.cases.country[idx_row_agegroup_list, year.idx.min : year.idx.max])
            template.country.routine$deaths[idx_row_agegroup_template] <- as.numeric(routine.deaths.country[idx_row_agegroup_list, year.idx.min : year.idx.max])
            template.country.routine$dalys[idx_row_agegroup_template] <- as.numeric(routine.DALYs.country[idx_row_agegroup_list, year.idx.min : year.idx.max])
            template.country.routine$cohort_size <- template.country.naive$cohort_size
            
            template.country.campaign$cases[idx_row_agegroup_template] <- as.numeric(campaign.cases.country[idx_row_agegroup_list, year.idx.min : year.idx.max])
            template.country.campaign$deaths[idx_row_agegroup_template] <- as.numeric(campaign.deaths.country[idx_row_agegroup_list, year.idx.min : year.idx.max])
            template.country.campaign$dalys[idx_row_agegroup_template] <- as.numeric(campaign.DALYs.country[idx_row_agegroup_list, year.idx.min : year.idx.max])
            template.country.campaign$cohort_size <- template.country.naive$cohort_size
        }
        template.naive[idx_row_template, ] <- template.country.naive
        template.routine[idx_row_template, ] <- template.country.routine
        template.campaign[idx_row_template, ] <- template.country.campaign
    }
    
    # Convert idx_run_id to the format with 3 number e.g.: 001, 010, 099, 100, 200, ...
    if (idx_run_id < 10){
        number_id <- paste0('00', idx_run_id)
    }else{
        if (idx_run_id < 100){
            number_id <- paste0('0', idx_run_id)
        }else{
            number_id <- idx_run_id
        }
    }
    
    # Save files
    cat('Saving files ... \n')
    write.csv(template.naive, file = paste0('Template_Stochastic_Naive_', number_id, '.csv'), row.names=FALSE)
    write.csv(template.routine, file = paste0('Template_Stochastic_Routine_', number_id, '.csv'), row.names=FALSE)
    write.csv(template.campaign, file = paste0('Template_Stochastic_Campaign_', number_id, '.csv'), row.names=FALSE)
    cat('Saving files [DONE] \n')
    
}

cat('===== FINISH [Fill_Template_Stochastic.R] =====\n')