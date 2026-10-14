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
creel_main = openxlsx::read.xlsx(paste0(lan_folder,"DATA FILES Cultus SMB/2023-2026 Cultus Lake SMB MASTER Creel.xlsx"), sheet = "Main Data") |> 
  janitor::clean_names() |> 
  dplyr::mutate(date = as.character(as.Date(as.numeric(date), origin = "1899-12-31")),
                time = format(as.POSIXct(time * 86400, origin = "1899-12-30", tz = "America/Vancouver"),
                  format = "%H:%M:%S"
                )
  ) |>
  arrange(date) |> 
  mutate(date_group = cumsum(date != lag(date, default = first(date)))) |> 
  group_by(date_group) |> 
  mutate(survey_number = row_number()) |>  
  ungroup() |> 
  select(-date_group) |> 
  mutate(date = as.character(date)) |> 
  mutate(time = hms(time)) |> 
  group_by(time) |> 
  mutate(
    time = if_else(row_number() > 1, time + minutes(5) * (row_number() - 1), time)
  ) |> 
  ungroup() |> 
  mutate(time = as.character(time)) |> 
  mutate(
    shift = str_remove(shift, "^\\d+: "),
    shift_end = sub(".*-", "", shift),
    shift_start = sub("-.*", "", shift),
    shift_start = if_else(str_detect(shift_start, "^\\d{1,2}:\\d{2}$"), paste0(shift_start, ":00"), shift_start),
    shift_end = if_else(str_detect(shift_end, "^\\d{1,2}:\\d{2}$"), paste0(shift_end, ":00"), shift_end),
    shift_start_time = hms::parse_hms(shift_start),
    shift_end_time = hms::parse_hms(shift_end),
    hours_worked = as.numeric(difftime(shift_end_time, shift_start_time, units = "hours"))
  ) |> 
  mutate(shift_start_time = as.character(paste(date, shift_start_time)),
         shift_end_time = as.character(paste(date, shift_end_time))) |> 
  dplyr::rename(
    aware_smb_illegal_introduction =
      are_you_aware_that_smb_were_illegally_introduced_into_cultus_lake,
    
    aware_live_fish_bait_restrictions =
      are_you_aware_that_the_movement_of_live_fish_and_the_use_of_live_bait_are_prohibited_in_bc,
    
    aware_dont_let_it_loose =
      are_you_aware_of_the_don_t_let_it_loose_practices,
    
    aware_clean_drain_dry =
      are_you_aware_of_the_clean_drain_dry_practices,
    
    interviewed_this_year =
      interviewed_this_year_at_this_location,
    
    annual_fishing_frequency =
      yearly_fishing_freq_at_this_location,
    
    location_reason =
      why_this_location,
    
    preferred_catch_species =
      preferred_catch_spp,
    
    fishing_rating =
      rate_fishing
  ) |>
  mutate(across(everything(), as.character))


col_types<-get_col_types(creel_main)

sur_col_types_sql <- col_types |>
  dplyr::mutate(key_status = case_when(
    col_name %in% c("date,survey_number") ~ "KEY",
    TRUE ~ ""
  )) |>
  dplyr::reframe(a = paste0(col_name, " ", stringr::str_to_upper(sqlite_type), " ", key_status))


sql = paste0("CREATE TABLE IF NOT EXISTS creelMain (
       ",paste0(sur_col_types_sql$a,collapse = ",\n"),
             ",\nPRIMARY KEY (date,survey_number))")
dbExecute(con, sql)
dbWriteTable(conn = con, "creelMain", creel_main, row.names = F, append = T)
dbListTables(con)

query <- "SELECT * FROM creelMain"
dbExecute(con = con, query)
#querydelete<-"DROP TABLE surveyData"
result <- dbSendQuery(conn = con, query)
df<-fetch(result, -1)
df
dbClearResult(result)             

creel_demo = openxlsx::read.xlsx(paste0(lan_folder,"DATA FILES Cultus SMB/2023-2026 Cultus Lake SMB MASTER Creel.xlsx"), sheet = "Demographic Data") |> 
  janitor::clean_names() |> 
  dplyr::mutate(
    date_time = as.POSIXct(
      as.numeric(date_time) * 86400,
      origin = "1899-12-30",
      tz = "America/Vancouver"
    ),
    date = as.Date(date_time),
    time = format(date_time, "%H:%M:%S")
  ) |>
  dplyr::select(-date_time) |> 
  arrange(date) |> 
  mutate(date_group = cumsum(date != lag(date, default = first(date)))) |> 
  group_by(date_group) |> 
  mutate(survey_number = row_number()) |>  
  ungroup() |> 
  select(-date_group) |> 
  mutate(date = as.character(date)) |> 
  mutate(time = hms(time)) |> 
  group_by(time) |> 
  mutate(
    time = if_else(row_number() > 1, time + minutes(5) * (row_number() - 1), time)
  ) |> 
  ungroup() |> 
  mutate(time = as.character(time)) |> 
  dplyr::mutate(across(everything(), as.character)) |> 
  dplyr::relocate(date, time, .after = year)


col_types<-get_col_types(creel_demo)

sur_col_types_sql <- col_types |>
  dplyr::mutate(key_status = case_when(
    col_name %in% c("date,survey_number") ~ "KEY",
    TRUE ~ ""
  )) |>
  dplyr::reframe(a = paste0(col_name, " ", stringr::str_to_upper(sqlite_type), " ", key_status))


sql = paste0("CREATE TABLE IF NOT EXISTS creelDemo (
       ",paste0(sur_col_types_sql$a,collapse = ",\n"),
             ",\nPRIMARY KEY (date,survey_number))")
dbExecute(con, sql)
dbWriteTable(conn = con, "creelDemo", creel_demo, row.names = F, append = T)
dbListTables(con)

query <- "SELECT * FROM creelDemo"
dbExecute(con = con, query)
#querydelete<-"DROP TABLE surveyData"
result <- dbSendQuery(conn = con, query)
df<-fetch(result, -1)
df
dbClearResult(result)  


creel_fish = openxlsx::read.xlsx(paste0(lan_folder,"DATA FILES Cultus SMB/2023-2026 Cultus Lake SMB MASTER Creel.xlsx"), sheet = "Fish Data") |> 
  janitor::clean_names() |> 
  dplyr::mutate(
    date_time = as.POSIXct(
      as.numeric(date_time) * 86400,
      origin = "1899-12-30",
      tz = "America/Vancouver"
    ),
    date = as.Date(date_time),
    time = format(date_time, "%H:%M:%S")
  ) |>
  dplyr::select(-date_time) |> 
  arrange(date) |> 
  mutate(date_group = cumsum(date != lag(date, default = first(date)))) |> 
  group_by(date_group) |> 
  mutate(survey_number = row_number()) |>  
  ungroup() |> 
  select(-date_group) |> 
  mutate(date = as.character(date)) |> 
  mutate(time = hms(time)) |> 
  group_by(time) |> 
  mutate(
    time = if_else(row_number() > 1, time + minutes(5) * (row_number() - 1), time)
  ) |> 
  ungroup() |> 
  mutate(time = as.character(time)) |> 
  dplyr::mutate(across(everything(), as.character)) |> 
  dplyr::relocate(date, time, .after = year)


col_types<-get_col_types(creel_fish)

sur_col_types_sql <- col_types |>
  dplyr::mutate(key_status = case_when(
    col_name %in% c("date,survey_number") ~ "KEY",
    TRUE ~ ""
  )) |>
  dplyr::reframe(a = paste0(col_name, " ", stringr::str_to_upper(sqlite_type), " ", key_status))


sql = paste0("CREATE TABLE IF NOT EXISTS creelFish (
       ",paste0(sur_col_types_sql$a,collapse = ",\n"),
             ",\nPRIMARY KEY (date,survey_number))")
dbExecute(con, sql)
dbWriteTable(conn = con, "creelFish", creel_fish, row.names = F, append = T)
dbListTables(con)

query <- "SELECT * FROM creelFish"
dbExecute(con = con, query)
#querydelete<-"DROP TABLE surveyData"
result <- dbSendQuery(conn = con, query)
df<-fetch(result, -1)
df
dbClearResult(result)  


creel_ice = openxlsx::read.xlsx(paste0(lan_folder,"DATA FILES Cultus SMB/2023-2026 Cultus Lake SMB MASTER Creel.xlsx"), sheet = "ICE") |> 
  janitor::clean_names() |> 
  dplyr::mutate(date = as.character(as.Date(as.numeric(date), origin = "1899-12-31")),
                time = format(as.POSIXct(time * 86400, origin = "1899-12-30", tz = "America/Vancouver"),
                              format = "%H:%M:%S"
                )
  ) |>
  mutate(date = as.character(date)) |> 
  mutate(time = hms(time)) |> 
  group_by(time) |> 
  mutate(
    time = if_else(row_number() > 1, time + minutes(5) * (row_number() - 1), time)
  ) |> 
  ungroup() |> 
  mutate(time = as.character(time)) |> 
  dplyr::mutate(across(everything(), as.character)) |> 
  dplyr::relocate(date, time, .after = year)

col_types<-get_col_types(creel_ice)

sur_col_types_sql <- col_types |>
  dplyr::mutate(key_status = case_when(
    col_name %in% c("date,time") ~ "KEY",
    TRUE ~ ""
  )) |>
  dplyr::reframe(a = paste0(col_name, " ", stringr::str_to_upper(sqlite_type), " ", key_status))


sql = paste0("CREATE TABLE IF NOT EXISTS creelICE (
       ",paste0(sur_col_types_sql$a,collapse = ",\n"),
             ",\nPRIMARY KEY (date,time))")
dbExecute(con, sql)
dbWriteTable(conn = con, "creelICE", creel_ice, row.names = F, append = T)
dbListTables(con)

query <- "SELECT * FROM creelICE"
dbExecute(con = con, query)
#querydelete<-"DROP TABLE surveyData"
result <- dbSendQuery(conn = con, query)
df<-fetch(result, -1)
df
dbClearResult(result)  

dbDisconnect(con)
