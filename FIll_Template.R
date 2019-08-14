# --- NOTE ---
# This file is used to fill in the form of central burden
# input is the result after running Create_Burden
# ---------- #

cat('===== START [Fill_Template.R] =====\n')

## Get directory of the script (this part only work if source the code, wont work if run directly in the console)
## This can be set manually !!! -->setwd('bla bla bla')
script.dir <- dirname(sys.frame(1)$ofile)
script.dir <- paste0(script.dir, '/')
setwd(script.dir)

## Create folder to store the result (will show warnings if the folder already exists --> but just warning, no problem)
dir.create(file.path('Generate/Template/Naive'), showWarnings = TRUE)
dir.create(file.path('Generate/Template/Routine'), showWarnings = TRUE)
dir.create(file.path('Generate/Template/Campaign'), showWarnings = TRUE)

Savepath_Naive <- 'Generate/Template/Naive/'
Savepath_Routine <- 'Generate/Template/Routine/'
Savepath_Campaign <- 'Generate/Template/Campaign/'

## ----- Load file -----
start_year_column <- 4 # index of column (year) in NaivePop dataframe (start from column 4: X1950, X1951, ...) 

naive.list <- readRDS('Generate/Burden/Naive_Burden_MeanBurden.Rds') # Burden in Naive scenario
routine.list <- readRDS('Generate/Burden/Routine_Burden_MeanBurden.Rds') # Burden in Routine scenario
campaign.list <- readRDS('Generate/Burden/Campaign_Burden_MeanBurden.Rds') # Burden in Campaign scenario
template.naive <- read.csv('Data/Burden_Template/central-burden-template.201810synthetic-3.JE_OUCRU-Clapham_standard_pine.csv') # Template to fill in
template.routine <- template.naive
template.campaign <- template.naive
Cohort.Origin <- read.csv('Data/Population/naive_pop_1950_2100.csv') # Population data
NaivePop.Origin <- read.csv('Generate/Susceptible_Population/NaivePop_All.csv') # Susceptible Pop in Naive scenario
colnames(NaivePop.Origin) <- c('country', colnames(NaivePop.Origin)[-1])

## ----- Process for each country -----
regions_vec <- names(naive.list[['cases']]) # Regions
regions_in_countries_vec <- substr(regions_vec, 1, 3) # ISO code
countries_vec <- unique(as.character(template.naive$country)) # countries in template
for (idx_country in 1 : length(countries_vec)){ # Run for each country in template
    country_name <- countries_vec[idx_country]
    cat('========== Processing:', country_name, '==========\n')
    idx_region <- which(regions_in_countries_vec %in% country_name)
    # Check if only 1 region in the country or more than 1 subregions
    # If more than 1 subregions --> Take the sum of all subregions
    if (length(idx_region) == 1){ ## Entire Country
        naive.cases.country <- naive.list[['cases']][[idx_region]]
        naive.deaths.country <- naive.list[['deaths']][[idx_region]]
        naive.DALYs.country <- naive.list[['DALYs']][[idx_region]]
        routine.cases.country <- routine.list[['cases']][[idx_region]]
        routine.deaths.country <- routine.list[['deaths']][[idx_region]]
        routine.DALYs.country <- routine.list[['DALYs']][[idx_region]]
        campaign.cases.country <- campaign.list[['cases']][[idx_region]]
        campaign.deaths.country <- campaign.list[['deaths']][[idx_region]]
        campaign.DALYs.country <- campaign.list[['DALYs']][[idx_region]]
        naive.pop.country <- NaivePop.Origin[which(NaivePop.Origin$country == regions_vec[idx_region]), ]
    }else{ ## Country has more than 1 regions --> find cumalative
        for (idx_idx_region in 1 : length(idx_region)){
            selected_idx_region <- idx_region[idx_idx_region]
            if (idx_idx_region == 1){ # if the first region --> Assign to variable
                naive.cases.country <- naive.list[['cases']][[selected_idx_region]]
                naive.deaths.country <- naive.list[['deaths']][[selected_idx_region]]
                naive.DALYs.country <-  naive.list[['DALYs']][[selected_idx_region]]
                routine.cases.country <- routine.list[['cases']][[selected_idx_region]]
                routine.deaths.country <- routine.list[['deaths']][[selected_idx_region]]
                routine.DALYs.country <-  routine.list[['DALYs']][[selected_idx_region]]
                campaign.cases.country <- campaign.list[['cases']][[selected_idx_region]]
                campaign.deaths.country <- campaign.list[['deaths']][[selected_idx_region]]
                campaign.DALYs.country <-  campaign.list[['DALYs']][[selected_idx_region]]
                naive.pop.country <- NaivePop.Origin[which(NaivePop.Origin$country == regions_vec[selected_idx_region]), ]
            }else{ # From the 2nd subregion --> take the sum of the current region and sum of all previous regions
                end_year_column <- ncol(naive.cases.country)
                naive.cases.country[, start_year_column : end_year_column] <- naive.cases.country[, start_year_column : end_year_column] + naive.list[['cases']][[selected_idx_region]][, start_year_column : end_year_column]
                naive.deaths.country[, start_year_column : end_year_column] <- naive.deaths.country[, start_year_column : end_year_column] + naive.list[['deaths']][[selected_idx_region]][, start_year_column : end_year_column]
                naive.DALYs.country[, start_year_column : end_year_column] <- naive.DALYs.country[, start_year_column : end_year_column] + naive.list[['DALYs']][[selected_idx_region]][, start_year_column : end_year_column]
                routine.cases.country[, start_year_column : end_year_column] <- routine.cases.country[, start_year_column : end_year_column] + routine.list[['cases']][[selected_idx_region]][, start_year_column : end_year_column]
                routine.deaths.country[, start_year_column : end_year_column] <- routine.deaths.country[, start_year_column : end_year_column] + routine.list[['deaths']][[selected_idx_region]][, start_year_column : end_year_column]
                routine.DALYs.country[, start_year_column : end_year_column] <- routine.DALYs.country[, start_year_column : end_year_column] + routine.list[['DALYs']][[selected_idx_region]][, start_year_column : end_year_column]
                campaign.cases.country[, start_year_column : end_year_column] <- campaign.cases.country[, start_year_column : end_year_column] + campaign.list[['cases']][[selected_idx_region]][, start_year_column : end_year_column]
                campaign.deaths.country[, start_year_column : end_year_column] <- campaign.deaths.country[, start_year_column : end_year_column] + campaign.list[['deaths']][[selected_idx_region]][, start_year_column : end_year_column]
                campaign.DALYs.country[, start_year_column : end_year_column] <- campaign.DALYs.country[, start_year_column : end_year_column] + campaign.list[['DALYs']][[selected_idx_region]][, start_year_column : end_year_column]
                naive.pop.country[, start_year_column : end_year_column] <- naive.pop.country[, start_year_column : end_year_column] + NaivePop.Origin[which(NaivePop.Origin$country == regions_vec[selected_idx_region]), start_year_column : end_year_column]
            }
            # Assign country name column
            naive.cases.country$country <- country_name
            naive.deaths.country$country <- country_name
            naive.DALYs.country$country <- country_name
            routine.cases.country$country <- country_name
            routine.deaths.country$country <- country_name
            routine.DALYs.country$country <- country_name
            campaign.cases.country$country <- country_name
            campaign.deaths.country$country <- country_name
            campaign.DALYs.country$country <- country_name
            naive.pop.country$country <- country_name
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
    
    for (idx_agegroup in 1 : length(agegroup_vec)){ # Run for each age group
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

# Save file and export to csv
write.csv(template.naive, file = paste0(Savepath_Naive, 'Template_Naive.csv'), row.names=FALSE)
write.csv(template.routine, file = paste0(Savepath_Routine, 'Template_Routine.csv'), row.names=FALSE)
write.csv(template.campaign, file = paste0(Savepath_Campaign, 'Template_Campaign.csv'), row.names=FALSE)

cat('===== FINISH [Fill_Template.R] =====\n')