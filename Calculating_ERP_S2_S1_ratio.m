% This script is used for calcualting ERP after epoching. 
cd('E:\1 Sensory Gating\Analysis')
load('Excluded_listening_trials.mat')
size(excluded_listening_trials_mtx) % 48 x 100


%% Calculate S1 baseline amplitude ([-200ms, 0] prior to S1)
total_trials = 100;
channels_interested = [1:32]';

excluded_subj_list = [13, 33];

load Baseline_Before_Listen_S1_epoch_cell_array.mat
mean_baseline_before_S1 = cell(1, totalSub);
for subID_idx = 1:totalSub
    current_subID = subID_list(subID_idx);
    if ismember(current_subID, excluded_subj_list)==0  
        for channel_idx = 1:length(channels_interested)
            for trial_idx = 1:total_trials
                if excluded_listening_trials_mtx(subID_idx, trial_idx) == 0
                    mean_baseline_before_S1{subID_idx}(channel_idx, trial_idx) = nan;
                else
                    mean_baseline_before_S1{subID_idx}(channel_idx, trial_idx) = mean(extracted_epoch_cell_array{subID_idx, trial_idx}(channels_interested(channel_idx), :));
                end
            end
        end
    end
end
disp('S1 Baseline mean amplitude calculation done')


%% Average across trials to get ERP (using [-200 ms, 0] before S1 as baseline)
channels_interested = [5; 9; 22; 26; 32]; % FC1, CP1, CP2, FC2, Cz 
mean_ERP_by_trial = cell(totalSub, 1);
mean_ERP_by_chan = nan(totalSub, 512, length(channels_interested));

load Whole_listening_period_epoch_cell_array.mat
% each cell in extracted_epoch_cell_array: 32 channels x 512 timepoints
for subID_idx = 1:totalSub 
    current_subID = subID_list(subID_idx);
    mean_ERP_by_trial{subID_idx, 1} = nan(length(channels_interested), 512, total_trials);
    if ismember(current_subID, excluded_subj_list)==0  
        for channel_idx = 1:length(channels_interested)
            temp_channel_mtx = nan(512, total_trials);
            temp_channel_mtx_crct = nan(512, total_trials);
            for time_idx = 1:512
                temp_mtx = [];
                for trial_idx = 1:total_trials
%                     if isempty(extracted_epoch_cell_array{subID_idx, trial_idx}) || isnan(mean_baseline_before_S1{subID_idx}(channels_interested(channel_idx), trial_idx)) || isempty(mean_baseline_before_S1{subID_idx})
                    if excluded_listening_trials_mtx(subID_idx, trial_idx) == 0
                        temp_channel_mtx_crct(time_idx, trial_idx) = nan;
                    else 
                        temp_channel_mtx(time_idx, trial_idx) = extracted_epoch_cell_array{subID_idx, trial_idx}(channels_interested(channel_idx), time_idx);
                        temp_channel_mtx_crct(time_idx, trial_idx) = temp_channel_mtx(time_idx, trial_idx) - mean_baseline_before_S1{subID_idx}(channels_interested(channel_idx), trial_idx);
                    end
                    mean_ERP_by_trial{subID_idx, 1}(channel_idx, time_idx, trial_idx) = temp_channel_mtx_crct(time_idx, trial_idx);
                end
                temp_mtx = temp_channel_mtx_crct(time_idx, :);
                mean_ERP_by_chan(subID_idx, time_idx, channel_idx) = mean(temp_mtx(~isnan(temp_mtx)));
            end
        end
    end
end
open mean_ERP_by_chan
disp('ERP by channel calculation done')


%% Average ERP across channels
mean_ERP_by_subj = nan(totalSub, 512);
single_trial_ERP_by_subj = cell(totalSub, 1);

for subID_idx = 1:totalSub
    current_subID = subID_list(subID_idx);
    single_trial_ERP_by_subj{subID_idx, 1} = nan(512, total_trials);
    if ismember(current_subID, excluded_subj_list)==0  
        for time_idx = 1:512             
            for trial_idx = 1:total_trials
                temp_mtx2 = mean_ERP_by_trial{subID_idx, 1}(:, time_idx, trial_idx);
                single_trial_ERP_by_subj{subID_idx, 1}(time_idx, trial_idx) = mean(temp_mtx2(~isnan(temp_mtx2)));
            end
        end
    end
end

for subID_idx = 1:totalSub
    current_subID = subID_list(subID_idx);
    if ismember(current_subID, excluded_subj_list)==0  
        for time_idx = 1:512 
            temp_mtx = mean_ERP_by_chan(subID_idx, time_idx, :);
            mean_ERP_by_subj(subID_idx, time_idx) = mean(temp_mtx(~isnan(temp_mtx)));
        end
    end
end
disp('ERP across channels calculation done')



%% FOR PAPER: plot ERP for single subject
cd('E:\1 Sensory Gating\Analysis\')
load('S2_to_S1_ratio.mat')

temp_subID_list = [8, 25];

for temp_subID_idx = 1:length(temp_subID_list)
    subID_idx = temp_subID_list(temp_subID_idx);
    
    current_subID = subID_list(subID_idx);
    if ismember(current_subID, excluded_subj_list)==0  

        Fig = figure;
        hold on
        baseline = plot([0 256], [0 0], 'k-');
        plot([0.04*sampling_rate 0.04*sampling_rate], [-10 12], 'k:')
        plot([0.08*sampling_rate 0.08*sampling_rate], [-10 12], 'k:')
        plot([0.15*sampling_rate 0.15*sampling_rate], [-10 12], 'k:')
        plot([0.25*sampling_rate 0.25*sampling_rate], [-10 12], 'k:')
        
        
        % thin shaded bar
        patch([0.04*sampling_rate 0.08*sampling_rate 0.08*sampling_rate 0.04*sampling_rate], ...
              [-4 -4 -4+0.1 -4+0.1], ...
              [0.5 0.5 0.5], ...     % light gray
              'EdgeColor','none');

        % label
        text((0.04*sampling_rate + 0.08*sampling_rate)/2, -4-0.5, 'P50', ...
             'HorizontalAlignment','center');

         
        patch([0.081*sampling_rate 0.15*sampling_rate 0.15*sampling_rate 0.081*sampling_rate], ...
              [-5 -5 -5+0.1 -5+0.1], ...
              [0.5 0.5 0.5], ...     % light gray
              'EdgeColor','none');
        text((0.081*sampling_rate + 0.15*sampling_rate)/2, -5-0.5, 'N100', ...
             'HorizontalAlignment','center');
         
        patch([0.151*sampling_rate 0.25*sampling_rate 0.25*sampling_rate 0.151*sampling_rate], ...
              [-6 -6 -6+0.1 -6+0.1], ...
              [0.5 0.5 0.5], ...     % light gray
              'EdgeColor','none');
        text((0.151*sampling_rate + 0.25*sampling_rate)/2, -6-0.5, 'P200', ...
             'HorizontalAlignment','center');
         

        curve1 = plot(mean_ERP_by_subj(subID_idx, 1:256), 'linewidth', 2, 'color', [0 0.4470 0.7410]);
        curve2 = plot(mean_ERP_by_subj(subID_idx, 257:512), 'linewidth', 2, 'color', [0.8500 0.3250 0.0980]);

        text(0.1*sampling_rate, 10, ...
            {['P50 S2/S1 ratio = ', num2str(round(S2_S1_ratio(subID_idx, 1), 2))];...
            ['MisoQuest score = ', num2str(round(miso_quest_score(subID_idx, 1), 2))];...
            ['SGI-B score = ', num2str(round(SGI_B_score(subID_idx, 1), 2))] })


        ylim([-10 12])
        xlim([-0.5 1*sampling_rate/2+0.5])
        xlabel('Time (milliseconds)')
        ylabel('Amplitude (\muV)')
        xticks([0 0.1*sampling_rate 0.2*sampling_rate 0.3*sampling_rate 0.4*sampling_rate 0.5*sampling_rate])
        xticklabels({'0', '100', '200', '300', '400', '500'})

        legend([curve1, curve2], {'S1 ERP', 'S2 ERP'})
        title(['Participant ', num2str(current_subID), ', ERP P50 (40-80 ms)'])

        saveas(Fig, ['Mean_ERP_ac_chan_Sub_', num2str(current_subID),'.fig'])
        saveas(Fig, ['Mean_ERP_ac_chan_Sub_', num2str(current_subID),'.tiff'])
        close(Fig)
    end
end




%% FOR PAPER: plot ERP for single subject 100 ms only
cd('E:\1 Sensory Gating\Analysis\')
load('S2_to_S1_ratio.mat')
load('Quest_scores.mat')

temp_subID_list = [8, 25];

for temp_subID_idx = 1:length(temp_subID_list)
    subID_idx = temp_subID_list(temp_subID_idx);
    
    current_subID = subID_list(subID_idx);
    if ismember(current_subID, excluded_subj_list)==0  

        Fig = figure;
        hold on
        baseline = plot([0 52], [0 0], 'k-');
        plot([0.04*sampling_rate 0.04*sampling_rate], [-10 12], 'k:')
        plot([0.08*sampling_rate 0.08*sampling_rate], [-10 12], 'k:')
        
        
        % thin shaded bar
        patch([0.04*sampling_rate 0.08*sampling_rate 0.08*sampling_rate 0.04*sampling_rate], ...
              [-4 -4 -4+0.1 -4+0.1], ...
              [0.5 0.5 0.5], ...     % light gray
              'EdgeColor','none');

        % label
        text((0.04*sampling_rate + 0.08*sampling_rate)/2, -4-0.5, 'P50', ...
             'HorizontalAlignment','center');


        curve1 = plot(mean_ERP_by_subj(subID_idx, 1:52), 'linewidth', 2, 'color', [0 0.4470 0.7410]);
        curve2 = plot(mean_ERP_by_subj(subID_idx, 257:308), 'linewidth', 2, 'color', [0.8500 0.3250 0.0980]);

        text(0.02*sampling_rate, 4, ...
            {['P50 S2/S1 ratio = ', num2str(round(S2_S1_ratio(subID_idx, 1), 2))];...
            ['MisoQuest score = ', num2str(round(miso_quest_score(subID_idx, 1), 2))];...
            ['SGI-B score = ', num2str(round(SGI_B_score(subID_idx, 1), 2))] })


        ylim([-6.1 6])
        xlim([0.5 0.1*sampling_rate+0.9])
        xlabel('Time (milliseconds)')
        ylabel('Amplitude (\muV)')
        xticks([0.5 0.04*sampling_rate 0.08*sampling_rate 0.1*sampling_rate ])
        xticklabels({'0', '40', '80', '100'})

        legend([curve1, curve2], {'S1 ERP', 'S2 ERP'})
        title(['Participant ', num2str(current_subID), ', ERP P50 (40-80 ms)'])

        saveas(Fig, ['Mean_ERP_ac_chan_Sub_', num2str(current_subID),'_100ms.fig'])
        saveas(Fig, ['Mean_ERP_ac_chan_Sub_', num2str(current_subID),'_100ms.tiff'])
        close(Fig)
    end
end





%% Average ERP across subjects
mean_ERP_across_subj = nan(1, 512);
SE_ERP_across_subj = nan(1, 512);
for time_idx = 1:512 
    temp_mtx = mean_ERP_by_subj(:, time_idx);
    temp_mtx = temp_mtx(~isnan(temp_mtx));
    mean_ERP_across_subj(1, time_idx) = mean(temp_mtx);
    SE_ERP_across_subj(1, time_idx) = std(temp_mtx)/sqrt(length(temp_mtx));
end
open SE_ERP_across_subj
open mean_ERP_across_subj




%% FOR PAPER: plot mean ERP across subjects
cd('E:\1 Sensory Gating\Analysis\')

Fig = figure;
hold on
baseline = plot([0 256], [0 0], 'k-');
plot([0.04*sampling_rate 0.04*sampling_rate], [-10 12], 'k:')
plot([0.08*sampling_rate 0.08*sampling_rate], [-10 12], 'k:')
plot([0.15*sampling_rate 0.15*sampling_rate], [-10 12], 'k:')
plot([0.25*sampling_rate 0.25*sampling_rate], [-10 12], 'k:')


% thin shaded bar
patch([0.04*sampling_rate 0.08*sampling_rate 0.08*sampling_rate 0.04*sampling_rate], ...
      [-4 -4 -4+0.1 -4+0.1], ...
      [0.5 0.5 0.5], ...     % light gray
      'EdgeColor','none');

% label
text((0.04*sampling_rate + 0.08*sampling_rate)/2, -4-0.5, 'P50', ...
     'HorizontalAlignment','center');


patch([0.081*sampling_rate 0.15*sampling_rate 0.15*sampling_rate 0.081*sampling_rate], ...
      [-5 -5 -5+0.1 -5+0.1], ...
      [0.5 0.5 0.5], ...     % light gray
      'EdgeColor','none');
text((0.081*sampling_rate + 0.15*sampling_rate)/2, -5-0.5, 'N100', ...
     'HorizontalAlignment','center');

patch([0.151*sampling_rate 0.25*sampling_rate 0.25*sampling_rate 0.151*sampling_rate], ...
      [-6 -6 -6+0.1 -6+0.1], ...
      [0.5 0.5 0.5], ...     % light gray
      'EdgeColor','none');
text((0.151*sampling_rate + 0.25*sampling_rate)/2, -6-0.5, 'P200', ...
     'HorizontalAlignment','center');

         
% Calculate upper and lower bounds for the shaded area
upperBound = mean_ERP_across_subj + SE_ERP_across_subj * 1.96;
lowerBound = mean_ERP_across_subj - SE_ERP_across_subj * 1.96;
% Plot the shaded area: Fill the shaded area between the upper and lower bounds
SE_area1 = fill([[1:256], fliplr([1:256])], [upperBound(1, 1:256), fliplr(lowerBound(1, 1:256))], ...
    [0.7, 0.8, 1], 'EdgeColor', 'none', 'facealpha', 0.8);
SE_area2 = fill([[1:256], fliplr([1:256])], [upperBound(1, 257:512), fliplr(lowerBound(1, 257:512))], ...
    [0.85 0.65 0.55], 'EdgeColor', 'none', 'facealpha', 0.8);

curve1 = plot(mean_ERP_across_subj(1, 1:256), 'linewidth', 2, 'color', [0 0.4470 0.7410]);
curve2 = plot(mean_ERP_across_subj(1, 257:512), 'linewidth', 2, 'color', [0.8500 0.3250 0.0980]);

ylim([-10 12])
xlim([-0.5 1*sampling_rate/2+0.5])
xlabel('Time (milliseconds)')
ylabel('Amplitude (\muV)')
xticks([0 0.1*sampling_rate 0.2*sampling_rate 0.3*sampling_rate 0.4*sampling_rate 0.5*sampling_rate])
xticklabels({'0', '100', '200', '300', '400', '500'})

legend([curve1, curve2, SE_area1, SE_area2], {'S1 ERP', 'S2 ERP', 'S1 95% CI', 'S2 95% CI'})
title(['Mean ERP, N = 46, P50 (40-80 ms)'])

saveas(Fig, ['Mean_ERP_across_subj(N = 46)_2_curves.fig'])
saveas(Fig, ['Mean_ERP_across_subj(N = 46)_2_curves.tiff'])






%% FOR PAPER: plot mean ERP across subjects 100 ms only
cd('E:\1 Sensory Gating\Analysis\')

Fig = figure;
hold on
baseline = plot([0 52], [0 0], 'k-');
plot([0.04*sampling_rate 0.04*sampling_rate], [-10 12], 'k:')
plot([0.08*sampling_rate 0.08*sampling_rate], [-10 12], 'k:')


% thin shaded bar
patch([0.04*sampling_rate 0.08*sampling_rate 0.08*sampling_rate 0.04*sampling_rate], ...
      [-4 -4 -4+0.1 -4+0.1], ...
      [0.5 0.5 0.5], ...     % light gray
      'EdgeColor','none');

% label
text((0.04*sampling_rate + 0.08*sampling_rate)/2, -4-0.5, 'P50', ...
     'HorizontalAlignment','center');


         
% Calculate upper and lower bounds for the shaded area
upperBound = mean_ERP_across_subj + SE_ERP_across_subj * 1.96;
lowerBound = mean_ERP_across_subj - SE_ERP_across_subj * 1.96;
% Plot the shaded area: Fill the shaded area between the upper and lower bounds
SE_area1 = fill([[1:52], fliplr([1:52])], [upperBound(1, 1:52), fliplr(lowerBound(1, 1:52))], ...
    [0.7, 0.8, 1], 'EdgeColor', 'none', 'facealpha', 0.8);
SE_area2 = fill([[1:52], fliplr([1:52])], [upperBound(1, 257:308), fliplr(lowerBound(1, 257:308))], ...
    [0.85 0.65 0.55], 'EdgeColor', 'none', 'facealpha', 0.8);

curve1 = plot(mean_ERP_across_subj(1, 1:52), 'linewidth', 2, 'color', [0 0.4470 0.7410]);
curve2 = plot(mean_ERP_across_subj(1, 257:308), 'linewidth', 2, 'color', [0.8500 0.3250 0.0980]);

ylim([-6 4])
xlim([0.5 0.1*sampling_rate+0.9])
xlabel('Time (milliseconds)')
ylabel('Amplitude (\muV)')
xticks([0.5 0.04*sampling_rate 0.08*sampling_rate 0.1*sampling_rate ])
xticklabels({'0', '40', '80', '100'})

legend([curve1, curve2, SE_area1, SE_area2], {'S1 ERP', 'S2 ERP', 'S1 95% CI', 'S2 95% CI'})
title(['Mean ERP, N = 46, P50 (40-80 ms)'])

saveas(Fig, ['Mean_ERP_across_subj(N = 46)_2_curves_100ms.fig'])
saveas(Fig, ['Mean_ERP_across_subj(N = 46)_2_curves_100ms.tiff'])





%% =======================================================================

%% find peaks to calculate P50 S2/S1 ratio
% Time window: [40, 80 ms] for S1, [540, 580 ms] for S2
% 0.04*512 = 20.48 
% 0.08*512 = 40.96 
% 0.54*512 = 276.48 
% 0.58*512 = 296.96 
% Therefore, we take elements 20-41 for S1 and 276-297 for S2 (22 elements)

current_window_S1_start_idx = 1; 
current_window_S1_end_idx = 52; 
current_window_S2_start_idx = 257; 
current_window_S2_end_idx = 308; 

excluded_subj_list

cd('E:\1 Sensory Gating\Analysis')

if isfile('S2_to_S1_ratio.mat')
    load S2_to_S1_ratio.mat
else
    S2_S1_ratio = nan(totalSub, 1);
    S1_pos_pk_val = nan(totalSub, 1);
    S1_trough_val2 = nan(totalSub, 1);
    S1_pk_amplitude_crct = nan(totalSub, 1);
    S2_pos_pk_val = nan(totalSub, 1);
    S2_trough_val2 = nan(totalSub, 1);
    S2_pk_amplitude_crct = nan(totalSub, 1);
    
    S1_pos_pk_latency = nan(totalSub, 1);
    S2_pos_pk_latency = nan(totalSub, 1);
end


%%%
cd('E:\1 Sensory Gating\Analysis\ERP figures 20250507\')


for subID_idx = 1:totalSub

    current_subID = subID_list(subID_idx);
    disp(['current_subID = ', num2str(current_subID)])

    if ismember(current_subID, excluded_subj_list)==0  
        current_subj_ERP = mean_ERP_by_subj(subID_idx, :); 
    
        current_window_S1 = current_subj_ERP(1, current_window_S1_start_idx:current_window_S1_end_idx);
        current_window_S2 = current_subj_ERP(1, current_window_S2_start_idx:current_window_S2_end_idx);
    
        % We want to find the peak and the nearest trough within the time window
        
        % For S1: 
        [S1_pos_pks, S1_pos_pks_locs] = findpeaks(current_window_S1);
        distance_to_50ms_S1 = abs(S1_pos_pks_locs - 0.050*sampling_rate);
        [min_distance_to_50ms_S1, S1_pos_pk_val_idx] = min(distance_to_50ms_S1); % use the peak nearest to 50ms as the P50 peak
        if current_subID == 36
            S1_pos_pk_val_idx = 3; % manually choose the peak in 40-80 ms window
        elseif current_subID == 42
            S1_pos_pk_val_idx = 3; % manually choose the peak in 40-80 ms window
        end
        S1_pos_pk_val(subID_idx,1) = S1_pos_pks(S1_pos_pk_val_idx);
        S1_pos_pk_latency(subID_idx,1) = (S1_pos_pks_locs(S1_pos_pk_val_idx) + current_window_S1_start_idx - 1)/sampling_rate*1000;
        
        % Find troughs preceding the peak
        [S1_troughs, S1_trouhgs_locs2] = findpeaks((-1)*current_window_S1(1, 1:S1_pos_pks_locs(S1_pos_pk_val_idx)));
        S1_trough_idx2 = find(S1_trouhgs_locs2 < S1_pos_pks_locs(S1_pos_pk_val_idx) ); 
        if ~isempty(S1_trough_idx2)
            if length(S1_trough_idx2) == 1 % if we only find one trough preceding the peak
                S1_trough_val2(subID_idx,1) = (-1)*S1_troughs(S1_trough_idx2); 
                nearest_trough_index = S1_trouhgs_locs2(S1_trough_idx2);
            elseif length(S1_trough_idx2) > 1 % if we find more than one trough preceding the peak
                % Calculate distances
                distances = S1_pos_pks_locs(S1_pos_pk_val_idx) - S1_trouhgs_locs2(S1_trough_idx2);
                % Find nearest trough
                [min_distance, min_index] = min(abs(distances));
                nearest_trough_index = S1_trouhgs_locs2(S1_trough_idx2(min_index));
                S1_trough_val2(subID_idx,1) = (-1)*S1_troughs(S1_trough_idx2(min_index)); 
            end
            disp('------ Found trough in S1 window: ------')
            disp(['S1_trough_val2 = ', num2str(S1_trough_val2(subID_idx,1))])
        elseif isempty(S1_trough_idx2)==1 % if we did not find any trough preceding the peak within the time window
            disp('------ No trough found in S1 window: Searching forward ------')
            nearest_trough_index = 0;
            search_window = current_subj_ERP(1, 1:(S1_pos_pks_locs(S1_pos_pk_val_idx)+current_window_S1_start_idx-1));
            [S1_troughs_search, S1_troughs_search_locs2] = findpeaks((-1)*search_window);
            if isempty(S1_troughs_search) % monotonically increasing before the peak
                S1_trough_val2(subID_idx,1) = current_subj_ERP(1, 1);
            else
                S1_trough_val2(subID_idx,1) = (-1)*S1_troughs_search(end); % use the trough nearest to the peak
            end
            disp(['S1_trough_val2 = ', num2str(S1_trough_val2(subID_idx,1))])
        end
    
        % For S2: 
        [S2_pos_pks, S2_pos_pks_locs] = findpeaks(current_window_S2);
        distance_to_50ms_S2 = abs(S2_pos_pks_locs - 0.050*sampling_rate);
        [min_distance_to_50ms_S2, S2_pos_pk_val_idx] = min(distance_to_50ms_S2); % use the peak nearest to 50ms as the P50 peak

        S2_pos_pk_val(subID_idx,1) = S2_pos_pks(S2_pos_pk_val_idx);
        S2_pos_pk_latency(subID_idx,1) = (S2_pos_pks_locs(S2_pos_pk_val_idx) + current_window_S1_start_idx - 1)/sampling_rate*1000; % according to S2 onset
        
        % Find troughs preceding the peak
        [S2_troughs, S2_trouhgs_locs2] = findpeaks((-1)*current_window_S2(1, 1:S2_pos_pks_locs(S2_pos_pk_val_idx) ));
        S2_trough_idx2 = find(S2_trouhgs_locs2 < S2_pos_pks_locs(S2_pos_pk_val_idx) );
        if ~isempty(S2_trough_idx2)
            if length(S2_trough_idx2) == 1 % if we only find one trough preceding the peak
                S2_trough_val2(subID_idx,1) = (-1)*S2_troughs(S2_trough_idx2); 
                nearest_trough_index2 = S2_trouhgs_locs2(S2_trough_idx2);
            elseif length(S2_trough_idx2) > 1 % if we find more than one trough preceding the peak
                % Calculate distances
                distances = S2_pos_pks_locs(S2_pos_pk_val_idx) - S2_trouhgs_locs2(S2_trough_idx2);
                % Find nearest trough
                [min_distance, min_index] = min(abs(distances));
                nearest_trough_index2 = S2_trouhgs_locs2(S2_trough_idx2(min_index));
                S2_trough_val2(subID_idx,1) = (-1)*S2_troughs(S2_trough_idx2(min_index)); 
            end
            disp('------ Found trough in S2 window: ------')
            disp(['S2_trough_val2 = ', num2str(S2_trough_val2(subID_idx,1))])
        elseif isempty(S2_trough_idx2) % if we did not find any trough preceding the peak within the time window
            disp('------ No trough found in S2 window: Searching forward ------')
            nearest_trough_index2 = 0;
            search_window = current_subj_ERP(1, (current_window_S1_end_idx+1):(S2_pos_pks_locs(S2_pos_pk_val_idx)+256)); % 256 timepoints = 500 ms
            [S2_troughs_search, S2_trouhgs_search_locs2] = findpeaks((-1)*search_window);
            S2_trough_val2(subID_idx,1) = (-1)*S2_troughs_search(end); % use the trough nearest to the peak
            disp(['S2_trough_val2 = ', num2str(S2_trough_val2(subID_idx,1))])
        end

        % if we did not find trough in S1's window 20-41: 
        if nearest_trough_index < 20 && nearest_trough_index2 >= 20 && nearest_trough_index2 <= S1_pos_pks_locs(S1_pos_pk_val_idx)
            % use the latency of S2 trough to get S1 trough
            disp('Re-setting S1 trough')
            S1_trough_val2(subID_idx,1) = current_window_S1(1, nearest_trough_index2);
        end
        
        
        % Calculate the ratio
        S2_pk_amplitude_crct(subID_idx, 1) = S2_pos_pk_val(subID_idx,1) - S2_trough_val2(subID_idx,1);
        S1_pk_amplitude_crct(subID_idx, 1) = S1_pos_pk_val(subID_idx,1) - S1_trough_val2(subID_idx,1);
        S2_S1_ratio(subID_idx, 1) = S2_pk_amplitude_crct(subID_idx, 1)/S1_pk_amplitude_crct(subID_idx, 1);
       
        
        % Plot to double check: 
        Fig1 = figure;
        subplot(2,1,1)
        hold on
        findpeaks(current_window_S1) % Note the triangle markers' corrodinates on this plot are NOT the peak values!!!
        plot([0.050*sampling_rate 0.050*sampling_rate], [-8 8], 'r-')
        plot([20 20], [-8 8], 'k-')
        plot([41 41], [-8 8], 'k-')
        title(['SubID = ', num2str(current_subID), ', S1']);
        text(8, -1, ['peak = ', num2str(S1_pos_pk_val(subID_idx,1))]);
        text(8, -3, ['Time point = ', num2str(S1_pos_pks_locs(S1_pos_pk_val_idx))]);
        if ~isempty(S1_trough_idx2)
            plot(nearest_trough_index, current_window_S1(1, nearest_trough_index), 'ro')
            text(8, -5, ['trough = ', num2str(S1_trough_val2(subID_idx,1))]);
            text(8, -7, ['Time point = ', num2str(nearest_trough_index)]);
        end
        if nearest_trough_index < 20 && nearest_trough_index2 >= 20 && nearest_trough_index2 <= S1_pos_pks_locs(S1_pos_pk_val_idx)
            plot(nearest_trough_index2, S1_trough_val2(subID_idx,1), 'ro')
        end
        ylim([-8 8])
        xlabel('Time points')
        ylabel('Amplitude (\muV)')
        
        subplot(2,1,2)
        hold on
        findpeaks(current_window_S2)
        plot([0.050*sampling_rate 0.050*sampling_rate], [-8 8], 'r-')        
        plot([20 20], [-8 8], 'k-')
        plot([41 41], [-8 8], 'k-')
        title(['SubID = ', num2str(current_subID), ', S2']);
        text(8, -1, ['peak = ', num2str(S2_pos_pk_val(subID_idx,1))]);
        text(8, -3, ['Time point = ', num2str(S2_pos_pks_locs(S2_pos_pk_val_idx))]);
        if ~isempty(S2_trough_idx2)
            plot(nearest_trough_index2, S2_trough_val2(subID_idx,1), 'ro')
            text(8, -5, ['trough = ', num2str(S2_trough_val2(subID_idx,1))]);
            text(8, -7, ['Time point = ', num2str(nearest_trough_index2)]);
        end
        ylim([-8 8])
        xlabel('Time points')
        ylabel('Amplitude (\muV)')
        
        text(14, 5, ['Ratio = ', num2str(S2_S1_ratio(subID_idx, 1) )])
        
        saveas(Fig1, ['Find_peaks_Sub_', num2str(current_subID),'.tiff'])
        
        close(Fig1)
        disp(' ')
        

        % if S2 peak is not found within the 40-80 ms window: 
        if S2_pos_pk_latency(subID_idx,1) < 40 || S2_pos_pk_latency(subID_idx,1) > 80
            S2_S1_ratio(subID_idx, 1) = inf;
        end
        
   end
end


%% P50 adjust S2/S1 ratio
% for sub 12, 27, 40, 43, 45, the S2 peak was not found within the window, so
% we use the min(S2 peak after correction) across all other participants
% for these participants as S2 peak: 
temp_sub_list = [12;27;40;43;45];
sub_list_for_S2_pk = subID_list;
sub_list_for_S2_pk(excluded_subj_list, :) = [];
sub_list_for_S2_pk(sub_list_for_S2_pk == 12) = [];
sub_list_for_S2_pk(sub_list_for_S2_pk == 27) = [];
sub_list_for_S2_pk(sub_list_for_S2_pk == 40) = [];
sub_list_for_S2_pk(sub_list_for_S2_pk == 43) = [];
sub_list_for_S2_pk(sub_list_for_S2_pk == 45) = [];

sub_list_for_S2_pk(sub_list_for_S2_pk == 34) = []; % S1 peak not found
sub_list_for_S2_pk(sub_list_for_S2_pk == 18) = []; % S1 trough not found, S2 trough outside window
sub_list_for_S2_pk(sub_list_for_S2_pk == 47) = []; % S1 trough not found, S2 trough outside window

length(sub_list_for_S2_pk) % 34
intersect(temp_sub_list, sub_list_for_S2_pk)

min(S2_pk_amplitude_crct(sub_list_for_S2_pk, 1)) % sub 24, value = 0.0171
S2_pk_amplitude_crct(temp_sub_list, 1) = min(S2_pk_amplitude_crct(sub_list_for_S2_pk, 1));

for temp_idx = 1:4
    subID_idx = temp_sub_list(temp_idx);
    S2_S1_ratio(subID_idx, 1) = S2_pk_amplitude_crct(subID_idx, 1)/S1_pk_amplitude_crct(subID_idx, 1);
end

output_ratio = [S1_pos_pk_val, S1_trough_val2, S1_pk_amplitude_crct, ...
    S2_pos_pk_val, S2_trough_val2, S2_pk_amplitude_crct, S2_S1_ratio];
open output_ratio

cd('E:\1 Sensory Gating\Analysis\ERP figures 20250507\')

save('S2_to_S1_ratio.mat', ... % this is the name of the workspace
    'S1_pos_pk_val', 'S1_trough_val2', 'S1_pk_amplitude_crct', ...
    'S2_pos_pk_val', 'S2_trough_val2', 'S2_pk_amplitude_crct', ...
    'S2_S1_ratio', 'S1_pos_pk_latency', 'S2_pos_pk_latency') % these are the variables to be saved
disp(' '); disp('----- S2_to_S1_ratio *saving* DONE -----'); disp(' ')





%%






 
