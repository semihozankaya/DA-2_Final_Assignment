rm(list = ls())
folder <- c("/home/ozzy/Documents/CEU/ECBS-5208-Coding-1-Business-Analytics/Final Assignment/Data/")
library(tidyverse)

#### Unemployment by State
setwd(paste0(folder, "Raw/Unemployment/"))
une_file <- lapply(Sys.glob("*"), read_csv)
une_merged <- une_file[[1]][1]
for(i in 1:52) {
  une_merged <- merge(une_merged, une_file[[i]], by = "DATE", all = TRUE)}                   
names(une_merged) <- str_remove(names(une_merged), "UR")
une_long <- gather(une_merged, State, Unemployment, c(-DATE))

#### Per Capita Income by State
setwd(paste0(folder, "Raw/Per Capita Income/"))
inc_file <- lapply(Sys.glob("*"), read_csv)
inc_merged <- inc_file[[1]][1]
for(i in 1:51) {
  inc_merged <- merge(inc_merged, inc_file[[i]], by = "DATE", all = TRUE)
}                   
names(inc_merged) <- str_remove(names(inc_merged), "PCPI")
inc_long <- gather(inc_merged, State, Income, c(-DATE))


#### Poverty,
setwd(paste0(folder, "Raw/Poverty Measure/"))
pov_file <- lapply(Sys.glob("*"), read_csv)
pov_merged <- pov_file[[1]][1]
for(i in 1:51) {
  pov_merged <- merge(pov_merged, pov_file[[i]], by = "DATE", all = TRUE)
}                   
names(pov_merged) <- str_remove(names(pov_merged), "PUAA")
names(pov_merged) <- str_sub(names(pov_merged), 1, 2)
names(pov_merged)[1] <- "DATE"

pov_long <- gather(pov_merged, State, Poverty, c(-DATE))

#### Capital Punishment
setwd(paste0(folder, "Raw/"))
cap <- read_csv("exest.csv")
cap <- cap[10:73,]
names(cap) <- cap[1,]
cap <- cap[2:64, ]
cap <- cap[1:62,]
cap <- filter(cap, is.na(cap$`Region and jurisdiction`) != TRUE)
cap <- select(cap, -Total)
names(cap)[1] <- "States"
cap_long <- gather(cap, Year, Executions, c(-States) )

#### Crimes
crime <- read_csv("estimated_crimes_1979_2019.csv")
violent_crime <- crime %>% select(year, state_abbr, state_name, population, violent_crime)
violent_crime <- violent_crime %>% filter(is.na(state_abbr) != TRUE)

### CPI
cpi <- read_csv("CPIAUCNS.csv")

### Urbanization Rate
urban <- read_csv("urbanization.csv")

##### Cleaning Up

state_abb_name <- select(violent_crime, 2:3)
state_abb_name <- unique(state_abb_name)

inc_long <- merge(inc_long, state_abb_name, by.x = "State", by.y = "state_abbr")
une_long <- merge(une_long, state_abb_name, by.x = "State", by.y = "state_abbr")
pov_long <- merge(pov_long, state_abb_name, by.x = "State", by.y = "state_abbr")
#### Preparing for merging

inc_long$datenum <- 1900 + as.POSIXlt(inc_long$DATE, format = "%Y/%m/%d")$year 
pov_long$datenum <- 1900 + as.POSIXlt(pov_long$DATE, format = "%Y/%m/%d")$year 
une_long$datemon <- 1+ as.POSIXlt(une_long$DATE, format = "%Y/%m/%d")$mon

une_long <- une_long %>% filter(datemon == 1)
une_long$datenum <- 1900+ as.POSIXlt(une_long$DATE, format = "%Y/%m/%d")$year

cpi$datenum <- 1900+ as.POSIXlt(cpi$DATE, format = "%Y/%m/%d")$year
cpi$datemon <- 1+ as.POSIXlt(cpi$DATE, format = "%Y/%m/%d")$mon
cpi <- cpi %>% filter(datemon == 1)

names(urban) <- c("State", "Urbanization")

violent_crime <- violent_crime %>% mutate(merging = str_c(year, state_name))
inc_long <- inc_long %>% mutate(merging = str_c(datenum, state_name))
pov_long <- pov_long %>% mutate(merging = str_c(datenum, state_name))
une_long <- une_long %>% mutate(merging = str_c(datenum, state_name))
cap_long <- cap_long %>% mutate(merging = str_c(Year, States))
urban <- urban %>% mutate(Year = 2000) %>% mutate(merging = str_c(Year, State)) 
### merging

final <- merge(violent_crime, inc_long, by = "merging", all.x = TRUE)
final <- merge(final, une_long, by = "merging", all.x = TRUE)
final <- final %>% select(merging, year, state_abbr, state_name, population, violent_crime,
                          Income, Unemployment)
final <- merge(final, pov_long, by = "merging", all = TRUE)
final <- final %>% select(merging, year, state_abbr, state_name.x, population, violent_crime,
                          Income, Unemployment, Poverty)
final <- merge(final, cpi, by.x = "year", by.y = "datenum", all.x = TRUE)
final <- final %>% select(merging, year, state_abbr, state_name.x, population, violent_crime,
                          Income, Unemployment, Poverty, CPIAUCNS)
final <- merge(final, cap_long, by = "merging", all.x = TRUE) 
final <- final %>% select(merging, year, state_abbr, state_name.x, population, violent_crime,
                          Income, Unemployment, Poverty, CPIAUCNS, Executions)
final <- merge(final, urban, by = "merging", all.x = TRUE) 


final <- final %>% select(year, state_abbr, state_name.x, population, violent_crime, Income, 
                          Unemployment, Poverty, CPIAUCNS, Executions, Urbanization)

setwd(paste0(folder, "Clean/"))
write_csv(final, "dataset.csv")
