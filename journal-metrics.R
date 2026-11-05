############ Population Metrics ############
# Age
bpdata %>%
  distinct(conversa_id, .keep_all = TRUE) %>%
  pull(age_ranges) %>%
  table() %>%
  prop.table()

# Race
bpdata %>%
  distinct(conversa_id, .keep_all = TRUE) %>%
  pull(race) %>%
  table() %>%
  prop.table()
  
# Classification
bpdata %>%
  distinct(conversa_id, .keep_all = TRUE) %>%
  pull(classification) %>%
  table() %>%
  prop.table()

bpdata %>%
  distinct(conversa_id, .keep_all = TRUE) %>%
  as.data.frame() %>%
  count(classification)

############ Model Figs ############
# Model 1
## Systolic
summary(overall_fit2_sys)
-1.617e-02 * 30
## Diastolic
summary(overall_fit2_dia)
-6.810e-03 * 30

# Model 2
## Systolic
summary(fit2_sys)
(-3.237e-05+-4.042e-02)*30
## Diastolic
summary(fit2_dia)
(-1.030e-03+-1.261e-02)*30

## S2 Study Duration
(-3.237e-05+-4.042e-02)*322
(-1.030e-03+-1.261e-02)*322
