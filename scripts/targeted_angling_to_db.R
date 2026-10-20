library(tidyverse)
library(DBI)
library(RSQLite)
library(openxlsx)
library(dplyr)
source("scripts/utils/col_types_f.R")

lan_folder = "//sfp.idir.bcgov/S140/S40203/WFC AEB/General/2 SCIENCE - Invasives/SPECIES/Smallmouth Bass/Cultus lake/"
db_filepath = "./output/CultusData.sqlite"

con<-dbConnect(RSQLite::SQLite(), db_filepath,extended_types = TRUE)

DBI::dbListTables(con)

angling = openxlsx::read.xlsx(paste0(lan_folder,"DATA FILES Cultus SMB/Targeted Angling/2026/2026_TargetedAngling.xlsx"), sheet= "Data") |> 
  janitor::clean_names() |> 
  dplyr::mutate(date = as.character(as.Date(as.numeric(date), origin = "1899-12-31"))
  ) |> 
  mutate(rowID = row_number())

col_types<-get_col_types(angling)

sur_col_types_sql <- col_types |>
  dplyr::mutate(key_status = case_when(
    col_name %in% c("rowID") ~ "KEY",
    TRUE ~ ""
  )) |>
  dplyr::reframe(a = paste0(col_name, " ", stringr::str_to_upper(sqlite_type), " ", key_status))




sql = paste0("CREATE TABLE IF NOT EXISTS anglingBasok (
       ",paste0(sur_col_types_sql$a,collapse = ",\n"),
             ",\nPRIMARY KEY (rowID))")
dbExecute(con, sql)
dbWriteTable(conn = con, "anglingBasok", angling, row.names = F, append = T)
dbListTables(con)

query <- "SELECT * FROM anglingBasok"
dbExecute(con = con, query)
# querydelete<-"DROP TABLE electro"
# dbExecute(con, querydelete)
result <- dbSendQuery(conn = con, query)
df<-fetch(result, -1)
df
dbClearResult(result)    