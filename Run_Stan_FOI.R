# --- NOTE ---
# This script is used to apply catalytic model and Rstan to fit the age-stratified cases data
# The result will be the FOI distribution of the countries we have data
# ---------- #

library(rstan)
library(readxl)

cat('===== START [Run_Stan_FOI.R] =====\n')

## Get directory of the script (this part only work if source the code, wont work if run directly in the console)
## This can be set manually !!! -->setwd('bla bla bla')
script.dir <- dirname(sys.frame(1)$ofile)
script.dir <- paste0(script.dir, '/')
setwd(script.dir)

## Create folder to store the result (will show warnings if the folder already exists --> but just warning, no problem)
dir.create(file.path('Generate/FOI_Distribution/'), showWarnings = TRUE)
dir.create(file.path('Generate/Rstan_Model/'), showWarnings = TRUE)
Savepath_distribution <- 'Generate/FOI_Distribution/'
Savepath_rstan_model <- 'Generate/Rstan_Model/'


# ===== Read Data and change column names to easier to process =====
DataPath <- 'Data/Age_Stratified_Cases_Data/'
data <- read_xlsx(paste0(DataPath, 'All_studies_sel_vs_endemic_area.xlsx'))
colnames(data) <- c('Endemic_region', 'Index', 'Year', 'Subnation', 'ISO', 'Age_group', 'Case_sero', 'Pop_all_age', 'Reference')

# ===== Set up parameters for Stan =====
Stan_model_name <- 'catalytic_model.stan' # Name of the saved stan file (or name that you want to save the file) 
par_iter <- 16000 # number of iteration for stan
par_warmup <-  8000 # number of warmup iteration
par_chains <- 4 # number of chains
par_cores <- 4 # number of parallel cores on the pc
par_thin <- 20 # # the distance that Rstan will store the result values (Here is for every par_thin results, it will store 1 values)
total_values <- round((par_iter - par_warmup) * par_chains / par_thin)
cat('The FOI distibution result will have approximate', total_values, 'values\n')

# # ===== Visualize 3 countries in the dataset: LAO, CHN, PHL (optional) =====
# data_short <- data[which(data$Endemic_region %in% c('LAO', 'CHN', 'PHL')), ]
# data_short$Endemic_region[which(data_short$Endemic_region == 'PHL')] <- 'PHILIPPINES'
# data_short$Endemic_region[which(data_short$Endemic_region == 'CHN')] <- 'CHINA'
# data_short$Endemic_region[which(data_short$Endemic_region == 'LAO')] <- 'LAOS'
# p <- ggplot(data = data_short, aes(x = Age_group, y = Case_sero)) +
#     geom_bar(stat = 'identity', fill = "#088CB5") +
#     facet_wrap(~Endemic_region, scale = 'free') +
#     labs(x = 'Age group', y = 'Cases') +
#     theme(axis.text = element_text(size = 15),
#           axis.text.x = element_text(angle = 90),
#           axis.title = element_text(size = 11),
#           strip.text = element_text(size = 11))
# p

# ----- Specific Region --> Specific Data -----
# specific_region_list <- c('IND.Medium') # run selected regions
specific_region_list <- unique(data$Endemic_region) # run all regions

for (idx.specific.region in 1 : length(specific_region_list)){
    specific_region <- specific_region_list[idx.specific.region]
    cat('========== Processing:', specific_region, '!!! ==========\n')
    # Extract data from the specific region
    idx.specific <- which(data$Endemic_region == specific_region)
    data.specific <- data[idx.specific, ]
    
    # Split the age group into numeric number and create lower age and upper age
    age_vec <- sapply(as.numeric(unlist(strsplit(data.specific$Age_group, '-'))), '[', 1)
    age.low <- age_vec[seq(1, length(age_vec), by = 2)]
    age.up <- age_vec[seq(2, length(age_vec), by = 2)]
    
    # Extract data for age groups
    pop.agegroup <- data.specific$Pop_all_age
    case.agegroup <- data.specific$Case_sero
    total.case <- sum(case.agegroup)
    Ngroup <- nrow(data.specific)
    
    # Create the input data for Rstan
    stan_data <- list(Ngroup = Ngroup, age_low = age.low, age_up = age.up, 
                      pop_agegroup = pop.agegroup, 
                      case_agegroup = case.agegroup,
                      total_case = total.case)
    
    # ----- Declare model for RSTAN -----
    if (!file.exists(paste0(Savepath_rstan_model, Stan_model_name))){ # if have not create STAN file, then write it
        cat('Have not create stan file yet --> Write Stan model file!\n')
        write(
            "
            data{
                int <lower = 1> Ngroup;
                vector <lower = 0, upper = 99> [Ngroup] age_low;
                vector <lower = 0, upper = 99> [Ngroup] age_up;
                vector <lower = 1> [Ngroup] pop_agegroup;
                vector <lower = 0> [Ngroup] case_agegroup;
                int <lower = 0> total_case;
            }
            
            transformed data{
                vector [Ngroup] log_case_agegroup_factorial;
                real log_total_case_factorial;
                log_total_case_factorial = lgamma(total_case + 1);
                log_case_agegroup_factorial = lgamma(case_agegroup + 1);
            }
            
            parameters{
                real <lower = 0> lambda;
                real <lower = 0, upper = 1> p;
            }
            
            transformed parameters{
                vector[Ngroup] Lp;
                vector[Ngroup] Le;
                real LMN;
                real LMNP;
                for (i in 1 : Ngroup){
                    Lp[i] = exp(-lambda * age_low[i]) - exp(-lambda*(age_up[i] + 1));
                    Le[i] = Lp[i] * pop_agegroup[i] * p;
                }
                LMN = log_total_case_factorial - sum(log_case_agegroup_factorial) + sum(case_agegroup .* log(Le / sum(Le)));
                LMNP = LMN + total_case * log(sum(Le)) - sum(Le) - log_total_case_factorial;
            }
            
            model{
                lambda ~ normal(0, 1000);
                p ~ uniform(0, 1);
                target += LMNP;
            }
            ",
            paste0(Savepath_rstan_model, Stan_model_name)
        )
    }else{
        cat('Found Stan model file!')
    }
    
    # ----- Run Rstan -----
    fit <- stan(file = paste0(Savepath_rstan_model, Stan_model_name), data = stan_data, 
                warmup = par_warmup, iter = par_iter, chains = par_chains, cores = par_cores, thin = par_thin)
    
    # ----- Resutl -----
    posterior <- extract(fit)
    saveRDS(posterior, paste0(Savepath_distribution, 'FOI_Posterior_', specific_region, '.Rds'))
}

cat('===== FINISH [Run_Stan_FOI.R] =====\n')
