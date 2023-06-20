The scripts in this folder analysed data stored in OSF (https://osf.io/x7u4j/), please see README in data section for details. The scripts perform the steps below: 

1. Preprocessing

The preprocessing pipeline follows a standard approach (as in Zhang et al, 2021) and can be executed using the provided MATLAB scripts. 

- input: *_original_EEG.zip
- output: *_ERP.zip
- Installation requirement: MATLAB, EEGlab (https://eeglab.org) and ERPlab (https://erpinfo.org/erplab).
- Running preprocessing_audio.m & preprocessing_video.m. These two scripts carried out a preprocessing pipeline including: 1) getting channel locations, 2) assigning event lists (created by preprocessing_generate_eventlist.py), 3) assigning binlisters, 4) extracting epochs, 5) filtering, 6) cleaning epochs, 7) running ICA, 8) removing noise components (following https://labeling.ucsd.edu/tutorial), 9) performing artifact rejection using moving window peak-to-peak method and 10) step-wise artifact rejection and 11) calculates averaged ERP. Note that the step 6) and 8) are carried out manually

2. Extracting N400

- input: *_ERP.zip
- output: *_lmer.zip/300-500.txt and baseline.txt
-  Manually extract mean ERP amplitudes in the 300-500ms (N400) and -100-0ms (baseline) time windows using the ERP measurement tool in ERPlab. It's important to note that we did not remove the baseline during epoching (s4) as per Zhang et al., 2021. Instead, we extracted the baseline ERP amplitude and included it in the subsequent LMER (linear mixed-effects regression) analysis.

3. Adding information per word

- input: *_lmer.zip/300-500.txt and baseline.txt, word_info.zip/word_merged_*.csv, word_info.zip/channel_coordinate.csv (also found in github data section)
- output: *_lmer.zip/300-500_info.csv
- Running preprocessing_variables.py to add baseline (baseline.txt) design matrix (word_merged_*.csv), electrode coordinates (channel_coordinate.csv) to the N400 data. 
- Note that the design matrix is created by merging word-by-word quantifications from various sources (see word_info.zip/word_quantifications). The scripts that combines them are tailored for individual needs and lack sufficient documentation. You can find these scripts in the code/supplementary_scripts/ directory.


4. Statistical Analysis
- input: *_lmer.zip/300-500_info.csv
- Running audio_lmer.R script section by section to conduct statistical analysis and piloting

Please refer to the individual scripts for additional instructions and requirements.
