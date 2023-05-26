################################################################

# AUDIO & AV SURPRISAL PROJECT

# This script generates the the regressor for LIMO analysis. LIMO analysis takes the surprisal (and prominence, although not included in the analysis) of each word, arranged according to the order of presentation. The LIMO analysis was not included in the later paper.

################################################################

# Importing modeules and setting display
import pandas as pd
import csv
import numpy as np

pd.set_option('display.width', 400)
pd.set_option('display.max_columns', 40)
pd.set_option('display.max_colwidth', 100)
pd.set_option('display.max_rows', 500)


# Setting path and reading files. Change path based on audio/video data
#path = '/Users/claudia/OneDrive - University College London/surprisal_audio/data/preprocessing' # Audio LIMO
path = '/Users/claudia/OneDrive - University College London/surprisal_audio/data/data_video' # Video LIMO
info = pd.read_excel('/Users/claudia/OneDrive - University College London/surprisal_audio/stimuli/word_merged_audio.xlsx')

# Iterating across all participants. Change i range based on number of participant
for i in range (1,32):

    part_id = i

    ## Reading eventlists for sequence of words
    #skip_num = 4733 # Audio: skipping the first 4733 rows with header info
    skip_num = 2674 # Video: skipping the first 2674 rows with header info
    eventlist = pd.read_csv(path + '/eventlist/export/eventlist_export_part'+str(part_id)+'.txt',
                            skiprows=skip_num, sep = '\t', header=None, usecols=[2])
    eventlist.columns = ['bin_id']

    #eventlist.drop(index=eventlist.index[:8],inplace=True) # somehow the first 8 rows of events are not included in epoch for part 1-9 & 25, need to investigate why; this is now removed because exported eventlist already removed these lines, still no idea why

    ## Add surprisal & prominence info per event
    # events_info = pd.merge(eventlist, info, on=['bin_id'], how='left') # Audio: merge on bin_id
    events_info = pd.merge(eventlist, info, left_on=['bin_id'], right_on= ['bin_id_prev'], how='left')  # Video: merge on bin_id_prev

    events_info['prominence_label'].replace(3,np.nan, inplace = True) # exclude words with prominence label 3
    events_info['pos_prev'].replace(0, np.nan, inplace = True) # exclude function words
    events_info['surprisal_ngram_content'] = np.where(events_info['pos_prev'].isnull(), events_info['pos_prev'],
                                                      events_info['surprisal_ngram'])
    events_info['surprisal_gpt_content'] = np.where(events_info['pos_prev'].isnull(), events_info['pos_prev'],
                                                      events_info['surprisal_gpt'])
    events_info['surprisal_bert_content'] = np.where(events_info['pos_prev'].isnull(), events_info['pos_prev'],
                                                      events_info['surprisal_bert'])

    # events_info['pos_prev_next'] = events_info.groupby('sentence_id')['pos_prev'].shift(-1)  # know the POS status of the next word, to analyse the words immediately before a content word
    # events_info['surprisal_ngram_precontent'] = np.where(events_info['pos_prev_next'].isnull(), events_info['pos_prev_next'],
    #                                                   events_info['surprisal_ngram'])
    # events_info['surprisal_gpt_precontent'] = np.where(events_info['pos_prev_next'].isnull(), events_info['pos_prev_next'],
    #                                                 events_info['surprisal_gpt'])
    # events_info['surprisal_bert_precontent'] = np.where(events_info['pos_prev_next'].isnull(), events_info['pos_prev_next'],
    #                                                  events_info['surprisal_bert'])

    ## Writting LIMO regressor
    events_info['prominence_label'].to_csv(path + '/LIMO/data/part'+str(part_id) + '/part'+str(part_id) +'_prom.txt',
                                           index=False, header=False,
                                           na_rep="NaN",
                                           quoting=csv.QUOTE_NONE)

    events_info['surprisal_ngram'].to_csv(path + '/LIMO/data/part'+str(part_id) + '/part'+str(part_id) + '_surp_ngram.txt',
                                           index=False, header=False,
                                           na_rep="NaN",
                                           quoting=csv.QUOTE_NONE)

    events_info['surprisal_gpt'].to_csv(path + '/LIMO/data/part'+str(part_id) + '/part'+str(part_id) + '_surp_gpt.txt',
                                           index=False, header=False,
                                           na_rep="NaN",
                                           quoting=csv.QUOTE_NONE)

    events_info['surprisal_bert'].to_csv(path + '/LIMO/data/part'+str(part_id) + '/part'+str(part_id) + '_surp_bert.txt',
                                           index=False, header=False,
                                           na_rep="NaN",
                                           quoting=csv.QUOTE_NONE)

    events_info['surprisal_ngram_content'].to_csv(path + '/LIMO/data/part'+str(part_id) + '/part'+str(part_id) + '_surp_ngram_content.txt',
                                           index=False, header=False,
                                           na_rep="NaN",
                                           quoting=csv.QUOTE_NONE)

    events_info['surprisal_gpt_content'].to_csv(path + '/LIMO/data/part'+str(part_id) + '/part'+str(part_id) + '_surp_gpt_content.txt',
                                           index=False, header=False,
                                           na_rep="NaN",
                                           quoting=csv.QUOTE_NONE)

    events_info['surprisal_bert_content'].to_csv(path + '/LIMO/data/part'+str(part_id) + '/part'+str(part_id) + '_surp_bert_content.txt',
                                           index=False, header=False,
                                           na_rep="NaN",
                                           quoting=csv.QUOTE_NONE)
