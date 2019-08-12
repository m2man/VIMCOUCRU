# --- NOTE ---
# Create susceptible population in Campaign scenario
# create susceptiable population of all countries in sequence loop after rountine at age 0 + campaign at age 0 -> 14
# make new csv
# note: input is naivepop country + vaccine campaign
# ---------- #

cat('===== START [Create_Campaign_Pop.R] =====\n')

## Get directory of the script (this part only work if source the code, wont work if run directly in the console)
## This can be set manually !!! --> setwd('bla bla bla')
script.dir <- dirname(sys.frame(1)$ofile)
script.dir <- paste0(script.dir, '/')
setwd(script.dir)

## Create folder to store the result (will show warnings if the folder already exists --> but just warning, no problem)
dir.create(file.path('Generate/Susceptible_Population/'), showWarnings = TRUE)
Savepath <- 'Generate/Susceptible_Population/'
## Create folder in the case you want to save the population data for each country seperately
dir.create(file.path('Generate/Susceptible_Population/Countries/'), showWarnings = TRUE)
Savepath_countries <- 'Generate/Susceptible_Population/Countries/'

## ===== Define functions =====

update_vaccinated_per_year <- function(vaccinated_last_year, naive_this_year, target_campaign_this_year, coverage_campaign_this_year, coverage_routine_this_year, agefrom = 0, ageto = 14){
    # Input
    #   - vaccinated_last_year is a vector with 100 elements for age 0 --> 99: vaccinated people from last year at each age
    #   - naive_this_year is a vector with 100 elements for age 0 --> 99: naive people from this year at each age
    #   - target_campaign_this_year is a number of target people aims to be vaccinated this year
    #   - coverage_campaign_this_year is the portion of target_campaign_this_year that will received vaccination this year
    #   - coverage_routine_this_year is the portion of entire susceptible people at age 0 will receive routine vaccination this year
    #   - agefrom, ageto: specific age milestone from age ... to age ... will be received campaign vaccination
    # Output
    #   - vaccinated_this_year with 100 elements (number of vaccinated people this year)
    
    if (ageto > 99)
        ageto <- 99 # sometime in csv file, ageto is 100 (but our model is only for 0 -- 99)
    
    # number of people that will receive vaccination this year (by campaign vaccination)
    total_vaccinated_this_year <- target_campaign_this_year * coverage_campaign_this_year
    
    # Find the vaccination people that each age group (from agefrom to ageto) will receive campaign vaccination this year
    # Assumption: Each age group (age group 0, 1, ..., 14 --> 15 agegroup total) equally receive campaign vaccination
    campaign_vaccinated_each_age_group_this_year <- total_vaccinated_this_year / (ageto - agefrom + 1)
    
    # Find the vaccination people at age 0 will receive routine vaccination this year
    # number of Susceptible people at age 0 this year will receive routine vaccination
    this_year_0_routine <- coverage_routine_this_year * naive_this_year[1]
    
    # vaccinated people last year grew up --> shift to 1 year old
    vaccinated_last_year_old <- vaccinated_last_year[1 : (length(vaccinated_last_year) - 1)] 
    
    # Bind routine vaccnation at age 0 this year and vaccinated people from last year grew up
    vaccinated_this_year <- c(this_year_0_routine, vaccinated_last_year_old)
    
    # Find the total vaccinated people this year (after routine and campaign)
    # After the routine, we take the campaign vaccination --> total vaccination is the sum
    vaccinated_this_year[(agefrom + 1) : (ageto + 1)] <- vaccinated_this_year[(agefrom + 1) : (ageto + 1)] + campaign_vaccinated_each_age_group_this_year 
    
    return(vaccinated_this_year)
}

create_vaccinated_campaign_df <- function(NaivePop, Vaccine.campaign, Vaccine.routine, startyearcolumn = 4){
    # Input
    #   - NaivePop: Susceptible population in the Naive scenario (result after running Create_Naive_Pop.R)
    #   - Vaccine.campaign: Campaign Vaccine coverage information given by VIMC
    #   - Vaccine.routine: Routine Vaccine coverage information given by VIMC
    #   - startyearcolumn: the column index (of NaivePop dataframe) from which the year starts. 
    #   The columns of NaivePop starts with country_code, age_from, age_to, X1950, X1951, ... --> startyearcolumn = 4
    # Output
    #   - VCPop.Country: The vaccinated people dataframe indicating the number of people that were vaccinated
    # This function is quite similar to the function in Create_Routine_Pop.R
    
    listyear.Naive <- colnames(NaivePop)[startyearcolumn : ncol(NaivePop)] # year start from 4th column
    listyear.Naive <- as.numeric(sapply(listyear.Naive, substring, 2)) # name of column is 'X1950' --> substring from 2nd character to get numeric year
    listyear.Vaccine.compaign <- Vaccine.campaign$year
    listyear.Vaccine.routine <- Vaccine.routine$year
    
    # assign missing year (before the year starting vaccination) information with 0
    target.campaign <- c(rep(0, length(listyear.Naive) - length(listyear.Vaccine.compaign)), Vaccine.campaign$target) 
    coverage.campaign <- c(rep(0, length(listyear.Naive) - length(listyear.Vaccine.compaign)), Vaccine.campaign$coverage)
    coverage.routine <- c(rep(0, length(listyear.Naive) - length(listyear.Vaccine.routine)), Vaccine.routine$coverage) 
    agefrom.campaign <- c(rep(0, length(listyear.Naive) - length(listyear.Vaccine.compaign)), Vaccine.campaign$age_first)
    ageto.campaign <- c(rep(0, length(listyear.Naive) - length(listyear.Vaccine.compaign)), Vaccine.campaign$age_last)
    
    VCPop.Country <- NaivePop
    VCPop.Country[, startyearcolumn:ncol(VCPop.Country)] <- 0
    
    for (i in 1 : length(coverage.campaign)){
        cat('Processing year', listyear.Naive[i], '\n')
        currentcolumn <- i + startyearcolumn - 1 # Start from startyearcolumn
        naivepop.column <- NaivePop[[currentcolumn]]
        
        if(currentcolumn == startyearcolumn){
            vaccinated.last.year <- rep(0, length(naivepop.column)) # We dont have information for the year before given by VIMC --> Assume no people has been vaccinated
        }else{
            vaccinated.last.year <- VCPop.Country[[currentcolumn - 1]] # Extract vaccinated people last year
        }
        VCPop.Country[[currentcolumn]] <- update_vaccinated_per_year(
            vaccinated.last.year, naivepop.column,
            target.campaign[i],
            coverage.campaign[i], coverage.routine[i],
            agefrom.campaign[i], ageto.campaign[i]
        )
    }
    
    return(VCPop.Country)
}

create_susceptible_rountine_df <- function(NaivePop, Routine, startyearcolumn = 4){
    # The same function with Create_Routine_Pop but now works for Campaign vaccination
    # The main achieve is to find the remaining susceptible people after the vaccination = NaivePop - Vaccinated people
    
    RTPop.Country <- NaivePop
    RTPop.Country[ , startyearcolumn:ncol(RTPop.Country)] <- RTPop.Country[ , startyearcolumn:ncol(RTPop.Country)] - Routine[ , startyearcolumn:ncol(Routine)]
    
    for (i in startyearcolumn : ncol(RTPop.Country)){
        idx <- which(RTPop.Country[[i]] < 0)
        RTPop.Country[[i]][idx] <- 0
    }
    return(RTPop.Country)
}


## ===== Read File =====
Distinct_Files <- FALSE # if you want to make separate files for each country --> change to TRUE
Naive_Folder <- 'Generate/Susceptible_Population/' # Folder contains NaivePop csv file
NaivePop.Origin <- read.csv(paste0(Naive_Folder, 'NaivePop_All.csv'))
Vaccine_Folder <- 'Data/Vaccine_Coverage/' # Folder contains Vaccine coverage files
Vaccine.Origin <- read.csv(paste0(Vaccine_Folder, 'coverage_201710gavi-6_je-campaign-gavi.csv'))

## ----- Processing data for each country -----
Vaccine.Origin$country_code <- as.character(Vaccine.Origin$country_code)
countries_vec <- unique(Vaccine.Origin$country_code)

for (idx_country in 1 : length(countries_vec)){ # Run for each country
    country_iso_code <- countries_vec[idx_country]
    cat('========== Processing', country_iso_code, '==========\n')
    ## Extract Campaign and Routine information and Take index of row of selected country from Vaccine dataframe
    idx.country.campaign <- which(Vaccine.Origin$country_code == country_iso_code & Vaccine.Origin$activity_type == 'campaign')
    idx.country.routine <- which(Vaccine.Origin$country_code == country_iso_code & Vaccine.Origin$activity_type == 'routine')
    ## Check carefully the following number (in case VIMC change the format and column order)
    Vaccine.Country.campaign <- Vaccine.Origin[idx.country.campaign, c(6, 8, 9, 10, 12, 13)] # CAMPAIGN: take isocode, year, agefirst, agelast, target, coverage
    Vaccine.Country.routine <- Vaccine.Origin[idx.country.routine, c(6, 8, 13)] # ROUTINE: take isocode, year, coverage
    Vaccine.Country.campaign$target <- as.numeric(as.character(Vaccine.Country.campaign$target)) # Convert character/factor to numeric
    
    ## Take index of row of selecte country from NaivePop --> Use grep function because some regions IND.Low, IND.High is also belong to IND
    idx_country_row <- grep(country_iso_code, NaivePop.Origin$country)
    NaivePop.Country <- NaivePop.Origin[idx_country_row, ]
    
    ## Preprocess
    startyearcolumn <- 4
    regions <- unique(NaivePop.Country$country)
    
    ## Running
    if (length(regions) == 1){ # only 1 endemic regions in a country
        # Find vaccinated people dataframe
        Vaccinated_Campaign <- create_vaccinated_campaign_df(NaivePop = NaivePop.Country, Vaccine.campaign = Vaccine.Country.campaign,
                                                             Vaccine.routine = Vaccine.Country.routine, startyearcolumn = startyearcolumn)
        # Find remaining Susceptible people after vaccination
        Susceptible_Campaign <- create_susceptible_rountine_df(NaivePop.Country, Vaccinated_Campaign, startyearcolumn)    
    }else{
        # Calculating for each subnational regions --> row bind to the national dataframe
        Vaccinated_Campaign_list <- list()
        # Extract year from NaivePop dataframe
        year_vec <- colnames(NaivePop.Country)[startyearcolumn : ncol(NaivePop.Country)] # year start from 4th column
        year_vec <- as.numeric(sapply(year_vec, substring, 2)) # name of column is 'X1950' --> substring from 2nd character to get numeric year
        
        for (i in 1 : length(regions)){ # Run for each subnational region
            subregion <- as.character(regions[i])
            cat('===== Processing', subregion, '=====\n')
            # Extract subregion information in NaivePop
            idx.subregion <- which(NaivePop.Country$country == subregion)
            NaivePop.Subregion <- NaivePop.Country[idx.subregion, ]
            
            # Find the population proportion between subnational region and national population
            ratio.pop <- as.numeric(colSums(NaivePop.Subregion[, c(4 : ncol(NaivePop.Subregion))]) / colSums(NaivePop.Country[, c(4 : ncol(NaivePop.Country))]))
            
            # Extract Vaccine information of subnational region
            Vaccine.Subregion.campaign <- Vaccine.Country.campaign
            
            # Find the index of the year from NaivePop from which the vaccination begins
            idx_year <- which(year_vec == Vaccine.Subregion.campaign$year[1])
            
            # Extract population proportion from the index year above
            ratio.pop <- ratio.pop[idx_year : length(ratio.pop)]
            
            # The number of vaccination targeted people also follow that portion --> calculate target for each subnational region
            Vaccine.Subregion.campaign$target <- Vaccine.Subregion.campaign$target * ratio.pop
            
            # Calculate vaccinated dataframe
            Vaccinated_Campaign <- create_vaccinated_campaign_df(NaivePop = NaivePop.Subregion, Vaccine.campaign = Vaccine.Subregion.campaign,
                                                                 Vaccine.routine = Vaccine.Country.routine, startyearcolumn = startyearcolumn)
            Vaccinated_Campaign_list[[i]] <- Vaccinated_Campaign
        }
        Vaccinated_Campaign <- do.call('rbind', Vaccinated_Campaign_list) # combine into 1 country
        Susceptible_Campaign <- create_susceptible_rountine_df(NaivePop.Country, Vaccinated_Campaign, startyearcolumn)
    }
    
    if (Distinct_Files){
        filename <- paste0('CampaignPop_', country_iso_code, '.csv')
        write.csv(Susceptible_Campaign, file = paste0(Savepath_countries, filename), row.names = FALSE)
    }
    
    if (idx_country == 1){
        final.df <- Susceptible_Campaign  
    }else{
        final.df <- rbind(final.df, Susceptible_Campaign)
    }
}

filename <- 'CampaignPop_All.csv'
write.csv(final.df, file = paste0(Savepath, filename), row.names = FALSE)

cat('===== FINISH [Create_Campaign_Pop.R] =====\n')

# library(ggplot2)
# sus <- colSums(Susceptible_Campaign[, c(4:ncol(Susceptible_Campaign))])
# year <- c(1950:2100)
# plt.df <- data.frame(x = year, y = sus)
# ggplot(aes(x = x, y = y), data = plt.df) + geom_col()
