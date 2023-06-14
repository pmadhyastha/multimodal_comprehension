The scripts in this folder are:

First, we will start with preprocessing: 

We start from EEG data, please look at section a in data/README.md fordetails relating to the EEG data. We are following Zhang et al., 2021 (https://royalsocietypublishing.org/doi/abs/10.1098/rspb.2021.0500) for the preprocessing (a standard pre-processing pipeline). The EEG data can be found on osf (LINK ID TO ADD).
Please follow preprocessing scripts below: 
  - `preprocessing_audio.m & preprocessing_video.m`: 
  - These are Matlab scripts for EEG preprocessing. It carries out steps including: 1. getting channel locations; 2. assigning eventlists (created by preprocessing_generate_eventlist.py), 3. assigning binlisters, 4. extracting epochs, 5. filtering, 6. cleaning epochs, 7. running ICA, 8. removing noise components (following https://labeling.ucsd.edu/tutorial), 9. Artifact rejection: moving window peak to peak, 10. Artifact rejection: step-wise, 11. calculate averaged ERP 
  - Note that step 6 and 8 are conducted manually. 
  - Requirement: MATLAB, EEGlab (https://eeglab.org) and ERPlab (https://erpinfo.org/erplab).

Then we will manually extract mean ERP amplitude in 300-500ms (N400) and -100-0ms (baseline) using ERP measurement tool in ERPlab. The data is saved as csv file, and can be found in data/data_*/lmer/ folders. We followed Zhang et al., 2021 and we did not remove baseline during the epoching (s4), but rather extracted baseline ERP amplitude and included it in subsequent LMER analysis.

We then used preprocessing_variables.py to add design matrix to the ERP data for analysis in R. The output is in data/data_*/lmer/300-500ms_info.csv. Note that the design matrix is created with a series of scripts that broadly merge word by word quantifications from different sources. As each script was tailored for individual needs, they are without sufficient documentations. Please find the scripts in code/supplementary_scripts/.

Finally, we used audio_lmer.R to analyse the 300-500ms_info.csv, conducting statistical analysis and plottings
