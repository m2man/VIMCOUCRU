# VIMCOUCRU INSTRUCTION

## Summary
This project is to apply catalytic model to fit age-stratified cases data to estimate the Force of infection (FOI) distribution of Japanese Encephalitis in endemic area (VIMC supported countries). Then using the vaccine coverage data to generate burden as given template. This project is created by R programming language.

The project is organized as following:
1. **_Script_**: Entire code files for the project
2. **_Data_** folder: Contains data that is necessary to run the script
3. **_Generate_** folder: Contains the result after running the script

#### SUPPORTING LIBRARY
Need to install the following libraries: rstan, readxl

## Workflow
1. Run Rstan to fit the catalytic model to age-stratified cases data
2. Create Susceptible population for the Naive (No vaccination) scenario
3. Create Susceptible population for the Routine scenario
4. Create Susceptible population for the Campaign scenario
5. Create Burden (Cases, Deaths, DALYs) for each scenario (MeanBurden)
6. (Optional) Create Burden (Cases, Deaths, DALYs) for each scenario (MeanFOI)
7. Create Burden STOCHASTIC (Cases, Deaths, DALYs) for each scenario
8. Fill the Burden result to given template

## Core functions
### Step 1: Run Rstan
Create (or run the given) Rstan model to fit the catalytic model to the given age-stratified cases data.

**Input**
- Age-stratified cases data in xls format is stored in **_Data/Age_Stratified_Cases_Data/_** folder.
- Rstan model script (if already given) is stored in **_Generate/Rstan_Model/_** folder. 

**Output**
- The stan result for each regions, named **FOI_distribution_[Region].Rds**, will be stored in **_Generate/FOI_Distribution/_** folder. This result will not only contain FOI distribution (as lambda component in the result), but also other information of stan.
- Rstan model script (if there is not a model in **_Generate/Rstan_Model/_** folder) will be stored in that folder.

**Function**
- **Run_Stan_FOI**: Run this script to fit the model

### Step 2: Create Susceptible population for Naive scenario
Create Susceptible population at each age in csv file in the Naive (no vaccination) scenario. The susceptible population in this scenario is quite similar with the original population given by VIMC. However, for some special countries (like CHN, PAK, ...) in which the endemic area are subnational regions. In these cases we need to adjust the population by using population at risk information from WHO or previous studies. This script also provided the option to save the susceptible population by countries seperately.

**Input**
- Population data given by VIMC is stored in **_Data/Population/_** folder.
- Population at risk information is writen in the script

**Output**
- **NaivePop.csv** is produced in **_Generate/Susceptible_Population/_** folder.
- Susceptible population for each country **NaivePop_[ISO].csv** are produced in the subfoler **_Generate/Susceptible_Population/Countries_**. (If you choose the option to save seperately)

**Function**
- **Create_Naive_Pop**: Create susceptible population in the naive scenario

### Step 3: Create Susceptible population for Routine scenario
Create Susceptible population at each age in csv file in the Routine scenario. Routine scenario means only people at age 0 will receive vaccination. The portion of people that will be vaccinated is described in the vaccine coverage file from VIMC. The procedure of this step is to calculate number of vaccinated people in routine scenario firstly. Then find the remaining susceptible population. This will equal naive population (susceptible population when there is no vaccination) from Step 2 minus number of vaccinated people in routine scenario. 

**Input**
- Vaccine coverage given by VIMC is stored in **_Data/Vaccine_Coverage/_** folder.
- Naive population produced in Step 2 (stored in **_Generate/Susceptible_Population/_** folder).

**Output**
- **RoutinePop.csv** is produced in **_Generate/Susceptible_Population/_** folder.
- Susceptible population for each country **RoutinePop_[ISO].csv** are produced in the subfoler **_Generate/Susceptible_Population/Countries_**. (If you choose the option to save seperately)

**Function**
- **Create_Routine_Pop**: Create susceptible population in the routine scenario (after the vaccination)

### Step 4: Create Susceptible population for Campaign scenario
Create Susceptible population at each age in csv file in the Campaign scenario. Campaign scenario means they will conduct Routine vaccination first, then perform a massive vaccination for the remaining susceptible people in the selected age range (normally from age 0 to age 14). The portion of people that will be vaccinated is described in the vaccine coverage file from VIMC. The procedure of this step is to calculate number of vaccinated people in routine scenario firstly. Then find the remaining susceptible population and calculate the vaccinated people in the campaign scenario. Finally we will the total remaining susceptible people, which will equal naive population (susceptible population when there is no vaccination) from Step 2 minus number of vaccinated people found as above. 

**Input**
- Vaccine coverage given by VIMC is stored in **_Data/Vaccine_Coverage/_** folder.
- Naive population produced in Step 2 (stored in **_Generate/Susceptible_Population/_** folder).

**Output**
- **CampaignPop.csv** is produced in **_Generate/Susceptible_Population/_** folder.
- Susceptible population for each country **CampaignPop_[ISO].csv** are produced in the subfoler **_Generate/Susceptible_Population/Countries_**. (If you choose the option to save seperately)

**Function**
- **Create_Campaign_Pop**: Create susceptible population in the campaign scenario (after the vaccination)

### Step 5: Create Burden (MeanBurden)
This step will calculate Cases, Deaths, and DALYs for each scenario of vaccination. We will use the FOI distribution from Step 1, the susceptible population for each scenario from Step 2, Step 3, Step 4. Besides, we also need the information of Life Expactation, which is provided by VIMC. Because the FOI distribution includes many values due to the simulation from Rstan, here we calculate burden based on each value, then take the mean all of them to have the final burden.

**Input**
- **NaivePop.csv**, **RoutinePop.csv**, **CampaignPop.csv**: Susceptible population for each vaccination scenario from Step 2, Step 3, Step 4
- **FOI_distribution** from Step 1
- Life Expectancy information stored in **_Data/Life_Expectation/_**

**Output**
- **Naive/Routine/Campaign_Burden_MeanBurden.Rds**: 3 lists of lists containing calculated burden for each scenario will be saved in **_Generate/Burden/_**

**Function**
- **Create_Burden_MeanBurden**: Create burden lists for each scenario. Each list describes one scenario and it includes 3 sub-lists for cases, deaths, and dalys

### Step 6: (Optinal) Create Burden (MeanFOI)
Basically, this step is optional and quite similar with Step 5. Instead calculating burden for each of all FOI values, here we take the mean of FOI distribution firstly, then calculate burden based on that average FOI value. 

**Input**
- **NaivePop.csv**, **RoutinePop.csv**, **CampaignPop.csv**: Susceptible population for each vaccination scenario from Step 2, Step 3, Step 4
- **FOI_distribution** from Step 1
- Life Expectancy information stored in **_Data/Life_Expectation/_**

**Output**
- **Naive/Routine/Campaign_Burden_MeanFOI.Rds**: 3 lists of lists containing calculated burden for each scenario will be saved in **_Generate/Burden/_**

**Function**
- **Create_Burden_MeanFOI**: Create burden lists for each scenario. Each list describes one scenario and it includes 3 sub-lists for cases, deaths, and dalys

### Step 7: Create Burden Stochastic
Basically, this step is optional and quite similar with Step 5. Instead taking the mean of all calculated burden, here we sample some of them (default is to randomly choose 200 from 1600 burden values)

**Input**
- **NaivePop.csv**, **RoutinePop.csv**, **CampaignPop.csv**: Susceptible population for each vaccination scenario from Step 2, Step 3, Step 4
- **FOI_distribution** from Step 1
- Life Expectancy information stored in **_Data/Life_Expectation/_**

**Output**
- **Naive/Routine/Campaign_Burden_Stochastic.Rds**: 3 lists of lists containing calculated burden for each scenario will be saved in **_Generate/Burden_Stochastic/_**. Each list will include 200 (default) lists for each run.

**Function**
- **Create_Burden_Stochastic**: Create burden lists for each scenario in Stochastic run.

### Step 8: Fill the burden result in given template
Fill in the template given by VIMC with burden (cases, deaths, dalys) and cohort size

**Input**
- **Naive/Routine/Campaign_Burden.Rds**: Burden list found from Step 6 (or Step 7)
- Burden template, given by VIMC, is stored at **_Data/Burden_Template/_**
- Population data, given by VIMC, is stored at **_Data/Population/_**
- Susceptible population in Naive scenario (from Step 2)

**Output**
- **Template_Naive/Routine/Campaign.csv**: 3 filled csv files will be stored at **_Generate/Template/_**

**Function**
- **Fill_Template**: Fill the burden and cohort size to the given template (from VIMC)