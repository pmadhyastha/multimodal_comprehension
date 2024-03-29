################################################################

# AUDIO & AV SURPRISAL PROJECT

# This script generates the eventlist used for the EEG analysis. Typically eventlist is automatically generated based on trigger sent during the experiment, marking the timing of each event. However, in our natrualistic comprehension paradigm, we measure N400 of each word in natrually produced speech and words come very close with each other. If we send one trigger per word, the distance will be too close so that the trigger may "jam", making the timing inaccurate. Instead, we send trigger for each video onset, and then annotate the onset per word (relative to video onset). The correct timing is then calculated accordingly to create a new eventlist, which replaces the automatically generated one.

################################################################

# Importing packages & setting display
import pandas as pd
import csv

pd.set_option('display.width', 400)
pd.set_option('display.max_columns', 40)
pd.set_option('display.max_rows', 500)
pd.options.mode.chained_assignment = None  # default='warn'

# Iterating across all participants to create new eventlists
for i in range (1, 26):

    partID = 'part'+str(i)
    file_path = '/Users/claudia/OneDrive - University College London/surprisal_audio/data/preprocessing/'

    ## Reading original eventlist, containing video onsets
    eventlist = pd.read_csv(file_path+'eventlist/original/eventlist_'+partID+'.txt',
                            skiprows=20, # Excluding 20 'non-editable headers', eventlist works without it
                            sep="\t")

    ## Reading log generated by Presentation software to get video sequence. Each participants has two log files (a & b).
    log_a = pd.read_csv(file_path+'log/'+partID+'_a.log',
                      skiprows=3, # Excluding 3 lines header, with scenario info
                      skipfooter=13, # Excluding 13 lines of footers, with scenario info
                      sep="\t",
                      engine='python')

    log_b = pd.read_csv(file_path+'log/'+partID+'_b.log',
                      skiprows=3, # Excluding 3 lines header, with scenario info
                      skipfooter=13, # Excluding 13 lines of footers, with scenario info
                      sep="\t",
                      engine='python')

    log_a_events = log_a[log_a['Event Type'] == 'Sound'] # Get video sequence
    log_b_events = log_b[log_b['Event Type'] == 'Sound']
    log_events = pd.concat([log_a_events,log_b_events])
    log_events.reset_index(inplace = True)

    ## Mapping eventlist to log
    #eventlist_exp4['sentenceID'] = log_events ['Code']
    eventlist_onset = eventlist[['      onset', '  ecode']]
    eventlist_onset = eventlist_onset.drop(eventlist_onset[(eventlist_onset['  ecode'] == 201) |
                                          (eventlist_onset['  ecode'] == 202)].index) # dropping 2 response buttons, annoyingly they also share the same trigger ID with 2 sentences (101 and 102), so the two sentences are excluded as well
    eventlist_onset['passage_id'] = eventlist_onset['  ecode']-100

    log_events['passage_id'] = log_events ['Code'].str.rstrip('SG')
    log_events_use = log_events[['passage_id', 'Code']]
    log_events_use['passage_id'] = log_events_use['passage_id'].astype('int')
    eventlist_onset_code = pd.merge(eventlist_onset, log_events_use, on = 'passage_id', how = 'left')

    eventlist_onset_code.drop(
        eventlist_onset_code[(eventlist_onset_code['passage_id'] == 49)|
                             (eventlist_onset_code['passage_id'] == 85)|
                             (eventlist_onset_code['passage_id'] == 29)].index,
        inplace=True
    )

    ## Calculating word onset
    info = pd.read_excel('/Users/claudia/OneDrive - University College London/surprisal_audio/stimuli/word_merged_audio.xlsx')
    info_onset = info[['bin_id', 'onset', 'word', 'sentence_id']]
    info_onset_combined = pd.merge(eventlist_onset_code, info_onset, left_on=['Code'], right_on=['sentence_id'], how='left')
    info_onset_combined['word_onset'] = info_onset_combined['onset'] + info_onset_combined['      onset']
    info_onset_combined['diff'] = info_onset_combined['word_onset'].diff()*1000

    ## Creating new eventlist
    new_eventlist = info_onset_combined[['bin_id', 'word_onset', 'diff']]
    new_eventlist.reset_index(inplace = True)
    new_eventlist = new_eventlist.dropna()

    new_eventlist['bin_id'] = new_eventlist['bin_id'].astype('int')
    new_eventlist['bepoch']='0.0'
    new_eventlist['label']='""'
    new_eventlist['dura'] = '0.0'
    new_eventlist['b_flags'] = '00000000     00000000'
    new_eventlist['a_flags'] = '1.0'
    new_eventlist['enable'] = '[    '
    #new_eventlist['bin'] = new_eventlist['binID'].astype(str)+']' #assing bin in the eventlist so that no need to run binlister separately
    new_eventlist['bin'] = ']'
    new_eventlist = new_eventlist[['index', 'bepoch', 'bin_id', 'label', 'word_onset', 'diff', 'dura', 'b_flags', 'a_flags', 'enable', 'bin']]
    new_eventlist.columns = eventlist.columns

    new_eventlist.to_csv(file_path+'eventlist/word/eventlist_word_'+partID+'.txt',
                         index=None, sep='\t', mode='w',
                         quoting=csv.QUOTE_NONE) # this function from package csv somehow solve the additional quatation mark issue!
