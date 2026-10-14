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

#get the file and shorten the names
bass_electro = openxlsx::read.xlsx(paste0(lan_folder,"DATA FILES Cultus SMB/2023-2026 Cultus Lake SMB MASTER Electrofishing.xlsx"), sheet = "All Bass") |> 
  janitor::clean_names() |> 
  dplyr::mutate(date = as.character(as.Date(as.numeric(date), origin = "1899-12-31"))
  ) |>
  mutate(across(everything(), as.character)) |> 
  select(-c(column1)) |> 
  mutate(electro_id = row_number())


col_types<-get_col_types(bass_electro)

sur_col_types_sql <- col_types |>
  dplyr::mutate(key_status = case_when(
    col_name %in% c("electro_id") ~ "KEY",
    TRUE ~ ""
  )) |>
  dplyr::reframe(a = paste0(col_name, " ", stringr::str_to_upper(sqlite_type), " ", key_status))




sql = paste0("CREATE TABLE IF NOT EXISTS electro (
       ",paste0(sur_col_types_sql$a,collapse = ",\n"),
             ",\nPRIMARY KEY (electro_id))")
dbExecute(con, sql)
dbWriteTable(conn = con, "electro", bass_electro, row.names = F, append = T)
dbListTables(con)

query <- "SELECT * FROM electro"
dbExecute(con = con, query)
# querydelete<-"DROP TABLE electro"
# dbExecute(con, querydelete)
result <- dbSendQuery(conn = con, query)
df<-fetch(result, -1)
df
dbClearResult(result)    

floy_tags = openxlsx::read.xlsx(paste0(lan_folder,"DATA FILES Cultus SMB/2023-2026 Cultus Lake SMB MASTER Electrofishing.xlsx"), sheet = "Floy Tags") |> 
  janitor::clean_names() |> 
  dplyr::mutate(date = as.character(as.Date(as.numeric(date), origin = "1899-12-31"))
  ) |>
  mutate(across(everything(), as.character))

col_types<-get_col_types(floy_tags)

sur_col_types_sql <- col_types |>
  dplyr::mutate(key_status = case_when(
    col_name %in% c("tag_code") ~ "KEY",
    TRUE ~ ""
  )) |>
  dplyr::reframe(a = paste0(col_name, " ", stringr::str_to_upper(sqlite_type), " ", key_status))





sql = paste0("CREATE TABLE IF NOT EXISTS floy (
       ",paste0(sur_col_types_sql$a,collapse = ",\n"),
             ",\nPRIMARY KEY (tag_code))")
dbExecute(con, sql)
dbWriteTable(conn = con, "floy", floy_tags, row.names = F, append = T)
dbListTables(con)

query <- "SELECT * FROM floy"
dbExecute(con = con, query)
#querydelete<-"DROP TABLE surveyData"
result <- dbSendQuery(conn = con, query)
df<-fetch(result, -1)
df
dbClearResult(result)    
