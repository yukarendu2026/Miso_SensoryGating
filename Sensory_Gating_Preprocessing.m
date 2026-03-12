%% 2025/05: The script preprocesses the raw data, and saves them as EEGLAB .set files.  

eeglab

%% Load necessary variables 
sampling_rate = 512;

subID_list = [...
1; 2; 3; 4; 5 ;
6; 7; 8; 9; 10; 
11; 12; 13; 14; 15; 
16; 17; 18; 19; 20; 
21; 22; 23; 24; 25; 
26; 27; 28; 29; 30; 
31; 32; 33; 34; 35; 
36; 37; 38; 39; 40; % 39 is Pilot1, 40 is Pilot3
41; 42; 43; 
44; 45; 46; 47; 48]; 

% total num of subjects
totalSub = length(subID_list);
disp(['totalSub = ', num2str(totalSub)])

channel_num = [1:1:32];
channel_name = {...
'Fp1';'AF3';'F7'; 'F3'; 'FC1'; % 1-5
'FC5';'T7'; 'C3'; 'CP1';'CP5'; % 6-10
'P7'; 'P3'; 'Pz'; 'PO3';'O1';  % 11-15
'Oz'; 'O2'; 'PO4';'P4'; 'P8';  % 16-20
'CP6';'CP2';'C4'; 'T8'; 'FC6'; % 21-25
'FC2';'F4'; 'F8'; 'AF4';'Fp2'; % 26-30
'Fz'; 'Cz'};                   % 31-32

ICA_file_path = 'E:\1 Sensory Gating\Analysis\EEG_ICA_decomposed\';
saving_file_path = 'E:\1 Sensory Gating\Data\working_data\';
working_file_path = 'E:\1 Sensory Gating\Data\working_data2\';

cd('E:\1 Sensory Gating\Analysis\')

%% read in raw datasets from bdf file (bdf -> raw.set)
for subID_idx = 1:totalSub
    current_dataFolder = 'E:\1 Sensory Gating\Data\bdf_files\';
    current_subID = subID_list(subID_idx);
    if current_subID < 10
        current_subID_str = ['0', num2str(current_subID)];
    else
        current_subID_str = num2str(current_subID);
    end 
    disp(' '); disp(['current_subID = ', num2str(current_subID)])

    if current_subID == 39 
        EEG = pop_biosig( [current_dataFolder, '\\Pilot1.bdf']); 
    elseif current_subID == 40
        EEG = pop_biosig( [current_dataFolder, '\\Pilot3.bdf']); 
    elseif current_subID >= 44 && current_subID <= 48
        EEG = pop_biosig( [current_dataFolder, '\\Subject_', current_subID_str,'.bdf']); 
    else
        EEG = pop_biosig( [current_dataFolder, '\\sona', current_subID_str,'.bdf']); 
    end
    EEG = pop_saveset( EEG, 'filename',['sona', current_subID_str,'_raw.set'], 'filepath', saving_file_path);
    disp('----- Data saving DONE -----')
end


%% remove extra channels + load channel location + re-reference + exclude bad channels
if isfile('All_detect_bad_channels.mat')
    load All_detect_bad_channels.mat
    size(all_bad_channel_list)
    size(all_bad_channel_name_cell)
else
    % if this is the first participant:
    disp(''); disp('---------- All_detect_bad_channels.mat: Not found ----------');
    all_bad_channel_list = [];
    all_bad_channel_name_cell = {};
end
if isfile('Automatic_detect_bad_channels.mat')
    load Automatic_detect_bad_channels.mat
    size(bad_channel_list)
    size(bad_channel_name_cell)
else
    % if this is the first participant: 
    disp(''); disp('---------- Automatic_detect_bad_channels.mat: Not found ----------');
    bad_channel_list = [];
    bad_channel_name_cell = {};
end


for subID_idx = 1:totalSub
    current_subID = subID_list(subID_idx);
    if current_subID < 10
        current_subID_str = ['0', num2str(current_subID)];
    else
        current_subID_str = num2str(current_subID);
    end 
    disp(' '); disp(['current_subID = ', num2str(current_subID)])
    EEG = pop_loadset('filename',[saving_file_path, '\\sona', current_subID_str,'_raw.set'] );        
    %pop_eegplot( EEG, 1, 1, 1);
    
    % remove extra channels (because we only have 32 valid channels)
    if size(EEG.data, 1) > 32
        disp(['size(EEG.data, 1) = ', num2str(size(EEG.data, 1))])
        disp('removing extra channels: ')
        EEG = pop_select( EEG, 'rmchannel',{'M1','M2','SO1','LO1','IO1','LO2','EXG7','EXG8'});
    end
    
    % load channel information: Use the MNI method (default) 
    EEG = pop_chanedit(EEG, []); % This will pop up the window and we should select the default method. 
    
    % Re-reference to Pz: Apply re-reference because there is no online reference channel for BioSemi. 
    % We cannot use average of all channels here because that would involve
    % extra noise into data in following steps. We use Pz as reference
    % channel temporarily and later we can re-reference to average. 
    if current_subID == 2 || current_subID == 16 
%         using Cz here because Pz is bad channel. 
        EEG = pop_reref( EEG, 32, 'keepref','on'); % 32 --- Cz
    elseif current_subID == 12 
        EEG = pop_reref( EEG, 31, 'keepref','on'); % 31 --- Fz
    elseif current_subID == 19 || current_subID == 5
        EEG = pop_reref( EEG, 8, 'keepref','on'); % 8 --- C3
    elseif current_subID == 10
        EEG = pop_reref( EEG, 23, 'keepref','on'); % 23 --- C4
    elseif current_subID == 29 
        EEG = pop_reref( EEG, 22, 'keepref','on'); % 22 --- CP2
    else
        EEG = pop_reref( EEG, 13, 'keepref','on'); % 13 --- Pz
    end
    disp(['Re-referenced to ', EEG.ref])
    
    % Exclude bad channels according to automatic detection
    %   Reject bad channel by kurtosis (this function will "detect" the bad channels). 
    EEG = pop_rejchan(EEG, 'elec',[1:32], 'threshold',3, 'norm','on','measure','kurt'); % threshold = 3*SD
    if isfield(EEG.chaninfo,'removedchans') == 1 % we found some bad channels
        disp(['length(EEG.chaninfo.removedchans) = ', num2str(length(EEG.chaninfo.removedchans))])
        bad_channel_name_cell{subID_idx} = {EEG.chaninfo.removedchans.labels};
        temp_bad_channel = ismember(strtrim(channel_name), strtrim(bad_channel_name_cell{subID_idx}));
        temp_bad_channel_idx = find(temp_bad_channel == 1);
        bad_channel_list{subID_idx} = temp_bad_channel_idx;
        disp(['size(EEG.data) = ', num2str(size(EEG.data))])
    else
        bad_channel_name_cell{subID_idx} = [];
        bad_channel_list{subID_idx} = [];
    end
    
    % Exclude bad channels according to visual inspection or notes during 
    % experiments; not for all participants: 
    if current_subID == 1
        current_manual_bad_chan = {'CP5', 'Cz'};  
    elseif current_subID == 2
        current_manual_bad_chan = {'Pz', 'C3', 'C4'}; 
    elseif current_subID == 3
        current_manual_bad_chan = {'T7', 'C3', 'F3', 'F7'}; 
    elseif current_subID == 4
        current_manual_bad_chan = {'T8', 'F3'}; 
    elseif current_subID == 5 %%%
        current_manual_bad_chan = {'Pz', 'Cz', 'Fz', 'F8'};
    elseif current_subID == 6
        current_manual_bad_chan = {'CP1'}; 
    elseif current_subID == 8
        current_manual_bad_chan = {'C3', 'C4', 'Oz'};  
    elseif current_subID == 9
        current_manual_bad_chan = {'T8', 'F7', 'F8'}; 
    elseif current_subID == 10 
        current_manual_bad_chan = {'Pz', 'Cz', 'Fz'}; 
    elseif current_subID == 12 
        current_manual_bad_chan = {'Pz', 'Cz', 'FC2', 'F3'};  
    elseif current_subID == 13 %%%
        current_manual_bad_chan = {'AF4'}; 
    elseif current_subID == 14
        current_manual_bad_chan = {'F3', 'F7', 'Fp1'}; 
    elseif current_subID == 15
        current_manual_bad_chan = {'Cz'}; 
    elseif current_subID == 16
        current_manual_bad_chan = {'Pz', 'P8'}; 
    elseif current_subID == 17
        current_manual_bad_chan = {'FC1', 'T7'}; 
    elseif current_subID == 18
        current_manual_bad_chan = {'F7', 'F8', 'P8', 'T7', 'T8', 'CP5'}; 
    elseif current_subID == 19 
        current_manual_bad_chan = {'Pz', 'Cz', 'Fz'}; 
    elseif current_subID == 20
        current_manual_bad_chan = {'P7', 'F4', 'F8', 'Oz'}; 
    elseif current_subID == 22
        current_manual_bad_chan = {'T7'}; 
    elseif current_subID == 24
        current_manual_bad_chan = {'CP6'}; 
    elseif current_subID == 26
        current_manual_bad_chan = {'F3'}; 
    elseif current_subID == 29 
        current_manual_bad_chan = {'Pz', 'Fz', 'Cz'}; 
    elseif current_subID == 31
        current_manual_bad_chan = {'CP5'}; 
    elseif current_subID == 33 %%%
        current_manual_bad_chan = {'F7', 'P7', 'Fp2', 'F8'}; 
    elseif current_subID == 34
        current_manual_bad_chan = {'CP1', 'F7', 'O1', 'FC6'};  
    elseif current_subID == 36
        current_manual_bad_chan = {'T8'};  
    elseif current_subID == 48
        current_manual_bad_chan = {'F8', 'P7', 'CP5', 'F7'}; 
    else
        current_manual_bad_chan = {}; 
    end
    EEG = pop_select( EEG, 'rmchannel', current_manual_bad_chan);
    disp(['After removal: size(EEG.data) = ', num2str(size(EEG.data))])
    
    length_auto_bad_chan = length(bad_channel_name_cell{subID_idx});
    length_current_bad_chan = length(current_manual_bad_chan);
    all_bad_channel_name_cell{subID_idx} = bad_channel_name_cell{subID_idx};
    if ~isempty(current_manual_bad_chan) && length_auto_bad_chan ~= 0
        all_bad_channel_name_cell{subID_idx}(length_auto_bad_chan+1: length_auto_bad_chan+length_current_bad_chan) = current_manual_bad_chan;
    elseif ~isempty(current_manual_bad_chan) && length_auto_bad_chan == 0
        all_bad_channel_name_cell{subID_idx} = current_manual_bad_chan;
    end
    
    if ~isempty(all_bad_channel_name_cell{subID_idx})
        temp_bad_channel = ismember(strtrim(channel_name), strtrim(all_bad_channel_name_cell{subID_idx}));
        temp_bad_channel_idx2 = find(temp_bad_channel == 1);
        all_bad_channel_list{subID_idx} = temp_bad_channel_idx2; 
    else
        all_bad_channel_list{subID_idx} = []; 
    end
    % Note all_bad_channel_name_cell{subID_idx} may be longer than
    % all_bad_channel_list{subID_idx} because some bad channels are also
    % detected in auto detection. But this will not influence the later
    % interpolation. 
    
%     pop_eegplot( EEG, 1, 1, 1);

    EEG = pop_saveset( EEG, 'filename',['Sona', current_subID_str,'_ref_clean.set'], 'filepath', saving_file_path);

    disp('----- Data saving DONE -----')
%     close all
end

% Save the bad channels results to a .mat file
save('Automatic_detect_bad_channels.mat', ... % this is the name of the workspace
    'bad_channel_list', 'bad_channel_name_cell' ) % these are the variables to be saved
disp(' '); disp('----- Automatic_detect_bad_channels *saving* DONE -----');

save('All_detect_bad_channels.mat', ... % this is the name of the workspace
    'all_bad_channel_list', 'all_bad_channel_name_cell' ) % these are the variables to be saved
disp(' '); disp('----- All_detect_bad_channels *saving* DONE -----'); disp(' ')

% pause here and check if the data is saved
open bad_channel_list
open bad_channel_name_cell
open all_bad_channel_list
open all_bad_channel_name_cell
disp('----- Re-reference + Removing bad channels DONE -----'); disp(' ')


%% Bandpass filtering (_ref_clean -> _ref_clean_dropped_filt)
for subID_idx = 1:totalSub
    current_subID = subID_list(subID_idx);
    if current_subID < 10
        current_subID_str = ['0', num2str(current_subID)];
    else
        current_subID_str = num2str(current_subID);
    end 
    disp(' '); disp(['current_subID = ', num2str(current_subID)])

    EEG = pop_loadset('filename',[saving_file_path, '\\Sona', current_subID_str,'_ref_clean.set'] );        

    %  band pass filtering 0.3-50 Hz
    EEG = pop_eegfiltnew(EEG, 'locutoff', 0.3, 'hicutoff', 50);
    % This might be a good time to add a comment to the dataset.
    EEG.comments = pop_comments(EEG.comments,'','Dataset was filtered at 0.3-50 Hz.',1);
    %pop_eegplot( EEG, 1, 1, 1); 

    EEG = pop_saveset( EEG, 'filename',['Sona', current_subID_str,'_ref_clean_dropped_filt.set'], 'filepath', saving_file_path);

    disp('----- Data saving DONE -----')
%     close all
end
disp('----- Bandpass filtering DONE -----')


%%  Epoch:  extract only the usable portion and remove other portions (_ref_clean_dropped_filt -> ICAready)
% Note: we cannot simply overwrite EEG.data by EEG.data = extracted_EEG
% because the event time markers will be messed up, which will cause
% troubles for later analyses. 

% There were 3 phases: 
% 1, Resting phase I: 256--48--48--48--48--48--48 (fixed length 60
% seconds, 6 trials in total)
% 2, Listening phase: 128--48--48
% 128 -- Trial started
% The first 48: Tone 1, 50 micro seconds
% 48 -- 48: fixed, 500 ms
% The second 48: Tone 2, 50 micro seconds
% 100 trials in total
% Trial End to next trial: 8-10 sec, varied
% 3, Resting phase II: same as the first resting phase

% We want to remove:
% 1) The periods between the phases
% 2) The periods in Listerning phase, Trial End to next trial: 8-10 sec

total_trials = 100; % 100 listening trials
excluded_subj_list = [13; 33];

if isfile('missing_trial_index.mat')
    load missing_trial_index.mat
else
    missing_trial_mtx = nan(totalSub, total_trials);
end

for subID_idx = 1:totalSub
    current_subID = subID_list(subID_idx);
    if current_subID < 10
        current_subID_str = ['0', num2str(current_subID)];
    else
        current_subID_str = num2str(current_subID);
    end 
    disp(' '); disp(['current_subID = ', num2str(current_subID)])

    if ~ismember(current_subID, excluded_subj_list)
        EEG = pop_loadset('filename',[saving_file_path, '\\Sona', current_subID_str,'_ref_clean_dropped_filt.set'] );        

        % Find the start and the end of each phase
        temp_extract_idx_48 = zeros(1, 212);
        temp_extract_idx_128 = zeros(1, total_trials);

        if current_subID >= 10 && current_subID ~= 39 && current_subID ~= 40
            temp_extract_idx_48 = find(ismember({EEG.event.type}, '18432')); % 2024/02/15: There are more than 212 events recorded. Always found extra events in Rest 1. 
            temp_extract_idx_128 = find(ismember({EEG.event.type}, 'condition 1'));
            temp_extract_idx_256 = find(ismember({EEG.event.type}, 'condition 2')); % the start of resting phases; should be 2 elements
        elseif current_subID <= 9 || current_subID == 39 || current_subID == 40
            temp_extract_idx_48 = find(ismember({EEG.event.type}, 'condition 48'));
            temp_extract_idx_128 = find(ismember({EEG.event.type}, 'condition 128'));
            temp_extract_idx_256 = find(ismember({EEG.event.type}, '256')); % the start of resting phases; should be 2 elements
        end
        
        if current_subID == 16 % restarted the program after finishing the listening phase
            % we keep the listening + R2 data in the second run and R1 data in the first run
            temp_extract_idx_48(:, 8:207) = [];
            temp_extract_idx_128(:, 1:100) = [];
        end

        disp(['size(temp_extract_idx_48) = ', num2str(size(temp_extract_idx_48))]) % should be 1 x 212
        disp(['size(temp_extract_idx_128) = ', num2str(size(temp_extract_idx_128))]) % should be 1 x 100
        disp(['size(temp_extract_idx_256) = ', num2str(size(temp_extract_idx_256))]) % should be 1 x 2

        all_events = {EEG.event.type};

        % Find if there is any missing or extra events (48) for the listening phase: 
        for trial_idx = 1:total_trials
            if trial_idx <= total_trials -1
                temp_events_array = all_events(temp_extract_idx_128(trial_idx):temp_extract_idx_128(trial_idx+1));
            elseif trial_idx == total_trials
                temp_events_array = all_events(temp_extract_idx_128(end): temp_extract_idx_256(2));
            end

            if current_subID >= 10 && current_subID ~= 39 && current_subID ~= 40
                occurrences = strcmp(temp_events_array, '18432');
            elseif current_subID <= 9 || current_subID == 39 || current_subID == 40
                occurrences = strcmp(temp_events_array, 'condition 48');
            end
            if sum(occurrences) < 2
                missing_trial_mtx(subID_idx, trial_idx) = 1;
            elseif sum(occurrences) > 2
                missing_trial_mtx(subID_idx, trial_idx) = 2;
            elseif sum(occurrences) == 2
                missing_trial_mtx(subID_idx, trial_idx) = 3;
            end
        end
        disp('Which trials are missing/extra 48 events: ')
        disp('find(missing_trial_mtx(subID_idx,:)==1)') % find the missing trial indices
        find(missing_trial_mtx(subID_idx,:)==1)
        disp('find(missing_trial_mtx(subID_idx,:)==2)')
        find(missing_trial_mtx(subID_idx,:)==2)

        % count how many event 48 in total for listening phase:
        temp_events_array = all_events(temp_extract_idx_128(1):temp_extract_idx_256(2));
        if current_subID >= 10 && current_subID ~= 39 && current_subID ~= 40
            listening_occurrences = strcmp(temp_events_array, '18432');
        elseif current_subID <= 9 || current_subID == 39 || current_subID == 40
            listening_occurrences = strcmp(temp_events_array, 'condition 48');
        end
        disp('Count event 48 in whole listening phase: ')
        disp(['sum(listening_occurrences) = ', num2str(sum(listening_occurrences))])

        % count for resting 1
        if current_subID == 16
            temp_events_array1 = all_events(temp_extract_idx_256(1):78);
        else
            temp_events_array1 = all_events(temp_extract_idx_256(1):temp_extract_idx_128(1));
        end
        if current_subID >= 10 && current_subID ~= 39 && current_subID ~= 40
            R1_occurrences = strcmp(temp_events_array1, '18432');
        elseif current_subID <= 9 || current_subID == 39 || current_subID == 40
            R1_occurrences = strcmp(temp_events_array1, 'condition 48');
        end
        disp('Count event 48 in Resting phase 1: ')
        disp(['sum(R1_occurrences) = ', num2str(sum(R1_occurrences))])

        % count for resting 2
        temp_events_array2 = all_events(temp_extract_idx_256(2):end);
        if current_subID >= 10 && current_subID ~= 39 && current_subID ~= 40
            R2_occurrences = strcmp(temp_events_array2, '18432');
        elseif current_subID <= 9 || current_subID == 39 || current_subID == 40
            R2_occurrences = strcmp(temp_events_array2, 'condition 48');
        end
        disp('Count event 48 in Resting phase 2: ')
        disp(['sum(R2_occurrences) = ', num2str(sum(R2_occurrences))])


        temp_cell = {EEG.event.latency}; % size(temp_cell) is how many rows/events/markers 

        % check if in Rest 1 and Rest 2 event 48 were appropriately distributed
        % (i.e., 60 seconds apart)
        R1_48_latency = nan(1, sum(R1_occurrences)+1);
        R1_distance_48_latency = nan(1, sum(R1_occurrences));
        for R1_idx = 1:sum(R1_occurrences)+1
            if R1_idx == 1
                R1_48_latency(R1_idx) = temp_cell{ temp_extract_idx_256(1) };
            else
                temp_idx = find(R1_occurrences); % get indices for all 1 values
                R1_48_latency(R1_idx) = temp_cell{ temp_idx(R1_idx - 1) + temp_extract_idx_256(1)-1 };
            end
        end
        for R1_idx = 1:sum(R1_occurrences)
            R1_distance_48_latency(R1_idx) = R1_48_latency(R1_idx+1) - R1_48_latency(R1_idx);
        end
        judge_R1_distance_48_latency = R1_distance_48_latency/sampling_rate - 60
        disp('find(abs(judge_R1_distance_48_latency) > 5 sec)')
        find(abs(judge_R1_distance_48_latency) > 5)

        R2_48_latency = nan(1, sum(R2_occurrences)+1);
        R2_distance_48_latency = nan(1, sum(R2_occurrences));
        for R2_idx = 1:sum(R2_occurrences)+1
            if R2_idx == 1
                R2_48_latency(R2_idx) = temp_cell{ temp_extract_idx_256(2) };
            else
                temp_idx = find(R2_occurrences); % get indices for all 1 values
                R2_48_latency(R2_idx) = temp_cell{ temp_idx(R2_idx - 1) + temp_extract_idx_256(2)-1 };
            end
        end
        for R2_idx = 1:sum(R2_occurrences)
            R2_distance_48_latency(R2_idx) = R2_48_latency(R2_idx+1) - R2_48_latency(R2_idx);
        end
        judge_R2_distance_48_latency = R2_distance_48_latency/sampling_rate - 60
        disp('find(abs(judge_R2_distance_48_latency) > 5 sec)')
        find(abs(judge_R2_distance_48_latency) > 5)


        temp_extract_begin_latency = []; % the start of the period we want to remove
        temp_extract_end_latency = []; % the end of the period we want to remove

        % find period between resting phase I and listening phase:     
        a = temp_extract_idx_256(1); % Define the starting index
        b = temp_extract_idx_128(1); % Define the ending index

        % Step 1: Find indices of "condition 48" within the range a:b in all_events
        if current_subID <= 9 || current_subID == 39 || current_subID == 40
            indices_condition_48 = find(strcmp(all_events(a:b), 'condition 48'));
        elseif current_subID >= 10 && current_subID ~= 39 && current_subID ~= 40
            indices_condition_48 = find(strcmp(all_events(a:b), '18432'));
        end

        if isempty(indices_condition_48)
            fprintf('No occurrences of "condition 48" within the specified range.\n');
        else
            % Step 2: Select the last occurrence of "condition 48" within the range
            % find the event 48 closest to 360 sec after 256
            R1_find_last_48 = find( abs((R1_48_latency - (6*60*sampling_rate+R1_48_latency(1)) +1)/sampling_rate) <= 5);
            disp(['R1_find_last_48 = ', num2str(R1_find_last_48)])
            last_index_condition_48 = indices_condition_48(R1_find_last_48(1) - 1);

            % Step 3: Find the index of this occurrence in the original cell array
            % all_events
            index_in_A = a - 1 + last_index_condition_48;
            disp(['index_in_A = ', num2str(index_in_A)])
            disp(['R1 last 48 latency = ', num2str(temp_cell{index_in_A})])

            % Step 4: Use this index to locate the corresponding element in cell
            % array temp_cell
            temp_trial_latency = temp_cell{index_in_A}+sampling_rate+1; % include 1 second after the last event 48
            % we plus 1 time point because we want to get the time point following. 
            disp(['-----> R1 cutoff = ', num2str(temp_trial_latency)])
        end
        temp_extract_begin_latency = [temp_extract_begin_latency; temp_trial_latency];
        temp_trial_latency = temp_cell{temp_extract_idx_128(1)}-1;
        temp_extract_end_latency = [temp_extract_end_latency; temp_trial_latency];

        
        % find period between listening phase and resting phase II: 
        a = temp_extract_idx_128(end); % Define the starting index
        b = temp_extract_idx_256(end); % Define the ending index

        % Step 1: Find indices of "condition 48" within the range a:b in all_events
        if current_subID <= 9 || current_subID == 39 || current_subID == 40
            indices_condition_48 = find(strcmp(all_events(a:b), 'condition 48'));
        elseif current_subID >= 10 && current_subID ~= 39 && current_subID ~= 40
            indices_condition_48 = find(strcmp(all_events(a:b), '18432'));
        end % length of indices_condition_48 should be 2

        if isempty(indices_condition_48)
            fprintf('No occurrences of "condition 48" within the specified range.\n');
        else
            % Step 2: Select the last occurrence of "condition 48" within the range
            last_index_condition_48 = indices_condition_48(end);

            % Step 3: Find the index of this occurrence in the original cell array
            % all_events
            index_in_A = a - 1 + last_index_condition_48;

            % Step 4: Use this index to locate the corresponding element in cell
            % array temp_cell
            temp_trial_latency = temp_cell{index_in_A}+sampling_rate+1;
        end
        % To find the time point after the second event 48 was shown, 
        % 0.05 ms = .00005s, therefore the number of time points = 0.0256 = (0.00005*512)
        % Also we want to get a period after event 48 enough long for further analysis,
        % therefore we plus 512 time points (1 second) after the second event 48.
        temp_extract_begin_latency = [temp_extract_begin_latency; temp_trial_latency];
        temp_trial_latency = temp_cell{temp_extract_idx_256(2)}-1;
        temp_extract_end_latency = [temp_extract_end_latency; temp_trial_latency];

        % deal with the period before the first 256 
        temp_trial_latency = 1;
        temp_extract_begin_latency = [temp_extract_begin_latency; temp_trial_latency];
        first_trial_extract_end_idx = temp_extract_idx_256(1);
        temp_trial_latency = temp_cell{first_trial_extract_end_idx}-1;
        temp_extract_end_latency = [temp_extract_end_latency; temp_trial_latency];

        % deal with the period after the last 48 + 1 sec    
        a = temp_extract_idx_256(2); % Define the starting index
        b = length(all_events); % Define the ending index
        if current_subID <= 9 || current_subID == 39 || current_subID == 40
            indices_condition_48 = find(strcmp(all_events(a:b), 'condition 48'));
        elseif current_subID >= 10 && current_subID ~= 39 && current_subID ~= 40
            indices_condition_48 = find(strcmp(all_events(a:b), '18432'));
        end 
        
        % find the event 48 closest to 360 sec after 256
        R2_find_last_48 = find( abs((R2_48_latency - (6*60*sampling_rate+R2_48_latency(1)) +1)/sampling_rate) <= 5);
        disp(['R2_find_last_48 = ', num2str(R2_find_last_48)])
        last_index_condition_48 = indices_condition_48(R2_find_last_48(1) - 1);
        last_trial_extract_begin_idx = a - 1 + last_index_condition_48;
        disp(['last_trial_extract_begin_idx = ', num2str(last_trial_extract_begin_idx)])
        disp(['R2 last 48 latency = ', num2str(temp_cell{last_trial_extract_begin_idx})])
        
        temp_trial_latency = temp_cell{last_trial_extract_begin_idx}+sampling_rate+1;
        disp(['-----> R2 cutoff = ', num2str(temp_trial_latency)])
        temp_extract_begin_latency = [temp_extract_begin_latency; temp_trial_latency];
        temp_trial_latency = length(EEG.data);
        temp_extract_end_latency = [temp_extract_end_latency; temp_trial_latency];
        
        % Retrieve the data by using the indices in latency
        temp_idx_matrix = [];
        temp_trial_idx = [];
        temp_trial_idx = [temp_extract_begin_latency temp_extract_end_latency];
        temp_idx_matrix = [temp_idx_matrix; temp_trial_idx] % should be 4 x 2

        % remove time periods 
        EEG = eeg_eegrej(EEG, temp_idx_matrix); % remove data
        [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG); % store changes
        eeglab redraw % redraw interface

        EEG = pop_saveset( EEG, 'filename',['Sona', current_subID_str,'_ICAready.set'], 'filepath', saving_file_path);

        disp('----- Data saving DONE -----')
        
        find(missing_trial_mtx(subID_idx, :) == 1)
        find(missing_trial_mtx(subID_idx, :) == 2)
    end
    
end

notes = '1 means 49 occurred less than twice; 2 means 48 occurred more than twice; 3 means 48 occurred twice';

% Save the missing trial index to a .mat file % make sure to save each into the same file 
save('missing_trial_index.mat', ... % this is the name of the workspace
    'missing_trial_mtx', 'notes' ) % these are the variables to be saved
disp(' '); disp('----- mising_trial_mtx *saving* DONE -----'); disp(' ')

open missing_trial_mtx
find(missing_trial_mtx == 1)
find(missing_trial_mtx == 2)
disp('----- Extract usable periods DONE -----')


%%  ICA independent component analysis (ICAready -> ICAdecomposed)

for subID_idx = 1:totalSub
    current_subID = subID_list(subID_idx);
    if current_subID < 10
        current_subID_str = ['0', num2str(current_subID)];
    else
        current_subID_str = num2str(current_subID);
    end 
    disp(' '); disp(['current_subID = ', num2str(current_subID)])

    if ~ismember(current_subID, excluded_subj_list)
        EEG = pop_loadset('filename',[saving_file_path, '\\Sona', current_subID_str,'_ICAready.set'] );

        % Re-reference to average 
        EEG = pop_reref(EEG, []);  
        disp(['Re-referenced to ', EEG.ref])
        
        % Check if rank = channel number
        rank(double(EEG.data))
        size(EEG.data,1)

        EEG = pop_runica( EEG, 'icatype', 'runica' );
        
        EEG = pop_saveset( EEG, 'filename',['Sona', current_subID_str,'_ICAdecomposed.set'], 'filepath', ICA_file_path);

        disp('----- Data saving DONE -----')
    end
end
disp('----- ICA DONE -----')


%% Examine the IC one by one (must load channel location information before this step)
for subID_idx = 1
    current_subID = subID_list(subID_idx);
    if current_subID < 10
        current_subID_str = ['0', num2str(current_subID)];
    else
        current_subID_str = num2str(current_subID);
    end 
    disp(' '); disp(['current_subID = ', num2str(current_subID)])

    if ~ismember(current_subID, excluded_subj_list)
        EEG = pop_loadset('filename',[ICA_file_path, '\\Sona', current_subID_str,'_ICAdecomposed.set']);

        % iclabel
        EEG = pop_iclabel(EEG, 'default');
        
        pop_viewprops(EEG, 0) % for component properties
%         pop_viewprops(EEG, 1) % for channel properties 
    end
end


%% Reject components  (ICAdecomposed -> icalabeled)

if isfile('ICA_results.mat') % Not the first participant
    load ICA_results.mat
else
    % if this is the first participant to run ICA: 
    compReject = cell(totalSub,1);
    sumCompReject = nan(totalSub,1);
    matrix_CompReject = cell(totalSub, 1);
end

% We should do ICA rejection by each participant. 
for subID_idx = 1:totalSub

    current_subID = subID_list(subID_idx);
    if current_subID < 10
        current_subID_str = ['0', num2str(current_subID)];
    else
        current_subID_str = num2str(current_subID);
    end 
    disp(' '); disp(['current_subID = ', num2str(current_subID)])

    if ~ismember(current_subID, excluded_subj_list)
        EEG = pop_loadset('filename',[ICA_file_path, '\\Sona', current_subID_str,'_ICAdecomposed.set']);

        pop_eegplot( EEG, 1, 1, 1)

        % iclabel
        EEG = pop_iclabel(EEG, 'default');
        
        % Manually drops ICA components 
        if current_subID == 1
            compReject{subID_idx, 1} = [1, 2, 3, 5, 9, 10, 11, 16, 17, 20];
        elseif current_subID == 2
            compReject{subID_idx, 1} = [1, 4, 5, 7, 9, 10, 17, 18, 26]; 
        elseif current_subID == 3
            compReject{subID_idx, 1} = [1, 2, 3, 6, 7, 8, 9, 10, 14 ];
        elseif current_subID == 4
            compReject{subID_idx, 1} = [1, 2, 3, 4, 6, 7, 8, 9, 10, 13, 14]; 
        elseif current_subID == 5 
            compReject{subID_idx, 1} = [1, 2, 5, 12, 13, 17, 18, 26];
        elseif current_subID == 6
            compReject{subID_idx, 1} = [1, 2, 3, 5, 8, 11, 16, 21, 25, 28]; 
        elseif current_subID == 7
            compReject{subID_idx, 1} = [1, 2, 4, 5, 8, 12, 13, 17, 18, 29 ];
        elseif current_subID == 8
            compReject{subID_idx, 1} = [1, 2, 4, 9, 10, 15, 16, 17, 19, 25, 26]; 
        elseif current_subID == 9
            compReject{subID_idx, 1} = [1, 2, 3, 4, 6, 7, 9, 21 ];
        elseif current_subID == 10 
            compReject{subID_idx, 1} = [1, 2, 3, 4, 7, 8, 10, 13, 17, 18, 19];
        elseif current_subID == 11
            compReject{subID_idx, 1} = [1, 2, 3, 4, 13 ];
        elseif current_subID == 12 
            compReject{subID_idx, 1} = [1, 3, 7, 13, 17, 22, 24, 25];
        elseif current_subID == 13 %%%
            compReject{subID_idx, 1} = [1, 7, 11, 12, 13, 14, 29]; 
        elseif current_subID == 14
            compReject{subID_idx, 1} = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 19 ]; 
        elseif current_subID == 15
            compReject{subID_idx, 1} = [1, 2, 3, 9, 10, 11, 13, 18, 20, 25, 29 ]; 
        elseif current_subID == 16
            compReject{subID_idx, 1} = [1, 2, 3, 4, 5, 8, 9, 10, 13, 24, 27 ]; 
        elseif current_subID == 17
            compReject{subID_idx, 1} = [1, 2, 3, 4, 5, 7, 9, 15, 17, 19, 24, 27]; 
        elseif current_subID == 18
            compReject{subID_idx, 1} = [1, 2, 3, 4, 5, 7, 8, 9, 13, 26]; 
        elseif current_subID == 19 
            compReject{subID_idx, 1} = [1, 2, 4, 9, 10, 26]; 
        elseif current_subID == 20
            compReject{subID_idx, 1} = [1, 2, 3, 4, 6, 13, 14]; 
        elseif current_subID == 21
            compReject{subID_idx, 1} = [1, 2, 3, 5, 6, 8, 13, 14, 19, 31];  
        elseif current_subID == 22
            compReject{subID_idx, 1} = [1, 2, 3, 5, 6, 7, 10, 12, 13, 15, 16, 21, 22, 27]; 
        elseif current_subID == 23
            compReject{subID_idx, 1} = [1, 2, 3, 5, 6, 10, 15, 18, 22, 30, 31]; 
        elseif current_subID == 24
            compReject{subID_idx, 1} = [1, 2, 3, 4, 5, 8, 10, 11, 13, 18, 19, 20, 27, 28]; 
        elseif current_subID == 25
            compReject{subID_idx, 1} = [1, 2, 3, 7, 12, 13, 14, 16, 24]; 
        elseif current_subID == 26
            compReject{subID_idx, 1} = [1, 2, 3, 4, 5, 8, 10, 14, 15, 20, 22, 23, 28]; 
        elseif current_subID == 27
            compReject{subID_idx, 1} = [1, 2, 3, 7, 11, 14, 16, 17, 19 ]; 
        elseif current_subID == 28
            compReject{subID_idx, 1} = [1, 2, 3, 8, 9, 11, 14, 15, 23, 25, 28]; 
        elseif current_subID == 29 
            compReject{subID_idx, 1} = [1, 2, 3, 8, 10, 11, 21, 27]; 
        elseif current_subID == 30
            compReject{subID_idx, 1} = [1, 2, 3, 5, 6, 13, 14, 15, 29]; 
        elseif current_subID == 31
            compReject{subID_idx, 1} = [1, 2, 3, 4, 5, 6, 7, 9, 10, 11, 13, 14, 15, 17, 18, 20]; 
        elseif current_subID == 32
            compReject{subID_idx, 1} = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 17, 19 ]; 
        elseif current_subID == 33 %%%
            compReject{subID_idx, 1} = [2, 8, 15, 25];  
        elseif current_subID == 34
            compReject{subID_idx, 1} = [1, 2, 3, 4, 5, 6, 8, 9, 14, 25];  
        elseif current_subID == 35
            compReject{subID_idx, 1} = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 13, 19, 22, 27, 29];  
        elseif current_subID == 36
            compReject{subID_idx, 1} = [1, 2, 3, 7, 9, 10, 12, 16, 21, 29];  
        elseif current_subID == 37
            compReject{subID_idx, 1} = [1, 2, 3, 5, 7, 8, 11, 19, 22, 28, 30];  
        elseif current_subID == 38
            compReject{subID_idx, 1} = [1, 2, 3, 4, 5, 6, 8, 10, 11, 12, 13, 14, 19];  
        elseif current_subID == 39
            compReject{subID_idx, 1} = [1, 2, 3, 4, 5, 12, 15, 28, 29];  
        elseif current_subID == 40
            compReject{subID_idx, 1} = [1, 2, 4, 5, 8, 15, 16, 20, 21, 25, 26, 29]; 
        elseif current_subID == 41
            compReject{subID_idx, 1} = [1, 2, 3, 4, 5, 6, 7, 8, 11, 16, 17]; 
        elseif current_subID == 42
            compReject{subID_idx, 1} = [5, 18, 19, 31];   
        elseif current_subID == 43
            compReject{subID_idx, 1} = [1, 2, 5, 6, 7, 8, 12, 13, 15, 16, 25];   
        elseif current_subID == 44
            compReject{subID_idx, 1} = [1, 2, 3, 4, 11, 13, 15, 20, 22, 26];   
        elseif current_subID == 45
            compReject{subID_idx, 1} = [1, 2, 3, 5, 8, 10, 11, 14, 15, 16, 20];   
        elseif current_subID == 46
            compReject{subID_idx, 1} = [1, 2, 5, 6, 8, 9, 10, 11, 17, 18, 26, 27, 29];   
        elseif current_subID == 47
            compReject{subID_idx, 1} = [1, 2, 3, 9, 11, 15, 18, 21, 23, 27];   
        elseif current_subID == 48
            compReject{subID_idx, 1} = [1, 2, 3, 5, 9, 10, 11, 12, 13, 14, 15, 16, 17];  
        else
            compReject{subID_idx, 1} = [];
        end
        
        cleanEEG = pop_subcomp(EEG, compReject{subID_idx,1}, 0);
        sumCompReject(subID_idx,1) = length( compReject{subID_idx,1} );
        temp_compo_prob = round(EEG.etc.ic_classification.ICLabel.classifications(:,:)*100);
        matrix_CompReject{subID_idx,1} = EEG.etc.ic_classification.ICLabel.classifications;
        pop_eegplot( cleanEEG, 1, 1, 1)
        
        % save
        EEG = pop_saveset( cleanEEG, 'filename',['Sona', current_subID_str, '_iclabeled.set'],'filepath', [ICA_file_path 'clean\\']);

        disp('----- Data saving DONE -----')
    end
end

% Save the ICA results to a .mat file % make sure to save each into the same file 
header = {'brain', 'muscle', 'eye', 'heart', 'line noise', 'channel noise', 'other'};
save('ICA_results.mat', ... % this is the name of the workspace
    'compReject', 'sumCompReject', 'matrix_CompReject', 'header') % these are the variables to be saved
disp(' '); disp('----- ICA_results *saving* DONE -----'); disp(' ')

disp('----- Reject IC DONE -----')


%% pause here and check the ICA results
open sumCompReject
open compReject
open matrix_CompReject


%% Interpolation: 

for subID_idx = 1:totalSub

    current_subID = subID_list(subID_idx);
    if current_subID < 10
        current_subID_str = ['0', num2str(current_subID)];
    else
        current_subID_str = num2str(current_subID);
    end 
    disp(' '); disp(['current_subID = ', num2str(current_subID)])

    if ~ismember(current_subID, excluded_subj_list)
        EEG = pop_loadset('filename',[ICA_file_path, 'clean\\Sona', current_subID_str,'_iclabeled.set'] );
%         pop_eegplot( EEG, 1, 1, 1)

        % Load the original dataset with all 32 channels
        originalEEG = pop_loadset('filename',['sona', current_subID_str,'_raw.set'],'filepath', saving_file_path );

        % remove extra channels (because we only have 32 valid channels)
        if size(originalEEG.data, 1) > 32
            originalEEG = pop_select( originalEEG, 'rmchannel',{'M1','M2','SO1','LO1','IO1','LO2','EXG7','EXG8'});
        end
        % load channel information: Use the MNI method (default) 
        originalEEG = pop_chanedit(originalEEG, []); % This will pop up the window and we should select the default method. 

        disp(['size(EEG.data) = ', num2str(size(EEG.data))])
        disp(['size(originalEEG.data) = ', num2str(size(originalEEG.data))])

        % Now use originalEEG.chanlocs for interpolation
        EEG = pop_interp(EEG, originalEEG.chanlocs, 'spherical');
        disp(['size(EEG.data) = ', num2str(size(EEG.data))])
        pop_eegplot( EEG, 1, 1, 1);

        EEG = pop_saveset( EEG, 'filename',['Sona', current_subID_str,'_iclabeled_itrplt_clean.set'],'filepath', [ICA_file_path 'clean\\']); 
        disp('----- Data saving DONE -----')
%         close all
    end
end
disp('----- Interpolation DONE -----')




%%



