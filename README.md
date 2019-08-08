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


## Core functions
### Step 1: Run Rstan
Create (or run the given) Rstan model to fit the catalytic model to the given age-stratified cases data.

**Input**
- Age-stratified cases data in xls format is stored in **_Data/Age_Stratified_Cases_Data/_** folder.
- Rstan model script (if already given) is stored in **_Generate/Rstan_Model/_** folder. 

**Output**
- The stan result for each regions will be stored in **_Generate/FOI_Distribution/_** folder. This result will not only contain FOI distribution (as lambda component in the result), but also other information of stan.
- Rstan model script (if there is not a model in **_Generate/Rstan_Model/_** folder) will be stored in that folder.

**Function**
- **Run_Stan_FOI**: Run this script to fit the model

### Step 2: Create Susceptible population for Naive scenario
Create Susceptible population at each age in csv file in the Naive (no vaccination) scenario. The susceptible population in this scenario is quite similar with the original population given by VIMC. However, for some special countries (like CHN, PAK, ...) in which the endemic area are subnational regions. In these cases we need to adjust the population by using population at risk information from WHO or previous studies. This script also provided the option to save the susceptible population by countries seperately.

**Input**
- Population data given by VIMC is stored in **_Data/Population/_** folder.
- Population at risk information is writen in the script

**Output**
- **Naive_Pop.csv** is produced in **_Generate/Susceptible_Population/_** folder.
- Susceptible population for each country **Naive_Pop_<ISO>.csv** are produced in the subfoler **_Generate/Susceptible_Population/Countries_**. (If you choose the option to save seperately)

**Function**
- **Create_Naive_Pop**: Create susceptible population in the naive scenario

### Step 3: Create Susceptible population for Routine scenario
Create Susceptible population at each age in csv file in the Routine scenario. Routine scenario means only people at age 0 will receive vaccination. The portion of people that will be vaccinated is described in the vaccine coverage file from VIMC. The procedure of this step is to calculate number of vaccinated people in routine scenario firstly. Then find the remaining susceptible population. This will equal naive population (susceptible population when there is no vaccination) from Step 2 minus number of vaccinated people in routine scenario. 

**Input**
- Vaccine coverage given by VIMC is stored in **_Data/Vaccine_Coverage/_** folder.
- Naive population produced in Step 2 (stored in **_Generate/Susceptible_Population/_** folder).

**Output**
- **Routine_Pop.csv** is produced in **_Generate/Susceptible_Population/_** folder.
- Susceptible population for each country **Routine_Pop_<ISO>.csv** are produced in the subfoler **_Generate/Susceptible_Population/Countries_**. (If you choose the option to save seperately)

**Function**
- **Create_Routine_Pop**: Create susceptible population in the routine scenario (after the vaccination)

### Step 4: Create Susceptible population for Campaign scenario
Create Susceptible population at each age in csv file in the Campaign scenario. Campaign scenario means they will conduct Routine vaccination first, then perform a massive vaccination for the remaining susceptible people in the selected age range (normally from age 0 to age 14). The portion of people that will be vaccinated is described in the vaccine coverage file from VIMC. The procedure of this step is to calculate number of vaccinated people in routine scenario firstly. Then find the remaining susceptible population and calculate the vaccinated people in the campaign scenario. Finally we will the total remaining susceptible people, which will equal naive population (susceptible population when there is no vaccination) from Step 2 minus number of vaccinated people found as above. 

**Input**
- Vaccine coverage given by VIMC is stored in **_Data/Vaccine_Coverage/_** folder.
- Naive population produced in Step 2 (stored in **_Generate/Susceptible_Population/_** folder).

**Output**
- **Campaign_Pop.csv** is produced in **_Generate/Susceptible_Population/_** folder.
- Susceptible population for each country **Campaign_Pop_<ISO>.csv** are produced in the subfoler **_Generate/Susceptible_Population/Countries_**. (If you choose the option to save seperately)

**Function**
- **Create_Campaign_Pop**: Create susceptible population in the campaign scenario (after the vaccination)