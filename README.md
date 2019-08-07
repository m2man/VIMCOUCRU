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
2. 


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