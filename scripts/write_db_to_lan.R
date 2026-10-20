library(tidyverse)
library(DBI)
library(RSQLite)
library(openxlsx)
library(dplyr)
source("scripts/utils/col_types_f.R")

lan_folder = "//sfp.idir.bcgov/S140/S40203/WFC AEB/General/2 SCIENCE - Invasives/SPECIES/Smallmouth Bass/Cultus lake/"
db_filepath = "./output/CultusData.sqlite"

file.copy(
  from = db_filepath,
  to = paste0(lan_folder, "DATA FILES Cultus SMB/database_clean/CultusData.sqlite"),
  overwrite = TRUE
)

con <- dbConnect(SQLite(), db_filepath)
table_names <- dbListTables(con)
excel_folder <- paste0(lan_folder, "DATA FILES Cultus SMB/database_clean/")
dir.create(excel_folder, recursive = TRUE, showWarnings = FALSE)

for (tbl in table_names) {
  dat <- dbReadTable(con, tbl)
  write.xlsx(
    dat,
    file = file.path(excel_folder, paste0(tbl, ".xlsx")),
    overwrite = TRUE
  )
}

dbDisconnect(con)


