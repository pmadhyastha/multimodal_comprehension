%% General set up
path = '/Users/claudia/Library/CloudStorage/OneDrive-UniversityCollegeLondon/surprisal_audio/data_video/preprocessing';
%% Preparation: get channel location
%1. Getting channel location. Somehow always require manual click of OK...
for id = 1:31
    partID = strcat('part',num2str(id));
    EEG = pop_loadset(strcat(partID,'.set'), strcat(path,'/Ori/'));
    EEG = pop_chanedit(EEG, '/Users/claudia/Documents/MATLAB/eeglab14_1_1b/plugins/dipfit2.4/standard_BESA/standard-10-5-cap385.elp');
    pop_saveset( EEG, partID, strcat(path,'/1_located/'));
end
%% Preparation: create eventlist
%     
% %2. Create eventlists: not used, already in last preprocessing
%     EEG  = pop_creabasiceventlist( EEG , 'AlphanumericCleaning', 'on', 'BoundaryNumeric', { -99 }, 'BoundaryString', { 'boundary' }, 'Eventlist',...
%  strcat('/Users/claudia/Library/CloudStorage/OneDrive-UniversityCollegeLondon/surprisal_audio/data/eventlist/original/eventlist_',partID,'.txt' ));
% %}
%% Pre ICA
for id = 1
    
    partID = strcat('part',num2str(id));
    EEG = pop_loadset(strcat(partID,'.set'),strcat(path,'/1_located/'));

%     %2. Replace eventlist: not used, already replaced in last
%     preprocessing
%     EEG = pop_importeegeventlist( EEG, strcat(path,'/eventlist/word/eventlist_word_',partID,'.txt') ,...
%      'ReplaceEventList', 'on' );
%     pop_saveset( EEG, partID, strcat(path,'/2_elisted/'));
    
    %3. Assign bin
    if not(isfolder(strcat(path,'/3_bined')))
        mkdir(path,'3_bined');
    end
    %EEG  = pop_binlister( EEG , 'BDF', strcat(path,'/binlister.txt'),...
    %'IndexEL',  1, 'SendEL2', 'EEG', 'Voutput', 'EEG' ); % GUI: 04-Jul-2022 15:26:41
    
    
    %Equivalent command: woked
    EEG  = pop_binlister( EEG , 'BDF', '/Users/claudia/Library/CloudStorage/OneDrive-UniversityCollegeLondon/surprisal_audio/data/data_video/binlister.txt',...
     'IndexEL',  1, 'SendEL2', 'EEG', 'Voutput', 'EEG' ); % GUI: 06-Oct-2022 12:37:44
    pop_saveset( EEG, partID, strcat(path,'/3_bined/'));

    %4. Extract epoch, extra long
    if not(isfolder(strcat(path,'/4_epoched')))
        mkdir(path,'4_epoched');
    end
    EEG = pop_epochbin( EEG , [-600.0  1200.0],  'none'); % No baseline correction performed
    pop_saveset( EEG, partID, strcat(path,'/4_epoched/'));

    %5. Filter
    %EEG  = pop_basicfilter( EEG,  1:38 , 'Cutoff', [ 0.1 100], 'Design', 'butter', 'Filter', 'bandpass', 'Order',...
    %2 );
    if not(isfolder(strcat(path,'/5_filtered')))
        mkdir(path,'5_filtered');
    end
    EEG  = pop_basicfilter( EEG,  1:38 , 'Cutoff', [ 0.1 100], 'Design', 'butter', 'Filter', 'bandpass', 'Order',  2, 'RemoveDC',...
    'on' ); % GUI: 01-Sep-2022 21:32:07, probably better to remove DC because we did not baseline correct data
 
    pop_saveset( EEG, partID, strcat(path,'/5_filtered/'));
    

    %6. Epoch clean
    % - If there are a large amount of data contaminated with noise, 
    %   manually reject epoch before running ICA. Overwrite the file in 6_epoch_cleaned
    % - Otherwise just save the same data as 5 in 6_epoch_cleaned
    if not(isfolder(strcat(path,'/6_epoch_cleaned')))
        mkdir(path,'6_epoch_cleaned');
    end
    pop_saveset( EEG, partID, strcat(path,'/6_epoch_cleaned/'));
    
%}
end    
%% ICA
for id = 1
    partID = strcat('part',num2str(id));
    EEG = pop_loadset(strcat(partID,'.set'),strcat(path,'/6_epoch_cleaned/'));

    % 7 Run ICA
    if not(isfolder(strcat(path,'/7_ICA_computed')))
        mkdir(path,'7_ICA_computed');
    end
    EEG = pop_runica(EEG, 'icatype', 'runica');
    pop_saveset( EEG, partID, strcat(path,'/7_ICA_computed'));
end
%% Post ICA
for id = 21:30
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

    % 10.ERP calculation
    %ERP = pop_averager( EEG , 'Criterion', 'good', 'DSindex',  1, 'ExcludeBoundary', 'on', 'SEM', 'on' );
    %pop_savemyerp( ERP, 'erpname', partID, 'filename', strcat(partID,'.erp'), 'filepath', strcat(path,'/11_ERP/'));

end
%% Export eventlist
for id = 1:30
    partID = strcat('part',num2str(id));
    EEG = pop_loadset(strcat(partID,'.set'),strcat(path,'/10_AR_stepwise/'));
    EEG = pop_exporteegeventlist( EEG , 'Filename', strcat('/Users/claudia/Library/CloudStorage/OneDrive-UniversityCollegeLondon/surprisal_audio/data_video/eventlist/export_ar/eventlist_export_AR_',partID,'.txt')); 
end
%% One that works
for id = 26

    partID = strcat('part',num2str(id));
    EEG = pop_loadset(strcat(partID,'.set'),strcat(path,'/1_located/'));

    %Equivalent command:
    EEG  = pop_binlister( EEG , 'BDF', '/Users/claudia/Library/CloudStorage/OneDrive-UniversityCollegeLondon/surprisal_audio/data/data_video/binlister.txt',...
     'IndexEL',  1, 'SendEL2', 'EEG', 'Voutput', 'EEG' ); % GUI: 07-Oct-2022 10:16:03

    %Equivalent command:
    EEG = pop_epochbin( EEG , [-600.0  1200.0],  'none'); % GUI: 07-Oct-2022 10:17:48

    %Equivalent command:
    EEG  = pop_basicfilter( EEG,  1:38 , 'Cutoff', [ 0.1 100], 'Design', 'butter', 'Filter', 'bandpass', 'Order',  2, 'RemoveDC',...
     'on' ); % GUI: 07-Oct-2022 10:19:04

    EEG = pop_runica(EEG, 'icatype', 'runica');

    pop_saveset( EEG, partID, strcat(path,'/7_ICA_computed2/'));

end