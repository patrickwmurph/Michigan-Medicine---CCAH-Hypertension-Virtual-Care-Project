library(tidyverse)
library(lme4)
library(lmerTest)
library(sjPlot)
library(ggsci)


#Overall Fit
bpdata <- bpdata %>%
  mutate(classification = fct_recode(classification,
                                    "Stage 1 Hypertension" = "S1 Hypertension",
                                    "Stage 2 Hypertension" = "S2 Hypertension"))

#Systolic
overall_fit2_sys <- bpdata %>%
  rename("Overall SBP" = "changebp_sys") %>%
  lmer(`Overall SBP` ~ days_since_baseline + (1|conversa_id), data = .)

#Diastolic
overall_fit2_dia <- bpdata %>%
  rename("Overall DBP" = "changebp_dia") %>%
  lmer(`Overall DBP` ~ days_since_baseline + (1|conversa_id), data = .)


#Fit by Class

#Systolic
fit2_sys <- bpdata %>%
  rename("Change SBP" = "changebp_sys") %>%
  lmer(`Change SBP` ~ days_since_baseline*classification + (1|conversa_id), data = .)

#Diastolic
fit2_dia <- bpdata %>%
  rename("Change DBP" = "changebp_dia") %>%
  lmer(`Change DBP` ~ days_since_baseline*classification + (1|conversa_id), data = .)

  
# Graph 
intercept_sys <- fixef(overall_fit2_sys)[1] 
slope_sys <- fixef(overall_fit2_sys)[2]     


y_at_x0_sys <- intercept_sys + slope_sys * 0     
y_at_x300_sys <- intercept_sys + slope_sys * 300

plot_fit2_sys <- fit2_sys %>%
  plot_model(type = 'int', axis.lim = list(c(0,330), c(-30,20)),ci.lvl = NA) +
  
  annotate("segment", x = 0, xend = 300, y = y_at_x0_sys, yend = y_at_x300_sys,
           color = '#374E55FF', linetype = "dashed", size = 1) +
  
  geom_line(aes(y = 1, x = 1, color = 'Normal BP'), size = 1,show.legend = F) +
  geom_line(aes(y = 1, x = 1, color = 'Elevated BP'), size = 1,show.legend = F) +
  geom_line(aes(y = 1, x = 1, color = 'Stage 1 Hypertension'), size = 1,show.legend = F) +
  geom_line(aes(y = 1, x = 1, color = 'Stage 2 Hypertension'), size = 1,show.legend = F) +
  geom_line(aes(y = 1, x = 1, color = 'Population Change'), linetype = "dashed", size = 1,show.legend = F) +
  
  scale_color_manual(
    name = NULL,
    values = c(
      'Population Change' = '#374E55FF',
      'Normal BP' = '#B24745FF',
      'Elevated BP' = "#79AF97FF", 
      'Stage 1 Hypertension' = "#DF8F44FF",
      'Stage 2 Hypertension' = "#6A6599FF"
    ),
    breaks = c('Population Change', 'Normal BP', 'Elevated BP', 'Stage 1 Hypertension', 'Stage 2 Hypertension'),
    guide = guide_legend(override.aes = list(linetype = c("dashed", rep("solid", 4)), size = 1))
  ) +
  scale_linetype_manual(
    values = c('Population Change'="dashed",
               'Normal BP'= "solid",
               'Elevated BP'="solid", 
               'Stage 1 Hypertension'="solid", 
               'Stage 2 Hypertension'="solid")
  ) +
  
  labs(
    y = 'Change Systolic Blood Pressure (mmHg)', 
    x = 'Patient Time Since First Collection (days)',
    title = 'Change Systolic Blood Pressure Over Time'
  ) +
  
  theme(
    plot.title = element_text(hjust = 0.5, size = 14),
    legend.key = element_blank(),
    legend.key.width = unit(.8, "cm"),
    legend.background = element_blank(),
    legend.position = c(0, 0),
    legend.justification = c(0, 0),
    axis.text.x = element_text(angle = 45, hjust = 1, size = 8),
    axis.text.y = element_text(size=8),
    axis.title.x = element_text(size=10),
    axis.title.y = element_text(size=10),
    axis.line = element_line(color = "#848484"),
    legend.text = element_text(size=10),
    legend.title = element_text(size=12),
    legend.key.size = unit(.5,'cm'),
    panel.grid.major = element_blank(), # new
    panel.grid.minor = element_blank(), # new
    panel.background = element_rect(fill = "white"), # new
    axis.ticks = element_line(color = "#848484") # new
  ) +
  
  scale_x_continuous(
    breaks = seq(0, max(bpdata$days_since_baseline) + 30, by = 30), 
    limits = c(0, 300), 
    expand = c(0, 0)
  ) +
  scale_y_continuous(breaks = seq(-26, 6, by = 2),
                     limits = c(-18,6))



########## Dia ########## 
intercept_dia <- fixef(overall_fit2_dia)[1] 
slope_dia <- fixef(overall_fit2_dia)[2]     


y_at_x0_dia <- intercept_dia + slope_dia * 0     
y_at_x300_dia <- intercept_dia + slope_dia * 300


plot_fit2_dia <- fit2_dia %>%
  plot_model(type = 'int', axis.lim = list(c(0,330), c(-30,20)),ci.lvl = NA) +
  
  annotate("segment", x = 0, xend = 300, y = y_at_x0_dia, yend = y_at_x300_dia,
           color = '#374E55FF', linetype = "dashed", size = 1) +
  
  geom_line(aes(y = 1, x = 1, color = 'Normal BP'), size = 1,show.legend = F) +
  geom_line(aes(y = 1, x = 1, color = 'Elevated BP'), size = 1,show.legend = F) +
  geom_line(aes(y = 1, x = 1, color = 'Stage 1 Hypertension'), size = 1,show.legend = F) +
  geom_line(aes(y = 1, x = 1, color = 'Stage 2 Hypertension'), size = 1,show.legend = F) +
  geom_line(aes(y = 1, x = 1, color = 'Population Change'), linetype = "dashed", size = 1,show.legend = F) +
  
  scale_color_manual(
    name = NULL,
    values = c(
      'Population Change' = '#374E55FF',
      'Normal BP' = '#B24745FF',
      'Elevated BP' = "#79AF97FF", 
      'Stage 1 Hypertension' = "#DF8F44FF",
      'Stage 2 Hypertension' = "#6A6599FF"
    ),
    breaks = c('Population Change', 'Normal BP', 'Elevated BP', 'Stage 1 Hypertension', 'Stage 2 Hypertension'),
    guide = guide_legend(override.aes = list(linetype = c("dashed", rep("solid", 4)), size = 1))
  ) +
  scale_linetype_manual(
                        values = c('Population Change'="dashed",
                        'Normal BP'= "solid",
                        'Elevated BP'="solid", 
                        'Stage 1 Hypertension'="solid", 
                        'Stage 2 Hypertension'="solid")
                        ) +
  
  labs(
    y = 'Change Diastolic Blood Pressure (mmHg)', 
    x = 'Patient Time Since First Collection (days)',
    title = 'Change Diastolic Blood Pressure Over Time'
  ) +
  
  theme(
    plot.title = element_text(hjust = 0.5, size = 14),
    legend.key = element_blank(),
    legend.key.width = unit(.8, "cm"),
    legend.background = element_blank(),
    legend.position = c(0, 0),
    legend.justification = c(0, 0),
    axis.text.x = element_text(angle = 45, hjust = 1, size = 8),
    axis.text.y = element_text(size=8),
    axis.title.x = element_text(size=10),
    axis.title.y = element_text(size=10),
    axis.line = element_line(color = "#848484"),
    legend.text = element_text(size=10),
    legend.title = element_text(size=12),
    legend.key.size = unit(.5,'cm'),
    panel.grid.major = element_blank(), # new
    panel.grid.minor = element_blank(), # new
    panel.background = element_rect(fill = "white"), # new
    axis.ticks = element_line(color = "#848484") # new
  ) +

  scale_x_continuous(
    breaks = seq(0, max(bpdata$days_since_baseline) + 30, by = 30), 
    limits = c(0, 300), 
    expand = c(0, 0)
  ) +
  scale_y_continuous(breaks = seq(-8,2,by = 2),
                     limits=c(-8,2))


final_plot <- gridExtra::grid.arrange(plot_fit2_sys, plot_fit2_dia)

ggsave(plot = final_plot, filename = 'figs/marginal_effects_plot.tiff', width = 8, height = 10, device='jpeg', dpi=700, units = 'in')

# Coefficient Table
tab_model(overall_fit2_sys, fit2_sys, overall_fit2_dia, fit2_dia,
          show.intercept = T,
          show.re.var = F,
          show.icc = F,
          show.ci = .95,
          digits = 2,
          digits.p = 3,
          p.style = "numeric_stars",
          title = 'Coefficients',
          string.pred = 'Model',
          string.est = 'β',
          string.ci = 'CI (95%)',
          string.p = 'p-values')



