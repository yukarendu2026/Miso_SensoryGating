% This script is used for time epoching after preprocessing. 

% Before running this script, should load necessary variables (in the preprocessing script)

cd 'D:\1 Sensory Gating\Analysis'

% There were 3 phases: 
% 1, Resting phase I: 256--48--48--48--48--48--48 (fixed length 60
% seconds, 6 trials in total; eye open --> eye closed --> ...)
% 2, Listening phase
% 3, Resting phase II: same as the first resting phase

%***********************************************************************
% for epoching different events, use this same code; should 
% switch between these before running the following sections:

current_interested_event = 'Rest_1_usable';
% current_interested_event = 'Rest_2_usable';

% need to clear all before running a different event!

excluded_subj_list = [13, 33];

extracted_epoch_cell_array = cell(totalSub, 6);
extracted_time_cell_array = cell(totalSub, 6);
all_latency_trial_start = nan(totalSub, 6);
all_latency_trial_end = nan(totalSub, 6);
each_trial_length = nan(totalSub, 6);


%% Epoch Rest_1_usable: 

usable_start_samples = nan(totalSub, 6);
usable_end_samples = nan(totalSub, 6);

fileName = 'EEG Noise Log 20250425.xlsx'; % manual inspection
sheetName = 'Sheet1';
raw_data_all = readtable(fileName, 'Sheet', sheetName);
raw_sub_no = raw_data_all(:,1);
raw_sub_no = table2array(raw_sub_no);
raw_noise_start_time = raw_data_all(:,2);
raw_noise_start_time = table2array(raw_noise_start_time);
raw_noise_end_time = raw_data_all(:,3);
raw_noise_end_time = table2array(raw_noise_end_time);
raw_noise_type = raw_data_all{:, 4};
length(raw_sub_no(~isnan(raw_sub_no)))


if strcmp(current_interested_event,'Rest_1_usable')==1 
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
            disp(['count_48_rest_1 = ', num2str(count_48_rest_1)]) % should be 6
            
            % remove the event 48 not in resting state phase
            temp_S48_mat(count_48_rest_1+1: end, :) = [];
            disp(['After removing: size(temp_S48_mat) = ', num2str(size(temp_S48_mat))]) % should be 6

            % check if in Resting state event 48 were appropriately distributed
            % (i.e., 60 seconds apart)
            R1_48_latency = nan(1, length(temp_S48_mat)+1);
            R1_distance_48_latency = nan(1, length(temp_S48_mat));
            for R1_idx = 1:length(temp_S48_mat)+1
                if R1_idx == 1
                    R1_48_latency(R1_idx) = temp_S256_mat(1);
                else
                    R1_48_latency(R1_idx) = temp_S48_mat(R1_idx - 1);
                end
            end
            for R1_idx = 1:length(temp_S48_mat)
                R1_distance_48_latency(R1_idx) = R1_48_latency(R1_idx+1) - R1_48_latency(R1_idx);
            end
            judge_R1_distance_48_latency = R1_distance_48_latency/sampling_rate - 60
%             disp('find(abs(judge_R1_distance_48_latency) > 5 sec)')
%             find(abs(judge_R1_distance_48_latency) > 5) % for debug
            
            %----------------------------------------------------------------% 
            % for each trial, find the start and end latencies closest to the expected value 
            temp_distance_mtx = (R1_48_latency - R1_48_latency(1))/sampling_rate;
            for trial_idx = 1:6
                current_start_cutoff = 60*(trial_idx-1) + 5;
                current_end_cutoff = 60*trial_idx + 5;
                % find all triggers for the same event: 
                set_a = find(temp_distance_mtx <= current_end_cutoff);
                set_b = find(temp_distance_mtx <= current_start_cutoff);
                idx_to_be_judged = setdiff(set_a, set_b);
                mtx_to_be_judged = temp_distance_mtx(idx_to_be_judged); % for debug
                
                % for sub 12, the first resting trial was about 80s long and the second trials was about 40s long
                if current_subID == 12 && trial_idx == 1 
                    idx_to_be_judged = 2;
                elseif current_subID == 12 && trial_idx == 2
                    idx_to_be_judged = 39;
                end

                if trial_idx == 1
                    all_latency_trial_start(subID_idx, trial_idx) = R1_48_latency(1);
                    all_latency_trial_start(subID_idx, trial_idx+1) = R1_48_latency(idx_to_be_judged(1, end)); 
                elseif trial_idx < 6 && trial_idx > 1
                    all_latency_trial_start(subID_idx, trial_idx+1) = R1_48_latency(idx_to_be_judged(1, end)); 
                end
                all_latency_trial_end(subID_idx, trial_idx) = R1_48_latency(idx_to_be_judged(1, 1));
            end
            
            % for subID = 18, there is an extra event 48 at ~261 seconds. should not use it. 
            if current_subID == 18
                all_latency_trial_end(subID_idx, 5) = R1_48_latency(1, 7);
                all_latency_trial_start(subID_idx, 6) = R1_48_latency(1, 7);
                all_latency_trial_end(subID_idx, 6) = R1_48_latency(1, 8);
            end
            
            %----------------------------------------------------------------%             
            % compare with noise periods
            current_subID_row_no_start = find(raw_sub_no == current_subID);
            if current_subID == subID_list(end)
                current_subID_row_no_end = length(raw_sub_no);
            else
                current_subID_row_no_end = find(raw_sub_no == subID_list(subID_idx+1))-1;
            end

            % rest 1: 
            current_noise_start = raw_noise_start_time(current_subID_row_no_start:current_subID_row_no_end, 1);
            current_noise_end = raw_noise_end_time(current_subID_row_no_start:current_subID_row_no_end, 1);
            current_noise_type = raw_noise_type(current_subID_row_no_start:current_subID_row_no_end, 1);

            current_noise_start = current_noise_start(strcmp(current_noise_type, 'Rest 1'));
            current_noise_end = current_noise_end(strcmp(current_noise_type, 'Rest 1'));

            current_noise_start = current_noise_start(~isnan(current_noise_start));
            current_noise_end = current_noise_end(~isnan(current_noise_end));
            
            current_noise_start = current_noise_start * sampling_rate; % convert into latency scale
            current_noise_end = current_noise_end * sampling_rate;
            
            required_clean_samples = sampling_rate * 20;
            for trial_idx = 1:6
                disp(' '); disp(['Trial = ', num2str(trial_idx)])
                % Trial window
                current_latency_trial_start = all_latency_trial_start(subID_idx, trial_idx);
                current_latency_trial_end = all_latency_trial_end(subID_idx, trial_idx);

                % Get noise segments that overlap with this trial
                in_trial_idx = find(current_noise_end >= current_latency_trial_start & current_noise_start <= current_latency_trial_end);
                trial_noise_start = current_noise_start(in_trial_idx);
                trial_noise_end = current_noise_end(in_trial_idx);

                % Build clean segments
                clean_segments = [];

                % Before first noise
                if isempty(trial_noise_start)
                    disp('No noise in this trial')
                    clean_segments = [current_latency_trial_start + 1 * sampling_rate, current_latency_trial_end - 1];
                else
                    if trial_noise_start(1) > current_latency_trial_start
                        clean_segments = [clean_segments; current_latency_trial_start + 1 * sampling_rate, trial_noise_start(1)-1];
                    end

                    % Between noises
                    for i = 1:length(trial_noise_start)-1
                        seg_start = trial_noise_end(i) + 1;
                        seg_end = trial_noise_start(i+1) - 1;
                        if seg_start <= seg_end
                            clean_segments = [clean_segments; seg_start, seg_end];
                        end
                    end

                    % After last noise
                    if trial_noise_end(end) < current_latency_trial_end
                        clean_segments = [clean_segments; trial_noise_end(end)+1, current_latency_trial_end - 1];
                    end
                end
                clean_segments

                % Look for clean segment ≥ 20s
                seg_len = [];
                for i = 1:size(clean_segments, 1)
                    seg_len(i) = clean_segments(i,2) - clean_segments(i,1) + 1;
                    if seg_len(i) >= required_clean_samples
                        % if there are multiple segments > 20 sec, we will use the last segment. 
                        usable_start_samples(subID_idx, trial_idx) = clean_segments(i,2) - required_clean_samples + 1;
                        usable_end_samples(subID_idx, trial_idx) = clean_segments(i,2); 
                        % we always extract the last usable 20 sec time points (e.g., 0-25 sec usable, we will use 5-25 sec)
                        each_trial_length(subID_idx, trial_idx) = (clean_segments(i,2) - clean_segments(i,1)+1)/sampling_rate;
                    end
                end
                disp(['seg_len/sampling_rate = ', num2str(seg_len/sampling_rate)])
                disp(['size(clean_segments) = ', num2str(size(clean_segments))])
                
            end
            [usable_start_samples(subID_idx, :)/sampling_rate; usable_end_samples(subID_idx, :)/sampling_rate]

        %------------------------- Epoching Rest_1_usable -----------------------------%        
            % varied each trial length 
            for trial_idx = 1:6
                if isnan(usable_start_samples(subID_idx,trial_idx))|| isnan(usable_end_samples(subID_idx, trial_idx))
                    extracted_epoch_cell_array{subID_idx, trial_idx} = [];
                    extracted_time_cell_array{subID_idx, trial_idx} = [];
                else
                    % we are NOT using pop_epoch here because we have already got all the time points information
                    extracted_epoch_cell_array{subID_idx, trial_idx} = EEG.data(:, usable_start_samples(subID_idx,trial_idx):usable_end_samples(subID_idx, trial_idx) ); 
                    extracted_time_cell_array{subID_idx, trial_idx} = EEG.times(:, usable_start_samples(subID_idx,trial_idx):usable_end_samples(subID_idx, trial_idx) );
                end
            end
%             disp(' '); disp(['size(extracted_epoch_cell_array) = ', num2str(size(extracted_epoch_cell_array))])
%             disp(['size(extracted_time_cell_array) = ', num2str(size(extracted_time_cell_array))])

        end
        disp(' '); disp(['----- current_subID = ', current_subID_str, ': Epoching ', current_interested_event, ' DONE -----']); disp(' ')
    end
end
disp(['----- Epoching *', current_interested_event, '* DONE -----'])

note = 'Here each_trial_length records the last continuous usable period.';
save('Rest_1_usable_epoch_cell_array.mat', ... % this is the name of the workspace
    'extracted_epoch_cell_array', 'extracted_time_cell_array', 'usable_start_samples',...
    'usable_end_samples', 'each_trial_length', 'note') % these are the variables to be saved
disp(' '); disp('----- epoch_cell_array *saving* DONE -----'); disp(' ')

open extracted_epoch_cell_array


%% plot each_trial_length
fig = figure; 
h = histogram(each_trial_length, 15);  
counts = h.Values;
binEdges = h.BinEdges;
binCenters = binEdges(1:end-1) + diff(binEdges)/2;
text(binCenters,counts,num2str(counts'),HorizontalAlignment="center",VerticalAlignment="bottom")
xlabel('Trial length (in seconds)'); ylabel('Frequency');
title('Resting state 1: Usable periods (N = 46)')
text(20, 140, {'Usable: continuous periods within '; 'a trial without noises'})
xlim([17 68])
ylim([0 190])
% Pause here to check if there is anything weird in the plot.         

% check if there is any trial too long
disp(['min(each_trial_length) = ', num2str(min(each_trial_length))])
disp(['max(each_trial_length) = ', num2str(max(each_trial_length))]) 

disp(['min(usable_start_samples) = ', num2str(min(usable_start_samples))])
disp(['max(usable_start_samples) = ', num2str(max(usable_start_samples))]) 

disp(['min(usable_end_samples) = ', num2str(min(usable_end_samples))])
disp(['max(usable_end_samples) = ', num2str(max(usable_end_samples))]) 


%% Epoch Rest_2_usable: 

usable_start_samples = nan(totalSub, 6);
usable_end_samples = nan(totalSub, 6);

fileName = 'EEG Noise Log 20250425.xlsx'; % manual inspection
sheetName = 'Sheet1';
raw_data_all = readtable(fileName, 'Sheet', sheetName);
raw_sub_no = raw_data_all(:,1);
raw_sub_no = table2array(raw_sub_no);
raw_noise_start_time = raw_data_all(:,2);
raw_noise_start_time = table2array(raw_noise_start_time);
raw_noise_end_time = raw_data_all(:,3);
raw_noise_end_time = table2array(raw_noise_end_time);
raw_noise_type = raw_data_all{:, 4};
length(raw_sub_no(~isnan(raw_sub_no)))


if strcmp(current_interested_event,'Rest_2_usable')==1 
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
            

            % count how many event 48 befor resting 2
            count_48_bf_rest_2 = length(find(temp_S48_mat < temp_S256_mat(2)));
            % count how many event 48 in resting 2
            count_48_rest_2 = length(find(temp_S48_mat > temp_S256_mat(2)));
            disp(['count_48_rest_2 = ', num2str(count_48_rest_2)]) % should be 6
            
            % remove the event 48 not in resting state phase
            temp_S48_mat(1:count_48_bf_rest_2, :) = [];
            disp(['After removing: size(temp_S48_mat) = ', num2str(size(temp_S48_mat))]) % should be 6

            % check if in Resting state event 48 were appropriately distributed
            % (i.e., 60 seconds apart)
            R2_48_latency = nan(1, length(temp_S48_mat)+1);
            R2_distance_48_latency = nan(1, length(temp_S48_mat));
            for R2_idx = 1:length(temp_S48_mat)+1
                if R2_idx == 1
                    R2_48_latency(R2_idx) = temp_S256_mat(2);
                else
                    R2_48_latency(R2_idx) = temp_S48_mat(R2_idx - 1);
                end
            end
            for R2_idx = 1:length(temp_S48_mat)
                R2_distance_48_latency(R2_idx) = R2_48_latency(R2_idx+1) - R2_48_latency(R2_idx);
            end
            judge_R2_distance_48_latency = R2_distance_48_latency/sampling_rate - 60
%             disp('find(abs(judge_R2_distance_48_latency) > 5 sec)')
%             find(abs(judge_R2_distance_48_latency) > 5) % for debug
            
            %----------------------------------------------------------------% 
            % for each trial, find the start and end latencies closest to the expected value 
            temp_distance_mtx = (R2_48_latency - R2_48_latency(1))/sampling_rate;
            for trial_idx = 1:6
                current_start_cutoff = 60*(trial_idx-1) + 5;
                current_end_cutoff = 60*trial_idx + 5;
                % find all triggers for the same event: 
                set_a = find(temp_distance_mtx <= current_end_cutoff);
                set_b = find(temp_distance_mtx <= current_start_cutoff);
                idx_to_be_judged = setdiff(set_a, set_b);
                mtx_to_be_judged = temp_distance_mtx(idx_to_be_judged); % for debug

                if trial_idx == 1
                    all_latency_trial_start(subID_idx, trial_idx) = R2_48_latency(1);
                    all_latency_trial_start(subID_idx, trial_idx+1) = R2_48_latency(idx_to_be_judged(1, end)); 
                elseif trial_idx < 6 && trial_idx > 1
                    all_latency_trial_start(subID_idx, trial_idx+1) = R2_48_latency(idx_to_be_judged(1, end)); 
                end
                all_latency_trial_end(subID_idx, trial_idx) = R2_48_latency(idx_to_be_judged(1, 1));
            end
            
            % for subID = 14, there is an extra event 48 at ~1276 seconds. should not use it. 
            if current_subID == 14
                all_latency_trial_end(subID_idx, 1) = R2_48_latency(1, 3);
            end
            
            %----------------------------------------------------------------% 
            % compare with noise periods
            current_subID_row_no_start = find(raw_sub_no == current_subID);
            if current_subID == subID_list(end)
                current_subID_row_no_end = length(raw_sub_no);
            else
                current_subID_row_no_end = find(raw_sub_no == subID_list(subID_idx+1))-1;
            end

            % rest 2: 
            current_noise_start = raw_noise_start_time(current_subID_row_no_start:current_subID_row_no_end, 1);
            current_noise_end = raw_noise_end_time(current_subID_row_no_start:current_subID_row_no_end, 1);
            current_noise_type = raw_noise_type(current_subID_row_no_start:current_subID_row_no_end, 1);

            current_noise_start = current_noise_start(strcmp(current_noise_type, 'Rest 2'));
            current_noise_end = current_noise_end(strcmp(current_noise_type, 'Rest 2'));

            current_noise_start = current_noise_start(~isnan(current_noise_start));
            current_noise_end = current_noise_end(~isnan(current_noise_end));
            
            current_noise_start = current_noise_start * sampling_rate; % convert into latency scale
            current_noise_end = current_noise_end * sampling_rate;
            
            required_clean_samples = sampling_rate * 20;
            for trial_idx = 1:6
                disp(' '); disp(['Trial = ', num2str(trial_idx)])
                % Trial window
                current_latency_trial_start = all_latency_trial_start(subID_idx, trial_idx);
                current_latency_trial_end = all_latency_trial_end(subID_idx, trial_idx);

                % Get noise segments that overlap with this trial
                in_trial_idx = find(current_noise_end >= current_latency_trial_start & current_noise_start <= current_latency_trial_end);
                trial_noise_start = current_noise_start(in_trial_idx);
                trial_noise_end = current_noise_end(in_trial_idx);

                % Build clean segments
                clean_segments = [];

                % Before first noise
                if isempty(trial_noise_start)
                    disp('No noise in this trial')
                    clean_segments = [current_latency_trial_start + 1 * sampling_rate, current_latency_trial_end - 1];
                else
                    if trial_noise_start(1) > current_latency_trial_start
                        clean_segments = [clean_segments; current_latency_trial_start + 1 * sampling_rate, trial_noise_start(1)-1];
                    end

                    % Between noises
                    for i = 1:length(trial_noise_start)-1
                        seg_start = trial_noise_end(i) + 1;
                        seg_end = trial_noise_start(i+1) - 1;
                        if seg_start <= seg_end
                            clean_segments = [clean_segments; seg_start, seg_end];
                        end
                    end

                    % After last noise
                    if trial_noise_end(end) < current_latency_trial_end
                        clean_segments = [clean_segments; trial_noise_end(end)+1, current_latency_trial_end - 1];
                    end
                end
                clean_segments

                % Look for clean segment ≥ 20s
                seg_len = [];
                for i = 1:size(clean_segments, 1)
                    seg_len(i) = clean_segments(i,2) - clean_segments(i,1) + 1;
                    if seg_len(i) >= required_clean_samples
                        % if there are multiple segments > 20 sec, we will use the last segment. 
                        usable_start_samples(subID_idx, trial_idx) = clean_segments(i,2) - required_clean_samples + 1;
                        usable_end_samples(subID_idx, trial_idx) = clean_segments(i,2); 
                        % we always extract the last usable 20 sec time points (e.g., 0-25 sec usable, we will use 5-25 sec)
                        each_trial_length(subID_idx, trial_idx) = (clean_segments(i,2) - clean_segments(i,1)+1)/sampling_rate;
                    end
                end
                disp(['seg_len/sampling_rate = ', num2str(seg_len/sampling_rate)])
                disp(['size(clean_segments) = ', num2str(size(clean_segments))])
                
            end
            [usable_start_samples(subID_idx, :)/sampling_rate; usable_end_samples(subID_idx, :)/sampling_rate]

        %------------------------- Epoching Rest_2_usable -----------------------------%        
            % varied each trial length 
            for trial_idx = 1:6
                if isnan(usable_start_samples(subID_idx,trial_idx))|| isnan(usable_end_samples(subID_idx, trial_idx))
                    extracted_epoch_cell_array{subID_idx, trial_idx} = [];
                    extracted_time_cell_array{subID_idx, trial_idx} = [];
                else
                    % we are NOT using pop_epoch here because we have already got all the time points information
                    extracted_epoch_cell_array{subID_idx, trial_idx} = EEG.data(:, usable_start_samples(subID_idx,trial_idx):usable_end_samples(subID_idx, trial_idx) ); 
                    extracted_time_cell_array{subID_idx, trial_idx} = EEG.times(:, usable_start_samples(subID_idx,trial_idx):usable_end_samples(subID_idx, trial_idx) );
                end
            end
%             disp(' '); disp(['size(extracted_epoch_cell_array) = ', num2str(size(extracted_epoch_cell_array))])
%             disp(['size(extracted_time_cell_array) = ', num2str(size(extracted_time_cell_array))])

        end
        disp(' '); disp(['----- current_subID = ', current_subID_str, ': Epoching ', current_interested_event, ' DONE -----']); disp(' ')
    end
end
disp(['----- Epoching *', current_interested_event, '* DONE -----'])

note = 'Here each_trial_length records the last continuous usable period.';
save('Rest_2_usable_epoch_cell_array.mat', ... % this is the name of the workspace
    'extracted_epoch_cell_array', 'extracted_time_cell_array', 'usable_start_samples',...
    'usable_end_samples', 'each_trial_length', 'note') % these are the variables to be saved
disp(' '); disp('----- epoch_cell_array *saving* DONE -----'); disp(' ')

open extracted_epoch_cell_array


%% plot each_trial_length
fig = figure; 
h = histogram(each_trial_length, 15);  
counts = h.Values;
binEdges = h.BinEdges;
binCenters = binEdges(1:end-1) + diff(binEdges)/2;
text(binCenters,counts,num2str(counts'),HorizontalAlignment="center",VerticalAlignment="bottom")
xlabel('Trial length (in seconds)'); ylabel('Frequency');
title('Resting state 2: Usable periods (N = 46)')
text(20, 140, {'Usable: continuous periods within '; 'a trial without noises'})
xlim([17 68])
ylim([0 190])
% Pause here to check if there is anything weird in the plot.         

% check if there is any trial too long
disp(['min(each_trial_length) = ', num2str(min(each_trial_length))])
disp(['max(each_trial_length) = ', num2str(max(each_trial_length))]) 

disp(['min(usable_start_samples) = ', num2str(min(usable_start_samples))])
disp(['max(usable_start_samples) = ', num2str(max(usable_start_samples))]) 

disp(['min(usable_end_samples) = ', num2str(min(usable_end_samples))])
disp(['max(usable_end_samples) = ', num2str(max(usable_end_samples))]) 




%%


