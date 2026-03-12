% This script is used for time frequency analysis after preprocessing and epoching. 

% Need BOSC scripts from Whitten et al. (2011)


%% run time-frequency 1-50 Hz
cd 'E:\1 Sensory Gating\Analysis'

% Switch between these before running the following sections:
% current_interested_event = 'Rest_1_usable';
% current_interested_event = 'Rest_2_usable';
current_interested_event = 'listening';

disp('current_interested_event: '); current_interested_event
disp(' ')

if strcmp(current_interested_event,'Rest_1_usable')==1 
    load Rest_1_usable_epoch_cell_array.mat
    total_trials = 6;
elseif strcmp(current_interested_event,'Rest_2_usable')==1 
    load Rest_2_usable_epoch_cell_array.mat
    total_trials = 6;
    
elseif strcmp(current_interested_event,'listening')==1 
    load Whole_listening_period_epoch_cell_array.mat
    total_trials = 100;
    
end
disp('---- Data loading DONE ----')


%% run tf and save B_cell 
start_time = datetime('now','TimeZone','local','Format','d-MMM-y HH:mm:ss Z')

interested_channel_list = [1:1:32]; 
excluded_subj_list = [13, 33];

for channel_idx = 1:length(interested_channel_list(1,:))

    current_channel = interested_channel_list(1,channel_idx)
    current_channel_name = strtrim(channel_name{current_channel}); % remove spaces
    disp(' '); disp(['current_channel_name = ', current_channel_name]); disp(' ')

    if strcmp(current_interested_event,'Rest_1_usable')==1 
        current_file_name = ['Rest_1_usable_power_cell_array_', num2str(current_channel),'.mat'];
    elseif strcmp(current_interested_event,'Rest_2_usable')==1 
        current_file_name = ['Rest_2_usable_power_cell_array_', num2str(current_channel),'.mat'];
    elseif strcmp(current_interested_event,'Rest_1_baseline')==1 
        current_file_name = ['Rest_1_baseline_power_cell_array_', num2str(current_channel),'.mat'];
    elseif strcmp(current_interested_event,'Rest_2_baseline')==1 
        current_file_name = ['Rest_2_baseline_power_cell_array_', num2str(current_channel),'.mat'];
        
    elseif strcmp(current_interested_event,'listening')==1 
        current_file_name = ['Listening_power_cell_array_', num2str(current_channel),'.mat'];
    end
    if isfile(current_file_name)
        load(current_file_name)
    end
    
    
    
    for subID_idx = 1:totalSub
        current_subID = subID_list(subID_idx);
        if current_subID < 10
            current_subID_str = ['0', num2str(current_subID)];
        else
            current_subID_str = num2str(current_subID);
        end 
        disp(' '); disp(['current_subID = ', num2str(current_subID)])

        if ismember(current_subID, excluded_subj_list)==0  

            for trial_idx = 1:total_trials
                if isempty(extracted_epoch_cell_array{subID_idx,trial_idx}) % missing trial
                    B_cell{subID_idx, trial_idx} = [];
                    P_cell{subID_idx, trial_idx} = [];
                    T_cell{subID_idx, trial_idx} = [];
                    F_cell{subID_idx, trial_idx} = [];
                else
                    [B,P,T,F] = BOSC_tf(extracted_epoch_cell_array{subID_idx,trial_idx}(current_channel,:), 1:1:50, sampling_rate, 6); % sampling rate = 512 Hz, wavelet width = 6
                    % B: power, P: phase
                    B_cell{subID_idx, trial_idx} = B;
                    P_cell{subID_idx, trial_idx} = P;
                    T_cell{subID_idx, trial_idx} = T;
                    F_cell{subID_idx, trial_idx} = F;
                end
            end
        end
    end
    disp('----- BOSC_tf DONE -----')

    
    % Save the dataset
    save(current_file_name, ... % this is the name of the workspace
        'B_cell', 'current_channel_name') % these are the variables to be saved        
    disp(' '); disp('----- _power_cell_array *saving* DONE -----'); 
    disp(' ')
end

% B_cell: the power array for each channel

disp('current_interested_event: '); current_interested_event
start_time
datetime('now','TimeZone','local','Format','d-MMM-y HH:mm:ss Z')


%%





