# NOTE
# This file is used to convert new format of 201710gavi-6_dds-201710_int_pop_both.csv to old format naive_pop_1950_2100.csv 
# Check the format first before running this file

rm(list=ls())

new.format <- read.csv('Directory/to/new/format/file.csv')
old.format <- read.csv('Directory/to/old/format/file.csv')

country_list <- unique(old.format$country)

idx1 <- which(new.format$country_code %in% country_list)
t1 <- new.format[idx1, ]
rm(new.format)

idx2 <- which(t1$age_from >= 0 & t1$age_from <= 99 & t1$age_to >= 0 & t1$age_to <= 99)
t2 <- t1[idx2, ]
rm(t1)

idx3 <- which(colnames(t2) %in% colnames(old.format)[-1]) # filter columns age_from, age_to, X1950, ..., X2100
idx3 <- c(which(colnames(t2) == 'country_code'), idx3) # add column country code
idx3 <- unique(idx3)
t3 <- t2[ , idx3]
rm(t2)

write.csv(t3, file = "naive_pop_1950_2100_Dec06.csv",row.names=FALSE)
