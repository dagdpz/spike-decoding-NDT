function sdndt_Sim_LIP_dPul_NDT_spiking_activity(monkey, injection, typeOfDecoding)

% The code converts the received raster data into binned data and then performs decoding.

% HOW TO CALL THE FUNCTION?
% Within a session:
% sdndt_Sim_LIP_dPul_NDT_spiking_activity('Bacchus', '1', 'each_unit_separately');
% sdndt_Sim_LIP_dPul_NDT_spiking_activity('Bacchus', '1', 'average_within_session');

% Across sessions:
% sdndt_Sim_LIP_dPul_NDT_spiking_activity('Bacchus', '1', 'average_across_session');
% sdndt_Sim_LIP_dPul_NDT_spiking_activity('Bacchus', '1', 'merged_files_across_sessions');





%% MODIFIABLE PARAMETERS
% injection: '0' - control sessions, '1' - inactivation sessions (for inactivation experiment),
%            '2' - for functional interaction experiment

% typeOfDecoding: 'each_unit_separately', 'merged_files_across_sessions'
% for 'merged_files_across_sessions' amountOfCurves:  'combine_all_sessions', 'sessions_separately'
% target_brain_structure = 'dPul_L', 'LIP_L', 'LIP_R',
%                  if both 'LIP_L_dPul_L' (functional interaction experiment) or 'LIP_L_LIP_R' (inactivation experiment)
% labels_to_use: 'instr_R_instr_L'
%                'choice_R_choice_L'
%                'instr_R_choice_R'
%                'instr_L_choice_L'
% listOfRequiredFiles - variable name, which contains the list of necessary files for decoding:
%                       'firstBlockFiles', 'secondBlockFiles', 'thirdBlockFiles',
%                       'fourthBlockFiles', 'fifthBlockFiles', 'sixthBlockFiles',
%                       'allBlocksFiles', 'overlapBlocksFiles',
%                       'overlapBlocksFiles_BeforeInjection', 'overlapBlocksFiles_AfterInjection'
%                       'overlapBlocksFiles_BeforeInjection_3_4', 'overlapBlocksFiles_AfterInjection_3_4'
%                       'overlap_thirdBlockFiles', 'overlap_fourthBlockFiles'
%                       'allBlocksFiles_BeforeInjection', 'allBlocksFiles_AfterInjection'


%% PARAMETERS that RUN AUTOMATICALLY (are in the internal function)
% typeOfSessions: 'all' - all sessions,
%                 'right' - right dPul injection (7 sessions) for mokey L
%                 'left' - left dPul injection (3 sessions) for mokey L
% target_state: 6 - cue on , 4 - target acquisition


%%
% Start timing the execution
startTime = tic;



%% Define the list of required files

if strcmp(monkey, 'Bacchus')
    listOfRequiredFiles = {'overlapBlocksFiles_BeforeInjection', 'overlapBlocksFiles_AfterInjection'};
elseif strcmp(monkey, 'Linus')
    listOfRequiredFiles = {'overlapBlocksFiles_BeforeInjection_3_4', 'overlapBlocksFiles_AfterInjection_3_4'};
end

% listOfRequiredFiles = {%'firstBlockFiles', 'secondBlockFiles', ...
%     'thirdBlockFiles', 'fourthBlockFiles', ...
%     'fifthBlockFiles', 'sixthBlockFiles', ...
%  'overlapBlocksFiles_BeforeInjection',          'overlapBlocksFiles_AfterInjection' %, ...
%     'overlapBlocksFiles_BeforeInjection_3_4',  'overlapBlocksFiles_AfterInjection_3_4'%, ...
%     'allBlocksFiles_BeforeInjection', 'allBlocksFiles_AfterInjection'
%     };  %'allBlocksFiles', 'overlapBlocksFiles', ...

%% Define typeOfSessions
% Calculate typeOfSessions based on the injection parameter
if strcmp(injection, '1')
    if strcmp(monkey, 'Linus')
        % typeOfSessions = {'right'};
        typeOfSessions = {'right'} %, 'left', 'all'}; % For control and injection experiments
    elseif strcmp(monkey, 'Bacchus')
        typeOfSessions = {'right'};
    end
elseif strcmp(injection, '0') || strcmp(injection, '2')
    typeOfSessions = {''}; % For the functional interaction experiment
else
    error('Invalid injection value. Use ''0'', ''1'', or ''2''.');
end


% Calculate the number of session types
numTypesOfSessions = numel(typeOfSessions);

%% Define approach parameters
% approach_to_use = {'all_approach', 'overlap_approach'};
if any(contains(listOfRequiredFiles, {'overlapBlocksFiles_BeforeInjection_3_4', 'overlapBlocksFiles_AfterInjection_3_4', 'overlapBlocksFiles_BeforeInjection', 'overlapBlocksFiles_AfterInjection', 'overlapBlocksFiles'}))
    approach_to_use = {'overlap_approach'};
elseif any(contains(listOfRequiredFiles, {'allBlocksFiles_BeforeInjection', 'allBlocksFiles_AfterInjection', 'allBlocksFiles'}))
    approach_to_use = {'all_approach'};
else
    approach_to_use = {'all_approach', 'overlap_approach'};
end

%% Define target_state parameters
targetParams = struct();

% Define target_state parameters
targetParams.cueON = 'cueON';
targetParams.GOSignal = 'GOsignal';

% Calculate the number of target state parameters (number of fields)
numFieldNames = numel(fieldnames(targetParams));

%% Define labels_to_use as a cell array containing both values
labels_to_use = {'instr_R_instr_L', 'choice_R_choice_L'};
% labels_to_use = {'instr_R_instr_L'};

%% Define valid combinations of injection and target_brain_structure
if strcmp(injection, '1') || strcmp(injection, '0')
    combinations_inj_and_target_brain_structure = struct('injection', {injection, injection}, 'target_brain_structure', {'LIP_R', 'LIP_L'});
    %combinations_inj_and_target_brain_structure = struct('injection', { injection}, 'target_brain_structure', {'LIP_R'});
    
elseif strcmp(injection, '2')
    combinations_inj_and_target_brain_structure = struct('injection', {injection, injection}, 'target_brain_structure', {'dPul_L', 'LIP_L'});
else
    error('Invalid injection value. Use ''0'', ''1'', or ''2''.');
end


%%
h = waitbar(0, 'Processing...'); % Initialize progress bar

numCombinations = numel(combinations_inj_and_target_brain_structure);
numLabels = numel(labels_to_use);
numApproach = numel(approach_to_use);

numTypeBlocks = numel(listOfRequiredFiles)/2;
listOfRequiredFiles_char = char(listOfRequiredFiles{:});

% Calculate total number of iterations
totalIterations = 0; % Initialize progress


%% Check if decoding should be performed for each session separately

if strcmp(typeOfDecoding, 'each_unit_separately') || strcmp(typeOfDecoding, 'average_within_session')
    datesForSessions = {};
    if strcmp(injection, '1')
        for type = 1:numel(typeOfSessions)
            % Get the dates for the corresponding injection and session types
            datesForSessions{end+1} = filelist_of_days_from_Simultaneous_dPul_PPC_recordings(monkey, injection, typeOfSessions{type});
        end
    elseif strcmp(injection, '0') || strcmp(injection, '2')
        datesForSessions = filelist_of_days_from_Simultaneous_dPul_PPC_recordings(monkey, injection, typeOfSessions);
    end
    % Calculate total number of iterations based on datesForSessions
    for j = 1:numTypesOfSessions
        totalIterations = totalIterations + numel(datesForSessions{j});
    end
else % strcmp(typeOfDecoding, 'merged_files_across_sessions')
    datesForSessions = {''};
    totalIterations = 1; % For merged_files_across_sessions, only one iteration per combination
end


%% Counting the number of iterations (how many times the loop will be run)

totalIterations = totalIterations * numApproach * numTypeBlocks * numCombinations * numLabels * numFieldNames * numTypesOfSessions;
overallProgress = 0; % Initialize progress


%% Loop through each combination of injection, target_brain_structure, and label

for file_index = 1:numTypeBlocks  % Loop through each file in listOfRequiredFiles % Loop through each file in listOfRequiredFiles
    % current_file = listOfRequiredFiles{file_index}; % Get the current file
    
    % Check the condition for monkey and current_file
    if strcmp(monkey, 'Bacchus') && (strcmp(listOfRequiredFiles_char, 'overlapBlocksFiles_BeforeInjection_3_4') || strcmp(listOfRequiredFiles_char, 'overlapBlocksFiles_AfterInjection_3_4'))
        fprintf('Skipping processing for %s with file %s.\n', monkey, listOfRequiredFiles_char);
        continue; % Skip this iteration and go to the next file
    end
    
    
    % Skip processing the second block if the injection is 0 or 1
    if ~((strcmp(injection, '0') || strcmp(injection, '1')) && ...
            (strcmp(listOfRequiredFiles_char, 'secondBlockFiles') || strcmp(listOfRequiredFiles_char, 'allBlocksFiles') || strcmp(listOfRequiredFiles_char , 'overlapBlocksFiles')))
        % ~(strcmp(current_file, 'secondBlockFiles') && (strcmp(injection, '0') || strcmp(injection, '1')))
        
        
        for comb_index = 1:numCombinations
            current_comb = combinations_inj_and_target_brain_structure(comb_index);
            current_injection = current_comb.injection;
            current_target_brain_structure = current_comb.target_brain_structure;
            
            
            % Loop through each label in approach_to_use
            for approach_index = 1:numApproach
                current_approach = approach_to_use{approach_index};
                
                % Loop through each label in labels_to_use
                for label_index = 1:numLabels
                    current_label = labels_to_use{label_index};
                    
                    
                    
                    % Check if decoding should be performed for each session separately
                    %if strcmp(typeOfDecoding, 'merged_files_across_sessions')
                    datesForSessions = {}; % Initialize datesForSessions as an empty cell array
                    if strcmp(injection, '1')
                        for type = 1:numel(typeOfSessions)
                            % Get the dates for the corresponding injection and session types
                            datesForSessions{end+1} = filelist_of_days_from_Simultaneous_dPul_PPC_recordings(monkey, injection, typeOfSessions{type});
                        end
                    elseif  strcmp(injection, '0') || strcmp(injection, '2')
                        datesForSessions = filelist_of_days_from_Simultaneous_dPul_PPC_recordings(monkey, injection, typeOfSessions);
                    end
                    %                      else % strcmp(typeOfDecoding, 'averages_across_sessions')
                    %                          datesForSessions = {''}; % Set a default value if decoding across sessions
                    %                      end
                    
                    
                    % Loop through each target_state parameter
                    fieldNames = fieldnames(targetParams);
                    numFieldNames = numel(fieldNames);
                    numTypesOfSessions = numel(typeOfSessions);
                    
                    for i = 1:numFieldNames
                        target_state_name = fieldNames{i};
                        target_state = targetParams.(target_state_name);
                        
                        for j = 1:numTypesOfSessions
                            % Call the main decoding function based on dateOfRecording
                            
                            current_set_of_date = datesForSessions{j}; % Get the corresponding set of dates !!!!!
                            current_type_of_session = typeOfSessions{j}; % Get the corresponding type of session !!!!!
                            
                            
                            if strcmp(typeOfDecoding, 'each_unit_separately') || strcmp(typeOfDecoding, 'average_within_session')
                                
                                current_set_of_date = datesForSessions{j}; % Get the corresponding set of dates !!!!!
                                % totalIterations = totalIterations + numel(current_set_of_date) * numLabels * numApproach * numFieldNames;
                                
                                
                                for numDays = 1:numel(current_set_of_date)
                                    current_date = current_set_of_date{numDays};
                                    
                                    % Call the internal decoding function for each day
                                    sdndt_Sim_LIP_dPul_NDT_spiking_activity_internal(monkey, current_injection, current_type_of_session, typeOfDecoding, current_date, current_target_brain_structure, target_state, current_label, current_approach, listOfRequiredFiles_char); % typeOfSessions{j}
                                    
                                    
                                    % Update progress for each iteration
                                    overallProgress = overallProgress + 1;
                                    waitbar(overallProgress / totalIterations, h, sprintf('Processing... %.2f%%', overallProgress / totalIterations * 100));
                                    
                                end
                                
                                
                            elseif strcmp(typeOfDecoding, 'merged_files_across_sessions') || strcmp(typeOfDecoding, 'average_across_session')
                                current_date = [];
                                % Call the internal decoding function only once
                                sdndt_Sim_LIP_dPul_NDT_spiking_activity_internal(monkey, current_injection, current_type_of_session,  typeOfDecoding, current_set_of_date, current_target_brain_structure, target_state, current_label, current_approach, listOfRequiredFiles_char);
                                
                                
                                % Update progress for each iteration
                                overallProgress = overallProgress + 1;
                                waitbar(overallProgress / totalIterations, h, sprintf('Processing... %.2f%%', overallProgress / totalIterations * 100));
                                
                                
                            end % if strcmp(typeOfDecoding, 'each_unit_separately')
                            
                        end % for j = 1:numTypesOfSessions
                    end % for i = 1:numFieldNames
                end % for label_index = 1:numLabels
            end % for approach_index = 1:numApproach
        end % for comb_index = 1:numCombinations
        
    end %  if ~(strcmp(current_file, 'secondBlockFiles')
end % file_index = 1:numFiles



% After all cycles are finished, close the progress bar
close(h);

% After all cycles are finished, close the existing figure
close(gcf); % Close the current figure


% Create a new figure window
figure;

% Display the green image
subplot(2, 1, 1); % Create subplot 1
green_image = zeros(100, 100, 3); % Create a green image (100x100 pixels)
green_image(:,:,2) = 1; % Set the green channel to 1
imshow(green_image); % Display the green image
% Add the text "Done" in the center of the square
text_location_x = size(green_image, 2) / 2; % X coordinate of the center
text_location_y = size(green_image, 1) / 2; % Y coordinate of the center
text(text_location_x, text_location_y, 'Done!', 'Color', 'black', 'FontSize', 14, 'HorizontalAlignment', 'center');



% Display the elapsed time
subplot(2, 1, 2); % Create subplot 2
% End timing the execution
endTime = toc(startTime);
minutesElapsed = floor(endTime / 60); % Convert the elapsed time from seconds to minutes and hours
hoursElapsed = floor(minutesElapsed / 60);
remainingMinutes = mod(minutesElapsed, 60);
white_image = zeros(100, 500, 3); % Create a green image (100x100 pixels)
white_image(:, :, 1) = 1; % Set red channel to 1
white_image(:, :, 2) = 1; % Set green channel to 1
white_image(:, :, 3) = 1; % Set blue channel to 1
imshow(white_image);
text_location_x = size(white_image, 2) / 2; % X coordinate of the center
text_location_y = size(white_image, 1) / 2; % Y coordinate of the center
text(text_location_x, text_location_y, sprintf('Code execution time: %d minutes (%d hours %d minutes)', minutesElapsed, hoursElapsed, remainingMinutes), ...
    'Color', 'black', 'FontSize', 12, 'HorizontalAlignment', 'center');

% Optional: Add a pause to keep the image displayed for some time
pause(5); % Display the image for 5 seconds (adjust as needed)

end





function sdndt_Sim_LIP_dPul_NDT_spiking_activity_internal(monkey, injection, typeOfSessions, typeOfDecoding, dateOfRecording, target_brain_structure, target_state, given_labels_to_use, given_approach, givenListOfRequiredFiles)
% ADDITIONAL SETTINGS
% The same as for sdndt_Sim_LIP_dPul_NDT_decoding function, except :
% target_state: 6 - cue on , 4 - target acquisition


%% Checking for mistakes while calling the function

if contains(injection, '0') && (contains(givenListOfRequiredFiles, 'overlapBlocksFiles_AfterInjection') || contains(givenListOfRequiredFiles, 'overlapBlocksFiles_BeforeInjection'))
    error("Injection data is not available for mode '0'.");
end


if contains(injection, '0') && contains(target_brain_structure, 'LIP_R') % Check if injection data is requested for mode '0'
    error("Control data is not available for 'LIP_R'.");
end

if contains(injection, '1') && contains(target_brain_structure, 'dPul_L') % Check if injection data is requested for 'dPul_L'
    error("Injection data is not available for 'dPul_L'.");
    
end

if ~ismember(injection, {'0', '1'}) % Check if injection is either '0' or '1'
    error('Data must be either ''0'' (control) or ''1'' (injection).');
end

% if ~(target_state == 'cueON' || target_state == 'GOsignal') % Check if target_state is either 6 or 4
%     error('Target state must be either 6 (cue on) or 4 (target acquisition).');
% end

% Check if labels_to_use is one of the allowed values
allowed_labels = {'instr_R_instr_L', 'choice_R_choice_L', 'instr_R_choice_R', 'instr_L_choice_L'};
if ~ismember(given_labels_to_use, allowed_labels)
    error('Invalid labels to use. Use ''instr_R_instr_L'', ''choice_R_choice_L'', ''instr_R_choice_R'' or ''instr_L_choice_L''');
end

% Check if listOfRequiredFiles contains the required fields
allowed_blocks = {'firstBlockFiles', 'secondBlockFiles', 'thirdBlockFiles', ...
    'fourthBlockFiles', 'fifthBlockFiles', 'sixthBlockFiles', ...
    'allBlocksFiles', 'overlapBlocksFiles',  ...
    'overlapBlocksFiles_BeforeInjection', 'overlapBlocksFiles_AfterInjection', ...
    'overlapBlocksFiles_BeforeInjection_3_4', 'overlapBlocksFiles_AfterInjection_3_4', ...
    'allBlocksFiles_BeforeInjection', 'allBlocksFiles_AfterInjection'};
if ~ismember(givenListOfRequiredFiles, allowed_blocks) % Check if the provided block name is in the list of allowed blocks
    error(['The specified block name is not correct. ', ...
        'You have to use one of the following: ', strjoin(allowed_blocks, ', ')]);
else
    %disp('The specified block name is correct.');
end

%% Path

%% Path
% Call the function to get the dates
allDateOfRecording = filelist_of_days_from_Simultaneous_dPul_PPC_recordings(monkey, injection, typeOfSessions);


% Call the settings function with the chosen set
[base_path, ~, OUTPUT_PATH_raster, OUTPUT_PATH_binned, monkey_prefix, settings] = sdndt_Sim_LIP_dPul_NDT_settings(monkey, injection, typeOfSessions);

%% find grouping_folder

% Initialize block_grouping_folder and block_grouping_folder_for_saving
block_grouping_folder = '';
block_grouping_folder_for_saving = '';

% Set the block grouping folder based on the approach
if strcmp(given_approach, 'all_approach')
    % For 'all_approach', set the block grouping folder prefix to 'All_'
    block_grouping_folder_prefix = 'All_';
elseif strcmp(given_approach, 'overlap_approach')
    % For 'overlap_approach', set the block grouping folder prefix to 'Overlap_'
    block_grouping_folder_prefix = 'Overlap_';
else
    % Handle the case when the approach is unknown
    error('Unknown approach. Please use either ''all_approach'' or ''overlap_approach''.');
end



% Initialize an array of structures to store the results
grouping_folder = struct('block_grouping_folder', {}, 'block_grouping_folder_saving', {}, 'num_block_suffix', {});

num_block = {};  % Initialize as an empty cell array

for s = 1:size(givenListOfRequiredFiles, 1)
    
    currentFile = strtrim(givenListOfRequiredFiles(s, :));  % Extract and trim the current row
    
    
    % Extract the block number suffix from givenListOfRequiredFiles
    if  strcmp(currentFile, 'overlapBlocksFiles_BeforeInjection')
        
        if strcmp(typeOfDecoding, 'each_unit_separately') || strcmp(typeOfDecoding, 'average_within_session')
            block_grouping_folder_saving = '';
            block_grouping_folder = 'Overlap_blocks_BeforeInjection';
            num_block_suffix = 'block_1';
        elseif strcmp(typeOfDecoding, 'merged_files_across_sessions') || strcmp(typeOfDecoding, 'average_across_session')
            block_grouping_folder_saving = 'overlapBlocksFilesAcrossSessions_BeforeInjection';
            block_grouping_folder = 'Overlap_blocks_BeforeInjection';
            num_block_suffix = 'block_1';
        end
        
    elseif strcmp(currentFile, 'overlapBlocksFiles_AfterInjection')
        
        if strcmp(typeOfDecoding, 'each_unit_separately') || strcmp(typeOfDecoding, 'average_within_session')
            block_grouping_folder_saving = '';
            block_grouping_folder = 'Overlap_blocks_AfterInjection';
            num_block_suffix = 'block_3_block_4';
        elseif strcmp(typeOfDecoding, 'merged_files_across_sessions') || strcmp(typeOfDecoding, 'average_across_session')
            block_grouping_folder_saving = 'overlapBlocksFilesAcrossSessions_AfterInjection';
            block_grouping_folder = 'Overlap_blocks_AfterInjection';
            num_block_suffix = 'block_3_block_4';
        end
        
    elseif strcmp(currentFile, 'overlapBlocksFiles_BeforeInjection_3_4')
        
        if strcmp(typeOfDecoding, 'each_unit_separately') || strcmp(typeOfDecoding, 'average_within_session')
            block_grouping_folder_saving = '';
            block_grouping_folder = 'Overlap_blocks_BeforeInjection_3_4';
            num_block_suffix = 'block_1';
        elseif strcmp(typeOfDecoding, 'merged_files_across_sessions') || strcmp(typeOfDecoding, 'average_across_session')
            block_grouping_folder_saving = 'overlapBlocksFilesAcrossSessions_BeforeInjection_3_4';
            block_grouping_folder = 'Overlap_blocks_BeforeInjection_3_4';
            num_block_suffix = 'block_1';
        end
        
    elseif strcmp(currentFile, 'overlapBlocksFiles_AfterInjection_3_4')
        
        if strcmp(typeOfDecoding, 'each_unit_separately') || strcmp(typeOfDecoding, 'average_within_session')
            block_grouping_folder_saving = '';
            block_grouping_folder = 'Overlap_blocks_AfterInjection_3_4';
            num_block_suffix = 'block_3_block_4';
        elseif strcmp(typeOfDecoding, 'merged_files_across_sessions') || strcmp(typeOfDecoding, 'average_across_session')
            block_grouping_folder_saving = 'overlapBlocksFilesAcrossSessions_AfterInjection_3_4';
            block_grouping_folder = 'Overlap_blocks_AfterInjection_3_4';
            num_block_suffix = 'block_3_block_4';
        end
        
    elseif strcmp(currentFile, 'allBlocksFiles_BeforeInjection')
        block_grouping_folder = 'All_blocks_BeforeInjection';
    elseif strcmp(currentFile, 'allBlocksFiles_AfterInjection')
        block_grouping_folder = 'All_blocks_AfterInjection';
    else
        error('Unknown value for givenListOfRequiredFiles.');
    end
    
    
    
    
    % Save the results in the structure array
    grouping_folder(s).block_grouping_folder = block_grouping_folder;
    grouping_folder(s).block_grouping_folder_saving = block_grouping_folder_saving;
    grouping_folder(s).num_block_suffix = num_block_suffix;
    
    
    % Construct num_block
    if isempty(grouping_folder(s).num_block_suffix)
        num_block{s} = '';  % Use curly braces for cell array assignment
    elseif ~isempty(grouping_folder(s).num_block_suffix)
        num_block{s} = num_block_suffix;
    else
        num_block{s} = sprintf('block_%s', num_block_suffix); % For specific block files, construct num_block
    end
    
    
end



% Preprocess given_labels_to_use
given_labels_to_use_split = strsplit(given_labels_to_use, '_');
combinedLabel = combine_label_segments(given_labels_to_use_split);



%%
cvSplitFolder_to_save = 'Spiking_activity';

% Create a combined folder name by comparing parts
parts_1 = strsplit(grouping_folder(1).block_grouping_folder, '_');
parts_2 = strsplit(grouping_folder(2).block_grouping_folder, '_');

common_parts = intersect(parts_1, parts_2);
diff_parts_1 = setdiff(parts_1, common_parts);
diff_parts_2 = setdiff(parts_2, common_parts);

% Add common parts in their original order
combined_folder_name_parts = {};
for i = 1:length(parts_1)
    if ismember(parts_1{i}, common_parts)
        combined_folder_name_parts{end+1} = parts_1{i};
    end
end

%combined_folder_name = strjoin([common_parts, strcat(diff_parts_1, '_and_', diff_parts_2)], '_');
combined_folder_name_parts = [combined_folder_name_parts, strcat(diff_parts_1, '_and_', diff_parts_2)]; % Add the different parts with 'and' in between
combined_folder_name = strjoin(combined_folder_name_parts, '_'); % Construct the combined folder name



if strcmp(typeOfDecoding, 'each_unit_separately') || strcmp(typeOfDecoding, 'average_within_session')
    
    % create output folder
    typeOfDecoding_monkey = [monkey_prefix dateOfRecording];
    
    OUTPUT_PATH_Spiking_activity_data_for_saving = fullfile(OUTPUT_PATH_binned, typeOfDecoding_monkey,  cvSplitFolder_to_save, combined_folder_name);
    % Check if cvSplitFolder_to_save folder exists, if not, create it
    if ~exist(OUTPUT_PATH_Spiking_activity_data_for_saving, 'dir')
        mkdir(OUTPUT_PATH_Spiking_activity_data_for_saving);
    end
    
    %     [dateOfRecording, target_brain_structure, target_state, combinedLabel, data_for_plotting_averages, settings, OUTPUT_PATH_binned_data_for_saving, numOfData] = collectingAveragesAcrossSessions(monkey, injection, typeOfSessions, dateOfRecording, target_brain_structure, target_state, combinedLabel, num_block, OUTPUT_PATH_binned_data_for_saving, block_grouping_folder);
    %     plotingAveragesAcrossSessions(dateOfRecording, target_brain_structure, target_state, combinedLabel, data_for_plotting_averages, settings, OUTPUT_PATH_binned_data_for_saving, numOfData, curves_per_session)
    
    
    % Collecting data before injection
    [dateOfRecording, target_brain_structure, target_state, data_for_plotting_Spiking_activity_before, ind_to_plot] = collectingBinnedData(monkey, injection, typeOfSessions, typeOfDecoding, dateOfRecording, target_brain_structure, target_state, combinedLabel, num_block{1}, OUTPUT_PATH_Spiking_activity_data_for_saving, strtrim(givenListOfRequiredFiles(1, :)), grouping_folder(1).block_grouping_folder);
    
    % Collecting data after injection
    [~, ~, ~, data_for_plotting_Spiking_activity_after, ~] = collectingBinnedData(monkey, injection, typeOfSessions, typeOfDecoding, dateOfRecording, target_brain_structure, target_state, combinedLabel, num_block{2}, OUTPUT_PATH_Spiking_activity_data_for_saving, strtrim(givenListOfRequiredFiles(2, :)), grouping_folder(2).block_grouping_folder);
    
    % Plotting both sets of data on the same figure
    plotingCombinedSpikingActivity(typeOfSessions,  typeOfDecoding, dateOfRecording, target_brain_structure, target_state, combinedLabel, data_for_plotting_Spiking_activity_before, data_for_plotting_Spiking_activity_after, settings, OUTPUT_PATH_Spiking_activity_data_for_saving, ind_to_plot);
    
    
    
    
elseif  strcmp(typeOfDecoding, 'merged_files_across_sessions') || strcmp(typeOfDecoding, 'average_across_session')
    
    % create output folder
    typeOfDecoding_monkey = [monkey_prefix typeOfDecoding];
    sorting_folder  = ['two_group_combination'];
    OUTPUT_PATH_Spiking_activity_data_for_saving = fullfile(OUTPUT_PATH_binned, typeOfDecoding_monkey, sorting_folder, cvSplitFolder_to_save, combined_folder_name);
    % Check if cvSplitFolder_to_save folder exists, if not, create it
    if ~exist(OUTPUT_PATH_Spiking_activity_data_for_saving, 'dir')
        mkdir(OUTPUT_PATH_Spiking_activity_data_for_saving);
    end
    
    
    % Collecting data before injection
    [dateOfRecording, target_brain_structure, target_state, data_for_plotting_Spiking_activity_before, ind_to_plot] = collectingBinnedData(monkey, injection, typeOfSessions, typeOfDecoding, dateOfRecording, target_brain_structure, target_state, combinedLabel, num_block{1}, OUTPUT_PATH_Spiking_activity_data_for_saving, strtrim(givenListOfRequiredFiles(1, :)), grouping_folder(1));
    
    % Collecting data after injection
    [~, ~, ~, data_for_plotting_Spiking_activity_after, ~] = collectingBinnedData(monkey, injection, typeOfSessions, typeOfDecoding, dateOfRecording, target_brain_structure, target_state, combinedLabel, num_block{2}, OUTPUT_PATH_Spiking_activity_data_for_saving, strtrim(givenListOfRequiredFiles(2, :)), grouping_folder(2));
    
    % Plotting both sets of data on the same figure
    plotingCombinedSpikingActivity(typeOfSessions, typeOfDecoding, dateOfRecording, target_brain_structure, target_state, combinedLabel, data_for_plotting_Spiking_activity_before, data_for_plotting_Spiking_activity_after, settings, OUTPUT_PATH_Spiking_activity_data_for_saving, ind_to_plot);
    
end




end






function combinedLabel = combine_label_segments(labelSegments)
% Combine segments 1 and 2, and segments 3 and 4
combinedSegments = {strjoin(labelSegments(1:2), '_'), strjoin(labelSegments(3:4), '_')};
combinedLabel = strjoin(combinedSegments, ' '); % Join the combined segments with a space
end




function [dateOfRecording, target_brain_structure, target_state, data_for_plotting_Spiking_activity, indices_centr] = collectingBinnedData(monkey, injection, typeOfSessions, typeOfDecoding, dateOfRecording, target_brain_structure, target_state, combinedLabel, num_block, OUTPUT_PATH_Spiking_activity_data_for_saving, givenListOfRequiredFiles, block_grouping_folder)
data_for_plotting_Spiking_activity = [];
indices_centr = [];
total_spike_counts_per_ms = [];

%% Path
% Call the function to get the dates
allDateOfRecording = filelist_of_days_from_Simultaneous_dPul_PPC_recordings(monkey, injection, typeOfSessions);


% Call the settings function with the chosen set
[base_path, INPUT_PATH, OUTPUT_PATH_raster, OUTPUT_PATH_binned, monkey_prefix, settings] = sdndt_Sim_LIP_dPul_NDT_settings(monkey, injection, typeOfSessions);




labels = strsplit(combinedLabel); % Split the string into individual labels
label_R = labels{1}; % 'instr_R'
label_L = labels{2}; % 'instr_L'


% Initialize decodingResultsFilePath
data_for_plotting_spiking_activity.decodingResultsFilePath = '';  % Initialize as an empty string

% Initialize cell arrays to store data across sessions
data_for_plotting_spiking_activity.session_info_combined = {};


if strcmp(typeOfDecoding, 'each_unit_separately')|| strcmp(typeOfDecoding, 'average_within_session')
    
    
    current_dateOfRecording_monkey = [monkey_prefix dateOfRecording];
    OUTPUT_PATH_binned_data = fullfile(OUTPUT_PATH_binned, current_dateOfRecording_monkey, block_grouping_folder, settings.num_cv_splits_approach_folder);
    
    % List the contents of the All_blocks_BeforeInjection folder
    cvSplitsFolders = dir(OUTPUT_PATH_binned_data);
    
    % Filter out current directory '.' and parent directory '..'
    cvSplitsFolders = cvSplitsFolders(~ismember({cvSplitsFolders.name}, {'.', '..'}));
    
    % Extract numeric values from folder names
    values_outside_parentheses = zeros(1, numel(cvSplitsFolders));
    
    
    
    for idx = 1:numel(cvSplitsFolders)
        cvSplitFolderName = cvSplitsFolders(idx).name;
        if startsWith(cvSplitFolderName, 'num_cv_splits_')
            values_outside_parentheses(idx) = str2double(extractBetween(cvSplitFolderName, 'num_cv_splits_', '('));
        end
    end
    
    
    % Filter out zeros
    nonZeroValues = values_outside_parentheses(values_outside_parentheses > 0);
    
    % Sort non-zero values in ascending order
    [sorted_nonZeroValues, sorted_idx] = sort(nonZeroValues);
    
    % Get the corresponding indices in the original array
    sorted_idx = find(values_outside_parentheses > 0);

    %         % Sort folders based on values outside parentheses (in descending order)
    %         [~, sorted_idx] = sort(values_outside_parentheses, 'descend');
    
    % Iterate over sorted folders and check for the file
    data_for_plotting_spiking_activity.decodingResultsFilePath = '';
    session_num_cv_splits_Info = '';
    
    % Initialize a flag to check if the file is found
    fileFound = false;
    
    for idx = sorted_idx
        cvSplitFolderName = cvSplitsFolders(idx).name;
        cvSplitFolderPath = fullfile(OUTPUT_PATH_binned_data, cvSplitFolderName);
        
        % List the contents of the current folder
        decodingResultsFiles = dir(fullfile(cvSplitFolderPath, '*.mat'));
        
        % Check if the required file exists in this folder
        for fileIndex = 1:numel(decodingResultsFiles)
            data_for_plotting_spiking_activity.decodingResultsFilename = decodingResultsFiles(fileIndex).name;
            
            
            % Filtering unnecessary files
            if contains(data_for_plotting_spiking_activity.decodingResultsFilename, '_smoothed') || contains(data_for_plotting_spiking_activity.decodingResultsFilename, '_DECODING_RESULTS')
                continue; % Skip files containing unnecessary substrings
            end
            
            
            if strcmp(num_block, 'block_3_block_4')
                num_block_cont = 'block_3';
            else
                num_block_cont = num_block;
                
            end
            
            
            % Check if the file name contains the desired target structure, state, and label
            if contains(data_for_plotting_spiking_activity.decodingResultsFilename, target_brain_structure) && ...
                    contains(data_for_plotting_spiking_activity.decodingResultsFilename, target_state) && ...
                    contains(data_for_plotting_spiking_activity.decodingResultsFilename, num_block_cont)
                % Construct the full path to the DECODING_RESULTS.mat file
                
                
                
                data_for_plotting_spiking_activity.decodingResultsFilePath = fullfile(cvSplitFolderPath, data_for_plotting_spiking_activity.decodingResultsFilename);
                
                % Now you have the path to the suitable DECODING_RESULTS.mat file
                % You can process or load this file as needed
                fileFound = true;  % Set flag to true
                
                % Extract data about session and num_cv_splits
                num_cv_splits = str2double(extractBetween(cvSplitFolderName, 'num_cv_splits_', '('));
                session_num_cv_splits_Info = sprintf('Session: %s, num_cv_splits: %d\n', dateOfRecording, num_cv_splits);
                
                
                break; % Exit the loop once the file is found
            end
            
        end
        
        if fileFound
            break; % Exit the loop if the file is found
        end
    end
    
    
    % Concatenate information about all sessions into a single string
    data_for_plotting_spiking_activity.session_info_combined{end+1} = [session_num_cv_splits_Info];
    
    
    
    
    % If no file was found in any folder, display error message
    if isempty(data_for_plotting_spiking_activity.decodingResultsFilePath)
        % disp('ERROR: No suitable decoding results file found.');
        disp(['No suitable decoding results file found for session: ', dateOfRecording]);
        return; % Move to the next iteration of the loop
    end
    %     else
    
    % Load the file
    loadedData = load(data_for_plotting_spiking_activity.decodingResultsFilePath);
    
    
    
    
    
    for g = 1:numel(loadedData.binned_data)
        
        % Get the current trial marks for this unit
        trial_labels = loadedData.binned_labels.trial_type_side{g};
        
        % Find the indices of trials corresponding to the label 'instr_R'
        label_R_indices = strcmp(trial_labels, label_R);
        sessionData_R{g} = loadedData.binned_data{g}(label_R_indices, :); % Save the data for the label ‘instr_R’
        
        % Find the indices of trials corresponding to the label ‘instr_L’
        label_L_indices = strcmp(trial_labels, label_L);
        sessionData_L{g} = loadedData.binned_data{g}(label_L_indices, :); %  Save the data for the label 'instr_L'
        
        
        % Get data for the current unit
        currentUnitData_R = sessionData_R{g};
        currentUnitData_L = sessionData_L{g};
        
        data_for_plotting_Spiking_activity.numTrials_R(g) = size(sessionData_R{g},1);
        data_for_plotting_Spiking_activity.numTrials_L(g) = size(sessionData_L{g},1);
        
        % Multiply the average values by the bin width to get the number of spikes
        spikeCounts_R = currentUnitData_R * settings.bin_width;
        spikeCounts_L = currentUnitData_L * settings.bin_width;
        
        % Sum the number of spikes across all bins for each trail
        numSpikes_perBin_R{g} = sum(spikeCounts_R, 1);
        numSpikes_perBin_L{g} = sum(spikeCounts_L, 1);
        
        
        % Calculate the number of trails for this unit
        num_trials_R = size(currentUnitData_R, 1);
        num_trials_L = size(currentUnitData_L, 1);
        
        % Spike count per second
        spikeRate_R{g} = (numSpikes_perBin_R{g} / num_trials_R) * (1000 / settings.bin_width);
        spikeRate_L{g} = (numSpikes_perBin_L{g} / num_trials_L) * (1000 / settings.bin_width);
        
        data_for_plotting_Spiking_activity.spikeRate_R = spikeRate_R;
        data_for_plotting_Spiking_activity.spikeRate_L = spikeRate_L;
        
        
        % Calculate the standard deviation of spikeRate
        stdSpikeRate_R{g} = std(spikeCounts_R);
        stdSpikeRate_L{g} = std(spikeCounts_L);
        
        data_for_plotting_Spiking_activity.stdSpikeRate_R = stdSpikeRate_R;
        data_for_plotting_Spiking_activity.stdSpikeRate_L = stdSpikeRate_L;
        
        
        % Find minimum and maximum values
        min_spikeRate_R(g) = min(spikeRate_R{g});
        max_spikeRate_R(g) = max(spikeRate_R{g});
        
        min_spikeRate_L(g) = min(spikeRate_L{g});
        max_spikeRate_L(g) = max(spikeRate_L{g});
        
        
    end
    
    % Convert cell array into a matrix for ease of calculations
    spikeRate_R_matrix = cell2mat(data_for_plotting_Spiking_activity.spikeRate_R');
    spikeRate_L_matrix = cell2mat(data_for_plotting_Spiking_activity.spikeRate_L');
    
    % Calculate the average value for each column
    data_for_plotting_Spiking_activity.average_spikeRate_R = mean(spikeRate_R_matrix, 1);
    data_for_plotting_Spiking_activity.average_spikeRate_L = mean(spikeRate_L_matrix, 1);
    
    
    % Calculation of the standard error of the mean (SEM) for each bin
    sem_spikeRate_R = std(spikeRate_R_matrix, 0, 1) / sqrt(size(spikeRate_R_matrix, 1));
    sem_spikeRate_L = std(spikeRate_L_matrix, 0, 1) / sqrt(size(spikeRate_L_matrix, 1));
    
    data_for_plotting_Spiking_activity.sem_spikeRate_R = sem_spikeRate_R;
    data_for_plotting_Spiking_activity.sem_spikeRate_L = sem_spikeRate_L;
    
    % Determination of minimum and maximum values between R and L
    min_spikeRate = min(min(min_spikeRate_R), min(min_spikeRate_L));
    max_spikeRate = max(max(max_spikeRate_R), max(max_spikeRate_L));
    
    data_for_plotting_Spiking_activity.min_spikeRate = min_spikeRate;
    data_for_plotting_Spiking_activity.max_spikeRate = max_spikeRate;
    
    
    data_for_plotting_Spiking_activity.unit_ID = loadedData.binned_site_info.unit_ID;
    
    %% Number of units
    data_for_plotting_Spiking_activity.NumOfUnits_per_session = size(loadedData.binned_site_info.unit_ID,2);
    
    %% save
    % Creating a folder path for saving data
    if ~exist(OUTPUT_PATH_Spiking_activity_data_for_saving, 'dir')
        mkdir(OUTPUT_PATH_Spiking_activity_data_for_saving); % Creating a folder if it does not exist
    end
    
    % Generating a file name for saving
    save_filename = [OUTPUT_PATH_Spiking_activity_data_for_saving '/spiking_activity_data_for_' dateOfRecording '_' target_brain_structure '_' target_state '_' num_block '_' combinedLabel '.mat'];
    
    % Saving variables to a mat file
    save(save_filename, 'data_for_plotting_Spiking_activity');
    
    
    
    
    
    
    
elseif  strcmp(typeOfDecoding, 'merged_files_across_sessions') || strcmp(typeOfDecoding, 'average_across_session')
    
    data_for_plotting_spiking_activity.decodingResultsFilePath = {};
    data_for_plotting_spiking_activity.decodingResultsFilename = {};
    data_for_plotting_spiking_activity.session_info_combined = {};
    
    
    for numOfData = 1:numel(dateOfRecording) % for each_unit_separately - one day, otherwise - set
        
        current_dateOfRecording = dateOfRecording{numOfData};
        current_dateOfRecording_monkey = [monkey_prefix current_dateOfRecording];
        OUTPUT_PATH_binned_data = fullfile(OUTPUT_PATH_binned, current_dateOfRecording_monkey, block_grouping_folder.block_grouping_folder, settings.num_cv_splits_approach_folder);
        
        % List the contents of the All_blocks_BeforeInjection folder
        cvSplitsFolders = dir(OUTPUT_PATH_binned_data);
        
        % Filter out current directory '.' and parent directory '..'
        cvSplitsFolders = cvSplitsFolders(~ismember({cvSplitsFolders.name}, {'.', '..'}));
        
        % Extract numeric values from folder names
        values_outside_parentheses = zeros(1, numel(cvSplitsFolders));
        
        
        
        for idx = 1:numel(cvSplitsFolders)
            cvSplitFolderName = cvSplitsFolders(idx).name;
            if startsWith(cvSplitFolderName, 'num_cv_splits_')
                values_outside_parentheses(idx) = str2double(extractBetween(cvSplitFolderName, 'num_cv_splits_', '('));
            end
        end
        
        
        % Filter out zeros
        nonZeroValues = values_outside_parentheses(values_outside_parentheses > 0);
        
        % Sort non-zero values in ascending order
        [sorted_nonZeroValues, sorted_idx] = sort(nonZeroValues);
        
        % Get the corresponding indices in the original array
        sorted_idx = find(values_outside_parentheses > 0);
       
        
        % Iterate over sorted folders and check for the file
        session_num_cv_splits_Info = '';
        
        % Initialize a flag to check if the file is found
        fileFound = false;
        
        for idx = sorted_idx
            cvSplitFolderName = cvSplitsFolders(idx).name;
            cvSplitFolderPath = fullfile(OUTPUT_PATH_binned_data, cvSplitFolderName);
            
            % List the contents of the current folder
            decodingResultsFiles = dir(fullfile(cvSplitFolderPath, '*.mat'));
            
            % Check if the required file exists in this folder
            for fileIndex = 1:numel(decodingResultsFiles)
                tempFilename = decodingResultsFiles(fileIndex).name;
                
                
                
                % Filtering unnecessary files
                if contains(tempFilename, '_smoothed') || contains(tempFilename, '_DECODING_RESULTS')
                    continue; % Skip files containing unnecessary substrings
                end
                
                if strcmp(num_block, 'block_3_block_4')
                    num_block_cont = 'block_3';
                else
                    num_block_cont = num_block;
                end
                
                % Check if the file name contains the desired target structure, state, and label
                if contains(tempFilename, target_brain_structure) && ...
                        contains(tempFilename, target_state) && ...
                        contains(tempFilename, num_block_cont)
                    % Construct the full path to the DECODING_RESULTS.mat file
                    
                    
                    
                    fullFilePath  = fullfile(cvSplitFolderPath, tempFilename);
                    
                    
                    
                    data_for_plotting_spiking_activity.decodingResultsFilePath{end+1} = fullFilePath;  % Using cell-array to save path 
                    data_for_plotting_spiking_activity.decodingResultsFilename{end+1} = tempFilename;  % Using cell-array to save file name 
                    
                    % Extract data about session and num_cv_splits
                    num_cv_splits = str2double(extractBetween(cvSplitFolderName, 'num_cv_splits_', '('));
                    session_num_cv_splits_Info = sprintf('Session: %s, num_cv_splits: %d\n', dateOfRecording{numOfData}, num_cv_splits);
                    data_for_plotting_spiking_activity.session_info_combined{end+1} = session_num_cv_splits_Info;
                    
                    
                    
                    % Now you have the path to the suitable DECODING_RESULTS.mat file
                    % You can process or load this file as needed
                    fileFound = true;  % Set flag to true
                    
                    
                    break; % Exit the loop once the file is found
                end
                
                
                % end
            end
            
            
            if fileFound
                break; % Exit the loop if the file is found
            end
        end
        
        if ~fileFound
            disp(['No suitable decoding results file found for session: ', current_dateOfRecording]);
            continue;
        end
        
    end
    
    
    % Initialisation of variables
    allUnits_perSession_R = {};
    allUnits_perSession_L = {};
    allSessions_allUnits_SpikeCounts_R_for_merged = [];
    allSessions_allUnits_SpikeCounts_L_for_merged = [];
    allUnit_IDs = {};
    num_trials_R_per_session = {};
    num_trials_L_per_session = {};
    
    
    % Loop over all sessions
    for sessionIdx = 1:numel(data_for_plotting_spiking_activity.decodingResultsFilePath)
        
        % Loading data from the current file
        loadedData = load(data_for_plotting_spiking_activity.decodingResultsFilePath{sessionIdx});
        
        
        % Store unit IDs for the current session
        unit_IDs_currentSession = loadedData.binned_site_info.unit_ID;  % Get IDs for the current session
        allUnit_IDs = [allUnit_IDs; unit_IDs_currentSession(:)];  % Append IDs to the list
        
        % Reinitialisation of variables for the current session
        numSpikes_perBin_R_for_average = cell(1, numel(loadedData.binned_data));
        numSpikes_perBin_L_for_average = cell(1, numel(loadedData.binned_data));
        spikeRate_R_per_Unit_for_average = cell(1, numel(loadedData.binned_data));
        spikeRate_L_per_Unit_for_average = cell(1, numel(loadedData.binned_data));
        
        % Initialisation of variables
        sessionData_R = cell(1, numel(loadedData.binned_data));
        sessionData_L = cell(1, numel(loadedData.binned_data));
        spikeCounts_R_allUnits_together = [];
        spikeCounts_L_allUnits_together = [];
        
        % Loop for each unit in the current session
        for g = 1:numel(loadedData.binned_data)
            
            % Get the current trials marks for this unit
            trial_labels = loadedData.binned_labels.trial_type_side{g};
            
            % Find the indices of trials corresponding to the label ‘instr_R’ (‘choice_R’)
            label_R_indices = strcmp(trial_labels, label_R);
            sessionData_R{g} = loadedData.binned_data{g}(label_R_indices, :);  % Save the data for tag ‘instr_R’
            
            % Find the indices of trials corresponding to the label ‘instr_L’ ('choice_L')
            label_L_indices = strcmp(trial_labels, label_L);
            sessionData_L{g} = loadedData.binned_data{g}(label_L_indices, :);  % Save the data for tag 'instr_L'
            
            % Get data for the current unit
            currentUnitData_R = sessionData_R{g};
            currentUnitData_L = sessionData_L{g};
            
            num_trials_R = size(currentUnitData_R, 1);
            num_trials_L = size(currentUnitData_L, 1);
            
            
            % Multiply the mean values by the bin width to get the number of spikes
            spikeCounts_R = currentUnitData_R * settings.bin_width;
            spikeCounts_L = currentUnitData_L * settings.bin_width;
            
            % Combine data for all units
            spikeCounts_R_allUnits_together = [spikeCounts_R_allUnits_together; spikeCounts_R];
            spikeCounts_L_allUnits_together = [spikeCounts_L_allUnits_together; spikeCounts_L];
            
            
            
            % % strcmp(typeOfDecoding, 'average_across_session')
            % Sum the number of spikes across all bins for each trail
            numSpikes_perBin_R_for_average{g} = sum(spikeCounts_R, 1);
            numSpikes_perBin_L_for_average{g} = sum(spikeCounts_L, 1);
            
            
            % Calculate the number of trails for this unit
            num_trials_R_per_Unit = size(currentUnitData_R, 1);
            num_trials_L_per_Unit = size(currentUnitData_L, 1);
            
            % Spike count per second
            spikeRate_R_per_Unit_for_average{g} = (numSpikes_perBin_R_for_average{g} / num_trials_R_per_Unit) * (1000 / settings.bin_width);
            spikeRate_L_per_Unit_for_average{g} = (numSpikes_perBin_L_for_average{g} / num_trials_L_per_Unit) * (1000 / settings.bin_width);
            
            spikeRate_R_matrix_for_average = vertcat(spikeRate_R_per_Unit_for_average{:});
            spikeRate_L_matrix_for_average = vertcat(spikeRate_L_per_Unit_for_average{:});
            
        end
        
        
        spikeRate_allSessions_R_for_average{sessionIdx} = spikeRate_R_matrix_for_average;
        spikeRate_allSessions_L_for_average{sessionIdx} = spikeRate_L_matrix_for_average;
        
        average_spikeRate_R_for_average_per_session{sessionIdx} = mean(spikeRate_allSessions_R_for_average{sessionIdx}, 1);
        average_spikeRate_L_for_average_per_session{sessionIdx} = mean(spikeRate_allSessions_L_for_average{sessionIdx}, 1);
        
        spikeRate_allSessions_R_matrix_for_average = vertcat(spikeRate_allSessions_R_for_average{:});
        spikeRate_allSessions_L_matrix_for_average = vertcat(spikeRate_allSessions_L_for_average{:});
        
        
        
        % Saving combined data for all units for the current session
        allUnits_perSession_R_for_merged{sessionIdx} = spikeCounts_R_allUnits_together;
        allUnits_perSession_L_for_merged{sessionIdx} = spikeCounts_L_allUnits_together;
        
        
        % Combine data from all sessions
        allSessions_allUnits_SpikeCounts_R_for_merged = [allSessions_allUnits_SpikeCounts_R_for_merged; allUnits_perSession_R_for_merged{sessionIdx}];
        allSessions_allUnits_SpikeCounts_L_for_merged = [allSessions_allUnits_SpikeCounts_L_for_merged; allUnits_perSession_L_for_merged{sessionIdx}];
        
        num_trials_R_per_session{sessionIdx} = num_trials_R;
        num_trials_L_per_session{sessionIdx} = num_trials_L;
        
    end
    
    
    %  Converting a cell array to a numeric array
    num_trials_array_R = cellfun(@(x) x, num_trials_R_per_session);
    num_trials_array_L = cellfun(@(x) x, num_trials_L_per_session);
    
    % Calculation of the sum of all values
    num_trials_R_for_plotting = sum(num_trials_array_R);
    num_trials_L_for_plotting = sum(num_trials_array_L);
    
    
    data_for_plotting_Spiking_activity.numTrials_R = num_trials_R_for_plotting;
    data_for_plotting_Spiking_activity.numTrials_L = num_trials_L_for_plotting;
    
    data_for_plotting_Spiking_activity.numSessions = size(data_for_plotting_spiking_activity.session_info_combined, 2);
    data_for_plotting_Spiking_activity.NumOfUnits = size(allUnit_IDs,1);
    data_for_plotting_Spiking_activity.unit_ID = allUnit_IDs;  % Save all unit IDs
    
    if strcmp(typeOfDecoding, 'merged_files_across_sessions')
        
        % Sum the number of spikes across all bins for each trail
        numSpikes_perBin_R = sum(allSessions_allUnits_SpikeCounts_R_for_merged, 1);
        numSpikes_perBin_L = sum(allSessions_allUnits_SpikeCounts_L_for_merged, 1);
        
        % Calculate the number of trails
        num_trials_R = size(allSessions_allUnits_SpikeCounts_R_for_merged, 1);
        num_trials_L = size(allSessions_allUnits_SpikeCounts_L_for_merged, 1);
        
        
        % Spike count per second
        spikeRate_R = (numSpikes_perBin_R / num_trials_R) * (1000 / settings.bin_width);
        spikeRate_L = (numSpikes_perBin_L / num_trials_L) * (1000 / settings.bin_width);
        
        
        % Calculate the standard deviation of spikeRate
        stdSpikeRate_R = std(allSessions_allUnits_SpikeCounts_R_for_merged);
        stdSpikeRate_L = std(allSessions_allUnits_SpikeCounts_L_for_merged);
        
        data_for_plotting_Spiking_activity.spikeRate_R = spikeRate_R;
        data_for_plotting_Spiking_activity.spikeRate_L = spikeRate_L;
        data_for_plotting_Spiking_activity.stdSpikeRate_R = stdSpikeRate_R;
        data_for_plotting_Spiking_activity.stdSpikeRate_L = stdSpikeRate_L;
        
        
    else
        
        data_for_plotting_Spiking_activity.average_spikeRate_R = mean(spikeRate_allSessions_R_matrix_for_average, 1);
        data_for_plotting_Spiking_activity.average_spikeRate_L = mean(spikeRate_allSessions_L_matrix_for_average, 1);
        
        % Calculation of the standard error of the mean (SEM) for each bin
        sem_spikeRate_R = std(spikeRate_allSessions_R_matrix_for_average, 0, 1) / sqrt(size(spikeRate_allSessions_R_matrix_for_average, 1));
        sem_spikeRate_L = std(spikeRate_allSessions_L_matrix_for_average, 0, 1) / sqrt(size(spikeRate_allSessions_L_matrix_for_average, 1));
        
        data_for_plotting_Spiking_activity.sem_spikeRate_R = sem_spikeRate_R;
        data_for_plotting_Spiking_activity.sem_spikeRate_L = sem_spikeRate_L;
        
        data_for_plotting_Spiking_activity.average_spikeRate_R_per_session = average_spikeRate_R_for_average_per_session;
        data_for_plotting_Spiking_activity.average_spikeRate_L_per_session = average_spikeRate_L_for_average_per_session;
    end
    
    %% save
    % Creating a folder path for saving data
    if ~exist(OUTPUT_PATH_Spiking_activity_data_for_saving, 'dir')
        mkdir(OUTPUT_PATH_Spiking_activity_data_for_saving); % Creating a folder if it does not exist
    end
    
    % Generating a file name for saving
    save_filename = [OUTPUT_PATH_Spiking_activity_data_for_saving '/spiking_activity_data_for_' typeOfDecoding '_' target_brain_structure '_' target_state '_' num_block '_' combinedLabel '.mat'];
    
    % Saving variables to a mat file
    save(save_filename, 'data_for_plotting_Spiking_activity');

    
end



end




function plotingCombinedSpikingActivity(typeOfSessions,  typeOfDecoding, dateOfRecording, target_brain_structure, target_state, combinedLabel, data_before, data_after, settings, OUTPUT_PATH, ind_to_plot)
%% Plot the results

%% Checking for empty input data
if isempty(data_before) || isempty(data_after)
    warning('data_before or data_after are empty. Interrupting the function execution.');
    return;
end

%%
if  strcmp(typeOfDecoding, 'average_across_session')
    typeOfGraph = {'average_across_session_and_per_session' ; 'no' }
end
for u = 1:numel(typeOfGraph)
    
    % Definition of colours for curves
    if strcmp(typeOfSessions, 'right')
        
        % Inactivation on the right: stimuli on the left - contralateral (orange, red), on the right - ipsilateral (blue, dark-blue)
        color_L_before = [1, 0.4, 0]; % Orange
        color_L_after = [1, 0, 0]; % Red
        color_R_before = [0, 0.4, 0.95]; % Blue
        color_R_after = [0.1, 0.3, 0.66]; % Dark-blue
        
        legend_name_L_before = ['contra pre'];
        legend_name_L_after = ['contra post'];
        legend_name_R_before = ['ipsi pre'];
        legend_name_R_after = ['ipsi post'];
        
        color_L_before_light = [1, 0.8, 0.6]; % Orange
        color_L_after_light = [1, 0.6, 0.6]; % Red
        color_R_before_light = [0.6, 0.8, 1]; % Blue
        color_R_after_light = [0.6, 0.6, 1]; %  Dark-blue
        
    elseif strcmp(typeOfSessions, 'left')
        
        % Inactivation on the left: stimuli on the right are contralateral (orange, red), stimuli on the left are ipsilateral (blue, dark-blue)
        color_L_before = [0, 0.4, 0.95]; % Blue
        color_L_after = [0.1, 0.3, 0.66]; % Dark-blue
        color_R_before = [1, 0.4, 0]; % Orange
        color_R_after = [1, 0, 0]; % Red
        
        legend_name_L_before = ['ipsi pre'];
        legend_name_L_after = ['ipsi post'];
        legend_name_R_before = ['contra pre'];
        legend_name_R_after = ['contra post'];
        
        
        color_L_before_light = [0.6, 0.8, 1]; % Blue
        color_L_after_light = [0.6, 0.6, 1]; % Dark-blue
        color_R_before_light = [1, 0.8, 0.6]; % Orange
        color_R_after_light = [1, 0.6, 0.6]; % Red
    end
    
    
    
    
    if strcmp(typeOfDecoding, 'each_unit_separately')
        %% Plot data for each unit
        numUnits = length(data_before.spikeRate_R); % Number of units
        x_axis = linspace(1, 1000, size(data_before.spikeRate_R{1}, 2)); % Assume bins from 1 to 1000 ms
        
        for unit = 1:numUnits
            
            num_of_Units = 1;
            num_of_Trials_R_before = data_before.numTrials_R(unit);
            num_of_Trials_L_before = data_before.numTrials_L(unit);
            num_of_Trials_before = num_of_Trials_R_before + num_of_Trials_L_before;
            
            
            num_of_Trials_R_after = data_after.numTrials_R(unit);
            num_of_Trials_L_after = data_after.numTrials_L(unit);
            num_of_Trials_after = num_of_Trials_R_after + num_of_Trials_L_after;
            
            
            figure; % Create a new figure for each unit
            hold on;
            
            % Plot for the right hemisphere
            plot(x_axis, data_before.spikeRate_R{unit}, 'Color', color_R_before, 'LineWidth', 2.7, 'DisplayName', legend_name_R_before);
            fill_area_R_before  = fill([x_axis, fliplr(x_axis)], ...
                [data_before.spikeRate_R{unit} + data_before.stdSpikeRate_R{unit}, fliplr(data_before.spikeRate_R{unit} - data_before.stdSpikeRate_R{unit})], ...
                color_R_before, 'FaceAlpha', 0.1, 'EdgeColor', 'none'); % Add shaded area for std deviation
            fill_area_R_before.HandleVisibility = 'off'; % Switch off std_bedore_R display in the legend
            
            plot(x_axis, data_after.spikeRate_R{unit}, 'Color', color_R_after,'LineWidth', 2.7, 'DisplayName', legend_name_R_after);
            fill_area_R_after = fill([x_axis, fliplr(x_axis)], ...
                [data_after.spikeRate_R{unit} + data_after.stdSpikeRate_R{unit}, fliplr(data_after.spikeRate_R{unit} - data_after.stdSpikeRate_R{unit})], ...
                color_R_after, 'FaceAlpha', 0.1, 'EdgeColor', 'none'); % Add shaded area for std deviation
            fill_area_R_after.HandleVisibility = 'off';
            
            
            % Plot for the left hemisphere
            plot(x_axis, data_before.spikeRate_L{unit}, 'Color', color_L_before, 'LineWidth', 2.7, 'DisplayName', legend_name_L_before);
            fill_area_L_before = fill([x_axis, fliplr(x_axis)], ...
                [data_before.spikeRate_L{unit} + data_before.stdSpikeRate_L{unit}, fliplr(data_before.spikeRate_L{unit} - data_before.stdSpikeRate_L{unit})], ...
                color_L_before, 'FaceAlpha', 0.1, 'EdgeColor', 'none'); % Add shaded area for std deviation
            fill_area_L_before.HandleVisibility = 'off';
            
            
            plot(x_axis, data_after.spikeRate_L{unit}, 'Color', color_L_after, 'LineWidth', 2.7, 'DisplayName', legend_name_L_after);
            fill_area_L_after = fill([x_axis, fliplr(x_axis)], ...
                [data_after.spikeRate_L{unit} + data_after.stdSpikeRate_L{unit}, fliplr(data_after.spikeRate_L{unit} - data_after.stdSpikeRate_L{unit})], ...
                color_L_after, 'FaceAlpha', 0.1, 'EdgeColor', 'none'); % Add shaded area for std deviation
            fill_area_L_after.HandleVisibility = 'off';
            
            
            
            % Getting information from the combinedLabel variable
            trial_labels = strsplit(combinedLabel, ' '); % split by space
            label_R = trial_labels{1}; % 'instr_R' or 'choice_R'
            label_L = trial_labels{2}; % 'instr_L' or 'choice_L'
            
            % Generation of the annotation string ‘Before inactivation’
            text_before = sprintf('Num of Units: %d\nNum of Trials: %d\n\nNum of %s: %d\nNum of %s: %d', ...
                num_of_Units, ...
                num_of_Trials_before, ...
                label_L, num_of_Trials_L_before, ...
                label_R, num_of_Trials_R_before);
            
            % Generation of the annotation string ‘After inactivation’
            text_after = sprintf('Num of Units: %d\nNum of Trials: %d\n\nNum of %s: %d\nNum of %s: %d', ...
                num_of_Units, ...
                num_of_Trials_after, ...
                label_L, num_of_Trials_L_after, ...
                label_R, num_of_Trials_R_after);
            
            % Generation of the annotation string ‘Sessions’
            unit_id_with_spaces = strrep(data_before.unit_ID{unit}, '_', ' '); % Replacing underscores with spaces
            text_sessions = sprintf('Unit ID: %s\n', unit_id_with_spaces); % Generate ‘Sessions’ annotation string with underscores replaced by spaces
            
            
            
            % Setting of axes
            ax = gca;
            ax.XAxis.FontSize = 14; % Font size for X-axis labels
            ax.YAxis.FontSize = 14; % Font size for Y-axis labels
            
            % Setting axis captions and axis dimensions
            xlabel('Time (ms)', 'FontSize', 17);
            ylabel('Spikes/s', 'FontSize', 20);
            
            
            % Draw a vertical line at position x=500
            vertline = xline(500, '-'); % Create a vertical line and save it to a variable
            vertline.HandleVisibility = 'off'; % Switch off line display in the legend
            
            
            min_spikeRate = min(data_before.min_spikeRate, data_after.min_spikeRate)-10;
            max_spikeRate = min(data_before.max_spikeRate, data_after.max_spikeRate)+10;
            % ylim([min_spikeRate max_spikeRate]); % Setting limits for the Y-axis
            % yticks(min_spikeRate:10:max_spikeRate);
            
            
            set(gca, 'Position', [0.11, 0.11, 0.85, 0.76] ) % change the position of the axes to fit the annotation into the figure too.
            
            target_info = [target_brain_structure '; ' target_state];
            [t, s] = title(combinedLabel, target_info);
            t.FontSize = 16;
            s.FontSize = 12;
            
            
            
            % Fixation of units of measurement in a coordinate system
            set(t, 'Units', 'normalized');
            set(s, 'Units', 'normalized');
            
            % Setting fixed positions for title and sub-title
            set(t, 'Position', [0.5, 1.1, 0]);
            set(s, 'Position', [0.5, 1.04, 0]);
            
            
            
            % Setting up the legend
            lgd = legend('show', 'Location', 'northeastoutside'); % Placing the legend outside of the graph
            lgd.FontSize = 12;
            
            
            % Add annotation to ‘Before inactivation’ graph
            positionOfAnnotation_before = [0.78, 0.4, 0.26, 0.26]; % [x position, y position, size x, size y]
            annotation('textbox', positionOfAnnotation_before, 'String', text_before, ...
                'FontSize', 11, 'HorizontalAlignment', 'left', 'FitBoxToText','on', 'Color', [0.5, 0.5, 0.5]);
            
            % Add annotation to ‘After inactivation’ graph
            positionOfAnnotation_after = [0.78, 0.2, 0.26, 0.26]; % [x position, y position, size x, size y]
            annotation('textbox', positionOfAnnotation_after, 'String', text_after, ...
                'FontSize', 11, 'HorizontalAlignment', 'left', 'FitBoxToText','on', 'Color', [0.3, 0.3, 0.3]);
            
            % Add annotation about amount of sessions
            positionOfAnnotation_sessions = [0.75, 0.7, 0.26, 0.26]; % [x position, y position, size x, size y]
            annotation('textbox', positionOfAnnotation_sessions, 'String', text_sessions, ...
                'FontSize', 11, 'HorizontalAlignment', 'left', 'FitBoxToText','on', ...
                'Color', [0.1, 0.1, 0.1], 'EdgeColor', 'none');
            
            % change the size of the figure
            set(gcf,'position',[450,400,750,680]) % [x0,y0,width,height]
            
            
            % Saving graph
            create_name_graph = ['spiking_activity_for_' data_before.unit_ID{unit} '_' target_brain_structure '_' target_state '_' combinedLabel '.png'];
            
            % Save the figure if needed
            if ~isempty(OUTPUT_PATH)
                saveas(gcf, fullfile(OUTPUT_PATH, create_name_graph));
            end
            
            hold off;
            close(gcf);
        end
        
        
        
        
        
        
        
    elseif strcmp(typeOfDecoding, 'merged_files_across_sessions') || strcmp(typeOfDecoding, 'average_within_session') || strcmp(typeOfDecoding, 'average_across_session')
        
        
        if strcmp(typeOfDecoding, 'merged_files_across_sessions')
            
            % Plot data for all unit all session (metasession)
            x_axis = linspace(1, 1000, size(data_before.spikeRate_R, 2)); % Assume bins from 1 to 1000 ms
            
            num_of_Trials_R_before = data_before.numTrials_R;
            num_of_Trials_L_before = data_before.numTrials_L;
            num_of_Trials_before = num_of_Trials_R_before + num_of_Trials_L_before;
            
            num_of_Trials_R_after = data_after.numTrials_R;
            num_of_Trials_L_after = data_after.numTrials_L;
            num_of_Trials_after = num_of_Trials_R_after + num_of_Trials_L_after;
            
            
        elseif strcmp(typeOfDecoding, 'average_within_session') || strcmp(typeOfDecoding, 'average_across_session')
            
            x_axis = linspace(1, 1000, size(data_before.average_spikeRate_R, 2)); % Assume bins from 1 to 1000 ms
            
            num_of_Trials_R_before = data_before.numTrials_R(1);
            num_of_Trials_L_before = data_before.numTrials_L(1);
            num_of_Trials_before = num_of_Trials_R_before + num_of_Trials_L_before;
            
            num_of_Trials_R_after = data_after.numTrials_R(1);
            num_of_Trials_L_after = data_after.numTrials_L(1);
            num_of_Trials_after = num_of_Trials_R_after + num_of_Trials_L_after;
            
            if strcmp(typeOfDecoding, 'average_within_session')
                data_before.NumOfUnits = size(data_before.unit_ID,2);
                data_after.NumOfUnits = size(data_after.unit_ID,2);
                data_after.numSessions = 1;
            end
        end
        
        
        figure; % Create a new figure for each unit
        hold on;
        
        if strcmp(typeOfDecoding, 'merged_files_across_sessions')
            
            % Plot for the right hemisphere
            plot(x_axis, data_before.spikeRate_R, 'Color', color_R_before, 'LineWidth', 2.7, 'DisplayName', legend_name_R_before);
            fill_area_R_before  = fill([x_axis, fliplr(x_axis)], ...
                [data_before.spikeRate_R + data_before.stdSpikeRate_R, fliplr(data_before.spikeRate_R - data_before.stdSpikeRate_R)], ...
                color_R_before, 'FaceAlpha', 0.1, 'EdgeColor', 'none'); % Add shaded area for std deviation
            fill_area_R_before.HandleVisibility = 'off'; % Switch off std_bedore_R display in the legend
            
            plot(x_axis, data_after.spikeRate_R, 'Color', color_R_after,'LineWidth', 2.7, 'DisplayName', legend_name_R_after);
            fill_area_R_after = fill([x_axis, fliplr(x_axis)], ...
                [data_after.spikeRate_R + data_after.stdSpikeRate_R, fliplr(data_after.spikeRate_R - data_after.stdSpikeRate_R)], ...
                color_R_after, 'FaceAlpha', 0.1, 'EdgeColor', 'none'); % Add shaded area for std deviation
            fill_area_R_after.HandleVisibility = 'off';
            
            % Plot for the left hemisphere
            plot(x_axis, data_before.spikeRate_L, 'Color', color_L_before, 'LineWidth', 2.7, 'DisplayName', legend_name_L_before);
            fill_area_L_before = fill([x_axis, fliplr(x_axis)], ...
                [data_before.spikeRate_L + data_before.stdSpikeRate_L, fliplr(data_before.spikeRate_L - data_before.stdSpikeRate_L)], ...
                color_L_before, 'FaceAlpha', 0.1, 'EdgeColor', 'none'); % Add shaded area for std deviation
            fill_area_L_before.HandleVisibility = 'off';
            
            plot(x_axis, data_after.spikeRate_L, 'Color', color_L_after, 'LineWidth', 2.7, 'DisplayName', legend_name_L_after);
            fill_area_L_after = fill([x_axis, fliplr(x_axis)], ...
                [data_after.spikeRate_L + data_after.stdSpikeRate_L, fliplr(data_after.spikeRate_L - data_after.stdSpikeRate_L)], ...
                color_L_after, 'FaceAlpha', 0.1, 'EdgeColor', 'none'); % Add shaded area for std deviation
            fill_area_L_after.HandleVisibility = 'off';
            
            ylim([20 100]); % Setting limits for the Y-axis
            yticks(0:10:100);
            
        elseif strcmp(typeOfDecoding, 'average_within_session') || strcmp(typeOfDecoding, 'average_across_session')
            
            if strcmp(typeOfDecoding, 'average_across_session')
                Y_scale = 50; 
             %  ylim([20 100]); % Setting limits for the Y-axis
                   ylim([20 Y_scale]);
                yticks(0:10:100);
                
                currentGraphType = typeOfGraph{u};
                if strcmp(currentGraphType, 'average_across_session_and_per_session')
                    for n = 1:numel(data_before.average_spikeRate_R_per_session)
                        plot_R_before = plot(x_axis, data_before.average_spikeRate_R_per_session{n}, 'Color', color_R_before_light, 'LineWidth', 0.2, 'DisplayName', legend_name_R_before);
                        plot_R_after = plot(x_axis, data_after.average_spikeRate_R_per_session{n}, 'Color', color_R_after_light,'LineWidth', 0.2, 'DisplayName', legend_name_R_after);
                        
                        plot_L_before = plot(x_axis, data_before.average_spikeRate_L_per_session{n}, 'Color', color_L_before_light, 'LineWidth', 0.2, 'DisplayName', legend_name_L_before);
                        plot_L_after = plot(x_axis, data_after.average_spikeRate_L_per_session{n}, 'Color', color_L_after_light, 'LineWidth', 0.2, 'DisplayName', legend_name_L_after);
                        
                        plot_R_before.HandleVisibility = 'off';
                        plot_R_after.HandleVisibility = 'off';
                        plot_L_before.HandleVisibility = 'off';
                        plot_L_after.HandleVisibility = 'off';
                    end
                    
                end
            end
            
            plot(x_axis, data_before.average_spikeRate_R, 'Color', color_R_before, 'LineWidth', 3.7, 'DisplayName', legend_name_R_before);
            fill_area_R_before  = fill([x_axis, fliplr(x_axis)], ...
                [data_before.average_spikeRate_R + data_before.sem_spikeRate_R, fliplr(data_before.average_spikeRate_R - data_before.sem_spikeRate_R)], ...
                color_R_before, 'FaceAlpha', 0.1, 'EdgeColor', 'none'); % Add shaded area for std deviation
            fill_area_R_before.HandleVisibility = 'off'; % Switch off std_bedore_R display in the legend
            
            plot(x_axis, data_after.average_spikeRate_R, 'Color', color_R_after,'LineWidth', 3.7, 'DisplayName', legend_name_R_after);
            fill_area_R_after = fill([x_axis, fliplr(x_axis)], ...
                [data_after.average_spikeRate_R + data_after.sem_spikeRate_R, fliplr(data_after.average_spikeRate_R - data_after.sem_spikeRate_R)], ...
                color_R_after, 'FaceAlpha', 0.1, 'EdgeColor', 'none'); % Add shaded area for std deviation
            fill_area_R_after.HandleVisibility = 'off';
            
            % Plot for the left hemisphere
            plot(x_axis, data_before.average_spikeRate_L, 'Color', color_L_before, 'LineWidth', 3.7, 'DisplayName', legend_name_L_before);
            fill_area_L_before = fill([x_axis, fliplr(x_axis)], ...
                [data_before.average_spikeRate_L + data_before.sem_spikeRate_L, fliplr(data_before.average_spikeRate_L - data_before.sem_spikeRate_L)], ...
                color_L_before, 'FaceAlpha', 0.1, 'EdgeColor', 'none'); % Add shaded area for std deviation
            fill_area_L_before.HandleVisibility = 'off';
            
            plot(x_axis, data_after.average_spikeRate_L, 'Color', color_L_after, 'LineWidth', 3.7, 'DisplayName', legend_name_L_after);
            fill_area_L_after = fill([x_axis, fliplr(x_axis)], ...
                [data_after.average_spikeRate_L + data_after.sem_spikeRate_L, fliplr(data_after.average_spikeRate_L - data_after.sem_spikeRate_L)], ...
                color_L_after, 'FaceAlpha', 0.1, 'EdgeColor', 'none'); % Add shaded area for std deviation
            fill_area_L_after.HandleVisibility = 'off';
            
            
        end
        
        
        % Getting information from the combinedLabel variable
        trial_labels = strsplit(combinedLabel, ' '); % split by space
        label_R = trial_labels{1}; % 'instr_R' or 'choice_R'
        label_L = trial_labels{2}; % 'instr_L' or 'choice_L'
        
        % Generation of the annotation string ‘Before inactivation’
        text_before = sprintf('Num of Units: %d\nNum of Trials: %d\n\nNum of %s: %d\nNum of %s: %d', ...
            data_before.NumOfUnits, ...
            num_of_Trials_before, ...
            label_L, num_of_Trials_L_before, ...
            label_R, num_of_Trials_R_before);
        
        % Generation of the annotation string ‘After inactivation’
        text_after = sprintf('Num of Units: %d\nNum of Trials: %d\n\nNum of %s: %d\nNum of %s: %d', ...
            data_after.NumOfUnits, ...
            num_of_Trials_after, ...
            label_L, num_of_Trials_L_after, ...
            label_R, num_of_Trials_R_after);
        
        % Generation of the annotation string ‘Sessions’
        text_sessions = sprintf('Num of Sessions: %d\n', data_after.numSessions);
        
        
        % Setting of axes
        ax = gca;
        ax.XAxis.FontSize = 18; % Font size for X-axis labels
        ax.YAxis.FontSize = 18; % Font size for Y-axis labels
        
        
        % Shift Y-axis number signatures to the left (in this case, a positive value moves them away from the axis)
        ax.YAxis.TickLabelInterpreter = 'none'; % Remove TeX interpretation (if it interferes)
        ax.YAxis.TickLength = [0.02, 0.02]; % Setting the length of ticks (divisions)
        
        % Visual indentation for numbers (TickLabels) on the Y axis
        ax.YRuler.TickLabelGapOffset = 9;  % Setting the indentation of numbers on the Y-axis from the axis itself
        
        
        % Setting axis captions and axis dimensions
        xlabel('Time (ms)', 'FontSize', 22);
        ylabel('Spikes/s', 'FontSize', 25);
        
        
        % Draw a vertical line at position x=500
        vertline = xline(500, '-'); % Create a vertical line and save it to a variable
        vertline.HandleVisibility = 'off'; % Switch off line display in the legend
        
        
        set(gca, 'Position', [0.14, 0.11, 0.8, 0.76] ) % change the position of the axes to fit the annotation into the figure too.
        
        target_info = [target_brain_structure '; ' target_state];
        [t, s] = title(combinedLabel, target_info);
        t.FontSize = 16;
        s.FontSize = 12;
        
        
        
        % Fixation of units of measurement in a coordinate system
        set(t, 'Units', 'normalized');
        set(s, 'Units', 'normalized');
        
        % Setting fixed positions for title and sub-title
        set(t, 'Position', [0.5, 1.1, 0]);
        set(s, 'Position', [0.5, 1.04, 0]);
        
        
        
        % Setting up the legend
        lgd = legend('show', 'Location', 'northeastoutside'); % Placing the legend outside of the graph
        lgd.FontSize = 12;
        
        
        % Add annotation to ‘Before inactivation’ graph
        positionOfAnnotation_before = [0.78, 0.4, 0.26, 0.26]; % [x position, y position, size x, size y]
        annotation('textbox', positionOfAnnotation_before, 'String', text_before, ...
            'FontSize', 11, 'HorizontalAlignment', 'left', 'FitBoxToText','on', 'Color', [0.5, 0.5, 0.5]);
        
        % Add annotation to ‘After inactivation’ graph
        positionOfAnnotation_after = [0.78, 0.2, 0.26, 0.26]; % [x position, y position, size x, size y]
        annotation('textbox', positionOfAnnotation_after, 'String', text_after, ...
            'FontSize', 11, 'HorizontalAlignment', 'left', 'FitBoxToText','on', 'Color', [0.3, 0.3, 0.3]);
        
        
        % Add annotation about amount of sessions
        positionOfAnnotation_sessions = [0.78, 0.7, 0.26, 0.26]; % [x position, y position, size x, size y]
        annotation('textbox', positionOfAnnotation_sessions, 'String', text_sessions, ...
            'FontSize', 11, 'HorizontalAlignment', 'left', 'FitBoxToText','on', ...
            'Color', [0.1, 0.1, 0.1], 'EdgeColor', 'none');
        
        
        % change the size of the figure
        set(gcf,'position',[450,400,850,700]) % [x0,y0,width,height]
        
        
        if strcmp(typeOfDecoding, 'average_across_session') && strcmp(currentGraphType, 'average_across_session_and_per_session')
            ending_name = '_per_session'
        else
            ending_name = ''
        end
        
        % Saving graph
        create_name_graph = ['spiking_activity_for_' typeOfDecoding '_' target_brain_structure '_' target_state '_' combinedLabel ending_name '_' num2str(Y_scale) '.png'];
        
        % Save the figure if needed
        if ~isempty(OUTPUT_PATH)
            saveas(gcf, fullfile(OUTPUT_PATH, create_name_graph));
        end
        
        hold off;
        close(gcf);
        
    end
end

end
