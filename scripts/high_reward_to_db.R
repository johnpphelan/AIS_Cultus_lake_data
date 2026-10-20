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

high_reward = openxlsx::read.xlsx(paste0(lan_folder,"DATA FILES Cultus SMB/High Reward Tags/High reward tags_2026-07-30.xlsx"), sheet= "Sheet1") |> 
  janitor::clean_names() |> 
  rename(date = date_reported) |> 
  dplyr::mutate(date = as.character(as.Date(as.numeric(date), origin = "1899-12-31"))
  ) |> 
  mutate(rowID = row_number())


col_types<-get_col_types(high_reward)

sur_col_types_sql <- col_types |>
  dplyr::mutate(key_status = case_when(
    col_name %in% c("rowID") ~ "KEY",
    TRUE ~ ""
  )) |>
  dplyr::reframe(a = paste0(col_name, " ", stringr::str_to_upper(sqlite_type), " ", key_status))




sql = paste0("CREATE TABLE IF NOT EXISTS highReward (
       ",paste0(sur_col_types_sql$a,collapse = ",\n"),
             ",\nPRIMARY KEY (rowID))")
dbExecute(con, sql)
dbWriteTable(conn = con, "highReward", high_reward, row.names = F, append = T)
dbListTables(con)

query <- "SELECT * FROM highReward"
dbExecute(con = con, query)
# querydelete<-"DROP TABLE electro"
# dbExecute(con, querydelete)
result <- dbSendQuery(conn = con, query)
df<-fetch(result, -1)
df
dbClearResult(result)   

dbDisconnect(con)
