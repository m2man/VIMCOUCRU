# --- NOTE --- 
# (MEAN FOI) 
# This file is used to generate cases and deaths from MEAN OF FOI DISTRIBUTION 
# Basically, it is very similar to Create_Burden_MeanBurden --> Only different thing: Take the mean of FOI distribution first --> Use this value to find burden
# (result after running Rstan_FOI and Population result(3 scenario: Naive, Routine, Campaign))
# Result will be a list of 3 list (cases, deaths, and DALYs for each scenario)
# Each list of cases or deaths is another lists for each country with a dataframe of 100 agegroup x several years
# - Update 26 Aug 2019: Add calculation of Number of Immuned People (without symptomatic rate) = cases / PSym
# ---------- #

cat('===== START [Create_Burden_MeanFOI.R] =====\n')

## Get directory of the script (this part only work if source the code, wont work if run directly in the console)
## This can be set manually !!! -->setwd('bla bla bla')
script.dir <- dirname(sys.frame(1)$ofile)
script.dir <- paste0(script.dir, '/')
setwd(script.dir)

## Create folder to store the result (will show warnings if the folder already exists --> but just warning, no problem)
dir.create(file.path('Generate/Burden/'), showWarnings = TRUE)
Savepath <- 'Generate/Burden/'

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

## ===== Set up burden weights parameters =====
acute_weight <-  0.133 # acute encephalitis (given VIMC)
chronic_weight <- 0.542 # severe motor plus cognitive impairments due to encephalitis (given by VIMC)
symptom_time <- 2.5 # 2.5 weeks
foi_time <- 52 # FOI by year = 52 weeks

## ===== Create a list to store the result =====
# Each scenario has a list. In each list, there will be 4 other lists for immuned, cases, deaths, and dalys
# Naive
naive.list <- list()
naive.list[['immuned']] <- list() # asymtomatic cases
naive.list[['cases']] <- list() # cases = immnued * symptomatic rate
naive.list[['deaths']] <- list()
naive.list[['DALYs']] <- list()

# Routine
routine.list <- list()
routine.list[['immuned']] <- list()
routine.list[['cases']] <- list()
routine.list[['deaths']] <- list()
routine.list[['DALYs']] <- list()


# Campaign
campaign.list <- list()
campaign.list[['immuned']] <- list()
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
        FOI.Posterior <- mean(Rstan.Posterior$lambda) # TAKE THE MEAN
        rm(Rstan.Posterior)
    }else{ ## do not have FOI Rstan --> run random distribution
        cat('### CANT Found Rstan FOI --> Random as lnorm! ###\n')
        FOI.Posterior <- mean(Rstan.Posterior) # TAKE THE MEAN
        rm(Rstan.Posterior)
    }
    
    # Initialize the lists
    # Naive
    Naive.Cases <- NaivePop.Region
    Naive.Immuned <- Naive.Cases
    Naive.Deaths <- Naive.Cases
    Naive.DALYs <- Naive.Cases
    
    # Routine
    Routine.Cases <- Naive.Cases
    Routine.Immuned <- Naive.Cases
    Routine.Deaths <- Naive.Cases
    Routine.DALYs <- Naive.Cases
    
    # Campaign
    Campaign.Cases <- Naive.Cases
    Campaign.Immuned <- Naive.Cases
    Campaign.Deaths <- Naive.Cases
    Campaign.DALYs <- Naive.Cases
    
    # Read unique years provided in the Life Expectency dataframe
    year_RemainLife <- unique(RemainLife.Region$year)
    
    # Run for each year
    for (idx_year in start_year_column : ncol(Naive.Cases)){
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
            naive.immuned.temp <- (1 - exp(-1*FOI.Posterior)) * exp(-1*FOI.Posterior*age.naive) * pop.age.naive 
            naive.cases.temp <- naive.immuned.temp * PSym
            naive.deaths.temp <- naive.cases.temp * PMor
            naive.DALYs.temp <- naive.deaths.temp*remainlife + naive.cases.temp*acute_weight*symptom_time/foi_time + 
                (naive.cases.temp - naive.deaths.temp)*PDis*chronic_weight*remainlife
            
            # Calculate burden (cases, deaths, dalys) for routine scenario
            routine.immuned.temp <- (1 - exp(-1*FOI.Posterior)) * exp(-1*FOI.Posterior*age.naive) * pop.age.routine
            routine.cases.temp <- routine.immuned.temp * PSym
            routine.deaths.temp <- routine.cases.temp * PMor
            routine.DALYs.temp <- routine.deaths.temp*remainlife + routine.cases.temp*acute_weight*symptom_time/foi_time + 
                (routine.cases.temp - routine.deaths.temp)*PDis*chronic_weight*remainlife
            
            # Calculate burden (cases, deaths, dalys) for campaign scenario
            campaign.immuned.temp <- (1 - exp(-1*FOI.Posterior)) * exp(-1*FOI.Posterior*age.naive) * pop.age.campaign
            campaign.cases.temp <- campaign.immuned.temp * PSym
            campaign.deaths.temp <- campaign.cases.temp * PMor
            campaign.DALYs.temp <- campaign.deaths.temp*remainlife + campaign.cases.temp*acute_weight*symptom_time/foi_time + 
                (campaign.cases.temp - campaign.deaths.temp)*PDis*chronic_weight*remainlife
            
            # Assign the value at each age and each year
            # Naive
            Naive.Cases[[idx_year]][idx.age] <- naive.cases.temp
            Naive.Immuned[[idx_year]][idx.age] <- naive.immuned.temp
            Naive.Deaths[[idx_year]][idx.age] <- naive.deaths.temp
            Naive.DALYs[[idx_year]][idx.age] <- naive.DALYs.temp
            
            # Routine
            Routine.Cases[[idx_year]][idx.age] <- routine.cases.temp
            Routine.Immuned[[idx_year]][idx.age] <- routine.immuned.temp
            Routine.Deaths[[idx_year]][idx.age] <- routine.deaths.temp
            Routine.DALYs[[idx_year]][idx.age] <- routine.DALYs.temp
            
            # Campaign
            Campaign.Cases[[idx_year]][idx.age] <- campaign.cases.temp
            Campaign.Immuned[[idx_year]][idx.age] <- campaign.immuned.temp
            Campaign.Deaths[[idx_year]][idx.age] <- campaign.deaths.temp
            Campaign.DALYs[[idx_year]][idx.age] <- campaign.DALYs.temp
        }
    }
    
    # Assign to the list
    # Naive
    naive.list[['cases']][[region_name]] <- Naive.Cases
    naive.list[['immuned']][[region_name]] <- Naive.Immuned
    naive.list[['deaths']][[region_name]] <- Naive.Deaths
    naive.list[['DALYs']][[region_name]] <- Naive.DALYs
    
    # Routine
    routine.list[['cases']][[region_name]] <- Routine.Cases
    routine.list[['immuned']][[region_name]] <- Routine.Immuned
    routine.list[['deaths']][[region_name]] <- Routine.Deaths
    routine.list[['DALYs']][[region_name]] <- Routine.DALYs
    
    # Campaign
    campaign.list[['cases']][[region_name]] <- Campaign.Cases
    campaign.list[['immuned']][[region_name]] <- Campaign.Immuned
    campaign.list[['deaths']][[region_name]] <- Campaign.Deaths
    campaign.list[['DALYs']][[region_name]] <- Campaign.DALYs
}

if (save_file){
    saveRDS(naive.list, paste0(Savepath, 'Naive_Burden_MeanFOI.Rds'))
    saveRDS(routine.list, paste0(Savepath, 'Routine_Burden_MeanFOI.Rds'))
    saveRDS(campaign.list, paste0(Savepath, 'Campaign_Burden_MeanFOI.Rds'))    
}

cat('===== FINISH [Create_Burden_MeanFOI.R] =====\n')