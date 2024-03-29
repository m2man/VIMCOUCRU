# --- NOTE ---
# create susceptiable population of all countries after rountine at age 0 (Routine scenario)
# note: input is NaivePop_All (after running Create_Naive_Pop.R) + vaccine routine --> run for each country
# Update 23 Aug 2019
#   + Add option run portion_vaccinated (if this is true --> vaccinated people growing up will be a portion, not the exact number from the last year)
#   + Formular (with Assumption that vaccinated people will die normally with portion): 
#       [*] {vaccinated at age [A] in year [Y]} = {population at age [A] in year [Y]} / {population at age [A-1] in year [Y-1]} * {vaccinated at age [A-1] in year [Y-1]}
# ---------- #

cat('===== START [Create_Routine_Pop.R] =====\n')

portion_vaccinated_run = TRUE # Set True if you want to run the option vaccinated people will be ageing portionally (not the exact number anymore)

## Get directory of the script (this part only work if source the code, wont work if run directly in the console)
## This can be set manually !!! -->setwd('bla bla bla')
script.dir <- dirname(sys.frame(1)$ofile)
script.dir <- paste0(script.dir, '/')
setwd(script.dir)

## Create folder to store the result (will show warnings if the folder already exists --> but just warning, no problem)
dir.create(file.path('Generate/Susceptible_Population/'), showWarnings = TRUE)
Savepath <- 'Generate/Susceptible_Population/'

dir.create(file.path('Generate/Vaccinated_Population/'), showWarnings = TRUE)
Savepath_vac <- 'Generate/Vaccinated_Population/'

## Create folder in the case you want to save the population data for each country seperately
dir.create(file.path('Generate/Susceptible_Population/Countries/'), showWarnings = TRUE)
Savepath_countries <- 'Generate/Susceptible_Population/Countries/'

dir.create(file.path('Generate/Vaccinated_Population/Countries/'), showWarnings = TRUE)
Savepath_countries_vac <- 'Generate/Vaccinated_Population/Countries/'

## ===== Define functions =====

create_vaccinated_rountine_df <- function(NaivePop, Vaccine, startyearcolumn = 4, portion_vaccinated = FALSE){
    # Input
    #   - NaivePop: Susceptible population in the Naive scenario (result after running Create_Naive_Pop.R) --> NaivePop is NaivePop for a specific country
    #       + Note that Naive does not mean Susceptible/unvaccinated people. Naive means original population
    #   - Vaccine: Vaccine coverage information given by VIMC
    #   - startyearcolumn: the column index (of NaivePop dataframe) from which the year starts. 
    #   - portion_vaccinated: Boolean variable (TRUE/FALSE) --> Set true if you want to run portion vaccinated ageing --> False mean number of vaccinated people will grow up overtime without death
    #   The columns of NaivePop starts with country_code, age_from, age_to, X1950, X1951, ... --> startyearcolumn = 4
    # Output: The vaccinated people dataframe indicating the number of people that were vaccinated
    
    listyear.Naive <- colnames(NaivePop)[startyearcolumn : ncol(NaivePop)] # year start from 4th column
    listyear.Naive <- as.numeric(sapply(listyear.Naive, substring, 2)) # name of column is 'X1950' --> substring from 2nd character to get numeric year
    listyear.Vaccine <- Vaccine$year
    
    coverage <- c(rep(0, length(listyear.Naive) - length(listyear.Vaccine)), Vaccine$coverage) # assign missing year with 0 (normally there are more year in Naive than Vaccine)
    
    startcoverage.vector <- which(coverage != 0)[1] # coverage[startcoverage.vector] > 0 --> find the year that begins the vaccination
    startcoverage.column <- startcoverage.vector + startyearcolumn - 1 # index the year column (in the NaivePop dataframe) that begins the vaccination
    cat('Year starting vaccination:', listyear.Vaccine[which(Vaccine$coverage != 0)[1]],
        '----- Colnames:', colnames(NaivePop)[startcoverage.column], '\n')
    
    # Initialize the vaccinated dataframe with 0 (same format with NaivePop dataframe)
    VCPop.Country <- NaivePop
    VCPop.Country[, startyearcolumn:ncol(VCPop.Country)] <- 0
    
    # Calulate the number of vaccinated people by year and by age --> multiply vaccine coverage portion with susceptible population
    for (i in startcoverage.vector : length(coverage)){
        cat('Processing year', listyear.Naive[i], '\n')
        currentcolumn <- startcoverage.column + i - startcoverage.vector
        VCPop.Country[1, currentcolumn] <- coverage[i] * NaivePop[1, currentcolumn]
        # Bring the current vaccinated people in this year to the next year with older age (older than 1 year old)
        if (portion_vaccinated == FALSE){
            # For example: In 2014, 100 people at age 0 were vaccinated --> In 2015, 100 people at age 1 were vaccinated (100 people grew up)
            # Above example is only true in Routine scenario --> Routine scenario: Only vaccine people at age 0
            # VCPop.Country[2 : nrow(VCPop.Country), currentcolumn] is vaccinated people this year (age A)
            # VCPop.Country[1 : (nrow(VCPop.Country) - 1), currentcolumn - 1] is vaccinated people lastyear (age A - 1)
            if (currentcolumn > startyearcolumn && currentcolumn <= ncol(VCPop.Country))
                VCPop.Country[2 : nrow(VCPop.Country), currentcolumn] <- VCPop.Country[1 : (nrow(VCPop.Country) - 1), currentcolumn - 1]    
        }else{
            # For example: In 2014, 100 people at age 0 were vaccinated --> In 2015, only a portion of 100 people at age 1 were vaccinated (some of them might be dead)
            # vaccinated people this year = portion of vaccination last year * population this year (at each age)
            # portion of vaccination last year = vaccinated people last year / population last year (at each age)
            if (currentcolumn > startyearcolumn && currentcolumn <= ncol(VCPop.Country)){
                VCPop.Country.Lastyear <- VCPop.Country[1 : (nrow(VCPop.Country) - 1), currentcolumn - 1]
                NaivePop.Country.Lastyear <- NaivePop[1 : (nrow(VCPop.Country) - 1), currentcolumn - 1]
                NaivePop.Country.Thisyear <- NaivePop[2 : nrow(VCPop.Country), currentcolumn]
                portion_vaccinated_people_alive <- NaivePop.Country.Thisyear/NaivePop.Country.Lastyear
                # Check infinity problem: naivepop last year is 0, naivepop this year is non-zeros (sound impossible but it appear in the naive population data)
                # In this case non-zero/0 = Inf --> we assign portion = 1 
                portion_vaccinated_people_alive[which(is.infinite(portion_vaccinated_people_alive))] <- 1
                # Check NAN problem: naivepop last year is 0, naivepop this year is also 0 (make sense, 0 people 98 year old last year, this year also 0 people at age 99)
                # In this case 0/0 = NAN --> we assign portion = 0 
                portion_vaccinated_people_alive[which(is.na(portion_vaccinated_people_alive))] <- 0
                # Multiply and got the ageging vaccinated people
                VCPop.Country[2 : nrow(VCPop.Country), currentcolumn] <- portion_vaccinated_people_alive * VCPop.Country.Lastyear
            }
            
        }
    }
    return(VCPop.Country)
}

create_susceptible_rountine_df <- function(NaivePop, Routine, startyearcolumn = 4){
    # Input
    #   - NaivePop: Susceptible population in the Naive scenario (result after running Create_Naive_Pop.R)
    #   - Routine: The vaccinated people dataframe (produce by the above function: create_vaccinated_rountine_df)
    #   - startyearcolumn: Same as above function
    # Output: The susceptible poulation in Routine scenario = Naivepop - Routine (Number of vaccinated people)
    
    RTPop.Country <- NaivePop
    RTPop.Country[ , startyearcolumn:ncol(RTPop.Country)] <- RTPop.Country[ , startyearcolumn:ncol(RTPop.Country)] - Routine[ , startyearcolumn:ncol(Routine)]
    
    for (i in startyearcolumn : ncol(RTPop.Country)){
        idx <- which(RTPop.Country[[i]] < 0) # if the number of vaccinated > naive population, then the result will be a negative number --> convert to 0
        RTPop.Country[[i]][idx] <- 0
    }
    return(RTPop.Country)
}

## ===== Read File =====
Distinct_Files <- FALSE # if you want to make separate files for each country --> change to TRUE
Naive_Folder <- 'Generate/Susceptible_Population/' # Folder contains NaivePop csv file
NaivePop.Origin <- read.csv(paste0(Naive_Folder, 'NaivePop_All.csv'))
Vaccine_Folder <- 'Data/Vaccine_Coverage/' # Folder contains Vaccine coverage files
Vaccine.Origin <- read.csv(paste0(Vaccine_Folder, 'coverage_201710gavi-6_je-routine-gavi.csv'))

## ===== Processing data for each country =====
Vaccine.Origin$country_code <- as.character(Vaccine.Origin$country_code)
countries_vec <- unique(Vaccine.Origin$country_code)

for (idx_country in 1 : length(countries_vec)){ # Run for each country
    country_iso_code <- countries_vec[idx_country]
    cat('========== Processing', country_iso_code, '==========\n')
    ## Take index of row of the country_iso_code in Vaccine
    idx_vaccine_row <- grep(country_iso_code, Vaccine.Origin$country_code)
    Vaccine.Country <- Vaccine.Origin[idx_vaccine_row, c(6, 8, 13)] # only take isocode, year, coverage
    
    ## Take index of row of the country_iso_code in NaivePop --> Use grep function because some regions IND.Low, IND.High is also belong to IND
    idx_country_row <- grep(country_iso_code, NaivePop.Origin$country)
    NaivePop.Country <- NaivePop.Origin[idx_country_row, ]
    
    ## Preprocess
    startyearcolumn <- 4 # See the input information in defined functions
    regions <- unique(NaivePop.Country$country) # Take the subnational regions (or national region) of the selected country
    
    ## Running
    if (length(regions) == 1){ # only 1 endemic region in a country
        # Find number of vaccinated people, then will be used in the next line of code
        Vaccinated_Routine <- create_vaccinated_rountine_df(NaivePop.Country, Vaccine.Country, startyearcolumn, portion_vaccinated = portion_vaccinated_run)
        # Find Susceptible people in Routine = Susceptible in Naive - Vaccinated people
        Susceptible_Routine <- create_susceptible_rountine_df(NaivePop.Country, Vaccinated_Routine, startyearcolumn)  
    }else{
        # Calculating for each subnational regions --> row bind to the national dataframe
        Vaccinated_Routine_list <- list()
        for (i in 1 : length(regions)){
            subregion <- as.character(regions[i])
            cat('===== Processing', subregion, '=====\n')
            idx.subregion <- which(NaivePop.Country$country == subregion)
            NaivePop.Subregion <- NaivePop.Country[idx.subregion, ]
            Vaccinated_Routine <- create_vaccinated_rountine_df(NaivePop.Subregion, Vaccine.Country, startyearcolumn, portion_vaccinated = portion_vaccinated_run)
            Vaccinated_Routine_list[[i]] <- Vaccinated_Routine
        }
        Vaccinated_Routine <- do.call('rbind', Vaccinated_Routine_list) # combine into 1 country
        Susceptible_Routine <- create_susceptible_rountine_df(NaivePop.Country, Vaccinated_Routine, startyearcolumn)
    }
    
    if (Distinct_Files){
        filename_sus <- paste0('RoutinePop_', country_iso_code, '.csv') # name the file will be saved
        filename_vac <- paste0('RoutineVac_', country_iso_code, '.csv') # name the file will be saved
        write.csv(Susceptible_Routine, file = paste0(Savepath_countries, filename_sus), row.names = FALSE)
        write.csv(Vaccinated_Routine, file = paste0(Savepath_countries_vac, filename_vac), row.names = FALSE)
    }
    
    if (idx_country == 1){
        final.df.sus <- Susceptible_Routine
        final.df.vac <- Vaccinated_Routine
    }else{
        final.df.sus <- rbind(final.df.sus, Susceptible_Routine) # row bind all countries into 1 final file
        final.df.vac <- rbind(final.df.vac, Vaccinated_Routine) # row bind all countries into 1 final file
    }
}

filename_sus <- 'RoutinePop_All.csv' # name the file will be saved
filename_vac <- 'RoutineVac_All.csv' # name the file will be saved
write.csv(final.df.sus, file = paste0(Savepath, filename_sus), row.names = FALSE)
write.csv(final.df.vac, file = paste0(Savepath_vac, filename_vac), row.names = FALSE)

cat('===== FINISH [Create_Routine_Pop.R] =====\n')