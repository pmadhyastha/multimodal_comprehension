The scripts in this folder are:

First, we will start with preprocessing: 

We start from EEG data, please look at section a in data/README.md fordetails relating to the EEG data. We are following [ref] for the preprocessing (this is a standard pre-processing technique ). 
Please follow preprocessing scripts below: 
  - `preprocessing_audio.m & preprocessing_video.m`: 
  - These are Matlab scripts for EEG preprocessing, 

Then we will 

preprocessing_generate_eventlist.py: scripts generating eventlists described above

supplementary scripts are provided in folderX, note that there this doesn't have sufficient documentation, but it was mostly used for data wrangling. 
preprocessing_variables.py: adding design matrix to the EEG data (in lmer folders) for analysis in R
LIMO_variables.py: LIMO package in Matlab was used at one point to identify time window associated with surprisal. This script generate variables for that analysis.
audio_lmer.R: statistical analysis and plotting in R
