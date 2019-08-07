# --- NOTE ---
## This file is used to create susceptible population in the naive scenario (no vaccination) for all countries and regions
## Can create distinct file for each country and combine into 1 file
# ---------- #

cat('===== START [Create_Naive_Pop.R] =====\n')

## Get directory of the script (this part only work if source the code, wont work if run directly in the console)
## This can be set manually !!! -->setwd('bla bla bla')
script.dir <- dirname(sys.frame(1)$ofile)
script.dir <- paste0(script.dir, '/')
setwd(script.dir)

## Create folder to store the result (will show warnings if the folder already exists --> but just warning, no problem)
dir.create(file.path('Generate/Susceptible_Population/'), showWarnings = TRUE)
Savepath <- 'Generate/Susceptible_Population/'
## Create folder in the case you want to save the population data for each country seperately
dir.create(file.path('Generate/Susceptible_Population/Countries/'), showWarnings = TRUE)
Savepath_countries <- 'Generate/Susceptible_Population/Countries/'

## ----- Read data -----
Distinct_Files <- FALSE # if you want to make separate files for each country --> change to TRUE
Folder <- 'Data/Population/'
NaivePop.Origin <- read.csv(paste0(Folder, 'naive_pop_1950_2100.csv')) # Population data from VIMC
colnames(NaivePop.Origin) <- c('country_code', colnames(NaivePop.Origin)[2 : ncol(NaivePop.Origin)])
NaivePop.Origin$country_code <- as.character(NaivePop.Origin$country_code) # Convert from factor to character

## ----- Create data.frame of additional infomation ----- 
# List of 16 lists for 16 countries we have data
# This list to indicate which countries have subnation endemic areas (IND, PAK, IDN, BTN, CHN) --> Adjust population for these countries
# Adjusting by calculating the proportion between population of subnation with national population in the same given year
# Then use that proportion to interpolate subnational population for other year (or until the next year we have data)
All_country_pop_info = data.frame(
    matrix(
        c("IND", list(c(53100000, 366400000, 428600000)), list(c("X2008", "X2008", "X2008")), F,
          "PAK", 30400000, "X2000", T,
          "KHM", NA, NA, F,
          "IDN", list(c(187200000, 50400000)), list(c("X2005", "X2010")), F, 
          "LAO", NA, NA, F,
          "VNM", NA, NA, F,
          "BGD", NA, NA, F,
          "NPL", NA, NA, F,
          "BTN", 400000, "X2005", T,
          "PRK", NA, NA, F,
          "MMR", NA, NA, F,
          "PNG", NA, NA, F,
          "LKA", NA, NA, F,
          "TLS", NA, NA, F,
          "CHN", 1302300000, "X2010", T,
          "PHL", NA, NA, F),
        ncol = 4, byrow = T, 
        dimnames = list(1:16, c("country", "pop", "year", "subnation"))
    )
)

## ----- Processing data for each country -----
countries_vec <- unique(NaivePop.Origin$country_code)

for (idx_country in 1 : length(countries_vec)){ # Run for each country
    country_iso_code <- countries_vec[idx_country]
    cat('========== Processing', country_iso_code, '==========\n')
    idx_addition <- which(All_country_pop_info$country %in% country_iso_code) #  index of the country in the All_country_pop_info dataframe
    idx_row_country <- which(NaivePop.Origin$country == country_iso_code) # index of country in the population dataframe 
    
    ## Check if the country is standard (national) or special (subnational) region
    ## Standard countries --> nothing special --> filter as normal
    country.df <- NaivePop.Origin[idx_row_country, ]
    
    ## Special countries --> do not mess up these ones !!! Do with all your cafefulness
    # Check if the All_country_pop_info$pop is not NA --> Subnational regions
    if (all(!is.na(All_country_pop_info$pop[[idx_addition]]))){
        ## Take the year in All_country_pop_info and find the index of these years in the population dataframe 
        XYear <- All_country_pop_info$year[[idx_addition]]
        idx_col_year <- rep(0, length(XYear))
        for (i in 1 : length(idx_col_year)){
            idx_col_year[i] <- which(colnames(NaivePop.Origin) %in% XYear[i])    
        }
        
        ## Find population in that year
        year.pop <- rep(0, length(XYear))
        for (i in 1 : length(year.pop)){
            year.pop[i] <- sum(country.df[[idx_col_year[i]]])
        }
        
        ## Find proportion of pop for specific year
        proportion <- rep(0, length(XYear))
        for (i in 1 : length(proportion)){
            proportion[i] <- All_country_pop_info$pop[[idx_addition]][i] / year.pop[i]
        }
        
        ## Create Column for new dataframe of specific contry
        if (length(All_country_pop_info$pop[[idx_addition]]) == 1){ ## TRUE --> only 1 subnational region 
            country.col <- country.df$country_code[1]
        }else{ ## FALSE --> many subnational regions --> divide into Low/Medium/High regions
            # Name these subnation regions as format <ISO>.<Low/Medium/High>
            if (length(All_country_pop_info$pop[[idx_addition]]) == 2){
                country.col <- paste0(country.df$country_code[1], '.', c('Low', 'High'))
            }else{
                country.col <- paste0(country.df$country_code[1], '.', c('Low', 'Medium', 'High'))
            }
        }
        
        # Create new dataframe for each subnation region --> then row bind it into 1 national dataframe
        country.col <- rep(country.col, each = nrow(country.df))
        age_from.col <- rep(country.df$age_from, length(proportion))
        age_to.col <- rep(country.df$age_to, length(proportion))
        for (i in 1 : length(proportion)){
            temp <- country.df[ , c(4 : ncol(country.df))] * proportion[i]
            if (i == 1){
                pop.col <- temp
            }else{
                pop.col <- rbind(pop.col, temp)
            }
            rm(temp)
        }
        country.df <- data.frame(country = country.col,
                                 age_from = age_from.col,
                                 age_to = age_to.col)
        country.df <- cbind(country.df, pop.col)
    }
    
    # Rename columns to match with other dataframes
    colnames(country.df) <- c('country', colnames(NaivePop.Origin)[2 : ncol(NaivePop.Origin)])
    
    # Save file
    if(Distinct_Files){ # if Distinct_Files == TRUE --> save separate files
        filename <- paste0('NaivePop_', country_iso_code, '.csv') # name the file will be saved
        write.csv(country.df, file = paste0(Savepath_countries, filename), row.names=FALSE)
    }
    if (idx_country == 1){
        final.df <- country.df
    }else{
        final.df <- rbind(final.df, country.df)
    }
}
filename <- 'NaivePop_All.csv' # name the file will be saved
write.csv(final.df, file = paste0(Savepath, filename), row.names=FALSE)

cat('===== FINISH [Create_Naive_Pop.R] =====\n')