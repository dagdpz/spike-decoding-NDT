function [raster_data, raster_labels, raster_site_info] = sdndt_Sim_LIP_dPul_NDT_to_make_raster(mat_file_name, target_state)
%  sdndt_Sim_LIP_dPul_NDT_to_make_raster('Y:\Projects\Simultaneous_dPul_PPC_recordings\ephys\dPul_LIP_Lin_20211109\population_Linus_20211109.mat', 4);

% This code loads one population**.mat file and converts it to a raster_data, array 0 and 1.


load(mat_file_name);
%load('Y:\Projects\Simultaneous_dPul_PPC_recordings\ephys\dPul_LIP_Lin_20211109\population_Linus_20211109.mat'); % once debug is complete, comment this line and enable the line above

run('sdndt_Sim_LIP_dPul_NDT_setting');


%%Make raster_data

if ~exist(OUTPUT_PATH_raster,'dir')
    mkdir(OUTPUT_PATH_raster);
end

%target_state = 6; % 6 - cue on , 4 - target acquisition

switch target_state
    case 6
        target_state_name = 'cueON';
    case 4
        target_state_name = 'GOsignal';
    otherwise
        fprintf('Invalid target_state value: %d\n', target_state);
        % You might want to handle the case when target_state is neither 6 nor 4
end


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
        
        % Check if the current block is the second or third block
%         if b == 1 || b == 2 || b == 3
%             % Continue to the next block if it's the second or third block
%             continue;
%         end
        
        % Get the number of trials for the current block
        num_block_trials = sum(block_trials);
        
        if num_block_trials > 0
            % Initialize cell arrays
            raster_labels.trial_type = cell(1, num_block_trials);
            raster_labels.sideSelected = cell(1, num_block_trials);
            raster_labels.trial_type_side = cell(1, num_block_trials);
            raster_labels.stimulus_position_X_coordinate = cell(1, num_block_trials);
            raster_labels.stimulus_position_Y_coordinate = cell(1, num_block_trials);
            raster_labels.perturbation = cell(1, num_block_trials);
            raster_labels.block = cell(1, num_block_trials);
            raster_labels.run = cell(1, num_block_trials);
            
            
            
            % Initialize numeric array for raster_data
            raster_data = NaN(num_block_trials, columnsNumberBasedOnWindow);
            
            %blocks_present = []; % Track the blocks present in the trials
            
            
            % Loop over trials for the current block
            for t = find(block_trials) % t = 1:num_trial
                

                if population(u).trial(t).success == 0 % Check if the trial should be excluded based on success value
                    fprintf('Trial %d in unit %d excluded from analysis (success = 0).\n', t, u);
                    continue;  % Skip the rest of the loop and move to the next trial
                end
                % choiceVariable = [population(45).trial(:).success]; valueToCount = true; howManySuccessTrials = sum(choiceVariable == valueToCount);
                %blocks_present = unique([blocks_present, population(u).trial(t).block]); % Add the block information to the blocks_present array
                
                
                % Check which block the trial belongs to
                current_block = population(u).trial(t).block;
                
                %%% raster_data
                state_index = find(population(u).trial(t).states == target_state);
                if isempty(state_index)
                    fprintf('State %d not found. Excluding from analysis.\n', target_state);
                else
                    onsetTimeOfRequiredStage(t) = population(u).trial(t).states_onset(state_index);
                    % Use the index to retrieve the corresponding value from 'states_onset'
                    %raster_data(t, :) = histcounts(population(u).trial(t).arrival_times, (onsetTimeOfRequiredStage(t) - settings.windowAroundEvent):0.001:(onsetTimeOfRequiredStage(t) + settings.windowAroundEvent));
                    if current_block == 1
                        raster_data(t, :) = histcounts(population(u).trial(t).arrival_times, (onsetTimeOfRequiredStage(t) - settings.windowAroundEvent):0.001:(onsetTimeOfRequiredStage(t) + settings.windowAroundEvent));
                    elseif current_block == 2
                        raster_data(t, :) = histcounts(population(u).trial(t).arrival_times, (onsetTimeOfRequiredStage(t) - settings.windowAroundEvent):0.001:(onsetTimeOfRequiredStage(t) + settings.windowAroundEvent));
                    end
                end
                
                
                % how many successful trials were made for each unit individually (as there are units with different numbers of record blocks)
                if population(u).trial(t).success == 1
                    num_of_success_trials_per_unit(u) = num_of_success_trials_per_unit(u) + 1;
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
                
                X_coordinate(1, t) = real(population(u).trial(t).tar_pos);
                Y_coordinate(1, t) = imag(population(u).trial(t).tar_pos);
                raster_labels.stimulus_position_X_coordinate{1, t} = X_coordinate(1, t);
                raster_labels.stimulus_position_Y_coordinate{1, t} = Y_coordinate(1, t);
                
                raster_labels.perturbation{1, t} = population(u).trial(t).perturbation;
                raster_labels.block{1, t} = population(u).trial(t).block;
                raster_labels.run{1, t} = population(u).trial(t).run;
               
                
                 
            end
            
            
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
            filename = [OUTPUT_PATH_raster population(u).unit_ID '_raster_' raster_site_info.target '_trial_state_' target_state_name '_block_' num2str(b) '.mat'];
            save(filename, 'raster_data', 'raster_labels', 'raster_site_info');
            
        end
        
    end
    % Accumulate all brain structure names in the list
    all_brain_structures = [all_brain_structures, raster_site_info.target];
end



% fprintf('%d units out of %d for the file %s not taken in the analysis.\n', units_skipped, num_units, mat_filename);

brain_structures_present = unique(all_brain_structures); % Get unique brain structure names
all_brain_structures = strjoin(brain_structures_present, '_'); % format suitable for file names



end
