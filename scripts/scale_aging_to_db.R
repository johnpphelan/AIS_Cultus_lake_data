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

scales = openxlsx::read.xlsx(paste0(lan_folder,"DATA FILES Cultus SMB/2023-2026 Cultus Lake SMB MASTER Scale Aging.xlsx")) |> 
  janitor::clean_names() |> 
  dplyr::mutate(date = as.Date(as.numeric(date), origin = "1899-12-31"),
                start_time = hms::as_hms(as.numeric(start_time) * 86400),
                end_time   = hms::as_hms(as.numeric(end_time) * 86400)
  ) |> 
  rename(
    broodYear = `aged_brood_year_calendar_year_in_which_this_fish_was_an_egg_otoliths_originate_during_early_embryo_development_and_therefore_the_date_of_egg_fertilization_is_used_as_a_starting_point_bcpal_age_0_particularly_in_relation_to_ffsbc_hatchery_stocking_records_the_brood_year_is_given_as_a_reference_to_eliminate_confusion_between_different_aging_conventions`,
    otolithAgeMethod = `otolith_age_is_based_from_known_species_spawn_egg_fertilizationas_age_0_ex_fall_or_spring_spawners_and_known_catch_date_if_fall_spawn_species_like_ko_eb_bt_then_egg_fertilized_in_fall_months_and_then_catch_date_was_in_the_fall_age_would_be_written_as_1yo_or_2yo_or_3yo_etc_if_spring_spawning_fish_egg_fertilized_in_spring_months_is_caught_in_the_fall_months_then_age_would_be_written_as_1_2_3_etc_based_from_its_brood_year`,
    ageComments = `age_comments_notes_about_structure_condition_broken_or_vateritic_otoliths_regen_scales_unable_to_age_data_mix_up_missing_sample_etc_vat_vateritic_bcpal_mar_9_2021_smb_are_spring_spawners_march_to_may_these_samples_were_collected_in_july_and_aug_2020_therefore_age_notation_will_have_some_growth_associated_ex_1_difficult_structures_to_age_i_looked_at_accompanying_scales_but_they_often_didnt_provide_much_confirmation_of_otoltih_age`,
    imaged = `imaged_y_n`,
    scaleAgeFertilisation = `scale_age_based_on_fertilization_birthday_used_to_calculate_brood_year_fall_spawning_species_will_have_1_added_to_winter_check_count_if_sampled_september_1st_onwards_if_spring_spawning_fish_egg_fertilized_in_spring_months_is_caught_in_the_spring_then_the_ager_may_add_1_onto_number_winter_checks_or_may_not_according_to_catch_date_and_whats_visible_on_age_structure_and_agers_final_decision_smb_spawning_late_may_into_june_the_cultus_lk_smb_are_being_caught_during_their_spawning_season_2025_catch_dates_may1_16_2025`,
    scaleAgeEdge = `scale_age_with_edge_notation_criteria_outlined_in_this_cells_note_when_hovered_over`,
    scaleAgeJan1 = `scale_age_using_jan1st_birthday_switchover_for_all_species_important_for_noting_jan_1st_birthday_for_next_years_2025_cultus_smb`,
    otolithAgeFertilisation = `otolith_age_fertilization`,
    otolithAgeEdge = `otolith_age_with_edge`,
    otolithAgeJan1 = `otolith_jan1st_age`,
    ageConfidence = `age_confidence_criteria_outlined_in_this_cells_note_when_hovered_over`,
    startTime = start_time,
    endTime = end_time
  ) |> 
  mutate(rowID = row_number()) |> 
  mutate(date = as.character(date))


col_types<-get_col_types(scales)

sur_col_types_sql <- col_types |>
  dplyr::mutate(key_status = case_when(
    col_name %in% c("rowID") ~ "KEY",
    TRUE ~ ""
  )) |>
  dplyr::reframe(a = paste0(col_name, " ", stringr::str_to_upper(sqlite_type), " ", key_status))


sql = paste0("CREATE TABLE IF NOT EXISTS scaleData (
       ",paste0(sur_col_types_sql$a,collapse = ",\n"),
             ",\nPRIMARY KEY (rowID))")
dbExecute(con, sql)
dbWriteTable(conn = con, "scaleData", scales, row.names = F, append = T)
dbListTables(con)

query <- "SELECT * FROM scaleData"
dbExecute(con = con, query)
#querydelete<-"DROP TABLE surveyData"
result <- dbSendQuery(conn = con, query)
df<-fetch(result, -1)
df
dbClearResult(result)             
