library(DBI)
library(RSQLite)

lan_folder <- "//sfp.idir.bcgov/S140/S40203/WFC AEB/General/2 SCIENCE - Invasives/SPECIES/Smallmouth Bass/Cultus lake/"

con <- DBI::dbConnect(RSQLite::SQLite(), paste0("./output/CultusData.sqlite"))

dbDisconnect(con)
