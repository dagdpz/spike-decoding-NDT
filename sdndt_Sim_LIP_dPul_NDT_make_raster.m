function [raster_data, raster_labels, raster_site_info] = sdndt_Sim_LIP_dPul_NDT_make_raster(mat_filename)
% [raster_data, raster_labels, raster_site_info] = Sim_LIP_dPul_NDT_make_raster('Y:\Projects\Simultaneous_dPul_PPC_recordings\ephys\dPul_LIP_Lin_20211109\population_Linus_20211109.mat');

% This code loads one population**.mat file and converts it to a raster_data, array 0 and 1.

load(mat_filename);
%load('Y:\Projects\Simultaneous_dPul_PPC_recordings\ephys\dPul_LIP_Lin_20211109\population_Linus_20211109.mat'); % once debug is complete, comment this line and enable the line above

run('sdndt_Sim_LIP_dPul_NDT_settings');

if ~exist(OUTPUT_PATH,'dir')
    mkdir(OUTPUT_PATH);
end

target_state = 6; % 6 - cue on , 4 - target acquisition

switch target_state
    case 6
        target_state_name = "cueON";
    case 4
        target_state_name = "GOsignal";
    otherwise
        fprintf('Invalid target_state value: %d\n', target_state);
        % You might want to handle the case when target_state is neither 6 nor 4
end
target_state_name_char = char(target_state_name);
%safe_target_state_name = strrep(target_state_name, ' ', '_'); % Replace spaces with underscores


window = 0.5; % sec 
some_column_size = window*2*1000; % ms

num_units = size (population, 2 );

for u = 1:num_units
    num_trial = size (population(u).trial, 2 );
    
    % Initialize cell arrays
    raster_labels.stimulus_ID = cell(1, num_trial);
    raster_labels.stimulus_side = cell(1, num_trial);
    raster_labels.stimulus_position = cell(1, num_trial);
    raster_labels.stimulus_position_X_coordinate = cell(1, num_trial);
    raster_labels.stimulus_position_X_coordinate = cell(1, num_trial);
    
    % Initialize numeric array for raster_data
    raster_data = NaN(num_trial, some_column_size); 
    
    
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
            onset_value (t) = population(u).trial(t).states_onset(state_index); % Use the index to retrieve the corresponding value from 'states_onset'
            raster_data(t, :) = histcounts(population(u).trial(t).arrival_times, (onset_value(t) - window):0.001:(onset_value(t) + window));
        end
        %raster_data (t, :) = histcounts(population(u).trial(t).arrival_times,  (onset_value-window):0.001:(onset_value+window));
        
        %%% raster_labels
        raster_labels.stimulus_ID {1, t} = population(u).trial(t).choice;
        if real(population(u).trial(t).tar_pos) > 0 % Convert positive values to 'R' and negative values to 'L'
            raster_labels.stimulus_side{1, t} = 'R';
        else
            raster_labels.stimulus_side{1, t} = 'L';
        end
   
        X_coordinate = real(population(u).trial(t).tar_pos);
        Y_coordinate = imag(population(u).trial(t).tar_pos);
        raster_labels.stimulus_position_X_coordinate{1, t} = X_coordinate;
        raster_labels.stimulus_position_Y_coordinate{1, t} = Y_coordinate;
        
        %%% raster_site_info
        raster_site_info.session_ID = population(u).unit_ID;
        raster_site_info.recording_channel = population(u).channel;
        raster_site_info.unit = population(u).block_unit;
        
    end
    
    
    raster_data = raster_data(~isnan(raster_data(:, 1)), :); % Remove NaN rows (trials with success == 0) from raster_data
    raster_labels.stimulus_ID = raster_labels.stimulus_ID(~cellfun('isempty', raster_labels.stimulus_ID)); % Remove empty cells (trials with success == 0) from raster_data
    raster_labels.stimulus_side = raster_labels.stimulus_side(~cellfun('isempty', raster_labels.stimulus_side));
    raster_labels.stimulus_position_X_coordinate = raster_labels.stimulus_position_X_coordinate(~cellfun('isempty', raster_labels.stimulus_position_X_coordinate));
    raster_labels.stimulus_position_Y_coordinate = raster_labels.stimulus_position_Y_coordinate(~cellfun('isempty', raster_labels.stimulus_position_Y_coordinate));

    
filename = [OUTPUT_PATH population(u).unit_ID '_trial_state_' target_state_name_char];
save(filename,'raster_data', 'raster_labels', 'raster_site_info')
end

