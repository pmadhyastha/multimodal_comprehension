The scripts in this folder are:

First, we will start with preprocessing: 

`preprocessing_audio.m & preprocessing_video.m`: Matlab scripts for EEG preprocessing
preprocessing_generate_eventlist.py: scripts generating eventlists described above
preprocessing_variables.py: adding design matrix to the EEG data (in lmer folders) for analysis in R
LIMO_variables.py: LIMO package in Matlab was used at one point to identify time window associated with surprisal. This script generate variables for that analysis.
audio_lmer.R: statistical analysis and plotting in R
