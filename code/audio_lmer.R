################################################################

# AUDIO & AV SURPRISAL PROJECT
# This project compares N400 effects of surprisal from different models in audio & audiovisual modality
# This scripts contains:
# 1. Correlation of surprisal from different models
# 2. Correlation of N400 in audio & audiovisual modality
# 3. Model comparison of different surprisal on audio & audiovisual data
# 4. Model comparison of different surprisal on audiovisual replication data

################################################################
# Loading modules & setting path

library('lme4')
library('tidyverse')
library('readxl')
library('visreg')
library('effects')
library('ggplot2')
library('ggpubr')
library('gridExtra')

path = '/Users/yezhang/OneDrive - University College London/surprisal_audio/'

################################################################
# 1. Surprisal correlations
# Correlating within surprisal from Pranava 2023 batch (used for the current study)
# Correlating the 2023 batch with Diego's surprisal (used for Proceedings B study) for validation
################################################################

info = read_excel(paste(path, 'stimuli/word_merged_audio.xlsx', sep = ''))

# Pranava's Surprisal from different files are moderately correlated
cor.test(info$surprisal_ngram, info$surprisal_gpt) #0.42, all (function + content words)
cor.test(info$surprisal_ngram, info$surprisal_bert) #0.33, all (function + content words) 
cor.test(info$surprisal_gpt, info$surprisal_bert) #0.40, all (function + content words)

# Pranava's Surprisal and Diego's surprisal are moderately correlated. 
# This is true both for all content + function words, and content words only 
info_prev = info %>%
  filter(word_prev!='NaN',
        surprisal_prev!='NaN',
        surprisal_prev!= 'inf') %>%
  mutate(surprisal_prev = as.numeric(surprisal_prev))

cor.test(info_prev$surprisal_ngram, info_prev$surprisal_gpt) #0.41, prev (all words)
cor.test(info_prev$surprisal_ngram, info_prev$surprisal_bert) #0.28, prev (all words) 
cor.test(info_prev$surprisal_gpt, info_prev$surprisal_bert) #0.40, prev (all words)

cor.test(info_prev$surprisal_prev, info_prev$surprisal_ngram) #0.59, prev (all words)
cor.test(info_prev$surprisal_prev, info_prev$surprisal_gpt) #0.29, prev (all words)
cor.test(info_prev$surprisal_prev, info_prev$surprisal_bert) #0.24, prev (all words)

info_content = info %>%
  filter(word_prev!='NaN') %>%
  filter(surprisal_prev!='NaN') %>%
  filter(surprisal_prev!= 'inf') %>%
  filter(pos_prev == 1) %>%
  mutate(surprisal_prev = as.numeric(surprisal_prev))

cor.test(info_content$surprisal_ngram, info_content$surprisal_gpt) #0.36, prev content words
cor.test(info_content$surprisal_ngram, info_content$surprisal_bert) #0.22, prev content words 
cor.test(info_content$surprisal_gpt, info_content$surprisal_bert) #0.40, prev content words

cor.test(info_content$surprisal_prev, info_content$surprisal_ngram) #0.52, prev content words
cor.test(info_content$surprisal_prev, info_content$surprisal_gpt) #0.27, prev content words
cor.test(info_content$surprisal_prev, info_content$surprisal_bert) #0.17, prev content words

################################################################
# 2. N400 correlations
# Calculating correlation between audio and audiovisual N400
# Calculating correlation within 2 random slice of data in audio and audiovisual respectively. This serves as 'baseline' correlation that accounts for cross participants variances & mechanical noise, but not difference in audio/AV condition
################################################################

preprocessing_plot <- function(data){
  data_preprocesed = data %>%
    # Filtering
    filter(
        pos_prev == 1, # only include content words
        ar_good == TRUE, # only include words without artifact; somehow eeglab won't sync that info. Remove if fixed
        surprisal_prev != 'Inf', # To compare prev 2 gram surprisal, removing invalid values there
        surprisal_prev != 'NA',
          ) %>% 
    # Recoding
    mutate(
        ERP_diff = ERP - baseline # baseline correction not performed in EEG lab, so it's substracted here for plotting. In statistical analysis baseline was treated as a variable as in e.g. Alday et al, 2017
          )
    
  return(data_preprocesed)
}

# Reading and preprocessing data
data_audio = read_csv(paste(path, 'data_audio/analysis/lmer/300-500_info.csv', sep = ''))
data_video = read_csv(paste(path, 'data_video/analysis/lmer/300-500_info.csv', sep = ''))
data_video_replication = read_csv(paste(path, 'data_video_replication/analysis/lmer/300-600_info.csv', sep = ''))

data_audio$modality = 'audio'
data_video$modality = 'audiovisual'
data_video_replication$modality = 'audiovisual(replication)'
data_audio$bin_id = data_audio$bin_id_video # set the same bin_id

data_audio_preprocessed = preprocessing_plot(data_audio)
data_video_preprocessed = preprocessing_plot(data_video)
data_video_replication_preprocessed = preprocessing_plot(data_video_replication)

data_combined = rbind(data_audio_preprocessed, data_video_preprocessed)

# Calculating & plotting correlation between audio and audiovisual

## Each word as a data point 
data_cor_wide = data_combined %>%
  group_by(bin_id, modality) %>% 
  summarise(across(everything(), list(mean))) %>%
  select(bin_id, modality, ERP_diff_1) %>% 
  pivot_wider(names_from = modality, values_from = ERP_diff_1)

cor.test(data_cor_wide$audio, data_cor_wide$audiovisual, use = 'complete.obs') # r = 0.11, p<.001

p_cor = 
  data_cor_wide %>%
  ggplot(aes(x = audio, y = audiovisual))+
  geom_point(alpha=0.5, color='#69b3a2')+
  geom_smooth(method='lm', formula= y~x,  color='#999999') +
  guides(size = 'none')+
  scale_x_continuous(limits = c(-10, 10)) +
  scale_y_continuous(limits = c(-10, 10)) +
  ylab('Audiovisual N400 amplitude (µV)') +
  xlab('Audio N400 amplitude (µV)')+
  theme_bw()
  
pdf(paste(path, 'results/ERP_cor.pdf', sep=''), 
    width = 4, height = 4) # Open a new pdf file
ggarrange(p_cor, ncol=1, nrow=1, common.legend = TRUE, legend='bottom')
dev.off()

## Grouping different words by surprisal and plot the grouped results to reduce noise

data_cor_wide_bin = data_combined %>%
  mutate(
      surprisal_cut = as.numeric(cut_number(surprisal_2gram,100)) # Cutting the words into 100 bins by surprisal, which is a bit random; only using 2gram surprisal as criteria, which somehow works the best
    )%>%
  group_by(modality, surprisal_cut) %>%
  summarise(across(everything(), list(mean))) %>%
  select(surprisal_cut, modality, ERP_diff_1) %>% 
  pivot_wider(names_from = modality, values_from = ERP_diff_1)
  
cor.test(data_cor_wide_bin$audio, data_cor_wide_bin$audiovisual, use = 'complete.obs') # correlation (obviously) changes based on number of bins and the grouping variable, making it a bit random.

p_cor_bin = 
data_cor_wide_bin %>%
  ggplot(aes(x = audio, y = audiovisual))+
  geom_point(alpha=0.5, color='#69b3a2')+
  #geom_smooth(method='lm', formula= y~x,  color='#999999') +
  guides(size = 'none')+
  # scale_x_continuous(limits = c(-1.5, 0.5)) +
  # scale_y_continuous(limits = c(-1.5, 0.5)) +
  ylab('Audiovisual N400 amplitude (µV)') +
  xlab('Audio N400 amplitude (µV)')+
  theme_bw()

pdf(paste(path, 'results/ERP_cor_bin100_noline.pdf', sep=''), 
    width = 4, height = 4) # Open a new pdf file
ggarrange(p_cor_bin, ncol=1, nrow=1, common.legend = TRUE, legend='bottom')
dev.off()


# Correlation within modality, serving as baseline
# The correlation value is in general lower than cross modality, which might be because the sample is smaller and mechanical noise larger. Of course the exact r is very dependent on random slicings, but it's approximately 0.03

## Audio
unique(data_audio_preprocessed$part_id) # check list of participant ID, try a few random combinations
data_cor_audio_wide = data_audio_preprocessed %>%
  mutate (
    slice = case_when(
        part_id == 'part1'| part_id == 'part7'| part_id == 'part10'
        | part_id == 'part11'| part_id == 'part14'| part_id == 'part15'
        | part_id == 'part19'| part_id == 'part22'| part_id == 'part23'
        | part_id == 'part25'| part_id == 'part2'| part_id == 'part6'
        | part_id == 'part3' ~ 'slice_1',
        TRUE ~ 'slice_2' # This is just one random slicing
    )
  ) %>%
  group_by(bin_id, slice) %>% 
  summarise(across(everything(), list(mean))) %>%
  select(bin_id, slice, ERP_diff_1) %>% 
  pivot_wider(names_from = slice, values_from = ERP_diff_1)

cor.test(data_cor_audio_wide$slice_1, data_cor_audio_wide$slice_2, use = 'complete.obs')

p_cor_audio =
data_cor_audio_wide %>%
  ggplot(aes(x = slice_1, y = slice_2))+
  geom_point(alpha=0.5, color='#69b3a2')+
  geom_smooth(method='lm', formula= y~x,  color='#999999') +
  guides(size = 'none')+
  scale_x_continuous(limits = c(-10, 10)) +
  scale_y_continuous(limits = c(-10, 10)) +
  ylab('slice_2 N400 amplitude (µV)') +
  xlab('slice_1 N400 amplitude (µV)')+
  ggtitle('N400 correlation in audio modality')+
  theme_bw()+
  theme(plot.title = element_text(hjust = 0.5),
        legend.position='none')

## Audiovisual
unique(data_video_preprocessed$part_id) # check list of participant ID, try a few random combinations
data_cor_video_wide = data_video_preprocessed %>%
  mutate (
    slice = case_when(
        part_id == 'part1'| part_id =='part4'| part_id =='part8'
        | part_id =='part9'| part_id =='part12'| part_id =='part13'
        | part_id =='part14'| part_id =='part17'| part_id =='part28'
        | part_id =='part29'| part_id =='part23'| part_id =='part5'
        | part_id =='part25'| part_id =='part16'| part_id =='part2'
        ~ 'slice_1',
        TRUE ~ 'slice_2' # Try a few random slices
    )
  ) %>%
  group_by(bin_id, slice) %>% 
  summarise(across(everything(), list(mean)))%>% 
  select(bin_id, slice, ERP_diff_1) %>% 
  pivot_wider(names_from = slice, values_from = ERP_diff_1)

cor.test(data_cor_video_wide$slice_1, data_cor_video_wide$slice_2, use = 'complete.obs')

p_cor_video =
data_cor_video_wide %>%
  ggplot(aes(x = slice_1, y = slice_2))+
  geom_point(alpha=0.5, color='#69b3a2')+
  geom_smooth(method='lm', formula= y~x,  color='#999999') +
  guides(size = 'none')+
  scale_x_continuous(limits = c(-10, 10)) +
  scale_y_continuous(limits = c(-10, 10)) +
  ylab('slice_2 N400 amplitude (µV)') +
  xlab('slice_1 N400 amplitude (µV)')+
  ggtitle('N400 correlation in audiovisual modality')+
  theme_bw()+
  theme(plot.title = element_text(hjust = 0.5),
        legend.position='none')

pdf(paste(path, 'results/ERP_cor_within_modality.pdf', sep = ''), width = 8, height = 4) # Open a new pdf file
grid.arrange(p_cor_audio, p_cor_video, ncol = 2, nrow = 1) 
dev.off() 

## Grouping words by surprisal to reduce noise, as in the cross modality correlation
## Just like in cross modality, the r increased to be around 0.1. However, it is still smaller than cross modality correlation, likely because the different number of data

data_cor_audio_wide_bin = data_audio_preprocessed %>%
  mutate (
    surprisal_cut = as.numeric(cut_number(surprisal_2gram,100)),
    slice = case_when(
        part_id == 'part1'| part_id == 'part7'| part_id == 'part10'
        | part_id == 'part11'| part_id == 'part14'| part_id == 'part15'
        | part_id == 'part19'| part_id == 'part22'| part_id == 'part23'
        | part_id == 'part25'| part_id == 'part2'| part_id == 'part6'
        | part_id == 'part3' ~ 'slice_1',
        TRUE ~ 'slice_2' # This is just one random slicing
    )
  ) %>%
  group_by(surprisal_cut, slice) %>% 
  summarise(across(everything(), list(mean))) %>%
  select(surprisal_cut, slice, ERP_diff_1) %>% 
  pivot_wider(names_from = slice, values_from = ERP_diff_1)

cor.test(data_cor_audio_wide_bin$slice_1, data_cor_audio_wide_bin$slice_2, use = 'complete.obs')

p_cor_audio_bin =
data_cor_audio_wide_bin %>%
  ggplot(aes(x = slice_1, y = slice_2))+
  geom_point(alpha=0.5, color='#69b3a2')+
  geom_smooth(method='lm', formula= y~x,  color='#999999') +
  guides(size = 'none')+
  ylab('slice_2 N400 amplitude (µV)') +
  xlab('slice_1 N400 amplitude (µV)')+
  ggtitle('N400 correlation in audio modality (100 bins)')+
  theme_bw()+
  theme(plot.title = element_text(hjust = 0.5),
        legend.position='none')

data_cor_video_wide_bin = data_video_preprocessed %>%
  mutate (
    surprisal_cut = as.numeric(cut_number(surprisal_2gram,100)),
    slice = case_when(
        part_id == 'part1'| part_id =='part4'| part_id =='part8'
        | part_id =='part9'| part_id =='part12'| part_id =='part13'
        | part_id =='part14'| part_id =='part17'| part_id =='part28'
        | part_id =='part29'| part_id =='part23'| part_id =='part5'
        | part_id =='part25'| part_id =='part16'| part_id =='part2'
        ~ 'slice_1',
        TRUE ~ 'slice_2' # Try a few random slices
    )
  ) %>%
  group_by(surprisal_cut, slice) %>% 
  summarise(across(everything(), list(mean)))%>% 
  select(surprisal_cut, slice, ERP_diff_1) %>% 
  pivot_wider(names_from = slice, values_from = ERP_diff_1)

cor.test(data_cor_video_wide_bin$slice_1, data_cor_video_wide_bin$slice_2, use = 'complete.obs')

p_cor_video_bin =
data_cor_video_wide_bin %>%
  ggplot(aes(x = slice_1, y = slice_2))+
  geom_point(alpha=0.5, color='#69b3a2')+
  geom_smooth(method='lm', formula= y~x,  color='#999999') +
  guides(size = 'none')+
  ylab('slice_2 N400 amplitude (µV)') +
  xlab('slice_1 N400 amplitude (µV)')+
  ggtitle('N400 correlation in audiovisual modality (100 bins)')+
  theme_bw()+
  theme(plot.title = element_text(hjust = 0.5),
        legend.position='none')

pdf(paste(path, 'results/ERP_cor_within_modality_bin100.pdf', sep = ''), width = 8, height = 4) # Open a new pdf file
grid.arrange(p_cor_audio_bin, p_cor_video_bin, ncol = 2, nrow = 1) 
dev.off() 

################################################################
# 3. Model comparison
# Compared fit of surprisal from different models, for audio & AV respectively
# (Exploratory) splitting the data based on whether the word is in the early part of the passage or the later, ran same model comparison
# (Exploratory) splitting the audiovisual data based on whether the video contains gesture
# (Exploratory) mutating audiovisual data to have same number of participants as audio modality and compare raw AIC score
################################################################

preprocessing <- function(data){
  data_preprocesed = data %>%
    # Filtering
    filter(
        pos_prev == 1, # only include content words
        ar_good == TRUE, # only include words without artifact; somehow eeglab won't sync that info. Remove if fixed
        surprisal_prev != 'Inf',
        surprisal_prev != 'NA',
        surprisal_2gram != 'Inf',
        surprisal_2gram != 'NA',
        surprisal_3gram != 'Inf',
        surprisal_3gram != 'NA',
        surprisal_4gram != 'Inf',
        surprisal_4gram != 'NA',     
        surprisal_5gram != 'Inf',
        surprisal_5gram != 'NA',     
        surprisal_6gram != 'Inf',
        surprisal_6gram != 'NA',     
        surprisal_bert != 'Inf',
        surprisal_bert != 'NA',   
        surprisal_gpt2 != 'Inf',
        surprisal_gpt2 != 'NA' 
          ) %>% 

    # Recode electrodes into ROIs, Replicating Michaelov et al 2021
    # ROI: Prefrontal, Fronto-central, Central, Posterior, Left Temporal, Right Temporal
    # Note that Michaelov et al 2021 didn't say which electrode is in which category, and the original experiment Bardolph et al., 2018 is a conference presentation that can't find online, I have to make a guess
    mutate(
        ROI = case_when(
             electrode == 'Fp1' | electrode =='Fp2' | electrode =='AF3' | electrode =='AF4' ~ 'prefrontal',
             electrode == 'F3' | electrode =='F7' | electrode =='Fz' | electrode =='F4' | electrode =='F8' | # not sure whether F is in this group
             electrode =='FC5' | electrode =='FC1' | electrode =='FC6' | electrode =='FC2' ~ 'fronto-central',  
             electrode == 'C3' | electrode =='C4' | electrode =='Cz' ~ 'central',
             electrode == 'CP1' | electrode =='CP5' | electrode =='CP2' | electrode =='CP6' | # Not sure CP is in this group
             electrode =='P3' | electrode =='P7' | electrode =='Pz' | electrode =='P4' | electrode =='P8' | 
             electrode =='PO3' | electrode =='PO4' | electrode =='O1' | electrode =='Oz' | electrode =='O2' ~ 'posterior', 
             electrode == 'T7' ~ 'left temporal',
             electrode == 'T8' ~ 'right temporal',
             TRUE ~ 'ERROR'
             )
      )
      return(data_preprocesed)
}

surprisal_comparison <- function(data, model){
  data_slice = data
  comp_model = data_slice[[paste('surprisal_', model, sep='')]] # surprisal from different computational models
  
  base_model = lmer(ERP ~
                      ROI + baseline + # note that Michaelov et al 2021 did not mention baseline in the model, possibly because they baseline-corrected the data in preprocessing. However, we followed a different approach so we would have to include it here
                      (1|part_id) +
                      (1|passage_id)+
                      (1|electrode), 
                    data = data_slice, REML=FALSE)
  
  main_model = lmer(ERP ~
                       comp_model +
                       ROI + baseline +
                       (1|part_id) +
                       (1|passage_id)+
                       (1|electrode), 
                     data = data_slice, REML=FALSE)
  
  inter_model = lmer(ERP ~
                     comp_model +
                     comp_model * ROI +
                     ROI + baseline +
                     (1|part_id) +
                     (1|passage_id)+
                     (1|electrode), 
                   data = data_slice, REML=FALSE)
  
  # Model comparison with log likelihood
  test <- rbind(
    anova(base_model, main_model),
    anova(main_model, inter_model)[2,]
                )
  
  test$aic_dif = test['base_model','AIC'] - test$AIC # Calculating AIC reduction
  test$interaction = c('base', 'main', 'interaction')
  
  return(test)
}


# Vanila version: model comparison in audio & AV data 

## Audio
data_audio = read_csv(paste(path, 'data_audio/analysis/lmer/300-500_info.csv', sep = ''))
data_audio_preprocessed = preprocessing(data_audio)

models <- c('2gram', '3gram', '4gram', '5gram', '6gram', 'gpt2', 'bert') # test surprisal generated by these models

test_list = list()
i=1
for (model in models){
    test_slice <- surprisal_comparison(data_audio_preprocessed, model)
    test_slice$model = model
    test_list[[i]] <- test_slice
    i=i+1
}

test_audio <- dplyr::bind_rows(test_list)
test_audio$modality = 'audio'
test_audio$p_fdr = p.adjust(test_audio$`Pr(>Chisq)`, method = 'fdr', n = 14)

write.table(test_audio, paste(path, 'results/model_audio.txt', sep = ''))

## Audiovisual

data_video = read_csv(paste(path, 'data_video/analysis/lmer/300-500_info.csv', sep = ''))
data_video_preprocessed = preprocessing(data_video)

test_list = list()
i=1
for (model in models){
    test_slice <- surprisal_comparison(data_video_preprocessed, model)
    test_slice$model = model
    test_list[[i]] <- test_slice
    i=i+1
}
test_video <- dplyr::bind_rows(test_list)
test_video$modality = 'audiovisual'
test_video$p_fdr = p.adjust(test_video$`Pr(>Chisq)`, method = 'fdr', n = 14)

write.table(test_video, paste(path, 'results/model_video.txt', sep = ''))

test=rbind(test_audio, test_video)
write.table(test, '/Users/claudia/OneDrive - University College London/surprisal_audio/results/model_combined.txt')

## Plotting model comparison results
test_result=read.table(paste(path, 'results/model_combined.txt', sep = ''))

AIC_plot_audio = 
  test_result %>%
  filter(modality == 'audio') %>% 
  filter(interaction=='interaction') %>%
  ggplot(aes(x = model, y = aic_dif, fill = model)) +
  geom_bar(stat='identity') + 
  scale_x_discrete(labels=c('2-gram','3-gram','4-gram', '5-gram', '6-gram', 'BERT', 'GPT-2'))+
  xlab('') +
  ylab(expression(Delta * 'AIC'))+
  ggtitle('Audio modality') +
  theme_bw() +
  theme(plot.title = element_text(hjust = 0.5),
        legend.position='none')

AIC_plot_video = 
  test_video %>%
  filter(interaction=='main') %>%
  ggplot(aes(x = model, y = aic_dif, fill = model)) +
  geom_bar(stat='identity') + 
  scale_x_discrete(labels=c('2-gram','3-gram','4-gram', '5-gram', '6-gram', 'BERT', 'GPT-2'))+
  xlab('') +
  ylab(expression(Delta * 'AIC'))+
  ggtitle('Audiovisual modality') +
  theme_bw() +
  theme(plot.title = element_text(hjust = 0.5),
        legend.position='none')

require(gridExtra)
pdf(paste(path, 'results/model_combined.pdf', sep = ''), 
    width = 8, height = 4,encoding='MacRoman') # Open a new pdf file
grid.arrange(AIC_plot_audio, AIC_plot_video, ncol = 2, nrow = 1) 
dev.off() 


# (Exploratory): splitting data by sequence
# Each stimuli video in this study contains two sentences. Run model comparison in the data of each sentence.

## Audio
data_audio_preprocessed = preprocessing(data_audio)
models <- c('2gram', '3gram', '4gram', '5gram', '6gram', 'gpt2', 'bert')
seqs <- c(1, 2)

test_list = list()
i=1
for (model in models){
  for (seq in seqs){
      data_slice = data_audio_preprocessed %>%
        filter(sentence_seq == seq)
      test_slice <- surprisal_comparison(data_slice, model)
      test_slice$model = model
      test_slice$sequence = seq
      test_list[[i]] <- test_slice
      i=i+1
  }
}
test_audio_seq <- dplyr::bind_rows(test_list)
test_audio_seq$modality = 'audio'
test_audio_seq$p_fdr = p.adjust(test_audio_seq$`Pr(>Chisq)`, method = 'fdr', n = 28)

## Audiovisual
data_video_preprocessed = preprocessing(data_video)
models <- c('2gram', '3gram', '4gram', '5gram', '6gram', 'gpt2', 'bert')
seqs <- c(1, 2)
test_list = list()
i=1
for (model in models){
  for (seq in seqs){
    data_slice = data_video_preprocessed %>%
      filter(sentence_seq == seq)
    test_slice <- surprisal_comparison(data_slice, model)
    test_slice$model = model
    test_slice$sequence = seq
    test_list[[i]] <- test_slice
    i=i+1
  }
}
test_video_seq <- dplyr::bind_rows(test_list)
test_video_seq$modality = 'audiovisual'
test_video_seq$p_fdr = p.adjust(test_video_seq$`Pr(>Chisq)`, method = 'fdr', n = 28)

test_seq=rbind(test_audio_seq, test_video_seq)
write.table(test_seq, paste(path, 'results/model_sequence.txt', sep = ''))


test_seq = read.table(paste(path, 'results/model_sequence.txt', sep = ''))

AIC_plot_audio_seq = 
  test %>%
  filter(modality == 'audio') %>% 
  filter(interaction=='interaction') %>%
  ggplot(aes(x = model, y = aic_dif, fill = model)) +
  geom_bar(stat='identity') + 
  facet_wrap(vars(sequence), ncol = 1) +
  xlab('') +
  ylab(expression(Delta * 'AIC'))+
  ggtitle('Audio modality') +
  theme(plot.title = element_text(hjust = 0.5),
        legend.position='none')

AIC_plot_video_seq = 
  test_video %>%
  filter(interaction=='main') %>%
  filter(modality == 'audiovisual') %>%
  ggplot(aes(x = model, y = aic_dif, fill = model)) +
  geom_bar(stat='identity') + 
  facet_wrap(vars(sequence), ncol = 1) +
  xlab('') +
  ylab(expression(Delta * 'AIC'))+
  ggtitle('Audiovisual modality') +
  theme(plot.title = element_text(hjust = 0.5),
        legend.position='none')

pdf(paste(path, 'results/model_seq.pdf', sep = ''), 
    width = 8, height = 4,encoding='MacRoman') # Open a new pdf file
grid.arrange(AIC_plot_audio_seq, AIC_plot_video_seq, ncol = 2, nrow = 1) 
dev.off() 


# (Exploratory): splitting AV data by gesture
# In the AV condition, each stimuli is recorded twice, once with gesture and once without. Run model comparison in the AV data of each type of stimuli

data_video_preprocessed = preprocessing(data_video)
data_video_preprocessed$is_G = ifelse(grepl("G", data_video_preprocessed$sentence_id_x), 'gesture', 'no_gesture')

models <- c('2gram', '3gram', '4gram', '5gram', '6gram', 'gpt2', 'bert')
gesture_list <- c('gesture', 'no_gesture')
test_list = list()
i=1
for (model in models){
  for (gesture in gesture_list){
    data_slice = data_video_preprocessed %>%
      filter(is_G == gesture)
    test_slice <- surprisal_comparison(data_slice, model)
    test_slice$model = model
    test_slice$gesture_condition = gesture
    test_list[[i]] <- test_slice
    i=i+1
  }
}
test_video_gesture <- dplyr::bind_rows(test_list)
test_video_gesture$modality = 'audiovisual'
test_video_gesture$p_fdr = p.adjust(test_video_gesture$`Pr(>Chisq)`, method = 'fdr', n = 28)

write.table(test_video_gesture, paste(path, 'results/model_AV_gesture_conditions.txt', sep = ''))

test_video_gesture = read.table(paste(path, 'results/model_AV_gesture_conditions.txt', sep = ''))

AIC_plot_video_gesture = 
  test_video_gesture  %>%
  filter(interaction=='main') %>%
  filter(modality == 'audiovisual') %>%
  ggplot(aes(x = model, y = aic_dif, fill = model)) +
  geom_bar(stat='identity') + 
  facet_wrap(vars(gesture_condition), ncol = 2) +
  xlab('') +
  ylab(expression(Delta * 'AIC'))+
  ggtitle('Audiovisual modality, gesture split') +
  theme(plot.title = element_text(hjust = 0.5),
        legend.position='none')

pdf(paste(path, 'results/model_video_gesture_contidions.pdf', sep = ''), 
    width = 8, height = 4,encoding='MacRoman') # Open a new pdf file
grid.arrange(AIC_plot_video_gesture, ncol = 1, nrow = 1) 
dev.off() 

# (Exploratory): randomly sampling AV data so that the number of participant is the same with audio data
# Audio experiment inlcuded 25 participants while the AV experiment tested 30 participants. The larger number of participants leads to larger raw AIC value. Making the number of participants equal so that AIC values are comparable

data_video_preprocessed = preprocessing(data_video)
unique(data_video_preprocessed$part_id)

part_sample = sample(unique(data_video_preprocessed$part_id), 25) # randomly select 25 participants out of 30
data_video_preprocessed_slice = filter(data_video_preprocessed,
                                       part_id %in% part_sample)

test_list = list()
i=1
for (model in models){
    test_slice <- surprisal_comparison(data_video_preprocessed_slice, model)
    test_slice$model = model
    test_list[[i]] <- test_slice
    i=i+1
}
test_video_sample <- dplyr::bind_rows(test_list)
test_video_sample$modality = 'audiovisual'
test_video_sample$p_fdr = p.adjust(test_video_sample$`Pr(>Chisq)`, method = 'fdr', n = 14)

write.table(test_video_sample, paste(path, 'results/model_video_sample2.txt', sep = ''))

# (Exploratory): randomly sampling AV data so that the number of observation is the same with audio data
# The number of observation per participant differs a lot. Therefore, the results in raw AIC is very sensitive to the random sampling. Here we randomly sample the rows to make it equivalant with audio data

data_audio_preprocessed = preprocessing(data_audio)
data_video_preprocessed = preprocessing(data_video)

audio_size = nrow(data_audio_preprocessed)
data_video_preprocessed_slice_observation = sample_n(data_video_preprocessed, audio_size)

test_list = list()
i=1
for (model in models){
    test_slice <- surprisal_comparison(data_video_preprocessed_slice_observation, model)
    test_slice$model = model
    test_list[[i]] <- test_slice
    i=i+1
}
test_video_sample_observation <- dplyr::bind_rows(test_list)
test_video_sample_observation$modality = 'audiovisual'
test_video_sample_observation$p_fdr = p.adjust(test_video_sample_observation$`Pr(>Chisq)`, method = 'fdr', n = 14)

write.table(test_video_sample_observation, paste(path, 'results/model_video_sample_observation.txt', sep = ''))

test_video_sample_observation = read.table(paste(path, 'results/model_video_sample_observation.txt', sep = ''))

AIC_plot_video_sample_observation = 
  test_video_sample_observation  %>%
  filter(interaction=='interaction') %>%
  ggplot(aes(x = model, y = aic_dif, fill = model)) +
  geom_bar(stat='identity') + 
  xlab('') +
  ylab(expression(Delta * 'AIC'))+
  ggtitle('Audiovisual modality, sampled') +
  theme(plot.title = element_text(hjust = 0.5),
        legend.position='none')

pdf(paste(path, 'results/model_video_sample_observation.pdf', sep = ''), 
    width = 8, height = 4,encoding='MacRoman') # Open a new pdf file
grid.arrange(AIC_plot_video_sample_observation, AIC_plot_audio, ncol = 2, nrow = 1) 
dev.off() 

################################################################
# 4. Model comparison (replication)
# Compared fit of surprisal from different models for audiovisual modality
# Note: 
# - all functions are defined above in 3.
# - Zhang et al 2021 used 300-600 as N400. However, this study used 300-500 for all modalities, so the same window is used here. 300-600 produced the same patterns though.
################################################################

# Reading and preprocessing data
data_video_replication = read_csv(paste(path, 'data_video_replication/lmer/300-500_info.csv', sep = ''))
data_video_replication$modality = 'audiovisual(replication)'
data_video_replication_preprocessed = preprocessing(data_video_replication)

# Running model comparisons
models <- c('2gram', '3gram', '4gram', '5gram', '6gram', 'gpt2', 'bert') # test surprisal generated by these models
test_list = list()
i=1
for (model in models){
    test_slice <- surprisal_comparison(data_video_replication_preprocessed, model)
    test_slice$model = model
    test_list[[i]] <- test_slice
    i=i+1
}

# Saving results
test_audiovisual_replication <- dplyr::bind_rows(test_list)
test_audiovisual_replication$modality = 'audiovisual(replication)'
test_audiovisual_replication$p_fdr = p.adjust(test_audiovisual_replication$`Pr(>Chisq)`, method = 'fdr', n = 14)

write.table(test_audiovisual_replication, paste(path, 'results/model_audiovisual_replication.txt', sep = ''))

test_audiovisual_replication = read.table(paste(path, 'results/model_audiovisual_replication.txt', sep = ''))

# Plotting results
AIC_plot_video_replication_main = 
  test_audiovisual_replication %>%
  filter(interaction=='main') %>%
  ggplot(aes(x = model, y = aic_dif, fill = model)) +
  geom_bar(stat='identity') + 
  scale_x_discrete(labels=c('2-gram','3-gram','4-gram', '5-gram', '6-gram', 'BERT', 'GPT-2'))+
  xlab('') +
  ylab(expression(Delta * 'AIC'))+
  ggtitle('Audiovisual modality (replication)\nmain effect model') +
  theme_bw() +
  theme(plot.title = element_text(hjust = 0.5),
        legend.position='none')

AIC_plot_video_replication_inter = 
  test_audiovisual_replication %>%
  filter(interaction=='interaction') %>%
  ggplot(aes(x = model, y = aic_dif, fill = model)) +
  geom_bar(stat='identity') + 
  scale_x_discrete(labels=c('2-gram','3-gram','4-gram', '5-gram', '6-gram', 'BERT', 'GPT-2'))+
  xlab('') +
  ylab(expression(Delta * 'AIC'))+
  ggtitle('Audiovisual modality (replication)\ninteraction model') +
  theme_bw() +
  theme(plot.title = element_text(hjust = 0.5),
        legend.position='none')

require(gridExtra)
pdf(paste(path, 'results/model_replication.pdf', sep = ''), 
    width = 8, height = 4,encoding='MacRoman') # Open a new pdf file
grid.arrange(AIC_plot_video_replication_main, AIC_plot_video_replication_inter, ncol = 2, nrow = 1) 
dev.off() 

# (Exploratory): splitting AV data by gesture
# In the AV condition, each stimuli is recorded twice, once with gesture and once without. Run model comparison in the AV data of each type of stimuli

data_video_replication_preprocessed = preprocessing(data_video_replication)
data_video_replication_preprocessed$is_G = ifelse(grepl("G", data_video_replication_preprocessed$passage_id), 'gesture', 'no_gesture')

models <- c('2gram', '3gram', '4gram', '5gram', '6gram', 'gpt2', 'bert')
gesture_list <- c('gesture', 'no_gesture')
test_list = list()
i=1
for (model in models){
  for (gesture in gesture_list){
    data_slice = data_video_replication_preprocessed %>%
      filter(is_G == gesture)
    test_slice <- surprisal_comparison(data_slice, model)
    test_slice$model = model
    test_slice$gesture_condition = gesture
    test_list[[i]] <- test_slice
    i=i+1
  }
}
test_video_replication_gesture <- dplyr::bind_rows(test_list)
test_video_replication_gesture$modality = 'audiovisual(replication)'
test_video_replication_gesture$p_fdr = p.adjust(test_video_replication_gesture$`Pr(>Chisq)`, method = 'fdr', n = 28)

write.table(test_video_replication_gesture, paste(path, 'results/model_AV_replication_gesture_conditions.txt', sep = ''))

test_video_replication_gesture = read.table(paste(path, 'results/model_AV_replication_gesture_conditions.txt', sep = ''))

AIC_plot_video_replication_gesture_main = 
  test_video_replication_gesture  %>%
  filter(interaction=='main') %>%
  filter(modality == 'audiovisual(replication)') %>%
  ggplot(aes(x = model, y = aic_dif, fill = model)) +
  geom_bar(stat='identity') + 
  facet_wrap(vars(gesture_condition), ncol = 2) +
  xlab('') +
  ylab(expression(Delta * 'AIC'))+
  ggtitle('Audiovisual replication, gesture split\nmain effect model') +
  theme(plot.title = element_text(hjust = 0.5),
        legend.position='none')

AIC_plot_video_replication_gesture_inter = 
  test_video_replication_gesture  %>%
  filter(interaction=='interaction') %>%
  filter(modality == 'audiovisual(replication)') %>%
  ggplot(aes(x = model, y = aic_dif, fill = model)) +
  geom_bar(stat='identity') + 
  facet_wrap(vars(gesture_condition), ncol = 2) +
  xlab('') +
  ylab(expression(Delta * 'AIC'))+
  ggtitle('Audiovisual replication, gesture split\ninteraction model') +
  theme(plot.title = element_text(hjust = 0.5),
        legend.position='none')

pdf(paste(path, 'results/model_video_replication_gesture_contidions.pdf', sep = ''), 
    width = 15, height = 4,encoding='MacRoman') # Open a new pdf file
grid.arrange(AIC_plot_video_replication_gesture_main,AIC_plot_video_replication_gesture_inter, ncol = 2, nrow = 1) 
dev.off() 
################################################################
# Scratch
################################################################

########## More plotting #############
data_audio_preprocessed = preprocessing(data_audio)
data_audio_preprocessed$modality = 'audio'
data_audio_preprocessed$bin_id = data_audio_preprocessed$bin_id_video

data_video_preprocessed = preprocessing(data_video)
data_video_preprocessed$modality = 'audiovisual'

data = rbind(data_audio_preprocessed, data_video_preprocessed)

data_plot = data %>%
  mutate (
    ERP_diff = ERP - baseline
  ) %>%
  group_by(bin_id, modality) %>% 
  summarise(across(everything(), list(mean)))


data_plot_ROI = data %>%
  mutate (
    ERP_diff = ERP - baseline
  ) %>%
  group_by(bin_id, modality, ROI) %>% 
  summarise(across(everything(), list(mean)))

data_plot_seq = data %>%
  mutate (
    ERP_diff = ERP - baseline
  ) %>%
  group_by(bin_id, modality, sentence_seq) %>% 
  summarise(across(everything(), list(mean)))


data_plot %>%
  group_by(modality, sentence_seq_1) %>%
  summarise(n())

models <- c('2gram', '3gram', '4gram', '5gram', '6gram', 'bert', 'gpt')


p_list = list()
i=1
for (model in models){
  p = 
    data_plot %>%
    select(modality, ERP_diff_1,!!sym(paste('surprisal_', model, '_1', sep=''))) %>%
    group_by(modality)%>%
    mutate(
      surprisal_cut = as.numeric(cut_number(!!sym(paste('surprisal_', model, '_1', sep='')),40))
    )%>%
    group_by(modality, surprisal_cut) %>%
    summarise(
      ERP_diff = mean(ERP_diff_1)
    ) %>%
    ggplot(aes(x = surprisal_cut, y = ERP_diff, color = modality)) +
    geom_point(alpha=0.5)+
    geom_smooth(method='lm', se=FALSE, fullrange=TRUE) +
    guides(size = 'none')+
    xlab('surprisal') +
    ylab('ERP') +
    ggtitle(model) +
    theme(plot.title = element_text(hjust = 0.5))
  
  p_list[[i]]=p
  i=i+1
}

require(gridExtra)
pdf(paste('/Users/claudia/OneDrive - University College London/surprisal_audio/results/diff_total_40groups.pdf', sep=''), 
    width = 16, height = 3) # Open a new pdf file
ggarrange(plotlist=p_list, ncol=7, nrow=1, common.legend = TRUE, legend='bottom')
#do.call('grid.arrange', c(p_list, ncol=7), mylegend)
#grid.arrange(p_list, ncol = 1, nrow = 7) 
dev.off()

p_list = list()
i=1
for (model in models){
  p = 
    data_plot_ROI %>%
    select(ROI, modality, ERP_diff_1,!!sym(paste('surprisal_', model, '_1', sep=''))) %>%
    group_by(modality, ROI)%>%
    mutate(
      surprisal_cut = as.numeric(cut_number(!!sym(paste('surprisal_', model, '_1', sep='')),40))
    )%>%
    group_by(modality, surprisal_cut, ROI) %>%
    summarise(
      ERP_diff = mean(ERP_diff_1)
    ) %>%
    ggplot(aes(x = surprisal_cut, y = ERP_diff, color = modality)) +
    geom_point(alpha=0.5)+
    geom_smooth(method='lm', se=FALSE, fullrange=TRUE) +
    guides(size = 'none')+
    facet_wrap(~ROI) +
    xlab('surprisal') +
    ylab('ERP') +
    ggtitle(model) +
    theme(plot.title = element_text(hjust = 0.5))
  
  p_list[[i]]=p
  i=i+1
}

require(gridExtra)
pdf(paste('/Users/claudia/OneDrive - University College London/surprisal_audio/results/diff_total_40groups_ROI.pdf', sep=''), 
    width = 10, height = 10) # Open a new pdf file
ggarrange(plotlist=p_list, ncol=3, nrow=3, common.legend = TRUE, legend='bottom')
#do.call('grid.arrange', c(p_list, ncol=4, nrow = 2))
#grid.arrange(p_list, ncol = 1, nrow = 7) 
dev.off()

p_list = list()
i=1
for (model in models){
  p = 
    data_plot_seq %>%
    select(sentence_seq, modality, ERP_diff_1,!!sym(paste('surprisal_', model, '_1', sep=''))) %>%
    group_by(modality, sentence_seq)%>%
    mutate(
      surprisal_cut = as.numeric(cut_number(!!sym(paste('surprisal_', model, '_1', sep='')),40))
    )%>%
    group_by(modality, surprisal_cut, sentence_seq) %>%
    summarise(
      ERP_diff = mean(ERP_diff_1)
    ) %>%
    ggplot(aes(x = surprisal_cut, y = ERP_diff, color = modality)) +
    geom_point(alpha=0.5)+
    geom_smooth(method='lm', se=FALSE, fullrange=TRUE) +
    guides(size = 'none')+
    facet_wrap(~sentence_seq) +
    xlab('surprisal') +
    ylab('ERP') +
    ggtitle(model) +
    theme(plot.title = element_text(hjust = 0.5))
  
  p_list[[i]]=p
  i=i+1
}

library(ggpubr)



require(gridExtra)
pdf(paste('/Users/claudia/OneDrive - University College London/surprisal_audio/results/diff_total_40groups_seq.pdf', sep=''), 
    width = 10, height = 10) # Open a new pdf file
ggarrange(plotlist=p_list, ncol=3, nrow=3, common.legend = TRUE, legend='bottom')
#do.call('grid.arrange', c(p_list, ncol=4, nrow = 2))
#grid.arrange(p_list, ncol = 1, nrow = 7) 
dev.off()



# Test convergence

model_test = lmerTest::lmer((ERP) ~
                              
                              surprisal_prev_z +
                              
                              ## Confounding Variables:
                              word_order +
                              # word_length +
                              sentence_order +
                              baseline +
                              x +
                              y +
                              z +
                              #(1|lemma_prev) +
                              (1+surprisal_prev_z|part_id),
                            data = data, REML=FALSE, 
                            control = lmerControl(optimizer = 'bobyqa')
)
summary(model_test)

# LMER Modelling

model_prev = lmerTest::lmer((ERP) ~
                               
                               surprisal_prev_log_z +
                               
                               ## Confounding Variables:
                               word_order_z +
                               #word_length_z +
                               sentence_order_z +
                               baseline +
                               x_z +
                               y_z +
                               z_z +
                               #(1|lemma_prev) +
                               (1+surprisal_prev_log_z|part_id),
                             data = data, REML=FALSE, 
                             control = lmerControl(optimizer = 'bobyqa')
)
summary(model_prev)

model_prev_prom = lmerTest::lmer((ERP_z) ~
                                    
                                    surprisal_prev_log_z +
                                    prominence_label +
                                    surprisal_prev_log_z:prominence_label +
                                    
                                    ## Confounding Variables:
                                    word_order_z +
                                    #word_length_z +
                                    sentence_order_z +
                                    baseline_z +
                                    x_z +
                                    y_z +
                                    z_z +
                                    #(1|lemma_prev) +
                                    (1+surprisal_prev_log_z|part_id),
                                  data = data, REML=FALSE, 
                                  control = lmerControl(optimizer = 'bobyqa')
)
summary(model_prev_prom)

anova(model_prev, model_prev_prom)

model_prev_F0 = lmerTest::lmer((ERP_z) ~
                                   
                                   surprisal_prev_log_z +
                                   mean_f0_prev_z +
                                   surprisal_prev_log_z:mean_f0_prev_z +
                                   
                                   ## Confounding Variables:
                                   word_order_z +
                                   #word_length_z +
                                   sentence_order_z +
                                   baseline_z +
                                   x_z +
                                   y_z +
                                   z_z +
                                   #(1|lemma_prev) +
                                   (1+surprisal_prev_log_z|part_id),
                                 data = data, REML=FALSE, 
                                 control = lmerControl(optimizer = 'bobyqa')
)
summary(model_prev_F0)

model_ngram = lmerTest::lmer((ERP_z) ~
                         
                         surprisal_ngram_log_z +

                         ## Confounding Variables:
                         word_order_z +
                         #word_length_z +
                         sentence_order_z +
                         baseline_z +
                         x_z +
                         y_z +
                         z_z +
                         #(1|lemma_prev) +
                         (1+surprisal_ngram_log_z|part_id),
                       data = data, REML=FALSE, 
                       control = lmerControl(optimizer = 'bobyqa')
)
summary(model_ngram)

model_ngram_prom = lmerTest::lmer((ERP_z) ~
                               
                               surprisal_ngram_log_z +
                               prominence_label +
                               surprisal_ngram_log_z:prominence_label +
                               
                               ## Confounding Variables:
                               word_order_z +
                               #word_length_z +
                               sentence_order_z +
                               baseline_z +
                               x_z +
                               y_z +
                               z_z +
                               #(1|lemma_prev) +
                               (1+surprisal_ngram_log_z|part_id),
                             data = data, REML=FALSE, 
                             control = lmerControl(optimizer = 'bobyqa')
)
summary(model_ngram_prom)

anova(model_ngram, model_ngram_prom)

model_gpt = lmerTest::lmer((ERP_z) ~
                               
                               surprisal_gpt_log_z +
                               
                               ## Confounding Variables:
                               word_order_z +
                               #word_length_z +
                               sentence_order_z +
                               baseline_z +
                               x_z +
                               y_z +
                               z_z +
                               #(1|lemma_prev) +
                               (1+surprisal_gpt_log_z|part_id),
                             data = data, REML=FALSE, 
                             control = lmerControl(optimizer = 'bobyqa')
)
summary(model_gpt)

model_gpt_prom = lmerTest::lmer((ERP_z) ~
                             
                             surprisal_gpt_log_z +
                             prominence_label +
                             surprisal_gpt_log_z:prominence_label +
                             
                             ## Confounding Variables:
                             word_order_z +
                             #word_length_z +
                             sentence_order_z +
                             baseline_z +
                             x_z +
                             y_z +
                             z_z +
                             #(1|lemma_prev) +
                             (1+surprisal_gpt_log_z|part_id),
                           data = data, REML=FALSE, 
                           control = lmerControl(optimizer = 'bobyqa')
)
summary(model_gpt_prom)

anova(model_gpt, model_gpt_prom)

model_bert = lmerTest::lmer((ERP_z) ~
                             
                             surprisal_bert_log_z +
                             
                             ## Confounding Variables:
                              word_order_z +
                              #word_length_z +
                              sentence_order_z +
                              baseline_z +
                              x_z +
                              y_z +
                              z_z +
                             #(1|lemma_prev) +
                             (1+surprisal_bert_log_z|part_id),
                           data = data, REML=FALSE, 
                           control = lmerControl(optimizer = 'bobyqa')
)
summary(model_bert)

model_bert_prom = lmerTest::lmer((ERP_z) ~
                              
                              surprisal_bert_log_z +
                              prominence_label +
                              surprisal_bert_log_z:prominence_label +
                              
                              ## Confounding Variables:
                              word_order_z +
                              #word_length_z +
                              sentence_order_z +
                              baseline_z +
                              x_z +
                              y_z +
                              z_z +
                              #(1|lemma_prev) +
                              (1+surprisal_bert_log_z|part_id),
                            data = data, REML=FALSE, 
                            control = lmerControl(optimizer = 'bobyqa')
)
summary(model_bert_prom)

anova(model_bert, model_bert_prom)

f = lm (ERP_z ~ surprisal_bert_log_z + baseline_z, data = data_prev)
summary(f)



####################### Prev filtering scripts #######################

# Categorical variable
data$prominence_label = as.factor(data$prominence_label) # dummy coding, 0 as baseline

# Continuous variables: center scaling
data <- mutate(data,
               ERP_z = scale(ERP),
               surprisal_prev_log_z = scale(log(surprisal_prev)),
               surprisal_ngram_log_z = scale(log(surprisal_ngram)),
               surprisal_gpt_log_z = scale(log(surprisal_gpt)),
               surprisal_bert_log_z = scale(log(surprisal_bert)),
               
               surprisal_prev_z = scale(surprisal_prev),
               surprisal_ngram_z = scale(surprisal_ngram),
               surprisal_gpt_z = scale(surprisal_gpt),
               surprisal_bert_z = scale(surprisal_bert),
               
               word_order = word_sequence,
               word_length = word_len_prev,
               
               mean_f0_prev_z = scale(mean_f0_prev),
               word_order_z = scale(word_sequence),
               sentence_order_z = scale(sentence_order),
               word_length_z = scale(word_len_prev),
               
               baseline_z = scale(baseline),
               x_z = scale(x),
               y_z = scale(y),
               z_z = scale(z)
)