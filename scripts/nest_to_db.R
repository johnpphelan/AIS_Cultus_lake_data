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

nests = openxlsx::read.xlsx(paste0(lan_folder,"DATA FILES Cultus SMB/2023-2026 Cultus Lake SMB MASTER Nest Surveys.xlsx"), sheet = "Nest Surveys") |> 
  janitor::clean_names() |> 
  dplyr::mutate(date = as.Date(as.numeric(date), origin = "1899-12-31"),
                start_time = hms::as_hms(as.numeric(start_time) * 86400),
                end_time   = hms::as_hms(as.numeric(end_time) * 86400)
                ) 
  
nests <- nests |> 
  mutate(date = as.character(date),
         start_time = as.character(start_time),
         end_time = as.character(end_time)) |> 
  mutate(nestID = row_number())


col_types<-get_col_types(nests)
  
sur_col_types_sql <- col_types |>
  dplyr::mutate(key_status = case_when(
    col_name %in% c("nestID") ~ "KEY",
    TRUE ~ ""
  )) |>
  dplyr::reframe(a = paste0(col_name, " ", stringr::str_to_upper(sqlite_type), " ", key_status))


sql = paste0("CREATE TABLE IF NOT EXISTS nestRaw (
       ",paste0(sur_col_types_sql$a,collapse = ",\n"),
             ",\nPRIMARY KEY (nestID))")
dbExecute(con, sql)
dbWriteTable(conn = con, "nestRaw", nests, row.names = F, append = T)
dbListTables(con)

query <- "SELECT * FROM nestRaw"
dbExecute(con = con, query)
#querydelete<-"DROP TABLE surveyData"
result <- dbSendQuery(conn = con, query)
df<-fetch(result, -1)
df
dbClearResult(result)             