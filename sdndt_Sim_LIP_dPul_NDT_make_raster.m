function [raster_data, raster_labels, raster_site_info] = sdndt_Sim_LIP_dPul_NDT_make_raster(monkey, injection)
% This function processes a list of files obtained from filelist_of_days_from_Simultaneous_dPul_PPC_recordings
% This code loads one population**.mat file and converts it to a raster_data, array 0 and 1

% Example, how to run it:
% sdndt_Sim_LIP_dPul_NDT_make_raster('Bacchus', '0');
% sdndt_Sim_LIP_dPul_NDT_make_raster('Bacchus', '1');
% sdndt_Sim_LIP_dPul_NDT_make_raster('Linus', '2');


%
% injection: '0' - control, '1' - injection (Inactivation experiment)
%            '2' - Functional interaction experiment (dPul and LIP)
% typeOfSessions: ' ' - for control (Inactivation experiment) and Functional interaction experiment (dPul and LIP)
%                 'right' - right dPul injection (7 sessions) for mokey L
%                 'left' - left dPul injection (3 sessions) for mokey L
%                 'all' - all sessions (right and left dPul injection together: 10 sessions for mokey L)
% target_state: 6 - cue on , 4 - target acquisition



%% Define the session types based on the injection value
if strcmp(injection, '1')
    if strcmp(monkey, 'Linus')
        typeOfSessions = {'left', 'right', 'all'}; % For control and injection experiments
    elseif strcmp(monkey, 'Bacchus')
        typeOfSessions = {'right'};
    end
elseif  strcmp(injection, '0') || strcmp(injection, '2')
    typeOfSessions = {''}; % For the functional interaction experiment
else
    error('Invalid injection value. Use ''0'', ''1'', or ''2''.');
end
%% Define target_state parameters
% target_state: 6 - cue on , 4 - target acquisition
targetParams = struct();

% Define target_state parameters
targetParams.cueON = 6;
targetParams.GOSignal = 4;
% Add more target_state parameters as needed

%% Loop through each target_state parameter and typeOfSessions
fieldNames = fieldnames(targetParams);

% visualisation : "loading"  
numFieldNames = numel(fieldNames); 
numTypesOfSessions = numel(typeOfSessions); 
h = waitbar(0, 'Processing...'); % Initialize progress bar 

for i = 1:numel(fieldNames)
    target_state_name = fieldNames{i};
    target_state = targetParams.(target_state_name);
    
    
    % Loop through each typeOfSessions
    for j = 1:numel(typeOfSessions)
        
        sdndt_Sim_LIP_dPul_NDT_make_raster_path(monkey, injection, typeOfSessions{j}, target_state);
        
        updateProgressBar(i, j, numFieldNames, numTypesOfSessions, h);  % Update progress bar
    end
end

close(h);  % Close progress bar
end


function sdndt_Sim_LIP_dPul_NDT_make_raster_path(monkey, injection, typeOfSessions, target_state)
% Call the function to get the dates
dateOfRecording = filelist_of_days_from_Simultaneous_dPul_PPC_recordings(monkey, injection, typeOfSessions);

% Call the settings function with the chosen set
[base_path, INPUT_PATH, OUTPUT_PATH_raster, OUTPUT_PATH_binned, monkey_prefix, settings] = sdndt_Sim_LIP_dPul_NDT_settings(monkey, injection, typeOfSessions);
%run('sdndt_Sim_LIP_dPul_NDT_settings');


for day = 1:length(dateOfRecording)
    
        
    % Create the folder for the list of required files
    OUTPUT_PATH_raster_dateOfRecording = [OUTPUT_PATH_raster monkey_prefix dateOfRecording{day} '/'];
    if ~exist(OUTPUT_PATH_raster_dateOfRecording, 'dir')
        mkdir(OUTPUT_PATH_raster_dateOfRecording);
    end
    
    % Construct the mat_file_name for the current day based on monkey and injection
        if strcmp(monkey, 'Linus')
            if strcmp(injection, '0') % '0' means 'control'
                mat_file_name = ['dPul_LIP_Lin_' dateOfRecording{day} '/population_Linus_' dateOfRecording{day} '.mat'];
            elseif strcmp(injection, '1') % '1' means 'injection'
                mat_file_name = ['dPul_inj_LIP_Lin_10s/population_Linus_' dateOfRecording{day} '.mat'];
            else
                error('Invalid selection. Use ''0'' or ''1'' for injection.');
            end
        elseif strcmp(monkey, 'Bacchus')
            if strcmp(injection, '0') % '0' means 'control'
                mat_file_name = ['dPul_LIP_Bac_9_sessions/population_Bacchus_' dateOfRecording{day} '.mat'];
            elseif strcmp(injection, '1') % '1' means 'injection'
                mat_file_name = ['dPul_inj_LIP_Bac_8s_paired/population_Bacchus_' dateOfRecording{day} '.mat'];
            else
                error('Invalid selection. Use ''0'' or ''1'' for injection.');
            end
        else
            error('Invalid monkey value. Use ''Bacchus'' or ''Linus''.');
        end
     
        
    % Call sdndt_Sim_LIP_dPul_NDT_make_raster for the current file
    sdndt_Sim_LIP_dPul_NDT_make_raster_internal(INPUT_PATH, OUTPUT_PATH_raster_dateOfRecording, mat_file_name, monkey, injection, target_state, settings);
    
    % Display message indicating session is done
    fprintf('Session of %s is completed.\n', dateOfRecording{day});
end

end




function sdndt_Sim_LIP_dPul_NDT_make_raster_internal(INPUT_PATH, OUTPUT_PATH_raster_dateOfRecording, mat_file_name, monkey, injection, target_state, settings)
% This is the internal function that contains the main logic of your code

input_population_file = [INPUT_PATH mat_file_name];
load(input_population_file);


units_skipped = 0; % Initialize the counter for skipped units
all_brain_structures = {}; % Initialize a cell array to store all brain structure names
columnsNumberBasedOnWindow = settings.windowAroundEvent*2*1000; % windowAroundEvent in ms

num_units = size(population, 2);

num_of_success_trials_per_unit = zeros(1, num_units); % Initialize an array to store success counts for each unit

for u = 1:num_units
    
    unique_blocks = unique([population(u).trial.block]); % Get the unique block numbers for the current unit
    % num_trial = size (population(u).trial, 2 );
    num_of_success_trials_per_unit(u) = 0; % Reset the counter for each unit
    
    % Loop over unique blocks for the current unit
    for b = unique_blocks
        % Filter trials for the current block
        block_trials = [population(u).trial.block] == b;
        
        % Get the number of trials for the current block
        num_block_trials = sum(block_trials);
        
        % Initialize cell arrays
        % Initializing the arrays outside the block loop ensures that each block starts with empty arrays, preventing any data leakage or mixing between blocks.
        raster_labels.trial_type = cell(1, 0);
        raster_labels.sideSelected = cell(1, 0);
        raster_labels.trial_type_side = cell(1, 0);
        raster_labels.stimulus_position_X_coordinate = cell(1, 0);
        raster_labels.stimulus_position_Y_coordinate = cell(1, 0);
        raster_labels.perturbation = cell(1, 0);
        raster_labels.block = cell(1, 0);
        raster_labels.run = cell(1, 0);
        raster_data = NaN(0, columnsNumberBasedOnWindow);
        
        if num_block_trials > 0
            %             % Initialize cell arrays
            %             raster_labels.trial_type = cell(1, num_block_trials);
            %             raster_labels.sideSelected = cell(1, num_block_trials);
            %             raster_labels.trial_type_side = cell(1, num_block_trials);
            %             raster_labels.stimulus_position_X_coordinate = cell(1, num_block_trials);
            %             raster_labels.stimulus_position_Y_coordinate = cell(1, num_block_trials);
            %             raster_labels.perturbation = cell(1, num_block_trials);
            %             raster_labels.block = cell(1, num_block_trials);
            %             raster_labels.run = cell(1, num_block_trials);
            
            
            
            % Initialize numeric array for raster_data
            raster_data = NaN(num_block_trials, columnsNumberBasedOnWindow);
            
            %blocks_present = []; % Track the blocks present in the trials
            
            
            % Loop over trials for the current block
            for t = find(block_trials) % t = 1:num_trial
                
                
                if population(u).trial(t).success == 1 % Check if the trial should be excluded based on success value
                    
                    
                    
                    %%% raster_data
                    state_index = find(population(u).trial(t).states == target_state);
                    if isempty(state_index)
                        %fprintf('State %d not found. Excluding from analysis.\n', target_state);
                    else
                        onsetTimeOfRequiredStage(t) = population(u).trial(t).states_onset(state_index);
                        % Use the index to retrieve the corresponding value from 'states_onset'
                        %raster_data(t, :) = histcounts(population(u).trial(t).arrival_times, (onsetTimeOfRequiredStage(t) - settings.windowAroundEvent):0.001:(onsetTimeOfRequiredStage(t) + settings.windowAroundEvent));
                        
                        %end+1 is: "add a new element after the last element." It is a convenient way to append a new row to a matrix without explicitly specifying the row index.
                        raster_data(end+1, :) = histcounts(population(u).trial(t).arrival_times, (onsetTimeOfRequiredStage(t) - settings.windowAroundEvent):0.001:(onsetTimeOfRequiredStage(t) + settings.windowAroundEvent)); % If you were to use raster_data = [raster_data; new_data];, it would achieve the same result.
                    end
                    
                    
                    % how many successful trials were made for each unit individually (as there are units with different numbers of record blocks)
                    num_of_success_trials_per_unit(u) = num_of_success_trials_per_unit(u) + 1;
                    
                    
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
                    
                    X_coordinate(1, t) = real(population(u).trial(t).tar_pos);
                    Y_coordinate(1, t) = imag(population(u).trial(t).tar_pos);
                    raster_labels.stimulus_position_X_coordinate{1, t} = X_coordinate(1, t);
                    raster_labels.stimulus_position_Y_coordinate{1, t} = Y_coordinate(1, t);
                    
                    raster_labels.perturbation{1, t} = population(u).trial(t).perturbation;
                    raster_labels.block{1, t} = population(u).trial(t).block;
                    raster_labels.run{1, t} = population(u).trial(t).run;
                    
                end % population(u).trial(t).success == 1
                
            end % for each trial
            
            
            %%% raster_site_info
            raster_site_info.recording_channel = population(u).channel;
            raster_site_info.session_ID = population(u).unit_ID(1:12);
            raster_site_info.unit_ID = population(u).unit_ID;
            raster_site_info.block_unit = [population(u).block_unit{:}]; % population(u).block_unit;
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
            
            
            all_brain_structures = [all_brain_structures, raster_site_info.target]; % Accumulate all brain structure names in the list
            
            
            
            
            %     % Check if both blocks 1 and 2 are present in the trials
            %     if ismember(1, blocks_present) && ismember(2, blocks_present)
            %         % Save data only if both blocks 1 and 2 are present
            %         filename = [OUTPUT_PATH_raster population(u).unit_ID '_raster_' raster_site_info.target '_trial_state_' target_state_name '.mat'];
            %         save(filename, 'raster_data', 'raster_labels', 'raster_site_info');
            %     else
            %         fprintf('Skipping unit %d because it does not have both blocks 1 and 2.\n', u);
            %         units_skipped = units_skipped + 1;
            %     end
            
            
            % Save data for the current block
            target_state_name = get_target_state_name(target_state);
            filename = [OUTPUT_PATH_raster_dateOfRecording population(u).unit_ID '_raster_' raster_site_info.target '_trial_state_' target_state_name '_block_' num2str(b) '.mat'];
            save(filename, 'raster_data', 'raster_labels', 'raster_site_info');
            
        end % num_block_trials > 0
        
    end %  b = unique_blocks
    
    % Accumulate all brain structure names in the list
    all_brain_structures = [all_brain_structures, raster_site_info.target];
end % for u = 1:num_units
%fprintf('%d units out of %d for the file %s not taken in the analysis.\n', units_skipped, num_units, mat_filename);

brain_structures_present = unique(all_brain_structures); % Get unique brain structure names
all_brain_structures = strjoin(brain_structures_present, '_'); % format suitable for file names
end




function target_state_name = get_target_state_name(target_state)
% Function to get the target state name based on the target_state value
switch target_state
    case 6
        target_state_name = 'cueON';
    case 4
        target_state_name = 'GOsignal';
    otherwise
        error('Invalid target_state value: %d\n', target_state);
end
end


function updateProgressBar(i, j, numFieldNames, numTypesOfSessions, h)
    % Update progress bar
    progress = ((i - 1) * numTypesOfSessions + j) / (numFieldNames * numTypesOfSessions);
    waitbar(progress, h, sprintf('Processing... %.2f%%', progress * 100));
end


%% old version

% sdndt_Sim_LIP_dPul_NDT_make_raster('dPul_LIP_Lin_20211109\population_Linus_20211109.mat', 4);

% mat_file_name: 'dPul_LIP_Lin_20211109\population_Linus_20211109.mat' % (control)
%                'dPul_inj_LIP_Lin_10s\population_Linus_20210520.mat'  % (injection)

% target_state: 6 - cue on , 4 - target acquisition

% This code loads one population**.mat file and converts it to a raster_data, array 0 and 1.


% if strcmp(injection, '0')
%
%     % Call the function to get the dates
%     dateOfRecording = filelist_of_days_from_Simultaneous_dPul_PPC_recordings(injection);
%
%     % Use the provided date as a subfolder
%     for day = 1:length(dateOfRecording)
%         OUTPUT_PATH_raster_dateOfRecording{day} = [OUTPUT_PATH_raster dateOfRecording{day} '/'];
%     end
%
%     % Create the folder for the list of required files
%     if ~exist(OUTPUT_PATH_raster_dateOfRecording, 'dir')
%         mkdir(OUTPUT_PATH_raster_dateOfRecording);
%     end
%
%     mat_file_name = ['dPul_LIP_Lin_' 20211109 '\population_Linus_' 20211109 '.mat'];
%
% else % (injection, '1')
%     %%%
% end


% input_population_file = [INPUT_PATH mat_file_name];
% load(input_population_file);
% %load('Y:\Projects\Simultaneous_dPul_PPC_recordings\ephys\dPul_LIP_Lin_20211109\population_Linus_20211109.mat'); % once debug is complete, comment this line and enable the line above
%
%
%
%
% % creating a personalized folder for a particular session
% parts = strsplit(mat_file_name, '_');
% required_parts =  parts(end);
% dateOfRecording = char(strrep(required_parts, '.mat', ''));
%



% %%Make raster_data
% OUTPUT_PATH_raster_dateOfRecording = [OUTPUT_PATH_raster dateOfRecording '/'];
% if ~exist(OUTPUT_PATH_raster_dateOfRecording,'dir')
%     mkdir(OUTPUT_PATH_raster_dateOfRecording);
% end


% %target_state = 6; % 6 - cue on , 4 - target acquisition
% switch target_state
%     case 6
%         target_state_name = 'cueON';
%     case 4
%         target_state_name = 'GOsignal';
%     otherwise
%         fprintf('Invalid target_state value: %d\n', target_state);
%         % You might want to handle the case when target_state is neither 6 nor 4
% end


%units_skipped = 0; % Initialize the counter for skipped units
% all_brain_structures = {}; % Initialize a cell array to store all brain structure names
% columnsNumberBasedOnWindow = settings.windowAroundEvent*2*1000; % windowAroundEvent in ms
%
% num_units = size(population, 2);
%
% num_of_success_trials_per_unit = zeros(1, num_units); % Initialize an array to store success counts for each unit
%
% for u = 1:num_units
%
%     unique_blocks = unique([population(u).trial.block]); % Get the unique block numbers for the current unit
%     % num_trial = size (population(u).trial, 2 );
%     num_of_success_trials_per_unit(u) = 0; % Reset the counter for each unit
%
%     % Loop over unique blocks for the current unit
%     for b = unique_blocks
%         % Filter trials for the current block
%         block_trials = [population(u).trial.block] == b;
%
%         % Get the number of trials for the current block
%         num_block_trials = sum(block_trials);
%
%         % Initialize cell arrays
%         % Initializing the arrays outside the block loop ensures that each block starts with empty arrays, preventing any data leakage or mixing between blocks.
%         raster_labels.trial_type = cell(1, 0);
%         raster_labels.sideSelected = cell(1, 0);
%         raster_labels.trial_type_side = cell(1, 0);
%         raster_labels.stimulus_position_X_coordinate = cell(1, 0);
%         raster_labels.stimulus_position_Y_coordinate = cell(1, 0);
%         raster_labels.perturbation = cell(1, 0);
%         raster_labels.block = cell(1, 0);
%         raster_labels.run = cell(1, 0);
%         raster_data = NaN(0, columnsNumberBasedOnWindow);
%
%         if num_block_trials > 0
% %             % Initialize cell arrays
% %             raster_labels.trial_type = cell(1, num_block_trials);
% %             raster_labels.sideSelected = cell(1, num_block_trials);
% %             raster_labels.trial_type_side = cell(1, num_block_trials);
% %             raster_labels.stimulus_position_X_coordinate = cell(1, num_block_trials);
% %             raster_labels.stimulus_position_Y_coordinate = cell(1, num_block_trials);
% %             raster_labels.perturbation = cell(1, num_block_trials);
% %             raster_labels.block = cell(1, num_block_trials);
% %             raster_labels.run = cell(1, num_block_trials);
%
%
%
%             % Initialize numeric array for raster_data
%             raster_data = NaN(num_block_trials, columnsNumberBasedOnWindow);
%
%             %blocks_present = []; % Track the blocks present in the trials
%
%
%             % Loop over trials for the current block
%             for t = find(block_trials) % t = 1:num_trial
%
%
%                 if population(u).trial(t).success == 1 % Check if the trial should be excluded based on success value
%
%
%
%                     %%% raster_data
%                     state_index = find(population(u).trial(t).states == target_state);
%                     if isempty(state_index)
%                         %fprintf('State %d not found. Excluding from analysis.\n', target_state);
%                     else
%                         onsetTimeOfRequiredStage(t) = population(u).trial(t).states_onset(state_index);
%                         % Use the index to retrieve the corresponding value from 'states_onset'
%                         %raster_data(t, :) = histcounts(population(u).trial(t).arrival_times, (onsetTimeOfRequiredStage(t) - settings.windowAroundEvent):0.001:(onsetTimeOfRequiredStage(t) + settings.windowAroundEvent));
%
%                         %end+1 is: "add a new element after the last element." It is a convenient way to append a new row to a matrix without explicitly specifying the row index.
%                         raster_data(end+1, :) = histcounts(population(u).trial(t).arrival_times, (onsetTimeOfRequiredStage(t) - settings.windowAroundEvent):0.001:(onsetTimeOfRequiredStage(t) + settings.windowAroundEvent)); % If you were to use raster_data = [raster_data; new_data];, it would achieve the same result.
%                     end
%
%
%                     % how many successful trials were made for each unit individually (as there are units with different numbers of record blocks)
%                     num_of_success_trials_per_unit(u) = num_of_success_trials_per_unit(u) + 1;
%
%
%                     %%% raster_labels
%                     if population(u).trial(t).choice
%                         raster_labels.trial_type{1, t} =  'choice';
%                     else
%                         raster_labels.trial_type{1, t} =  'instr';
%                     end
%
%                     if real(population(u).trial(t).tar_pos) > 0 % Convert positive values to 'R' and negative values to 'L'
%                         raster_labels.sideSelected{1, t} = 'R';
%                     else
%                         raster_labels.sideSelected{1, t} = 'L';
%                     end
%
%                     raster_labels.trial_type_side {1, t} = append(raster_labels.trial_type{1, t},'_',raster_labels.sideSelected{1, t});
%
%                     X_coordinate(1, t) = real(population(u).trial(t).tar_pos);
%                     Y_coordinate(1, t) = imag(population(u).trial(t).tar_pos);
%                     raster_labels.stimulus_position_X_coordinate{1, t} = X_coordinate(1, t);
%                     raster_labels.stimulus_position_Y_coordinate{1, t} = Y_coordinate(1, t);
%
%                     raster_labels.perturbation{1, t} = population(u).trial(t).perturbation;
%                     raster_labels.block{1, t} = population(u).trial(t).block;
%                     raster_labels.run{1, t} = population(u).trial(t).run;
%
%                 end % population(u).trial(t).success == 1
%
%             end % for each trial
%
%
%             %%% raster_site_info
%             raster_site_info.recording_channel = population(u).channel;
%             raster_site_info.session_ID = population(u).unit_ID(1:12);
%             raster_site_info.unit_ID = population(u).unit_ID;
%             raster_site_info.block_unit = [population(u).block_unit{:}]; % population(u).block_unit;
%             raster_site_info.perturbation_site = population(u).perturbation_site;
%             raster_site_info.SNR_rating = population(u).SNR_rating;
%             raster_site_info.Single_rating = population(u).Single_rating;
%             raster_site_info.stability_rating = population(u).stability_rating;
%             raster_site_info.site_ID = population(u).site_ID;
%             raster_site_info.target = population(u).target;
%             raster_site_info.grid_x = population(u).grid_x;
%             raster_site_info.grid_y = population(u).grid_y;
%             raster_site_info.electrode_depth = population(u).electrode_depth;
%
%
%
%             raster_data = raster_data(~isnan(raster_data(:, 1)), :); % Remove NaN rows (trials with success == 0) from raster_data
%             raster_labels.trial_type = raster_labels.trial_type(~cellfun('isempty', raster_labels.trial_type)); % Remove empty cells (trials with success == 0) from raster_data
%             raster_labels.sideSelected = raster_labels.sideSelected(~cellfun('isempty', raster_labels.sideSelected));
%             raster_labels.trial_type_side = raster_labels.trial_type_side(~cellfun('isempty', raster_labels.trial_type_side));
%             raster_labels.stimulus_position_X_coordinate = raster_labels.stimulus_position_X_coordinate(~cellfun('isempty', raster_labels.stimulus_position_X_coordinate));
%             raster_labels.stimulus_position_Y_coordinate = raster_labels.stimulus_position_Y_coordinate(~cellfun('isempty', raster_labels.stimulus_position_Y_coordinate));
%             raster_labels.perturbation = raster_labels.perturbation(~cellfun('isempty', raster_labels.perturbation));
%             raster_labels.block = raster_labels.block(~cellfun('isempty', raster_labels.block));
%             raster_labels.run = raster_labels.run(~cellfun('isempty', raster_labels.run));
%
%
%             all_brain_structures = [all_brain_structures, raster_site_info.target]; % Accumulate all brain structure names in the list
%
%
%
%
%             %     % Check if both blocks 1 and 2 are present in the trials
%             %     if ismember(1, blocks_present) && ismember(2, blocks_present)
%             %         % Save data only if both blocks 1 and 2 are present
%             %         filename = [OUTPUT_PATH_raster population(u).unit_ID '_raster_' raster_site_info.target '_trial_state_' target_state_name '.mat'];
%             %         save(filename, 'raster_data', 'raster_labels', 'raster_site_info');
%             %     else
%             %         fprintf('Skipping unit %d because it does not have both blocks 1 and 2.\n', u);
%             %         units_skipped = units_skipped + 1;
%             %     end
%
%
%             % Save data for the current block
%             filename = [OUTPUT_PATH_raster_dateOfRecording population(u).unit_ID '_raster_' raster_site_info.target '_trial_state_' target_state_name '_block_' num2str(b) '.mat'];
%             save(filename, 'raster_data', 'raster_labels', 'raster_site_info');
%
%         end % num_block_trials > 0
%
%     end %  b = unique_blocks
%
%     % Accumulate all brain structure names in the list
%     all_brain_structures = [all_brain_structures, raster_site_info.target];
% end % for u = 1:num_units



% fprintf('%d units out of %d for the file %s not taken in the analysis.\n', units_skipped, num_units, mat_filename);

% brain_structures_present = unique(all_brain_structures); % Get unique brain structure names
% all_brain_structures = strjoin(brain_structures_present, '_'); % format suitable for file names

