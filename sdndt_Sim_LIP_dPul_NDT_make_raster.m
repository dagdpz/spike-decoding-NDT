function [raster_data, raster_labels, raster_site_info] = sdndt_Sim_LIP_dPul_NDT_make_raster(mat_filename)
% [raster_data, raster_labels, raster_site_info] = sdndt_Sim_LIP_dPul_NDT_make_raster('Y:\Projects\Simultaneous_dPul_PPC_recordings\ephys\dPul_LIP_Lin_20211109\population_Linus_20211109.mat');

% This code loads one population**.mat file and converts it to a raster_data, array 0 and 1.

load(mat_filename);
%load('Y:\Projects\Simultaneous_dPul_PPC_recordings\ephys\dPul_LIP_Lin_20211109\population_Linus_20211109.mat'); % once debug is complete, comment this line and enable the line above

run('sdndt_Sim_LIP_dPul_NDT_settings');

if ~exist(OUTPUT_PATH_raster,'dir')
    mkdir(OUTPUT_PATH_raster);
end

target_state = 6; % 6 - cue on , 4 - target acquisition

switch target_state
    case 6
        target_state_name = 'cueON';
    case 4
        target_state_name = 'GOsignal';
    otherwise
        fprintf('Invalid target_state value: %d\n', target_state);
        % You might want to handle the case when target_state is neither 6 nor 4
end


columnsNumberBasedOnWindow = settings.windowAroundEvent*2*1000; % windowAroundEvent in ms

num_units = size(population, 2);

for u = 1:num_units
    num_trial = size (population(u).trial, 2 );
    
    % Initialize cell arrays
    raster_labels.trial_type = cell(1, num_trial);
    raster_labels.sideSelected = cell(1, num_trial);
    raster_labels.trial_type_side = cell(1, num_trial);
    raster_labels.stimulus_position_X_coordinate = cell(1, num_trial);
    raster_labels.stimulus_position_X_coordinate = cell(1, num_trial);
    raster_labels.perturbation = cell(1, num_trial);
    raster_labels.block = cell(1, num_trial);
    raster_labels.run = cell(1, num_trial);
    
    % Initialize numeric array for raster_data
    raster_data = NaN(num_trial, columnsNumberBasedOnWindow);
    
    
    for t = 1:num_trial
        
        if population(u).trial(t).success == 0 % Check if the trial should be excluded based on success value
            fprintf('Trial %d in unit %d excluded from analysis (success = 0).\n', t, u);
            continue;  % Skip the rest of the loop and move to the next trial
        end
        
        %%% raster_data
        state_index = find(population(u).trial(t).states == target_state); % Find the index of the target state in the 'states' array
        if isempty(state_index)
            fprintf('State %d not found. Excluding from analysis.\n', target_state);
        else
            onsetTimeOfRequiredStage (t) = population(u).trial(t).states_onset(state_index); % Use the index to retrieve the corresponding value from 'states_onset'
            raster_data(t, :) = histcounts(population(u).trial(t).arrival_times, (onsetTimeOfRequiredStage(t) - settings.windowAroundEvent):0.001:(onsetTimeOfRequiredStage(t) + settings.windowAroundEvent));
        end
        
        
        %%% raster_labels
        if population(u).trial(t).choice
            raster_labels.trial_type{1, t} =  'choice';
        else
            raster_labels.trial_type{1, t} =  'instr';
        end
        
        if real(population(u).trial(t).tar_pos) > 0 % Convert positive values to 'R' and negative values to 'L'
            raster_labels.sideSelected{1, t} = 'R';
        else
            raster_labels.sideSelected{1, t} = 'L';
        end
        
        raster_labels.trial_type_side {1, t} = append(raster_labels.trial_type{1, t},'_',raster_labels.sideSelected{1, t});
        
        X_coordinate = real(population(u).trial(t).tar_pos);
        Y_coordinate = imag(population(u).trial(t).tar_pos);
        raster_labels.stimulus_position_X_coordinate{1, t} = X_coordinate;
        raster_labels.stimulus_position_Y_coordinate{1, t} = Y_coordinate;
        
        raster_labels.perturbation{1, t} = population(u).trial(t).perturbation;
        raster_labels.block{1, t} = population(u).trial(t).block;
        raster_labels.run{1, t} = population(u).trial(t).run;
        
    end
    
    %%% raster_site_info
    raster_site_info.recording_channel = population(u).channel;
    raster_site_info.session_ID = population(u).unit_ID(1:12);
    raster_site_info.unit_ID = population(u).unit_ID;
    raster_site_info.block_unit = [population(u).block_unit{:}];
    raster_site_info.perturbation_site = population(u).perturbation_site;
    raster_site_info.SNR_rating = population(u).SNR_rating;
    raster_site_info.Single_rating = population(u).Single_rating;
    raster_site_info.stability_rating = population(u).stability_rating;
    raster_site_info.site_ID = population(u).site_ID;
    raster_site_info.target = population(u).target;
    raster_site_info.grid_x = population(u).grid_x;
    raster_site_info.grid_y = population(u).grid_y;
    raster_site_info.electrode_depth = population(u).electrode_depth;
    
    

    
    
    raster_data = raster_data(~isnan(raster_data(:, 1)), :); % Remove NaN rows (trials with success == 0) from raster_data
    raster_labels.trial_type = raster_labels.trial_type(~cellfun('isempty', raster_labels.trial_type)); % Remove empty cells (trials with success == 0) from raster_data
    raster_labels.sideSelected = raster_labels.sideSelected(~cellfun('isempty', raster_labels.sideSelected));
    raster_labels.trial_type_side = raster_labels.trial_type_side(~cellfun('isempty', raster_labels.trial_type_side));
    raster_labels.stimulus_position_X_coordinate = raster_labels.stimulus_position_X_coordinate(~cellfun('isempty', raster_labels.stimulus_position_X_coordinate));
    raster_labels.stimulus_position_Y_coordinate = raster_labels.stimulus_position_Y_coordinate(~cellfun('isempty', raster_labels.stimulus_position_Y_coordinate));
    raster_labels.perturbation = raster_labels.perturbation(~cellfun('isempty', raster_labels.perturbation));
    raster_labels.block = raster_labels.block(~cellfun('isempty', raster_labels.block));
    raster_labels.run = raster_labels.run(~cellfun('isempty', raster_labels.run));
    
    

    filename = [OUTPUT_PATH_raster population(u).unit_ID '_raster_trial_state_' target_state_name '.mat'];
    save(filename,'raster_data', 'raster_labels', 'raster_site_info')
end

