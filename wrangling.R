library(tidyverse)
library(readxl)

## Read in Data

answers_file_path = 'data/mm-ccah-answers-export-20230222104651_analytic files.xlsx'
patient_file_path = 'data/mm-ccah-patients-export-20230222104740_analytic files.xlsx'

answers_file <- read_excel(answers_file_path, sheet = 'Sheet1', range = 'A1:J39582')
patient_file <- read_excel(patient_file_path, sheet = 'Sheet1', range = 'A1:Q838')


patient_file <- patient_file %>%
  mutate(age = floor(time_length(interval(patient_file$dob, Sys.Date()), "years")))

##Create Dataframe of SBP and DBP by session identifier
bp_response_by_session_id <- answers_file %>%
  filter(question_identifier %in% c(201884,201886)) %>% #filter by question identifier for SBP and DBP recording
  group_by(session_id, question_identifier) %>%
  summarize(response_text = toString(response_text), .groups = "drop") %>% #string of response_text values and removes grouped values
  pivot_wider(names_from = question_identifier, values_from = response_text) %>%
  left_join(., answers_file[answers_file$question_identifier == 197924, c('session_id', 'color')], by = 'session_id') %>%
  distinct(session_id, .keep_all = T) %>%
  rename('response_systolic' = '201884' , 'response_diastolic' = '201886') %>%
  filter(!session_id %in% c(145328958, 148481072))

##Generate BP data csv
bpdata <- merge(answers_file%>%select(-color), bp_response_by_session_id, by = 'session_id', all.x = T) %>% #merge response_text values by session
  filter(!is.na(response_systolic) & question_identifier %in% c(201884,201886)) %>% #remove NA and all question aside from recording
  distinct(session_id, .keep_all = T) %>% #only include unique session ids
  mutate(responded_date = as.Date(responded_datetime), 
         response_systolic = suppressWarnings(as.numeric(response_systolic)), 
         response_diastolic = suppressWarnings(as.numeric(response_diastolic))) %>% #conversion of variables to correct format to avoid coercion
  arrange(conversa_id, responded_date) %>% #order by conversa_id by ascending time
  group_by(conversa_id) %>%
  select(answer_id, session_id, conversa_id, responded_date,responded_datetime, response_systolic, response_diastolic, color)

##Clean Up - REMOVE FOR FUTURE USE
bpdata <- bpdata %>%
  filter(!answer_id == 107005500, !session_id %in% c(145328958, 148481072)) ##remove double recording and multiple recordings under same session_id

## Add days since collection
bpdata <- bpdata %>%
  group_by(conversa_id) %>%
  mutate(
    first_reading_date = first(responded_date),
    days_since_collection1 = as.integer(difftime(responded_date, first_reading_date, units = "days"))
  ) %>%
  select(-c(first_reading_date))


## Inclusion of demographic data and generation of intervals
bpdata <- bpdata %>%
  merge(., patient_file[, c('conversa_id', 'age', 'race')], by = 'conversa_id', all.x = T) %>% #merge demographic data
  mutate(time_interval = cut(days_since_collection1, breaks = seq(0,max(days_since_collection1), by = 30), include.lowest = T), #create time_interval from days since collection
         age_ranges = cut(.$age, breaks = c(-Inf, 65, 75, Inf), labels = c("<65", "65-75", ">75"), right = FALSE)) #group age ranges by func

# Classify BP
# classifyBP<- function(baseline_dia, baseline_sys) {
#   if (all(baseline_sys <= 120) && all(baseline_dia <= 80)) {
#     return("Normal BP")
#   } else if (all(baseline_sys <= 129) && all(baseline_dia <= 80)) {
#     return("Elevated BP")
#   } else if (all(baseline_sys <=139) || all(baseline_dia <= 89)) {
#     return("S1 Hypertension")
#   } else if (all(baseline_sys >= 140) || all(baseline_dia >= 90)) {
#     return("S2 Hypertension")
#   } else { 
#     return(classifyBPsys(baseline_sys))
#   }
# } 

# classifyBPsys <- function(baseline_sys) {
#   if (baseline_sys<=120) {
#     return("Normal BP")
#   } else if (baseline_sys<=129) {
#     return("Elevated BP")
#   } else if (baseline_sys<=139) {
#     return("S1 Hypertension")
#   } else {
#     return("S2 Hypertension")
#   }
# }

classifyBP <- function(baseline_sys, baseline_dia) {
  if (baseline_sys < 120 && baseline_dia < 80) {
    return("Normal BP")
  } else if (baseline_sys >= 120 && baseline_sys <= 129 && baseline_dia < 80) {
    return("Elevated BP")
  } else if ((baseline_sys >= 130 && baseline_sys <= 139) || (baseline_dia >= 80 && baseline_dia <= 89)) {
    return("S1 Hypertension")
  } else if (baseline_sys >= 140 || baseline_dia >= 90) {
    return("S2 Hypertension")
  } else {
    return("Unclassified") # This case should not occur given the provided ranges but is here as a fallback
  }
}

# Clean Up
rm(bp_response_by_session_id, patient_file, answers_file)

# Add Classification 
baseline_period <- 0
bpdata <- bpdata %>%
  select(conversa_id, response_systolic, response_diastolic, days_since_collection1) %>%
  filter(days_since_collection1 <=baseline_period) %>%
  group_by(conversa_id) %>%
  summarize(mean_sys = mean(response_systolic), mean_dia = mean(response_diastolic)) %>%
  mutate(classification = factor(mapply(classifyBP, mean_sys, mean_dia), 
                                 levels = c('Normal BP', 'Elevated BP', 'S1 Hypertension', 'S2 Hypertension'))) %>%
  left_join(bpdata[, !(names(bpdata) %in% c('classification', 'new_changebp_sys', 'new_changebp_dia'))], 
            .[c('conversa_id', 'new_class')], 
            by = 'conversa_id') %>%
  mutate(new_changebp_sys = response_systolic-mean_sys,
         new_changebp_dia = response_diastolic-mean_dia) %>%
  filter(days_since_collection1>=baseline_period) %>%
  group_by(conversa_id) %>%
  mutate(days_since_baseline = as.numeric(responded_date - min(responded_date))) %>%
  rename(changebp_sys='new_changebp_sys', changebp_dia= 'new_changebp_dia',
         baselinebp_sys= 'mean_sys', baselinebp_dia = 'mean_dia')



save(bpdata, file = "data/bpdata.rda")
