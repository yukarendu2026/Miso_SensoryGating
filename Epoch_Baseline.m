% This script is used for time epoching after preprocessing. 

% Before running this script, should load necessary variables (in the preprocessing script)

cd 'D:\1 Sensory Gating\Analysis'

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

%***********************************************************************
% for epoching different events, use this same code; should 
% switch between these before running the following sections:

% current_interested_event = 'Baseline_Before_Listen_S1';
current_interested_event = 'Baseline_Before_Listen_S2';
% Need to clear all before running a different event!

excluded_subj_list = [13, 33];

extracted_epoch_cell_array = cell(totalSub, 100);
extracted_time_cell_array = cell(totalSub, 100);
all_latency_S1 = nan(totalSub, 100);
all_latency_S2 = nan(totalSub, 100);


%% BASELINE: Epoch Baseline_Before_Listen_S1 time period: 

if strcmp(current_interested_event,'Baseline_Before_Listen_S1')==1 
    disp(' '); disp(['******** Epoching: ', current_interested_event, ' ********']); disp(' ')

    
    for subID_idx = 1:totalSub
        current_subID = subID_list(subID_idx);
        if current_subID < 10
            current_subID_str = ['0', num2str(current_subID)];
        else
            current_subID_str = num2str(current_subID);
        end 
        disp(' '); disp(['current_subID = ', num2str(current_subID)])

        if ismember(current_subID, excluded_subj_list)==0  
            EEG = pop_loadset('filename', ['Sona', current_subID_str, '_iclabeled_itrplt_clean.set'], 'filepath', [ICA_file_path 'clean\']);
        %----------------------------------------------------------------%        
            % Get the indices from EEG.event.type       
            temp_latency = {EEG.event.latency}; % size(temp_latency) is how many rows/events/markers

            if current_subID >= 10 && current_subID ~= 39 && current_subID ~= 40
                temp_S48 = temp_latency(find(ismember({EEG.event.type}, '18432')));
                temp_S128 = temp_latency(find(ismember({EEG.event.type}, 'condition 1')));
                temp_S256 = temp_latency(find(ismember({EEG.event.type}, 'condition 2'))); % the start of resting phases; should be 2 elements
                total_trials = length(find(ismember({EEG.event.type}, 'condition 1'))); % trial starts; should be 100

            elseif current_subID <= 9 || current_subID == 39 || current_subID == 40
                total_trials = length(find(ismember({EEG.event.type}, 'condition 128'))); % trial starts; should be 100
                temp_S48 = temp_latency(find(ismember({EEG.event.type}, 'condition 48')));
                temp_S128 = temp_latency(find(ismember({EEG.event.type}, 'condition 128')));
                temp_S256 = temp_latency(find(ismember({EEG.event.type}, '256'))); % the start of resting phases; should be 2 elements
            end
            temp_S48_mat = cell2mat(temp_S48)';
            temp_S128_mat = cell2mat(temp_S128)';
            temp_S256_mat = cell2mat(temp_S256)';
            disp(['size(temp_S48_mat) = ', num2str(size(temp_S48_mat))]) % should be 212 (pause and check)
            disp(['size(temp_S128_mat) = ', num2str(size(temp_S128_mat))]) % should be 100
            disp(['size(temp_S256_mat) = ', num2str(size(temp_S256_mat))]) % should be 2
            

            % count how many event 48 in resting 1
            count_48_rest_1 = length(find(temp_S48_mat < temp_S128_mat(1)));
            % count how many event 48 in resting 2
            count_48_rest_2 = length(find(temp_S48_mat > temp_S256_mat(2)));
            
            % remove the event 48 not in listening phase
            temp_S48_mat(1:count_48_rest_1, :) = [];
            temp_S48_mat((length(temp_S48_mat)-count_48_rest_2+1):length(temp_S48_mat), :) = [];
            disp(['After removing resting events: size(temp_S48_mat) = ', num2str(size(temp_S48_mat))]) % should be 200
                        
        %----------------------------------------------------------------% 
            % for each trial, find events between 128 and the next 128
            for trial_idx = 1:total_trials
                if trial_idx <= total_trials-1   
                    a = find(temp_S48_mat < temp_S128_mat(trial_idx+1));
                    b = find(temp_S48_mat < temp_S128_mat(trial_idx));
                elseif trial_idx == total_trials
                    a = find(temp_S48_mat < temp_S256_mat(2));
                    b = find(temp_S48_mat < temp_S128_mat(trial_idx));
                end
                current_count_48 = length(a) - length(b);
                current_48_idx = setdiff(a,b);
                if current_count_48 == 2 % regular trials
                    all_latency_S1(subID_idx, trial_idx) = temp_S48_mat(current_48_idx(1), 1); 
                    all_latency_S2(subID_idx, trial_idx) = temp_S48_mat(current_48_idx(2), 1);
                elseif current_count_48 == 1 % missing a 48, discard this trial
                    all_latency_S1(subID_idx, trial_idx) = 0; 
                    all_latency_S2(subID_idx, trial_idx) = 0;
                    disp(['trial_idx = ', num2str(trial_idx), '; current_count_48 = ', num2str(current_count_48)])
                elseif current_count_48 > 2  % extra 48, discard this trial
                    all_latency_S1(subID_idx, trial_idx) = 0; 
                    all_latency_S2(subID_idx, trial_idx) = 0;
                    disp(['trial_idx = ', num2str(trial_idx), '; current_count_48 = ', num2str(current_count_48)])
                end
            end

            % for sub 18, trial 6 only: 
            if current_subID == 18
                for trial_idx = 6
                    a = find(temp_S48_mat < temp_S128_mat(trial_idx+1));
                    b = find(temp_S48_mat < temp_S128_mat(trial_idx));
                    current_count_48 = length(a) - length(b);
                    current_48_idx = setdiff(a,b);
                    all_latency_S1(subID_idx, trial_idx) = temp_S48_mat(current_48_idx(1), 1); 
                    all_latency_S2(subID_idx, trial_idx) = temp_S48_mat(current_48_idx(2), 1);
                end
            end

        %------------------------- Epoching BASELINE -----------------------------%        
            % we want to epoch [-200 ms, 0] for each trial; 
            % i.e., epoch 0.2*512 timepoints prior to S1 (excluding the time point of S1 onset)
            % 0.2 * 512 = 102.4 timepoints which means there will be 103 elements in each cell
            for trial_idx = 1:total_trials
                current_trial_latency = all_latency_S1(subID_idx, trial_idx);
                if current_trial_latency == 0 || isnan(current_trial_latency)  % missing trial
                    extracted_epoch_cell_array{subID_idx, trial_idx} = [];
                    extracted_time_cell_array{subID_idx, trial_idx} = [];
                else
                    extracted_epoch_cell_array{subID_idx, trial_idx} = EEG.data(:, (current_trial_latency - 0.2*sampling_rate -1):(current_trial_latency - 1)); % we are NOT using pop_epoch here because we have already got all the time points information
                    extracted_time_cell_array{subID_idx, trial_idx} = EEG.times(:, (current_trial_latency - 0.2*sampling_rate -1):(current_trial_latency - 1));
                end
            end
            disp(' '); disp(['size(extracted_epoch_cell_array) = ', num2str(size(extracted_epoch_cell_array))])
            disp(['size(extracted_time_cell_array) = ', num2str(size(extracted_time_cell_array))])

        end
        disp(' '); disp(['----- current_subID = ', current_subID_str, ': Epoching ', current_interested_event, ' DONE -----']); disp(' ')
    end
end
disp(['----- Epoching *', current_interested_event, '* DONE -----'])

save('Baseline_Before_Listen_S1_epoch_cell_array.mat', ... % this is the name of the workspace
    'extracted_epoch_cell_array', 'extracted_time_cell_array', 'all_latency_S1', 'all_latency_S2') % these are the variables to be saved
disp(' '); disp('----- epoch_cell_array *saving* DONE -----'); disp(' ')

open extracted_epoch_cell_array


%% BASELINE: Epoch Baseline_Before_Listen_S2 time period: 

if strcmp(current_interested_event,'Baseline_Before_Listen_S2')==1 
    disp(' '); disp(['******** Epoching: ', current_interested_event, ' ********']); disp(' ')

    for subID_idx = 1:totalSub
        current_subID = subID_list(subID_idx);
        if current_subID < 10
            current_subID_str = ['0', num2str(current_subID)];
        else
            current_subID_str = num2str(current_subID);
        end 
        disp(' '); disp(['current_subID = ', num2str(current_subID)])

        if ismember(current_subID, excluded_subj_list)==0  
            EEG = pop_loadset('filename', ['Sona', current_subID_str, '_iclabeled_itrplt_clean.set'], 'filepath', [ICA_file_path 'clean\']);
            
        %----------------------------------------------------------------%        
            % Get the indices from EEG.event.type       
            temp_latency = {EEG.event.latency}; % size(temp_latency) is how many rows/events/markers

            if current_subID >= 10 && current_subID ~= 39 && current_subID ~= 40
                temp_S48 = temp_latency(find(ismember({EEG.event.type}, '18432')));
                temp_S128 = temp_latency(find(ismember({EEG.event.type}, 'condition 1')));
                temp_S256 = temp_latency(find(ismember({EEG.event.type}, 'condition 2'))); % the start of resting phases; should be 2 elements
                total_trials = length(find(ismember({EEG.event.type}, 'condition 1'))); % trial starts; should be 100

            elseif current_subID <= 9 || current_subID == 39 || current_subID == 40
                total_trials = length(find(ismember({EEG.event.type}, 'condition 128'))); % trial starts; should be 100
                temp_S48 = temp_latency(find(ismember({EEG.event.type}, 'condition 48')));
                temp_S128 = temp_latency(find(ismember({EEG.event.type}, 'condition 128')));
                temp_S256 = temp_latency(find(ismember({EEG.event.type}, '256'))); % the start of resting phases; should be 2 elements
            end
            temp_S48_mat = cell2mat(temp_S48)';
            temp_S128_mat = cell2mat(temp_S128)';
            temp_S256_mat = cell2mat(temp_S256)';
            disp(['size(temp_S48_mat) = ', num2str(size(temp_S48_mat))]) % should be 212 (pause and check)
            disp(['size(temp_S128_mat) = ', num2str(size(temp_S128_mat))]) % should be 100
            disp(['size(temp_S256_mat) = ', num2str(size(temp_S256_mat))]) % should be 2
            

            % count how many event 48 in resting 1
            count_48_rest_1 = length(find(temp_S48_mat < temp_S128_mat(1)));
            % count how many event 48 in resting 2
            count_48_rest_2 = length(find(temp_S48_mat > temp_S256_mat(2)));
            
            % remove the event 48 not in listening phase
            temp_S48_mat(1:count_48_rest_1, :) = [];
            temp_S48_mat((length(temp_S48_mat)-count_48_rest_2+1):length(temp_S48_mat), :) = [];
            disp(['After removing resting events: size(temp_S48_mat) = ', num2str(size(temp_S48_mat))]) % should be 200
                        
        %----------------------------------------------------------------% 
            % for each trial, find vents between 128 and the next 128
            for trial_idx = 1:total_trials
                if trial_idx <= total_trials-1   
                    a = find(temp_S48_mat < temp_S128_mat(trial_idx+1));
                    b = find(temp_S48_mat < temp_S128_mat(trial_idx));
                elseif trial_idx == total_trials
                    a = find(temp_S48_mat < temp_S256_mat(2));
                    b = find(temp_S48_mat < temp_S128_mat(trial_idx));
                end
                current_count_48 = length(a) - length(b);
                current_48_idx = setdiff(a,b);
                if current_count_48 == 2 % regular trials
                    all_latency_S1(subID_idx, trial_idx) = temp_S48_mat(current_48_idx(1), 1); 
                    all_latency_S2(subID_idx, trial_idx) = temp_S48_mat(current_48_idx(2), 1);
                elseif current_count_48 == 1 % missing a 48, discard this trial
                    all_latency_S1(subID_idx, trial_idx) = 0; 
                    all_latency_S2(subID_idx, trial_idx) = 0;
                    disp(['trial_idx = ', num2str(trial_idx), '; current_count_48 = ', num2str(current_count_48)])
                elseif current_count_48 > 2  % extra 48, discard this trial
                    all_latency_S1(subID_idx, trial_idx) = 0; 
                    all_latency_S2(subID_idx, trial_idx) = 0;
                    disp(['trial_idx = ', num2str(trial_idx), '; current_count_48 = ', num2str(current_count_48)])
                end
            end

            % for sub 18, trial 6 only: 
            if current_subID == 18
                for trial_idx = 6
                    a = find(temp_S48_mat < temp_S128_mat(trial_idx+1));
                    b = find(temp_S48_mat < temp_S128_mat(trial_idx));
                    current_count_48 = length(a) - length(b);
                    current_48_idx = setdiff(a,b);
                    all_latency_S1(subID_idx, trial_idx) = temp_S48_mat(current_48_idx(1), 1); 
                    all_latency_S2(subID_idx, trial_idx) = temp_S48_mat(current_48_idx(2), 1);
                end
            end
            
        %------------------------- Epoching BASELINE -----------------------------%        
            % we want to epoch [-200 ms, 0] for each trial; 
            % i.e., epoch 0.2*512 timepoints prior to S2 (excluding the time point of S2 onset)
            % 0.2 * 512 = 102.4 timepoints which means there will be 103 elements in each cell
            for trial_idx = 1:total_trials
                current_trial_latency = all_latency_S2(subID_idx, trial_idx);
                if current_trial_latency == 0 % missing trial
                    extracted_epoch_cell_array{subID_idx, trial_idx} = [];
                    extracted_time_cell_array{subID_idx, trial_idx} = [];
                else
                    extracted_epoch_cell_array{subID_idx, trial_idx} = EEG.data(:, (current_trial_latency - 0.2*sampling_rate -1):(current_trial_latency - 1)); % we are NOT using pop_epoch here because we have already got all the time points information
                    extracted_time_cell_array{subID_idx, trial_idx} = EEG.times(:, (current_trial_latency - 0.2*sampling_rate -1):(current_trial_latency - 1));
                end
            end
            disp(' '); disp(['size(extracted_epoch_cell_array) = ', num2str(size(extracted_epoch_cell_array))])
            disp(['size(extracted_time_cell_array) = ', num2str(size(extracted_time_cell_array))])

        end
        disp(' '); disp(['----- current_subID = ', current_subID_str, ': Epoching ', current_interested_event, ' DONE -----']); disp(' ')
    end
end
disp(['----- Epoching *', current_interested_event, '* DONE -----'])

save('Baseline_Before_Listen_S2_epoch_cell_array.mat', ... % this is the name of the workspace
    'extracted_epoch_cell_array', 'extracted_time_cell_array', 'all_latency_S1', 'all_latency_S2') % these are the variables to be saved
disp(' '); disp('----- epoch_cell_array *saving* DONE -----'); disp(' ')

open extracted_epoch_cell_array


%%


