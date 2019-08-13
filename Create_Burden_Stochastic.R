# --- NOTE ---
# STOCHASTIC RUN
# (MEAN BURDEN) 
# This file is used to generate cases and deaths from SERIES POSTERIOR_FOI$LAMBDA, THEN TAKE RANDOM 200 SAMPLES OF BURDEN
# (result after running Rstan_FOI and Population result(3 scenario: Naive, Routine, Campaign))
# Result will be a list of 3 list (cases, deaths, and DALYs for each scenario)
# Each list of cases or deaths is another lists for each country with a dataframe of 100 agegroup x several years
# ---------- #

cat('===== START [Create_Burden_Stochastic.R] =====\n')

## Get directory of the script (this part only work if source the code, wont work if run directly in the console)
## This can be set manually !!! -->setwd('bla bla bla')
script.dir <- dirname(sys.frame(1)$ofile)
script.dir <- paste0(script.dir, '/')
setwd(script.dir)

## Create folder to store the result (will show warnings if the folder already exists --> but just warning, no problem)
dir.create(file.path('Generate/Burden_Stochastic/'), showWarnings = TRUE)
Savepath <- 'Generate/Burden_Stochastic/'

## ===== Load file =====
start_year_column <- 4 # See Create_Campaign_Pop to know what is it
save_file <- TRUE # Set to TRUE if you want to save the results

## Load FOI Posterior of specific region (if available, some regions do not have data to run Rstan)
Folder.FOI <- 'Generate/FOI_Distribution/'
FOI.files <- list.files(Folder.FOI)
FOI.files.regions <- substring(FOI.files, 15, nchar(FOI.files) - 4) # Take the regions (only works if filename is as formated)

## Load Susceptible population at each scenario
Folder.Susceptible <- 'Generate/Susceptible_Population/'
NaivePop.Origin <- read.csv(paste0(Folder.Susceptible, 'NaivePop_All.csv'))
RoutinePop.Origin <- read.csv(paste0(Folder.Susceptible, 'RoutinePop_All.csv'))
CampaignPop.Origin <- read.csv(paste0(Folder.Susceptible, 'CampaignPop_All.csv'))

## Load Life expectation file --> Used for DALY calculating
Folder.Life <- 'Data/Life_Expactation/'
RemainLife.Origin <- read.csv(paste0(Folder.Life, '201710gavi-2_dds-201710_life_ex_both.csv'))

## ===== Set up symptomatic, Mortality and Disability rate =====
set.seed(114) # make sure the sampling is the same all the time we run the file
PSym <- runif(1600, 1/500, 1/250)
PMor <- runif(1600, 0.1, 0.3) 
PDis <- runif(1600, 0.3, 0.5)

## ===== Set up 200 samples for Stochastics ====
set.seed(911)
numb_of_file <- 10 # Sample numb_of_file values
idx_stochastic <- sample(1:1600, numb_of_file) # Sample from 1600 simulations of FOI distribution

## ===== Create a list to store the result =====
# Each scenario has a list. In each list, there will be 3 other lists for cases, deaths, and dalys
naive.list <- list()
naive.list[['cases']] <- list()
naive.list[['deaths']] <- list()
naive.list[['DALYs']] <- list()

routine.list <- list()
routine.list[['cases']] <- list()
routine.list[['deaths']] <- list()
routine.list[['DALYs']] <- list()

campaign.list <- list()
campaign.list[['cases']] <- list()
campaign.list[['deaths']] <- list()
campaign.list[['DALYs']] <- list()

## ===== Process for each region =====
regions_vector <- unique(as.character(NaivePop.Origin$country))

# Run for each region
for (idx_region in 1 : length(regions_vector)){
    region_name <- regions_vector[idx_region]
    country_name <- substr(region_name, 1, 3)
    cat('========== Processing:', region_name, '==========\n')
    # Extract region information (NaivePop, RoutinePop, CampaignPop, and Life Expectancy)
    NaivePop.Region <- NaivePop.Origin[which(NaivePop.Origin$country == region_name), ]
    RoutinePop.Region <- RoutinePop.Origin[which(RoutinePop.Origin$country == region_name), ]
    CampaignPop.Region <- CampaignPop.Origin[which(CampaignPop.Origin$country == region_name), ]
    RemainLife.Region <- RemainLife.Origin[which(RemainLife.Origin$country_code == country_name), ]
    
    # Read the FOI distribution
    # If the region has age-stratified case data --> Load the Rstan distribution
    # If not --> Load the random distribution (log norm distribution)
    idx_foi <- which(FOI.files.regions %in% region_name)
    Rstan.Posterior <- readRDS(paste0(Folder.FOI, FOI.files[idx_foi]))
    if (class(Rstan.Posterior) == 'list'){ ## have FOI Rstan result
        cat('### Found Rstan FOI ###\n')
        FOI.Posterior <- Rstan.Posterior$lambda
        rm(Rstan.Posterior)
    }else{ ## do not have FOI Rstan --> run random distribution
        cat('### CANT Found Rstan FOI --> Random as lnorm! ###\n')
        FOI.Posterior <- Rstan.Posterior
        rm(Rstan.Posterior)
    }
    
    # Initialize the lists
    Naive.Cases <- rep(list(NaivePop.Region), numb_of_file) # numb_of_fle lists for numb_of_file stochastics samples
    Naive.Deaths <- Naive.Cases
    Naive.DALYs <- Naive.Cases
    Routine.Cases <- Naive.Cases
    Routine.Deaths <- Naive.Cases
    Routine.DALYs <- Naive.Cases
    Campaign.Cases <- Naive.Cases
    Campaign.Deaths <- Naive.Cases
    Campaign.DALYs <- Naive.Cases
    
    # Read unique years provided in the Life Expectency dataframe
    year_RemainLife <- unique(RemainLife.Region$year)
    
    # Run for each year
    for (idx_year in start_year_column : ncol(NaivePop.Region)){
        year_char <- colnames(Naive.Cases)[idx_year]
        cat('~~~~~ Year:', year_char, '~~~~~\n')
        year_num <- as.integer(substr(year_char, 2, nchar(year_char))) # remove 'X' character in colnames: X1950, X1951, ... and convert to numeric
        # Since the year provided in Life Expectancy might be not included in NaivePop years
        # --> Use the year in Life Expectancy that closest and less than the year appear in Naive Pop
        year_temp <- year_num - year_RemainLife
        year_select <- year_RemainLife[which(year_temp == min(year_temp[year_temp >= 0]))]
        RemainLife.Region.Year <- RemainLife.Region[which(RemainLife.Region$year == year_select), ]
        
        # Run for each age
        for (idx.age in 1 : nrow(NaivePop.Region)){
            # Assign the remaining life for each age, at selected year
            age.naive <- NaivePop.Region$age_from[idx.age]
            idx.age.remain <- which(RemainLife.Region.Year$age_from <= age.naive & RemainLife.Region.Year$age_to >= age.naive)
            remainlife <- RemainLife.Region.Year$value[idx.age.remain]
            
            # Extract Susceptible population at each age, each year, for each scenario
            pop.age.naive <- NaivePop.Region[[idx_year]][idx.age]
            pop.age.routine <- RoutinePop.Region[[idx_year]][idx.age]
            pop.age.campaign <- CampaignPop.Region[[idx_year]][idx.age]
            
            # Calculate burden (cases, deaths, dalys) for naive scenario
            naive.cases.temp <- (1 - exp(-1*FOI.Posterior)) * exp(-1*FOI.Posterior*age.naive) * PSym * pop.age.naive
            naive.deaths.temp <- naive.cases.temp * PMor
            naive.DALYs.temp <- naive.deaths.temp*remainlife + naive.cases.temp*0.133*2.5/52 + 
                (naive.cases.temp - naive.deaths.temp)*PDis*0.542*remainlife
            
            # Calculate burden (cases, deaths, dalys) for routine scenario
            routine.cases.temp <- (1 - exp(-1*FOI.Posterior)) * exp(-1*FOI.Posterior*age.naive) * PSym * pop.age.routine
            routine.deaths.temp <- routine.cases.temp * PMor
            routine.DALYs.temp <- routine.deaths.temp*remainlife + routine.cases.temp*0.133*2.5/52 + 
                (routine.cases.temp - routine.deaths.temp)*PDis*0.542*remainlife
            
            # Calculate burden (cases, deaths, dalys) for campaign scenario
            campaign.cases.temp <- (1 - exp(-1*FOI.Posterior)) * exp(-1*FOI.Posterior*age.naive) * PSym * pop.age.campaign
            campaign.deaths.temp <- campaign.cases.temp * PMor
            campaign.DALYs.temp <- campaign.deaths.temp*remainlife + campaign.cases.temp*0.133*2.5/52 + 
                (campaign.cases.temp - campaign.deaths.temp)*PDis*0.542*remainlife
            
            # Sample numb_of_file values at specific index sampled above
            for (idx.stochastics in 1 : numb_of_file){
                Naive.Cases[[idx.stochastics]][[idx_year]][idx.age] <- naive.cases.temp[idx_stochastic[idx.stochastics]]
                Naive.Deaths[[idx.stochastics]][[idx_year]][idx.age] <- naive.deaths.temp[idx_stochastic[idx.stochastics]]
                Naive.DALYs[[idx.stochastics]][[idx_year]][idx.age] <- naive.DALYs.temp[idx_stochastic[idx.stochastics]]
                Routine.Cases[[idx.stochastics]][[idx_year]][idx.age] <- routine.cases.temp[idx_stochastic[idx.stochastics]]
                Routine.Deaths[[idx.stochastics]][[idx_year]][idx.age] <- routine.deaths.temp[idx_stochastic[idx.stochastics]]
                Routine.DALYs[[idx.stochastics]][[idx_year]][idx.age] <- routine.DALYs.temp[idx_stochastic[idx.stochastics]]
                Campaign.Cases[[idx.stochastics]][[idx_year]][idx.age] <- campaign.cases.temp[idx_stochastic[idx.stochastics]]
                Campaign.Deaths[[idx.stochastics]][[idx_year]][idx.age] <- campaign.deaths.temp[idx_stochastic[idx.stochastics]]
                Campaign.DALYs[[idx.stochastics]][[idx_year]][idx.age] <- campaign.DALYs.temp[idx_stochastic[idx.stochastics]]
            }
        }
    }
    
    # Assign to the list
    naive.list[['cases']][[region_name]] <- Naive.Cases
    naive.list[['deaths']][[region_name]] <- Naive.Deaths
    naive.list[['DALYs']][[region_name]] <- Naive.DALYs
    routine.list[['cases']][[region_name]] <- Routine.Cases
    routine.list[['deaths']][[region_name]] <- Routine.Deaths
    routine.list[['DALYs']][[region_name]] <- Routine.DALYs
    campaign.list[['cases']][[region_name]] <- Campaign.Cases
    campaign.list[['deaths']][[region_name]] <- Campaign.Deaths
    campaign.list[['DALYs']][[region_name]] <- Campaign.DALYs
}

if (save_file){
    saveRDS(naive.list, paste0(Savepath, 'Naive_Burden_Stochastic.Rds'))
    saveRDS(routine.list, paste0(Savepath, 'Routine_Burden_Stochastic.Rds'))
    saveRDS(campaign.list, paste0(Savepath, 'Campaign_Burden_Stochastic.Rds'))    
}

cat('===== FINISH [Create_Burden_Stochastic.R] =====\n')