################################################################

# AUDIO & AV SURPRISAL PROJECT

# This script creates design matrix by combining word information from different sources:
# Prosodic prominence
# Previous word info from Zhang et al., 2021

################################################################
import pandas as pd
import os

data_slices = []
def combine_data(path):
    for filename in os.listdir(path):
        if '.prom.disc' in filename:
            f = os.path.join(path, filename)
            # checking if it is a file
            if os.path.isfile(f):
                slice = pd.read_csv(f, sep='\t', header=None)
                data_slices.append(slice)
combine_data('/Users/claudia/OneDrive - University College London/surprisal_audio/stimuli/prosody_category/GestureAudio/')
combine_data('/Users/claudia/OneDrive - University College London/surprisal_audio/stimuli/prosody_category/NoGestureAudio/')

data = pd.concat(data_slices,axis=0)
data.columns = ['sentence_id', 'onset', 'offset', 'word', 'prominence_value', 'boundary_value', 'prominence_label']
data['id'] = data['sentence_id'].str.rstrip('SG')
data = data.sort_values(by = ['id'])
data = data[data['word']!='_SIL_']
data.reset_index(inplace = True)
data.drop(columns = ['index','id'], inplace = True)
data.reset_index(inplace = True)
data.rename(columns = {'index':'bin_id_new'}, inplace = True)

info_prev = pd.read_csv('/Users/claudia/OneDrive - University College London/surprisal_audio/stimuli/WordMerged_total.csv',
                        usecols = ['WordID', 'SentenceID', 'Unnamed: 3', 'word', 'bin_id', 'maxf0', 'minf0', 'meanf0',
       'meanIntensity', 'FrequencyNew', 'POSBinary', 'POSDetail', 'lemma', 'wdLen', 'SurprisalFull'])
info_prev['sentence_id'] = info_prev['SentenceID'].astype('str') + info_prev['Unnamed: 3']
info_prev.drop(columns=['SentenceID', 'Unnamed: 3'], inplace=True)

data_info = pd.merge(data, info_prev, on=['sentence_id', 'word'], how = 'left')
data_info.columns = ['bin_id_new', 'sentence_id', 'onset', 'offset', 'word', 'prominence_value',
       'boundary_value', 'prominence_label', 'word_sequence', 'bin_id_old','maxf0', 'minf0',
       'meanf0', 'mean_intensity', 'frequency', 'pos_binary', 'pos_detail',
       'lemma', 'word_length', 'surprisal']

data.to_excel('/Users/claudia/OneDrive - University College London/surprisal_audio/stimuli/word_merged_audio.xlsx')


data = pd.read_excel('/Users/claudia/OneDrive - University College London/surprisal_audio/stimuli/word_merged_audio.xlsx')
info_use = info_prev[['word', 'BinID','POSBinary', 'POSDetail', 'lemma', 'wdLen','sentence_id']]
data_info = pd.merge(data, info_use, on=['sentence_id', 'word'], how = 'left')
data_info.to_excel('/Users/claudia/OneDrive - University College London/surprisal_audio/stimuli/word_merged_audio_bin.xlsx')
info_now = pd.read_excel('/Users/claudia/OneDrive - University Coimport pandas as pd
import os

data_slices = []
def combine_data(path):
    for filename in os.listdir(path):
        if '.prom.disc' in filename:
            f = os.path.join(path, filename)
            # checking if it is a file
            if os.path.isfile(f):
                slice = pd.read_csv(f, sep='\t', header=None)
                data_slices.append(slice)
combine_data('/Users/claudia/OneDrive - University College London/surprisal_audio/stimuli/prosody_category/GestureAudio/')
combine_data('/Users/claudia/OneDrive - University College London/surprisal_audio/stimuli/prosody_category/NoGestureAudio/')

data = pd.concat(data_slices,axis=0)
data.columns = ['sentence_id', 'onset', 'offset', 'word', 'prominence_value', 'boundary_value', 'prominence_label']
data['id'] = data['sentence_id'].str.rstrip('SG')
data = data.sort_values(by = ['id'])
data = data[data['word']!='_SIL_']
data.reset_index(inplace = True)
data.drop(columns = ['index','id'], inplace = True)
data.reset_index(inplace = True)
data.rename(columns = {'index':'bin_id_new'}, inplace = True)

info_prev = pd.read_csv('/Users/claudia/OneDrive - University College London/surprisal_audio/stimuli/WordMerged_total.csv',
                        usecols = ['WordID', 'SentenceID', 'Unnamed: 3', 'word', 'bin_id', 'maxf0', 'minf0', 'meanf0',
       'meanIntensity', 'FrequencyNew', 'POSBinary', 'POSDetail', 'lemma', 'wdLen', 'SurprisalFull'])
info_prev['sentence_id'] = info_prev['SentenceID'].astype('str') + info_prev['Unnamed: 3']
info_prev.drop(columns=['SentenceID', 'Unnamed: 3'], inplace=True)

data_info = pd.merge(data, info_prev, on=['sentence_id', 'word'], how = 'left')
data_info.columns = ['bin_id_new', 'sentence_id', 'onset', 'offset', 'word', 'prominence_value',
       'boundary_value', 'prominence_label', 'word_sequence', 'bin_id_old','maxf0', 'minf0',
       'meanf0', 'mean_intensity', 'frequency', 'pos_binary', 'pos_detail',
       'lemma', 'word_length', 'surprisal']

data.to_excel('/Users/claudia/OneDrive - University College London/surprisal_audio/stimuli/word_merged_audio.xlsx')


data = pd.read_excel('/Users/claudia/OneDrive - University College London/surprisal_audio/stimuli/word_merged_audio.xlsx')
info_use = info_prev[['word', 'BinID','POSBinary', 'POSDetail', 'lemma', 'wdLen','sentence_id']]
data_info = pd.merge(data, info_use, on=['sentence_id', 'word'], how = 'left')
data_info.to_excel('/Users/claudia/OneDrive - University College London/surprisal_audio/stimuli/word_merged_audio_bin.xlsx')
info_now = pd.read_excel('/Users/claudia/OneDrive - University College London/surprisal_audio/stimuli/word_merged_audio.xlsx')
info_temp = pd.merge(info_prev, info_now, on=['sentence_id', 'word'], how = 'left')
info_temp.columns = ['word_sequence', 'word', 'bin_id', 'maxf0', 'minf0', 'meanf0',
       'meanIntensity', 'FrequencyNew', 'pos_binary', 'POSDetail', 'lemma',
       'word_length', 'surprisal', 'sentence_id', 'word_sequence', 'onset',
       'offset', 'prominence_value', 'boundary_value', 'prominence_label',
       'id', 'bin_id_new', 'bin_id_old', 'surprisal_ngram', 'surprisal_gpt',
       'surprisal_bert']
info_temp.to_excel('/Users/claudia/OneDrive - University College London/surprisal_audio/stimuli/word_merged_audio_temp.xlsx')

llege London/surprisal_audio/stimuli/word_merged_audio.xlsx')
info_temp = pd.merge(info_prev, info_now, on=['sentence_id', 'word'], how = 'left')
info_temp.columns = ['word_sequence', 'word', 'bin_id', 'maxf0', 'minf0', 'meanf0',
       'meanIntensity', 'FrequencyNew', 'pos_binary', 'POSDetail', 'lemma',
       'word_length', 'surprisal', 'sentence_id', 'word_sequence', 'onset',
       'offset', 'prominence_value', 'boundary_value', 'prominence_label',
       'id', 'bin_id_new', 'bin_id_old', 'surprisal_ngram', 'surprisal_gpt',
       'surprisal_bert']
info_temp.to_excel('/Users/claudia/OneDrive - University College London/surprisal_audio/stimuli/word_merged_audio_temp.xlsx')

