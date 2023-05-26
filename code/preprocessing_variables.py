################################################################

# AUDIO & AV SURPRISAL PROJECT

# This script combines EEG data (csv files, exported from ERP) with: 
# 1. Design matrix: e.g. surprisal info per word
# 2. Channel coordinate: x, y, z coordinates of each electrode, measuring topographic distribution of electrodes 
# 3. Baseline: EEG amplitude -100 to 0 before words, as the baseline correction was not performed during preprocessing (see Frank et al., 2015; Alday et al, 2017; Zhang et al., 2021)
# 4. Artifact rejection label: artifact rejection is completed in erplab but somehow the information is not recorded correctly when exporting. Therefore, the eventlists are exported after artifact rejection and the rejection label per word is extracted and combined with data.
# 5. Sentence order: sentence order is extracted from eventlist as a control variable in analysis

################################################################

# Importing modules and setting display
import pandas as pd

pd.set_option('display.width', 400)
pd.set_option('display.max_columns', 40)
pd.set_option('display.max_rows', 500)
pd.options.mode.chained_assignment = None  # default='warn'

# Setting parameters based on audio/video data, change mode below according to need
mode = 'audio'
#mode = 'video'

if mode == 'audio':
    path = '/Users/claudia/OneDrive - University College London/surprisal_audio/data_audio/' # path for audio data
    bin_id_mode = 'bin_id_audio'
    part_num = 25
    skipnum = 4733
elif mode == 'video':
    path = '/Users/claudia/OneDrive - University College London/surprisal_audio/data_video/'  # path for audiovisual data
    bin_id_mode = 'bin_id_video'
    part_num = 30
    skipnum = 2674
else:
    print('Error in mode!')

# Loading design matrix with info per word
info = pd.read_excel('/Users/claudia/OneDrive - University College London/surprisal_audio/stimuli/word_merged_audio_seq.xlsx')
info['bin_id'] = info[bin_id_mode]
electrode = pd.read_csv('/Users/claudia/OneDrive - University College London/surprisal_audio/stimuli/channel_coordinate.csv')
electrode.columns = ['electrode', 'x', 'y', 'z']
electrode['electrode'] = electrode['electrode'].str.strip(' ')


# Loading data & baseline
baseline = pd.read_csv(path + 'lmer/baseline.txt', sep="\t",
                       usecols=['       value', '     chlabel', '        bini', 'ERPset'])
baseline.columns = ['baseline', 'electrode', 'bin_id', 'part_id']

data = pd.read_csv(path + 'lmer/300-500.txt', sep="\t",
                   usecols=['       value', '     chlabel', '        bini', 'ERPset'])
data.columns = ['ERP', 'electrode', 'bin_id', 'part_id']

# Merging data with design matrix & baseline
data_baselined = pd.merge(data, baseline, on=['electrode', 'bin_id', 'part_id'])
data_baselined['electrode'] = data_baselined['electrode'].str.strip(' ')
data_baselined_removed = data_baselined[(data_baselined['ERP']!= 0) | (data_baselined['baseline']!= 0)]

data_baselined_removed_info = pd.merge(data_baselined_removed, info, on = ['bin_id'])

data_baselined_removed_info_location = pd.merge(data_baselined_removed_info, electrode,on=['electrode'])

# Extracting info from eventlist (AR, sentence sequence)
elist_full = []
info_filtered = info[info['bin_id'].notnull()] # there are empty entries in video mode, filtering out to make sure there is not bug in mapping
sentence_dic = dict(zip(info_filtered.bin_id, info_filtered.sentence_id))
for i in range (1, part_num+1):
    part_id = 'part' + str(i)
    elist_slice = pd.read_csv(path + 'eventlist/export_ar/eventlist_export_AR_' + str(part_id) + '.txt',
        sep="\t", skiprows=skipnum, header=None, usecols=[2, 7])
    elist_slice.columns = ['bin_id', 'ar']
    elist_slice['part_id'] = part_id

    # Somehow there's error when syncing AR info with ERP in audio data. Therefore do it manually here. Remove if not needed
    elist_slice['ar_good'] = elist_slice['ar'].apply(lambda x: True if x == '    00000000     00000000' else False)

    elist_slice['sentence_id'] = elist_slice['bin_id'].map(sentence_dic)
    sentence_order = elist_slice.groupby('sentence_id', sort=False).count().reset_index()['sentence_id'].reset_index()
    sentence_order.columns = ['sentence_order', 'sentence_id']
    elist_slice_order = pd.merge(elist_slice, sentence_order, on = 'sentence_id')

    elist_full.append(elist_slice_order)
elist_info = pd.concat(elist_full)

# Merging data with AR lable and sentence sequence
data_baselined_removed_info_location_elist = pd.merge(data_baselined_removed_info_location, elist_info, on=['part_id', 'bin_id'])
data_baselined_removed_info_location_elist.drop(columns=
    ['meaningful_gesture_prev', 'beat_gesture_prev', 'gesture_corres_prev', 'mouth_dist_prev', 'ar', 'sentence_id_y'], inplace=True
)

# Saving final file
data_baselined_removed_info_location_elist.to_csv(path + 'lmer/300-500_info.csv')