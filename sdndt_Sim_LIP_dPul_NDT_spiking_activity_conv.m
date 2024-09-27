function sdndt_Sim_LIP_dPul_NDT_spiking_activity_conv(monkey, injection, typeOfDecoding)

% The code converts the received raster data into binned data and then performs decoding.

% HOW TO CALL THE FUNCTION?
% If we decode within a session:
% sdndt_Sim_LIP_dPul_NDT_spiking_activity_conv('Bacchus', '1', 'each_session_separately');

% If we decode across sessions:
% sdndt_Sim_LIP_dPul_NDT_spiking_activity_conv('Bacchus', '1', 'merged_files_across_sessions');




%% MODIFIABLE PARAMETERS
% injection: '0' - control sessions, '1' - inactivation sessions (for inactivation experiment),
%            '2' - for functional interaction experiment

% typeOfDecoding: 'each_session_separately', 'merged_files_across_sessions'
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

%% Define the type of data
%typeOfData = {'raster'};
typeOfData = {'binned'};

%% Define the amount of curves

if strcmp(typeOfDecoding, 'merged_files_across_sessions')
    amountOfCurves = {'combine_all_sessions'}; % sum of data for all sessions (one curve on the graph)
    % amountOfCurves = {'sessions_separately'}; % to plot the curves for each session separately on one graph
else
    amountOfCurves = {'one_session'};
end
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
    combinations_inj_and_target_brain_structure = struct('injection', {injection, injection}, 'target_brain_structure', {'LIP_L', 'LIP_R'});
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

if strcmp(typeOfDecoding, 'each_session_separately')
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
                            
                            
                            if strcmp(typeOfDecoding, 'each_session_separately') % typeOfDecoding
                                
                                current_set_of_date = datesForSessions{j}; % Get the corresponding set of dates !!!!!
                                % totalIterations = totalIterations + numel(current_set_of_date) * numLabels * numApproach * numFieldNames;
                                
                                
                                for numDays = 1:numel(current_set_of_date)
                                    current_date = current_set_of_date{numDays};
                                    
                                    % Call the internal decoding function for each day
                                    sdndt_Sim_LIP_dPul_NDT_spiking_activity_conv_internal(monkey, current_injection, current_type_of_session, typeOfDecoding, current_date, current_target_brain_structure, target_state, current_label, current_approach, listOfRequiredFiles_char, amountOfCurves); % typeOfSessions{j}
                                    
                                    
                                    % Update progress for each iteration
                                    overallProgress = overallProgress + 1;
                                    waitbar(overallProgress / totalIterations, h, sprintf('Processing... %.2f%%', overallProgress / totalIterations * 100));
                                    
                                end
                                
                                
                            else % strcmp(typeOfDecoding, 'merged_files_across_sessions')
                                current_date = [];
                                % Call the internal decoding function only once
                                sdndt_Sim_LIP_dPul_NDT_spiking_activity_conv_internal(monkey, current_injection, current_type_of_session,  typeOfDecoding, current_set_of_date, current_target_brain_structure, target_state, current_label, current_approach, listOfRequiredFiles_char, amountOfCurves);
                                
                                
                                % Update progress for each iteration
                                overallProgress = overallProgress + 1;
                                waitbar(overallProgress / totalIterations, h, sprintf('Processing... %.2f%%', overallProgress / totalIterations * 100));
                                
                                
                            end % if strcmp(typeOfDecoding, 'each_session_separately')
                            
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





function sdndt_Sim_LIP_dPul_NDT_spiking_activity_conv_internal(monkey, injection, typeOfSessions, typeOfDecoding, dateOfRecording, target_brain_structure, target_state, given_labels_to_use, given_approach, givenListOfRequiredFiles, amountOfCurves)
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
% Call the function to get the dates
allDateOfRecording = filelist_of_days_from_Simultaneous_dPul_PPC_recordings(monkey, injection, typeOfSessions);



% Call the settings function with the chosen set
[base_path, INPUT_PATH, OUTPUT_PATH_raster, OUTPUT_PATH_binned, monkey_prefix, settings] = sdndt_Sim_LIP_dPul_NDT_settings(monkey, injection, typeOfSessions);




% Check if dateOfRecording is valid
%     if ~strcmp(dateOfRecording, 'merged_files_across_sessions') && ~strcmp(dateOfRecording, 'each_session_separately')
if ~strcmp(typeOfDecoding, 'merged_files_across_sessions') && ~any(strcmp(dateOfRecording, allDateOfRecording))
    error('Invalid dateOfRecording. It must be ''merged_files_across_sessions'' or one of the dates in allDateOfRecording.');
end





%% find grouping_folder

% Initialize block_grouping_folder and block_grouping_folder_for_saving
block_grouping_folder = '';

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
grouping_folder = struct('block_grouping_folder', {}, 'num_block_suffix', {});

num_block = {};  % Initialize as an empty cell array


for s = 1:size(givenListOfRequiredFiles, 1)
    
    currentFile = strtrim(givenListOfRequiredFiles(s, :));  % Extract and trim the current row
    
    
    % Extract the block number suffix from givenListOfRequiredFiles
    if  strcmp(currentFile, 'overlapBlocksFiles_BeforeInjection')
        
        if strcmp(typeOfDecoding, 'each_session_separately')
            block_grouping_folder = 'Overlap_blocks_BeforeInjection';
        elseif strcmp(typeOfDecoding, 'merged_files_across_sessions')
            block_grouping_folder = 'overlapBlocksFilesAcrossSessions_BeforeInjection';
        end
        
    elseif strcmp(currentFile, 'overlapBlocksFiles_AfterInjection')
        
        if strcmp(typeOfDecoding, 'each_session_separately')
            block_grouping_folder = 'Overlap_blocks_AfterInjection';
        elseif strcmp(typeOfDecoding, 'merged_files_across_sessions')
            block_grouping_folder = 'overlapBlocksFilesAcrossSessions_AfterInjection';
        end
        
    elseif strcmp(currentFile, 'overlapBlocksFiles_BeforeInjection_3_4')
        
        if strcmp(typeOfDecoding, 'each_session_separately')
            block_grouping_folder = 'Overlap_blocks_BeforeInjection_3_4';
        elseif strcmp(typeOfDecoding, 'merged_files_across_sessions')
            block_grouping_folder = 'overlapBlocksFilesAcrossSessions_BeforeInjection_3_4';
        end
        
    elseif strcmp(currentFile, 'overlapBlocksFiles_AfterInjection_3_4')
        
        if strcmp(typeOfDecoding, 'each_session_separately')
            block_grouping_folder = 'Overlap_blocks_AfterInjection_3_4';
        elseif strcmp(typeOfDecoding, 'merged_files_across_sessions')
            block_grouping_folder = 'overlapBlocksFilesAcrossSessions_AfterInjection_3_4';
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
    % grouping_folder(s).num_block_suffix = num_block_suffix;
    
    % Construct num_block
    if isempty(grouping_folder(s).num_block_suffix)
        num_block{s} = '';  % Use curly braces for cell array assignment
    else
        % For specific block files, construct num_block
        num_block{s} = sprintf('block_%s', num_block_suffix);
    end
    
    
end



% Preprocess given_labels_to_use
given_labels_to_use_split = strsplit(given_labels_to_use, '_');
combinedLabel = combine_label_segments(given_labels_to_use_split);



%%
Folder_to_save = 'Spiking_activity';


if strcmp(typeOfDecoding, 'each_session_separately')
    
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
    
    
    % create output folder
    typeOfDecoding_monkey = [monkey_prefix dateOfRecording];
    OUTPUT_PATH_Spiking_activity_data_for_saving = fullfile(OUTPUT_PATH_raster, typeOfDecoding_monkey, combined_folder_name);
    % Check if cvSplitFolder_to_save folder exists, if not, create it
    if ~exist(OUTPUT_PATH_Spiking_activity_data_for_saving, 'dir')
        mkdir(OUTPUT_PATH_Spiking_activity_data_for_saving);
    end
    
    
    
    % Collecting data before injection
    [dateOfRecording, target_brain_structure, target_state, data_for_plotting_Spiking_activity_before, ind_to_plot, numUnitsTrials_before] = collectingRasters(monkey, injection, typeOfSessions, typeOfDecoding, dateOfRecording, target_brain_structure, target_state, combinedLabel, num_block{1}, OUTPUT_PATH_Spiking_activity_data_for_saving, strtrim(givenListOfRequiredFiles(1, :)), grouping_folder(1).block_grouping_folder, amountOfCurves);
    
    % Collecting data after injection
    [~, ~, ~, data_for_plotting_Spiking_activity_after, ~, numUnitsTrials_after] = collectingRasters(monkey, injection, typeOfSessions, typeOfDecoding, dateOfRecording, target_brain_structure, target_state, combinedLabel, num_block{2}, OUTPUT_PATH_Spiking_activity_data_for_saving, strtrim(givenListOfRequiredFiles(2, :)), grouping_folder(2).block_grouping_folder, amountOfCurves);
    
    % Plotting both sets of data on the same figure
    plotingCombinedSpikingActivity(typeOfSessions,  typeOfDecoding, dateOfRecording, target_brain_structure, target_state, combinedLabel, data_for_plotting_Spiking_activity_before, data_for_plotting_Spiking_activity_after, settings, OUTPUT_PATH_Spiking_activity_data_for_saving, ind_to_plot, numUnitsTrials_before, numUnitsTrials_after, amountOfCurves);
    
    
    
    
elseif  strcmp(typeOfDecoding, 'merged_files_across_sessions')
    
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
    
    
    % create output folder
    typeOfDecoding_monkey = [monkey_prefix typeOfDecoding];
    sorting_folder  = ['two_group_combination'];
    OUTPUT_PATH_Spiking_activity_data_for_saving = fullfile(OUTPUT_PATH_raster, typeOfDecoding_monkey, sorting_folder, combined_folder_name);
    % Check if cvSplitFolder_to_save folder exists, if not, create it
    if ~exist(OUTPUT_PATH_Spiking_activity_data_for_saving, 'dir')
        mkdir(OUTPUT_PATH_Spiking_activity_data_for_saving);
    end
    
    
    % Collecting data before injection
    [dateOfRecording, target_brain_structure, target_state, data_for_plotting_Spiking_activity_before, ind_to_plot, numUnitsTrials_before] = collectingRasters(monkey, injection, typeOfSessions, typeOfDecoding, dateOfRecording, target_brain_structure, target_state, combinedLabel, num_block{1}, OUTPUT_PATH_Spiking_activity_data_for_saving, strtrim(givenListOfRequiredFiles(1, :)), grouping_folder(1).block_grouping_folder, amountOfCurves);
    
    % Collecting data after injection
    [~, ~, ~, data_for_plotting_Spiking_activity_after, ~, numUnitsTrials_after] = collectingRasters(monkey, injection, typeOfSessions, typeOfDecoding, dateOfRecording, target_brain_structure, target_state, combinedLabel, num_block{2}, OUTPUT_PATH_Spiking_activity_data_for_saving, strtrim(givenListOfRequiredFiles(2, :)), grouping_folder(2).block_grouping_folder, amountOfCurves);
    
    % Plotting both sets of data on the same figure
    plotingCombinedSpikingActivity(typeOfSessions, typeOfDecoding, dateOfRecording, target_brain_structure, target_state, combinedLabel, data_for_plotting_Spiking_activity_before, data_for_plotting_Spiking_activity_after, settings, OUTPUT_PATH_Spiking_activity_data_for_saving, ind_to_plot, numUnitsTrials_before, numUnitsTrials_after, amountOfCurves);
    
end




end






function combinedLabel = combine_label_segments(labelSegments)
% Combine segments 1 and 2, and segments 3 and 4
combinedSegments = {strjoin(labelSegments(1:2), '_'), strjoin(labelSegments(3:4), '_')};
combinedLabel = strjoin(combinedSegments, ' '); % Join the combined segments with a space
end




function [dateOfRecording, target_brain_structure, target_state, total_spike_counts_per_ms, indices_centr, numUnitsTrials] = collectingRasters(monkey, injection, typeOfSessions, typeOfDecoding, dateOfRecording, target_brain_structure, target_state, combinedLabel, num_block, OUTPUT_PATH_Spiking_activity_data_for_saving, givenListOfRequiredFiles, block_grouping_folder, amountOfCurves)
numUnitsTrials = [];
indices_centr = [];

%% Path
% Call the function to get the dates
allDateOfRecording = filelist_of_days_from_Simultaneous_dPul_PPC_recordings(monkey, injection, typeOfSessions);


% Call the settings function with the chosen set
[base_path, INPUT_PATH, OUTPUT_PATH_raster, OUTPUT_PATH_binned, monkey_prefix, settings] = sdndt_Sim_LIP_dPul_NDT_settings(monkey, injection, typeOfSessions);



%% Parameters of the Gaussian kernel
sigma = 0.015;  % standard deviation of the kernel in seconds (e.g. 15 ms)
kernel_width = 3 * sigma;  % kernel range [-3*sigma, 3*sigma]
time_range = -kernel_width:0.001:kernel_width;  % step 1 ms (0.001 sec)
kernel = normpdf(time_range, 0, sigma);  % calculation of the Gaussian kernel
kernel = kernel * 0.001;  % normalisation by bin width


%% List loading
if  strcmp(typeOfDecoding, 'merged_files_across_sessions')
    partOfName = 'allSessionsBlocksFiles';
    monkey_folder = 'merged_files_across_sessions';
elseif strcmp(typeOfDecoding, 'each_session_separately')
    partOfName = dateOfRecording;
    monkey_folder = dateOfRecording;
end

% Load required files for each session or merged files
OUTPUT_PATH_list_of_required_files = [OUTPUT_PATH_raster monkey_prefix monkey_folder '/List_of_required_files/sdndt_Sim_LIP_dPul_NDT_' partOfName '_list_of_required_files.mat'];
load(OUTPUT_PATH_list_of_required_files);



requiredFiles = list_of_required_files.(givenListOfRequiredFiles);

% Selection of files containing target_brain_structure and target_state
selectedFiles = cell(0, 1); % Initialisation
for i = 1:length(requiredFiles)
    fileName = requiredFiles{i};
    if contains(fileName, target_brain_structure) && contains(fileName, target_state)
        selectedFiles{end+1, 1} = fileName;
    end
end




labels = strsplit(combinedLabel); % Split the string into individual labels
label_R = labels{1}; % 'instr_R'
label_L = labels{2}; % 'instr_L'

% Initialisation
loaded_data_for_Spiking_activity = [];
data_for_Spiking_activity = [];


if strcmp(typeOfDecoding, 'each_session_separately')
    % Process each file separately
    
    sessionData_R = [];
    sessionData_L = [];
    
    fieldName = ['session_' dateOfRecording];
    
    
    if isempty(selectedFiles) % If selectedFiles is empty, create a text file with a notification message
        warningFilePath = fullfile(OUTPUT_PATH_Spiking_activity_data_for_saving, ['SpikingActivity_' dateOfRecording '_no_data_for_' target_brain_structure '_' target_state '_' combinedLabel '.txt']);
        fid = fopen(warningFilePath, 'w'); % Open the file for writing
        
        % Check whether the file could be opened
        if fid == -1
            error('Error when creating the file %s', warningFilePath);
        end
        
        fprintf(fid, 'No data found for session %s, brain structure %s, state %s.\n', dateOfRecording, target_brain_structure, target_state);
        fclose(fid);
        
        % Create a field for the current session in the total_spike_counts_per_ms structure with empty arrays
        sessionFieldName = ['session_' dateOfRecording];
        total_spike_counts_per_ms.(sessionFieldName) = struct('sum_R', [], 'sum_L', [], 'stdev_R', [], 'stdev_L', []);
        
        return;  % Move to the next iteration of the loop
    end
    
  %  numUnitsTrials.(fieldName).num_of_Units = length(selectedFiles);
    
 % Search for unique units
    pattern = '[A-Za-z]{3}_\d{8}_\d{2}';  % Template for searching "XXX_YYYYMMDD_XX", where XXX — is any three letters
    unit_ids = cellfun(@(x) regexp(x, pattern, 'match', 'once'), selectedFiles, 'UniformOutput', false);
    unique_unit_ids = unique(unit_ids); % Get unique identifiers
    num_unique_units = length(unique_unit_ids); % Count the number of unique units

    numUnitsTrials.(fieldName).num_of_Units = num_unique_units; % Assign this value to the structure numUnitsTrials

    
    for i = 1:length(selectedFiles)
       
       
        
        data = load(selectedFiles{i});
        % Combine loaded data into one structure
        loaded_data_for_Spiking_activity = [loaded_data_for_Spiking_activity; data];
        
        
        % Attempt selection for ‘R’ (instr or choice)
        label_R_indices  = strcmp(loaded_data_for_Spiking_activity(i).raster_labels.trial_type_side, label_R);
        sessionData_R = [sessionData_R; loaded_data_for_Spiking_activity(i).raster_data(label_R_indices, :)];
        
        % Attempt selection for ‘L’ (instr or choice)
        label_L_indices = strcmp(loaded_data_for_Spiking_activity(i).raster_labels.trial_type_side, label_L);
        sessionData_L = [sessionData_L; loaded_data_for_Spiking_activity(i).raster_data(label_L_indices, :)];
        
        %% Sum
        % Sum the values per row (i.e. per trial) for each unit.
        spike_counts_per_ms_per_Unit_R = sum(sessionData_R, 1);
        spike_counts_per_ms_per_Unit_L = sum(sessionData_L, 1);
        
        %         % Normalisation by the number of attempts to obtain Spikes/s
        %         num_trials_R = size(raster_data_R, 1);
        %         num_trials_L = size(raster_data_L, 1);
        %
        %
        %         spikes_per_ms_R = spike_counts_per_ms_per_Unit_R / num_trials_R;
        %         spikes_per_ms_L = spike_counts_per_ms_per_Unit_L / num_trials_L;
        
        spikes_per_ms_R = spike_counts_per_ms_per_Unit_R;
        spikes_per_ms_L = spike_counts_per_ms_per_Unit_L;
        
        % Storing these values in a structure
        data_for_Spiking_activity(i).spikes_per_ms_R = spikes_per_ms_R;
        data_for_Spiking_activity(i).spikes_per_ms_L = spikes_per_ms_L;
        
        
    end
    
    % Retrieval of trial types for the first unit
    trial_types = loaded_data_for_Spiking_activity(1).raster_labels.trial_type_side;
    
    % Counting the number of trials for instr_R and instr_L
    count_instr_R = sum(strcmp(trial_types, 'instr_R'));
    count_instr_L = sum(strcmp(trial_types, 'instr_L'));
    count_instr_R_L = count_instr_R + count_instr_L;
    numUnitsTrials.(fieldName).num_of_Trials = count_instr_R_L;
    numUnitsTrials.(fieldName).num_of_Trials_R = count_instr_R;
    numUnitsTrials.(fieldName).num_of_Trials_L = count_instr_L;
    
    
    % collect totals for all units
    total_spike_counts_per_ms.(fieldName).sum_R = sum(cat(1, data_for_Spiking_activity.spikes_per_ms_R), 1);
    total_spike_counts_per_ms.(fieldName).sum_L = sum(cat(1, data_for_Spiking_activity.spikes_per_ms_L), 1);
    
    
    % Combine data for all units
    all_spikes_per_ms_R = cat(1, data_for_Spiking_activity.spikes_per_ms_R);
    all_spikes_per_ms_L = cat(1, data_for_Spiking_activity.spikes_per_ms_L);
    
    % Calculate the standard deviation for each time point
    total_spike_counts_per_ms.(fieldName).stdev_R = std(all_spikes_per_ms_R, 0, 1);
    total_spike_counts_per_ms.(fieldName).stdev_L = std(all_spikes_per_ms_L, 0, 1);
    
    
    %% Spike Density Function (SDF)
    % Convolution for the SDF
    convolved_R = conv(total_spike_counts_per_ms.(fieldName).sum_R, kernel, 'same');  % ‘same’ for size adjustment
    convolved_L = conv(total_spike_counts_per_ms.(fieldName).sum_L, kernel, 'same');
    
    % Saving SDF results
    total_spike_counts_per_ms.(fieldName).SDF_R = convolved_R;
    total_spike_counts_per_ms.(fieldName).SDF_L = convolved_L;
    
    
    % Centring and cutting
    center = ceil(length(time_range)/2);
    start_index = center;
    end_index = length(total_spike_counts_per_ms.(fieldName).SDF_R) - center + 1;  % Конечный индекс для обрезки
    
    % Check to make sure that the array is not exceeded
    if end_index > length(total_spike_counts_per_ms.(fieldName).SDF_R)
        end_index = length(total_spike_counts_per_ms.(fieldName).SDF_R);
    end
    
    
    % Get centred and trimmed array
    total_spike_counts_per_ms.(fieldName).SDF_R_centr = total_spike_counts_per_ms.(fieldName).SDF_R(start_index:end_index);
    total_spike_counts_per_ms.(fieldName).SDF_L_centr = total_spike_counts_per_ms.(fieldName).SDF_L(start_index:end_index);
    
    
    % Add zero values for edge smoothing
    % padding = round(length(time_range)/2); % Rounding to the nearest whole number
    padding = floor(length(time_range)/2);  % Cut 45 values on each side
    length_SDF_R = length(total_spike_counts_per_ms.(fieldName).SDF_R);  % Length of the original array
    % total_spike_counts_per_ms.(fieldName).SDF_R_padded = [zeros(1, padding), total_spike_counts_per_ms.(fieldName).SDF_R_centr, zeros(1, padding)];
    % total_spike_counts_per_ms.(fieldName).SDF_L_padded = [zeros(1, padding), total_spike_counts_per_ms.(fieldName).SDF_L_centr, zeros(1, padding)];
    
    
    % Calculation of initial and final indices
    start_index_original = padding + 1;  % Starting index in the original array
    end_index_original = length_SDF_R - padding;  % Final index in the original array
    
    % Determination of all indices
    indices_centr = start_index_original:end_index_original;
    
elseif strcmp(typeOfDecoding, 'merged_files_across_sessions')
    % Initialization for merged sessions
    
    % Initialize containers for session data
    sessionData = struct();
    % Create valid field names for the structure
    for i = 1:length(dateOfRecording)
        sessionName = dateOfRecording{i};
        % Use dynamic field names without leading digits
        fieldName = ['session_' sessionName];
        sessionData.(fieldName) = {};
    end
    
    
    
    numUnitsTrials.session_all.num_of_Units = length(selectedFiles);
    
    % Organize selected files by session
    for i = 1:length(selectedFiles)
        fileName = selectedFiles{i};
        % Extract session date from the file name
        fileDate = regexp(fileName, '\d{8}', 'match', 'once');  % Extract date in the format YYYYMMDD
        
        if ismember(fileDate, dateOfRecording)
            fieldName = ['session_' fileDate];
            sessionData.(fieldName){end+1} = fileName;
        end
    end
    
    % Initialize the combined data storage
    combinedData = struct('spikes_per_ms_R', [], 'spikes_per_ms_L', []);
    
    % Initialisation of variables for storing amounts
    total_num_of_Trials = 0;
    total_num_of_Trials_R = 0;
    total_num_of_Trials_L = 0;
    
       % Initialize a list to store all unique unit IDs across sessions
    all_unique_unit_ids = {};
    
    % Process each session separately
    for i = 1:length(dateOfRecording)
        sessionName = dateOfRecording{i};
        fieldName = ['session_' sessionName];
        
        % Get file list for the current session
        sessionFiles = sessionData.(fieldName);
        
        % Skip empty sessions
        if isempty(sessionFiles)
            warning('No data found for session %s. Skipping...', sessionName);
            
            % Create a text file with the notification
            warningFilePath = fullfile(OUTPUT_PATH_Spiking_activity_data_for_saving, ['SpikingActivity_' sessionName '_no_data_for_' target_brain_structure '_' target_state '_' combinedLabel '.txt']);
            fid = fopen(warningFilePath, 'w'); % Open the file for writing
            
            if fid == -1 % Check if the file can be opened
                error('Error when creating the file %s', warningFilePath);
            end
            
            % Write the notification to a file
            fprintf(fid, 'No data found for session %s, brain structure %s, state %s.\n', sessionName, target_brain_structure, target_state);
            fclose(fid); % Close the file
            continue;
        end
        
        
        % Initialize session-specific data
        sessionData_R = [];
        sessionData_L = [];
        
        for j = 1:length(sessionFiles)
            data = load(sessionFiles{j});
            % Combine loaded data into one structure
            loaded_data_for_Spiking_activity = [data];
                      
            % Поиск уникальных юнитов в каждом файле
            pattern = '[A-Za-z]{3}_\d{8}_\d{2}';  % Шаблон для поиска "XXX_YYYYMMDD_XX", где XXX — это любые три буквы
            unit_ids = regexp(sessionFiles{j}, pattern, 'match', 'once');
            all_unique_unit_ids = [all_unique_unit_ids; unit_ids]; % Собираем все уникальные идентификаторы юнитов

            
            % Attempt selection for ‘R’ (instr or choice)
            label_R_indices  = strcmp(loaded_data_for_Spiking_activity.raster_labels.trial_type_side, label_R);
            sessionData_R = [sessionData_R; loaded_data_for_Spiking_activity.raster_data(label_R_indices, :)];
            
            % Attempt selection for ‘L’ (instr or choice)
            label_L_indices = strcmp(loaded_data_for_Spiking_activity.raster_labels.trial_type_side, label_L);
            sessionData_L = [sessionData_L; loaded_data_for_Spiking_activity.raster_data(label_L_indices, :)];
        end
        
        
        
        % Sum the values per row (i.e. per trial) for each unit
        spike_counts_per_ms_R = sum(sessionData_R, 1);
        spike_counts_per_ms_L = sum(sessionData_L, 1);
        
        
        % Store spike counts
        total_spike_counts_per_ms.(fieldName).sum_R = spike_counts_per_ms_R; % spikes_per_ms_R = spike_counts_per_ms_R;
        total_spike_counts_per_ms.(fieldName).sum_L = spike_counts_per_ms_L; % spikes_per_ms_L = spike_counts_per_ms_L;
        
        %             % Normalisation by the number of attempts to obtain Spikes/s
        %             num_trials_R = size(raster_data_R, 1);
        %             num_trials_L = size(raster_data_L, 1);
        %
        %             spikes_per_ms_R = spike_counts_per_ms_per_Unit_R / num_trials_R;
        %             spikes_per_ms_L = spike_counts_per_ms_per_Unit_L / num_trials_L;
        
        
        % Store standard deviation
        total_spike_counts_per_ms.(fieldName).stdev_R = std(sessionData_R, 0, 1);
        total_spike_counts_per_ms.(fieldName).stdev_L = std(sessionData_L, 0, 1);
        
        % Convolution for SDF
        convolved_R = conv(total_spike_counts_per_ms.(fieldName).sum_R, kernel, 'same');
        convolved_L = conv(total_spike_counts_per_ms.(fieldName).sum_L, kernel, 'same');
        
        % SDF results saved for each session
        total_spike_counts_per_ms.(fieldName).SDF_R = convolved_R;
        total_spike_counts_per_ms.(fieldName).SDF_R = convolved_L;
        
        
        % Determination of indices
        padding = floor(length(time_range)/2);  % Cut 45 values on each side
        length_SDF_R = length(total_spike_counts_per_ms.(fieldName).SDF_R);  % Length of the original array
        
        start_index_original = padding + 1;  % Starting index in the original array
        end_index_original = length_SDF_R - padding;  % Final index in the original array
        
        indices_centr = start_index_original:end_index_original; % Determination of all indices
        
        
        % Combine data across sessions
        combinedData.spikes_per_ms_R = [combinedData.spikes_per_ms_R; spike_counts_per_ms_R];
        combinedData.spikes_per_ms_L = [combinedData.spikes_per_ms_L; spike_counts_per_ms_L];
        
        
        %             % Append to the data structure for this session
        %             data_for_Spiking_activity = [data_for_Spiking_activity; struct('spikes_per_ms_R', spikes_per_ms_R, 'spikes_per_ms_L', spikes_per_ms_L)];
        
        
        
        
        % Retrieval of trial types for the first unit
        trial_types = loaded_data_for_Spiking_activity.raster_labels.trial_type_side;
        
        % Counting the number of trials for instr_R and instr_L
        count_instr_R = sum(strcmp(trial_types, 'instr_R'));
        count_instr_L = sum(strcmp(trial_types, 'instr_L'));
        count_instr_R_L = count_instr_R + count_instr_L;
        numUnitsTrials.(fieldName).num_of_Trials = count_instr_R_L;
        numUnitsTrials.(fieldName).num_of_Trials_R = count_instr_R;
        numUnitsTrials.(fieldName).num_of_Trials_L = count_instr_L;
        
         
        total_num_of_Trials = total_num_of_Trials + numUnitsTrials.(fieldName).num_of_Trials;
        total_num_of_Trials_R = total_num_of_Trials_R + numUnitsTrials.(fieldName).num_of_Trials_R;
        total_num_of_Trials_L = total_num_of_Trials_L + numUnitsTrials.(fieldName).num_of_Trials_L;
        
    end
    
     % Find unique unit IDs across all sessions
    unique_unit_ids_across_sessions = unique(all_unique_unit_ids);
    num_unique_units_across_sessions = length(unique_unit_ids_across_sessions);

    % Save the total number of unique units
    numUnitsTrials.session_all.num_of_Units = num_unique_units_across_sessions;
    
    
    % Combine all session data for 'merged_files_across_sessions'
    if strcmp(amountOfCurves, 'combine_all_sessions')
        
        % Sum all spikes by session
        total_spike_counts_per_ms.session_all.sum_R = sum(combinedData.spikes_per_ms_R, 1);
        total_spike_counts_per_ms.session_all.sum_L = sum(combinedData.spikes_per_ms_L, 1);
        
        total_spike_counts_per_ms.session_all.stdev_R = std(combinedData.spikes_per_ms_R, 0, 1);
        total_spike_counts_per_ms.session_all.stdev_L = std(combinedData.spikes_per_ms_L, 0, 1);
        
        
        % Reconciliation for SDF of all merged sessions
        convolved_R_all = conv(total_spike_counts_per_ms.session_all.sum_R, kernel, 'same');
        convolved_L_all = conv(total_spike_counts_per_ms.session_all.sum_L, kernel, 'same');
        
        % Saving results
        total_spike_counts_per_ms.session_all.SDF_R = convolved_R_all;
        total_spike_counts_per_ms.session_all.SDF_L = convolved_L_all;
        
        

        % Saving results to numUnitsTrials.session_all
        numUnitsTrials.session_all.num_of_Trials = total_num_of_Trials;
        numUnitsTrials.session_all.num_of_Trials_R = total_num_of_Trials_R;
        numUnitsTrials.session_all.num_of_Trials_L = total_num_of_Trials_L;
    end
    
    %         % Combine data for all units in the session
    %         all_spikes_per_ms_R = cat(1, data_for_Spiking_activity.spikes_per_ms_R);
    %         all_spikes_per_ms_L = cat(1, data_for_Spiking_activity.spikes_per_ms_L);
    %
    %         % Calculate the sum and standard deviation for this session
    %         total_spike_counts_per_ms.(fieldName).sum_R = sum(all_spikes_per_ms_R, 1);
    %         total_spike_counts_per_ms.(fieldName).sum_L = sum(all_spikes_per_ms_L, 1);
    %         total_spike_counts_per_ms.(fieldName).stdev_R = std(all_spikes_per_ms_R, 0, 1);
    %         total_spike_counts_per_ms.(fieldName).stdev_L = std(all_spikes_per_ms_L, 0, 1);
    %
    %
    %          % Add to the combined data
    %         combinedData.spikes_per_ms_R = [combinedData.spikes_per_ms_R; all_spikes_per_ms_R];
    %         combinedData.spikes_per_ms_L = [combinedData.spikes_per_ms_L; all_spikes_per_ms_L];
    
end


end




function plotingCombinedSpikingActivity(typeOfSessions,  typeOfDecoding, dateOfRecording, target_brain_structure, target_state, combinedLabel, data_before, data_after, settings, OUTPUT_PATH, ind_to_plot, numUnitsTrials_before, numUnitsTrials_after, amountOfCurves)
%% Plot the results

%type_of_graph = 'sum_std';
type_of_graph = 'sdf';

% Check if there is data for plotting the graph
if strcmp(typeOfDecoding, 'each_session_separately')
    % Get all session names from data_before (assuming data_before and data_after have the same structure)
    sessionNames = fieldnames(data_before);
    
    % Initialize a flag to check if all sessions are empty
    allSessionsEmpty = true;
    
    % Loop through each session and check if the data is empty
    for i = 1:length(sessionNames)
        sessionName = sessionNames{i};
        if ~isempty(data_before.(sessionName).sum_R) || ...
                ~isempty(data_before.(sessionName).sum_L) || ...
                ~isempty(data_after.(sessionName).sum_R) || ...
                ~isempty(data_after.(sessionName).sum_L)
            allSessionsEmpty = false;
            break;
        end
    end
    
    % If all sessions are empty, issue a warning and return
    if allSessionsEmpty
        warning('No data available for plotting spiking activity.');
        return;
    end
end


% Creating a figure
figure;
hold on;

% Time scale ( the data represents 1ms per point)

sessionNames = fieldnames(data_before); % Get session names
firstSession = sessionNames{1}; % Assuming that at least one session is non-empty, we take the first one to determine the size
time_axis = 1:size(data_before.(firstSession).sum_R, 2); % Time array on the X-axis

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
end


% % Calculation of mean and standard deviation
% mean_L_before = mean(data_before.L);
% mean_L_after = mean(data_after.L);
% mean_R_before = mean(data_before.R);
% mean_R_after = mean(data_after.R);
%
% std_L_before = std(data_before.L);
% std_L_after = std(data_after.L);
% std_R_before = std(data_before.R);
% std_R_after = std(data_after.R);
%
%
%
% % Plotting areas of standard deviation
% fill([time_axis, fliplr(time_axis)], [mean_L_before + std_L_before, fliplr(mean_L_before - std_L_before)], color_L_before, 'FaceAlpha', 0.2, 'EdgeColor', 'none');
% fill([time_axis, fliplr(time_axis)], [mean_L_after + std_L_after, fliplr(mean_L_after - std_L_after)], color_L_after, 'FaceAlpha', 0.2, 'EdgeColor', 'none');
% fill([time_axis, fliplr(time_axis)], [mean_R_before + std_R_before, fliplr(mean_R_before - std_R_before)], color_R_before, 'FaceAlpha', 0.2, 'EdgeColor', 'none');
% fill([time_axis, fliplr(time_axis)], [mean_R_after + std_R_after, fliplr(mean_R_after - std_R_after)], color_R_after, 'FaceAlpha', 0.2, 'EdgeColor', 'none');


% Initialize variables for standard deviation
std_L_before = [];
std_L_after = [];
std_R_before = [];
std_R_after = [];


%% for Sum
for i = length(sessionNames)
    % Smoothing
    if strcmp(typeOfDecoding, 'merged_files_across_sessions')
        % Handle combined session data
        if strcmp(amountOfCurves{1}, 'combine_all_sessions')
            % Use data_before.session_all and data_after.session_all
            if isfield(data_before, 'session_all') && isfield(data_after, 'session_all')
                smoothed_L_before = smoothdata(data_before.session_all.sum_L, 2, settings.smoothing_method, settings.smoothing_window);
                smoothed_L_after = smoothdata(data_after.session_all.sum_L, 2, settings.smoothing_method, settings.smoothing_window);
                smoothed_R_before = smoothdata(data_before.session_all.sum_R, 2, settings.smoothing_method, settings.smoothing_window);
                smoothed_R_after = smoothdata(data_after.session_all.sum_R, 2, settings.smoothing_method, settings.smoothing_window);
                
                % Compute std for plotting
                std_L_before = data_before.session_all.stdev_L;
                std_L_after = data_after.session_all.stdev_L;
                std_R_before = data_before.session_all.stdev_R;
                std_R_after = data_after.session_all.stdev_R;
            else
                warning('Data for combined sessions is missing.');
            end
        elseif strcmp(amountOfCurves{1}, 'sessions_separately')
            % Use individual session data
            if isfield(data_before, sessionName) && isfield(data_after, sessionName)
                smoothed_L_before = smoothdata(data_before.(sessionName).sum_L, 2, settings.smoothing_method, settings.smoothing_window);
                smoothed_L_after = smoothdata(data_after.(sessionName).sum_L, 2, settings.smoothing_method, settings.smoothing_window);
                smoothed_R_before = smoothdata(data_before.(sessionName).sum_R, 2, settings.smoothing_method, settings.smoothing_window);
                smoothed_R_after = smoothdata(data_after.(sessionName).sum_R, 2, settings.smoothing_method, settings.smoothing_window);
                
                % Compute std for plotting
                std_L_before = data_before.(sessionName).stdev_L;
                std_L_after = data_after.(sessionName).stdev_L;
                std_R_before = data_before.(sessionName).stdev_R;
                std_R_after = data_after.(sessionName).stdev_R;
            else
                warning('Data for session %s is missing.', sessionName);
            end
        else
            error('Unexpected value for amountOfCurves.');
        end
    else
        % Handle case for other typeOfDecoding if needed
        % (e.g., if strcmp(typeOfDecoding, 'each_session_separately'))
        if isfield(data_before, sessionName) && isfield(data_after, sessionName)
            smoothed_L_before = smoothdata(data_before.(sessionName).sum_L, 2, settings.smoothing_method, settings.smoothing_window);
            smoothed_L_after = smoothdata(data_after.(sessionName).sum_L, 2, settings.smoothing_method, settings.smoothing_window);
            smoothed_R_before = smoothdata(data_before.(sessionName).sum_R, 2, settings.smoothing_method, settings.smoothing_window);
            smoothed_R_after = smoothdata(data_after.(sessionName).sum_R, 2, settings.smoothing_method, settings.smoothing_window);
            
            % Compute std for plotting
            std_L_before = data_before.(sessionName).stdev_L;
            std_L_after = data_after.(sessionName).stdev_L;
            std_R_before = data_before.(sessionName).stdev_R;
            std_R_after = data_after.(sessionName).stdev_R;
        else
            warning('Data for session %s is missing.', sessionName);
        end
    end
end



% % Plotting smoothed curves
% plot(time_axis, smoothed_L_before, 'Color', color_L_before, 'LineWidth', 2.7, 'DisplayName', legend_name_L_before);
% plot(time_axis, smoothed_L_after, 'Color', color_L_after, 'LineWidth', 2.7, 'DisplayName', legend_name_L_after);
% plot(time_axis, smoothed_R_before, 'Color', color_R_before, 'LineWidth', 2.7, 'DisplayName', legend_name_R_before);
% plot(time_axis, smoothed_R_after, 'Color', color_R_after, 'LineWidth', 2.7, 'DisplayName', legend_name_R_after);
%
% fill([time_axis, fliplr(time_axis)], [smoothed_L_before + std_L_before, fliplr(smoothed_L_before - std_L_before)], color_L_before, 'FaceAlpha', 0.2, 'EdgeColor', 'none');
% fill([time_axis, fliplr(time_axis)], [smoothed_L_after + std_L_after, fliplr(smoothed_L_after - std_L_after)], color_L_after, 'FaceAlpha', 0.2, 'EdgeColor', 'none');
% fill([time_axis, fliplr(time_axis)], [smoothed_R_before + std_R_before, fliplr(smoothed_R_before - std_R_before)], color_R_before, 'FaceAlpha', 0.2, 'EdgeColor', 'none');
% fill([time_axis, fliplr(time_axis)], [smoothed_R_after + std_R_after, fliplr(smoothed_R_after - std_R_after)], color_R_after, 'FaceAlpha', 0.2, 'EdgeColor', 'none');



if strcmp(amountOfCurves{1}, 'combine_all_sessions')
    %     plot(time_axis, data_before.session_all.SDF_L, 'Color', color_L_before, 'LineWidth', 2.7, 'DisplayName', legend_name_L_before);
    %     plot(time_axis, data_after.session_all.SDF_L, 'Color', color_L_after, 'LineWidth', 2.7, 'DisplayName', legend_name_L_after);
    %     plot(time_axis, data_before.session_all.SDF_R, 'Color', color_R_before, 'LineWidth', 2.7, 'DisplayName', legend_name_R_before);
    %     plot(time_axis, data_after.session_all.SDF_R, 'Color', color_R_after, 'LineWidth', 2.7, 'DisplayName', legend_name_R_after);
    
    % Filtering of data by indices
    filtered_data_before_SDF_L = data_before.session_all.SDF_L(ind_to_plot);
    filtered_data_after_SDF_L = data_after.session_all.SDF_L(ind_to_plot);
    filtered_data_before_SDF_R = data_before.session_all.SDF_R(ind_to_plot);
    filtered_data_after_SDF_R = data_after.session_all.SDF_R(ind_to_plot);
    
    % Plotting
    plot(time_axis(ind_to_plot), filtered_data_before_SDF_L, 'Color', color_L_before, 'LineWidth', 2.7, 'DisplayName', legend_name_L_before);
    plot(time_axis(ind_to_plot), filtered_data_after_SDF_L, 'Color', color_L_after, 'LineWidth', 2.7, 'DisplayName', legend_name_L_after);
    plot(time_axis(ind_to_plot), filtered_data_before_SDF_R, 'Color', color_R_before, 'LineWidth', 2.7, 'DisplayName', legend_name_R_before);
    plot(time_axis(ind_to_plot), filtered_data_after_SDF_R, 'Color', color_R_after, 'LineWidth', 2.7, 'DisplayName', legend_name_R_after);
    
elseif strcmp(amountOfCurves{1}, 'one_session')
    %     plot(time_axis, data_before.(sessionName).SDF_L, 'Color', color_L_before, 'LineWidth', 2.7, 'DisplayName', legend_name_L_before);
    %     plot(time_axis, data_after.(sessionName).SDF_L, 'Color', color_L_after, 'LineWidth', 2.7, 'DisplayName', legend_name_L_after);
    %     plot(time_axis, data_before.(sessionName).SDF_R, 'Color', color_R_before, 'LineWidth', 2.7, 'DisplayName', legend_name_R_before);
    %     plot(time_axis, data_after.(sessionName).SDF_R, 'Color', color_R_after, 'LineWidth', 2.7, 'DisplayName', legend_name_R_after);
    
    % Filtering of data by indices
    filtered_data_before_SDF_L = data_before.(sessionName).SDF_L(ind_to_plot);
    filtered_data_after_SDF_L = data_after.(sessionName).SDF_L(ind_to_plot);
    filtered_data_before_SDF_R = data_before.(sessionName).SDF_R(ind_to_plot);
    filtered_data_after_SDF_R = data_after.(sessionName).SDF_R(ind_to_plot);
    
    % Plotting
    plot(time_axis(ind_to_plot), filtered_data_before_SDF_L, 'Color', color_L_before, 'LineWidth', 2.7, 'DisplayName', legend_name_L_before);
    plot(time_axis(ind_to_plot), filtered_data_after_SDF_L, 'Color', color_L_after, 'LineWidth', 2.7, 'DisplayName', legend_name_L_after);
    plot(time_axis(ind_to_plot), filtered_data_before_SDF_R, 'Color', color_R_before, 'LineWidth', 2.7, 'DisplayName', legend_name_R_before);
    plot(time_axis(ind_to_plot), filtered_data_after_SDF_R, 'Color', color_R_after, 'LineWidth', 2.7, 'DisplayName', legend_name_R_after);
    
end


% Установка ограничений для оси Y
ylim([50 1600]);


% Получение информации из переменной combinedLabel
    trial_labels = strsplit(combinedLabel, ' '); % разделяем на части по пробелу
    label_R = trial_labels{1}; % 'instr_R' или 'choice_R'
    label_L = trial_labels{2}; % 'instr_L' или 'choice_L'

    % Формирование строки для аннотации "Before inactivation"
    text_before = sprintf('Num of Units: %d\nNum of Trials: %d\n\nNum of %s: %d\nNum of %s: %d', ...
        numUnitsTrials_before.session_all.num_of_Units, ...
        numUnitsTrials_before.session_all.num_of_Trials, ...
        label_L, numUnitsTrials_before.session_all.num_of_Trials_L, ...
        label_R, numUnitsTrials_before.session_all.num_of_Trials_R);

    % Формирование строки для аннотации "After inactivation"
    text_after = sprintf('Num of Units: %d\nNum of Trials: %d\n\nNum of %s: %d\nNum of %s: %d', ...
        numUnitsTrials_after.session_all.num_of_Units, ...
        numUnitsTrials_after.session_all.num_of_Trials, ...
        label_L, numUnitsTrials_after.session_all.num_of_Trials_L, ...
        label_R, numUnitsTrials_after.session_all.num_of_Trials_R);
    
    
    

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


set(gca, 'Position', [0.11, 0.11, 0.85, 0.76] ) % change the position of the axes to fit the annotation into the figure too.



% Setting X-axis marks every 200 ms
xticks(0:200:1000);
yticks(0:200:1600);

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


% Добавление аннотации на график "Before inactivation"
positionOfAnnotation_before = [0.78, 0.4, 0.26, 0.26]; % [x position, y position, size x, size y]
annotation('textbox', positionOfAnnotation_before, 'String', text_before, ...
    'FontSize', 11, 'HorizontalAlignment', 'left', 'FitBoxToText','on', 'Color', [0.5, 0.5, 0.5]);

% Добавление аннотации на график "After inactivation"
positionOfAnnotation_after = [0.78, 0.2, 0.26, 0.26]; % [x position, y position, size x, size y]
annotation('textbox', positionOfAnnotation_after, 'String', text_after, ...
    'FontSize', 11, 'HorizontalAlignment', 'left', 'FitBoxToText','on', 'Color', [0.3, 0.3, 0.3]);




% change the size of the figure
set(gcf,'position',[450,400,750,680]) % [x0,y0,width,height]



% Saving graph
saveas(gcf, fullfile(OUTPUT_PATH, ['SpikingActivity_' target_brain_structure '_' target_state '_' combinedLabel '_' type_of_graph '.png']));
hold off;

close(gcf);

end
