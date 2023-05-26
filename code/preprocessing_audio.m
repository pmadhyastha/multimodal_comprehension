%% General set up
%path = 'C:\Users\y.zhang\OneDrive - University College London\surprisal_audio\data\preprocessing';
path = '/Users/claudia/Library/CloudStorage/OneDrive-UniversityCollegeLondon/surprisal_audio/data/preprocessing';

%% Pre ICA
for id = 19
    
    partID = strcat('part',num2str(id));
    EEG = pop_loadset(strcat(partID,'.set'),strcat(path,'/1_located/'));
%{
%1. Getting channel location. Somehow always require manual click of OK...
    EEG = pop_loadset(strcat(partID,'.set'), '/Users/claudia/Library/CloudStorage/OneDrive-UniversityCollegeLondon/surprisal_audio/data/original/');
    EEG = pop_chanedit(EEG, '/Users/claudia/Documents/MATLAB/eeglab14_1_1b/plugins/dipfit2.4/standard_BESA/standard-10-5-cap385.elp');
    pop_saveset( EEG, partID, strcat(path,'/1_located/'));
%1. Create eventlists
    EEG  = pop_creabasiceventlist( EEG , 'AlphanumericCleaning', 'on', 'BoundaryNumeric', { -99 }, 'BoundaryString', { 'boundary' }, 'Eventlist',...
 strcat('/Users/claudia/Library/CloudStorage/OneDrive-UniversityCollegeLondon/surprisal_audio/data/eventlist/original/eventlist_',partID,'.txt' ));
%}

    %2. Replace eventlist
    EEG = pop_importeegeventlist( EEG, strcat(path,'/eventlist/word/eventlist_word_',partID,'.txt') ,...
     'ReplaceEventList', 'on' );
    pop_saveset( EEG, partID, strcat(path,'/2_elisted/'));
    
    %3. Assign bin
    EEG  = pop_binlister( EEG , 'BDF', strcat(path,'/binlister.txt'),...
     'IndexEL',  1, 'SendEL2', 'EEG', 'Voutput', 'EEG' ); % GUI: 04-Jul-2022 15:26:41
    pop_saveset( EEG, partID, strcat(path,'/3_bined/'));

    %4. Extract epoch
    EEG = pop_epochbin( EEG , [-200.0  1200.0],  'none'); % No baseline correction performed
    pop_saveset( EEG, partID, strcat(path,'/4_epoched/'));

    %5. Filter
    %EEG  = pop_basicfilter( EEG,  1:34 , 'Cutoff', [ 0.1 100], 'Design', 'butter', 'Filter', 'bandpass', 'Order',...
    %2 );
    EEG  = pop_basicfilter( EEG,  1:34 , 'Cutoff', [ 0.1 100], 'Design', 'butter', 'Filter', 'bandpass', 'Order',  2, 'RemoveDC',...
    'on' ); % GUI: 01-Sep-2022 21:32:07, probably better to remove DC because we did not baseline correct data
    pop_saveset( EEG, partID, strcat(path,'/5_filtered/'));

    %6. Epoch clean
    % - If there are a large amount of data contaminated with noise, 
    %   manually reject epoch before running ICA. Overwrite the file in 6_epoch_cleaned
    % - Otherwise just save the same data as 5 in 6_epoch_cleaned
    pop_saveset( EEG, partID, strcat(path,'/6_epoch_cleaned/'));
    
%}
end    
%% ICA
for id = 19
    partID = strcat('part',num2str(id));
    EEG = pop_loadset(strcat(partID,'.set'),strcat(path,'/6_epoch_cleaned/'));

    % 7 Run ICA
    EEG = pop_runica(EEG, 'icatype', 'runica');
    pop_saveset( EEG, partID, strcat(path,'/7_ICA_computed'));
end
%% Post ICA
for id = 23
    partID = strcat('part',num2str(id));
    EEG = pop_loadset(strcat(partID,'.set'),strcat(path,'/8_ICA_removed/'));
    
    % 9.Artifact rejection: moving window peak to peak 
    EEG  = pop_artmwppth( EEG , 'Channel',  1:34, 'Flag',  1, 'Threshold',  100, 'Twindow', [ -199.2 1195.3], 'Windowsize',  200, 'Windowstep',...
      20 );
    pop_saveset(EEG, partID, strcat(path,'/9_AR_moving_window/'));

    % 10.Artifact rejection: step-wise
    EEG  = pop_artstep( EEG , 'Channel',  1:34, 'Flag',  1, 'Threshold',  35, 'Twindow', [ -199.2 1195.3], 'Windowsize',  400, 'Windowstep',...
      10 );
    pop_saveset( EEG, partID, strcat(path,'/10_AR_stepwise/'));

end
%% ERP
% 10.ERP calculation
for id = 15:25
    partID = strcat('part',num2str(id));
    EEG = pop_loadset(strcat(partID,'.set'),strcat(path,'/10_AR_stepwise/'));    
    ERP = pop_averager( EEG , 'Criterion', 'all', 'ExcludeBoundary', 'on', 'SEM', 'on' ); %somehow criterion 'good' can't work. Therefore I have to make it "all" here and use eventlist to reject later. This is not ideal but is probably a easy way to fix this
    pop_savemyerp( ERP, 'erpname', partID, 'filename', strcat(partID,'.erp'), 'filepath', strcat(path,'/11_ERP/'));
    
end

%% Export eventlist: audio
id = 25;
partID = strcat('part',num2str(id));
EEG = pop_loadset(strcat(partID,'.set'),strcat(path,'/10_AR_stepwise/'));
EEG = pop_exporteegeventlist( EEG , 'Filename', strcat(path,'/eventlist/export_ar/eventlist_export_AR_',partID,'.txt')); % GUI: 21-Sep-2022 15:41:20
%% Export eventlist: video

for id = 1:9
    partID = strcat('0',num2str(id),'.set');
    ERP = pop_loaderp(strcat(partID,'.erp'),'/Users/claudia/Library/CloudStorage/OneDrive-UniversityCollegeLondon//Users/claudia/Library/CloudStorage/OneDrive-UniversityCollegeLondon/SurprisalProjects/EEG/Exp1/ERP/');
    pop_exporterpeventlist(ERP, 1,...
 strcat('/Users/claudia/Library/CloudStorage/OneDrive-UniversityCollegeLondon/surprisal_audio/data/video_lmer/eventlist_video/', partID));
end
