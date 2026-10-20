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
tempA = openxlsx::read.xlsx(paste0(lan_folder,"DATA FILES Cultus SMB/Temperature/CLASSTempSummary2024.xlsx"), sheet = "2024Summary") |> 
  janitor::clean_names() |> 
  dplyr::mutate(date = as.character(as.Date(as.numeric(date), origin = "1899-12-31")),
                time = hms::as_hms(as.numeric(time) * 86400)
  ) |>
  mutate(across(everything(), as.character))

tempB = openxlsx::read.xlsx(paste0(lan_folder,"DATA FILES Cultus SMB/Temperature/CLASS Field Sheet 2025.xlsx"), sheet = "2025Summary") |> 
  janitor::clean_names() |> 
  dplyr::mutate(date = as.character(as.Date(as.numeric(date), origin = "1899-12-31")),
                time = hms::as_hms(as.numeric(time) * 86400)
  ) |>
  mutate(across(everything(), as.character))

classTemp = bind_rows(tempA, tempB) |> 
  mutate(rwoID = row_number()) |> 
  distinct()




col_types<-get_col_types(classTemp)

sur_col_types_sql <- col_types |>
  dplyr::mutate(key_status = case_when(
    col_name %in% c("rowID") ~ "KEY",
    TRUE ~ ""
  )) |>
  dplyr::reframe(a = paste0(col_name, " ", stringr::str_to_upper(sqlite_type), " ", key_status))




sql = paste0("CREATE TABLE IF NOT EXISTS tempClass (
       ",paste0(sur_col_types_sql$a,collapse = ",\n"),
             ",\nPRIMARY KEY (electro_id))")
dbExecute(con, sql)
dbWriteTable(conn = con, "tempClass", classTemp, row.names = F, append = T)
dbListTables(con)

query <- "SELECT * FROM tempClass"
dbExecute(con = con, query)
# querydelete<-"DROP TABLE electro"
# dbExecute(con, querydelete)
result <- dbSendQuery(conn = con, query)
df<-fetch(result, -1)
df
dbClearResult(result)   

shoreTemp = openxlsx::read.xlsx(paste0(lan_folder,"DATA FILES Cultus SMB/Temperature/CultusShoreTemps(SMB).xlsx")) |> 
  janitor::clean_names() |> 
  dplyr::mutate(date = as.character(as.Date(as.numeric(date), origin = "1899-12-31"))
  ) |>
  mutate(across(everything(), as.character)) |> 
  mutate(rowID = row_number())

col_types<-get_col_types(shoreTemp)

sur_col_types_sql <- col_types |>
  dplyr::mutate(key_status = case_when(
    col_name %in% c("rowID") ~ "KEY",
    TRUE ~ ""
  )) |>
  dplyr::reframe(a = paste0(col_name, " ", stringr::str_to_upper(sqlite_type), " ", key_status))




sql = paste0("CREATE TABLE IF NOT EXISTS shoreTemp (
       ",paste0(sur_col_types_sql$a,collapse = ",\n"),
             ",\nPRIMARY KEY (rowID))")
dbExecute(con, sql)
dbWriteTable(conn = con, "shoreTemp", shoreTemp, row.names = F, append = T)
dbListTables(con)

query <- "SELECT * FROM shoreTemp"
dbExecute(con = con, query)
# querydelete<-"DROP TABLE electro"
# dbExecute(con, querydelete)
result <- dbSendQuery(conn = con, query)
df<-fetch(result, -1)
df
dbClearResult(result)   
