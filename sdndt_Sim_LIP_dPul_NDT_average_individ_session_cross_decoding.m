function sdndt_Sim_LIP_dPul_NDT_average_individ_session_cross_decoding(monkey, injection, typeOfDecoding, curves_per_session)

% For across session analysis, you just need to average individual session
% sdndt_Sim_LIP_dPul_NDT_average_individ_session_cross_decoding('Bacchus', '1', 'сollected_files_across_sessions', 'nis')


% monkey: 'Linus', 'Bacchus'
% 
% injection: '0' - control sessions, '1' - inactivation sessions (for inactivation experiment),
%            '2' - for functional interaction experiment
%
% typeOfDecoding: 'сollected_files_across_sessions' - to plot only one data set (e.g. "train: block 3, test: block 4")
%                 'two_group_combination' - to plot,two data sets (e.g. "train: block 3, test: block 4" and 
%                                           "train: block 4, test: block 3" at the same graph) - NOT CREATED YET
% 
% curves_per_session: 'Same' - showing individual sessions (monochrome) on the graph
%                     'Color' - showing individual sessions (with individual color) on the graph
%                     'nis' (no individual session) - without plotting individual sessions on the graph

%%
% Start timing the execution
startTime = tic;


%% Define the list of required files
% if strcmp(typeOfDecoding, 'сollected_files_across_sessions')
    %     listOfRequiredFiles = {%'firstBlockFiles', 'secondBlockFiles', 'thirdBlockFiles', ...
    %         %     'fourthBlockFiles', 'fifthBlockFiles', 'sixthBlockFiles', ...
    %         'overlapBlocksFiles_BeforeInjection', 'overlapBlocksFiles_AfterInjection' %, ...
    %         %'allBlocksFiles_BeforeInjection', 'allBlocksFiles_AfterInjection'...
    %        % 'overlapBlocksFiles_BeforeInjection_3_4',  'overlapBlocksFiles_AfterInjection_3_4'
    %         %'allBlocksFiles', 'overlapBlocksFiles'
    %         };
    if strcmp(monkey, 'Bacchus')
        listOfRequiredFiles_test = {% 'overlapBlocksFiles_BeforeInjection',  'overlapBlocksFiles_AfterInjection'%,...
            'thirdBlockFiles', 'fourthBlockFiles' % 'firstBlockFiles',
           }; % select the data to be used for the test
    elseif strcmp(monkey, 'Linus')
        listOfRequiredFiles_test = {%'overlapBlocksFiles_BeforeInjection_3_4', 'overlapBlocksFiles_AfterInjection_3_4'%, ...
            'thirdBlockFiles', 'fourthBlockFiles' % 'firstBlockFiles', 
           };
    end
    
% elseif strcmp(typeOfDecoding, 'two_group_combination')
%     if strcmp(monkey, 'Bacchus')
%         listOfRequiredFiles_test = {'overlapBlocksFiles_BeforeInjection', 'overlapBlocksFiles_AfterInjection'};
%     elseif strcmp(monkey, 'Linus')
%         listOfRequiredFiles_test = {'overlapBlocksFiles_BeforeInjection_3_4', 'overlapBlocksFiles_AfterInjection_3_4'};
%     end
% end


%% Define typeOfSessions
% Calculate typeOfSessions based on the injection parameter
if strcmp(injection, '1')
    if strcmp(monkey, 'Linus')
        % typeOfSessions = {'right'};
        typeOfSessions = {'right' %, 'left', 'all'
            }; % For control and injection experiments
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
if any(contains(listOfRequiredFiles_test, {'overlapBlocksFiles_BeforeInjection_3_4', 'overlapBlocksFiles_AfterInjection_3_4', 'overlapBlocksFiles_BeforeInjection', 'overlapBlocksFiles_AfterInjection', 'overlapBlocksFiles'}))
    approach_to_use = {'overlap_approach'};
elseif any(contains(listOfRequiredFiles_test, {'allBlocksFiles_BeforeInjection', 'allBlocksFiles_AfterInjection', 'allBlocksFiles'}))
    approach_to_use = {'all_approach'};
else
    approach_to_use = {%'all_approach',...
        'overlap_approach'};
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


%% Define valid combinations of injection and target_brain_structure
if strcmp(injection, '1') || strcmp(injection, '0')
    combinations_inj_and_target_brain_structure = struct('injection', {injection, injection}, 'target_brain_structure', {'LIP_L', 'LIP_R'});
   %      combinations_inj_and_target_brain_structure = struct('injection', { injection}, 'target_brain_structure', {'LIP_L'});
    
elseif strcmp(injection, '2')
    combinations_inj_and_target_brain_structure = struct('injection', {injection, injection}, 'target_brain_structure', {'dPul_L', 'LIP_L'});
else
    error('Invalid injection value. Use ''0'', ''1'', or ''2''.');
end


%% Loop through each combination of injection, target_brain_structure, and label
h = waitbar(0, 'Processing...'); % Initialize progress bar (for 'each_session_separately')

numCombinations = numel(combinations_inj_and_target_brain_structure);
numLabels = numel(labels_to_use);
numApproach = numel(approach_to_use);

% Depending on the task, the required number of loops and the format of the current_file variable are selected
if strcmp(typeOfDecoding, 'сollected_files_across_sessions')
    numTypeBlocks = numel(listOfRequiredFiles_test); % Add this line to get the number of files
elseif strcmp(typeOfDecoding, 'two_group_combination')
    numTypeBlocks = numel(listOfRequiredFiles_test)/2;
    current_file = char(listOfRequiredFiles_test{:})
end

% Calculate total number of iterations
totalIterations = numApproach * numTypeBlocks * numCombinations * numLabels * numFieldNames * numTypesOfSessions;
overallProgress = 0; % Initialize progress


for file_index = 1:numTypeBlocks % Loop through each file in listOfRequiredFiles
    if strcmp(typeOfDecoding, 'сollected_files_across_sessions')
        current_file = listOfRequiredFiles_test{file_index}; % Get the current file
    end
    
    % Check the condition for monkey and current_file
    if strcmp(monkey, 'Bacchus') && (strcmp(current_file, 'overlapBlocksFiles_BeforeInjection_3_4') || strcmp(current_file, 'overlapBlocksFiles_AfterInjection_3_4'))
        fprintf('Skipping processing for %s with file %s.\n', monkey, current_file);
        continue; % Skip this iteration and go to the next file
    end
    
    % Skip processing the second block if the injection is 0 or 1
    if ~((strcmp(injection, '0') || strcmp(injection, '1')) && ...
            (strcmp(current_file, 'secondBlockFiles') || strcmp(current_file, 'allBlocksFiles') || strcmp(current_file , 'overlapBlocksFiles')))
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
                    % if strcmp(typeOfDecoding, 'each_session_separately')
                    datesForSessions = {}; % Initialize datesForSessions as an empty cell array
                    if strcmp(injection, '1')
                        for type = 1:numel(typeOfSessions)
                            % Get the dates for the corresponding injection and session types
                            datesForSessions{end+1} = filelist_of_days_from_Simultaneous_dPul_PPC_recordings(monkey, injection, typeOfSessions{type});
                        end
                    elseif  strcmp(injection, '0') || strcmp(injection, '2')
                        datesForSessions = filelist_of_days_from_Simultaneous_dPul_PPC_recordings(monkey, injection, typeOfSessions);
                    end
                    %                 else % strcmp(typeOfDecoding, 'averages_across_sessions')
                    %                     datesForSessions = {''}; % Set a default value if decoding across sessions
                    %                 end
                    
                    
                    
                    % Loop through each target_state parameter
                    fieldNames = fieldnames(targetParams);
                    numFieldNames = numel(fieldNames);
                    numTypesOfSessions = numel(typeOfSessions);
                    
                    for i = 1:numFieldNames
                        target_state_name = fieldNames{i};
                        target_state = targetParams.(target_state_name);
                        
                        for j = 1:numTypesOfSessions
                            % Call the main decoding function based on dateOfRecording
                            
                            % current_set_of_date = datesForSessions{j}; % Get the corresponding set of dates !!!!!
                            current_type_of_session = typeOfSessions{j}; % Get the corresponding type of session !!!!!
                            current_set_of_date = datesForSessions{j}; % Get the corresponding set of dates !!!!!
                            
                            
                            
                            
                            if  strcmp(typeOfDecoding, 'сollected_files_across_sessions') || strcmp(typeOfDecoding, 'two_group_combination')
                                current_date = [];
                                
                                % Call the internal decoding function only once
                                sdndt_Sim_LIP_dPul_NDT_average_cross_decoding_internal(monkey, current_injection, current_type_of_session, typeOfDecoding, current_set_of_date, current_target_brain_structure, target_state, current_label, current_approach, current_file, curves_per_session);
                                
                                % Update progress for each iteration
                                overallProgress = overallProgress + 1;
                                waitbar(overallProgress / totalIterations, h, sprintf('Processing... %.2f%%', overallProgress / totalIterations * 100));
                                
                                
                            end % if strcmp(typeOfDecoding, 'each_session_separately')
                            
                        end % for j = 1:numTypesOfSessions
                    end % for i = 1:numFieldNames
                end % for label_index = 1:numLabels
            end % approach_index = 1:numApproach
        end % for comb_index = 1:numCombinations
        
    end %  if ~(strcmp(current_file, 'secondBlockFiles')
end % file_index = 1:numTypeBlocks



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





function sdndt_Sim_LIP_dPul_NDT_average_cross_decoding_internal(monkey, injection, typeOfSessions, typeOfDecoding, dateOfRecording, target_brain_structure, target_state, given_labels_to_use, current_approach, givenListOfRequiredFiles, curves_per_session)



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
if strcmp(current_approach, 'all_approach')
    % For 'all_approach', set the block grouping folder prefix to 'All_'
    block_grouping_folder_prefix = 'All_';
elseif strcmp(current_approach, 'overlap_approach')
    % For 'overlap_approach', set the block grouping folder prefix to 'Overlap_'
    block_grouping_folder_prefix = 'Overlap_';
else
    % Handle the case when the approach is unknown
    error('Unknown approach. Please use either ''all_approach'' or ''overlap_approach''.');
end



% Initialize an array of structures to store the results
grouping_folder = struct('block_grouping_folder', {}, 'block_grouping_folder_for_saving', {}, 'num_block_suffix', {});

num_block = {};  % Initialize as an empty cell array

for s = 1:size(givenListOfRequiredFiles, 1)
    
    currentFile = strtrim(givenListOfRequiredFiles(s, :));  % Extract and trim the current row
    
    
    % Extract the block number suffix from givenListOfRequiredFiles
    % selection of the data on which the TESTing was done
    if strcmp(currentFile, 'firstBlockFiles')  &&  strcmp(current_approach, 'overlap_approach')
        num_block_suffix = '1';
        block_grouping_folder = sprintf('%sBy_block', block_grouping_folder_prefix);
    elseif strcmp(currentFile, 'secondBlockFiles')
        num_block_suffix = '2';
        block_grouping_folder = sprintf('%sBy_block', block_grouping_folder_prefix);
    elseif strcmp(currentFile, 'thirdBlockFiles')  &&  strcmp(current_approach, 'overlap_approach')
        num_block_suffix = '3';
        block_grouping_folder = sprintf('%sBy_block', block_grouping_folder_prefix);
    elseif strcmp(currentFile, 'fourthBlockFiles')  &&  strcmp(current_approach, 'overlap_approach')
        num_block_suffix = '4';
        block_grouping_folder = sprintf('%sBy_block', block_grouping_folder_prefix);
    elseif strcmp(currentFile, 'fifthBlockFiles')
        num_block_suffix = '5';
        block_grouping_folder = sprintf('%sBy_block', block_grouping_folder_prefix);
    elseif strcmp(currentFile, 'sixthBlockFiles')
        num_block_suffix = '6';
        block_grouping_folder = sprintf('%sBy_block', block_grouping_folder_prefix);
    elseif strcmp(currentFile, 'overlapBlocksFiles_BeforeInjection') &&  strcmp(monkey, 'Bacchus')
        % For overlap blocks before injection
        block_grouping_folder = 'Overlap_blocks_3_4/';
        block_grouping_folder_for_saving = 'overlapBlocksFilesAcrossSessions_BeforeInjection';
        num_block_suffix = '1';
    elseif strcmp(currentFile, 'overlapBlocksFiles_AfterInjection') &&  strcmp(monkey, 'Bacchus')
        % For overlap blocks after injection
        block_grouping_folder = 'Overlap_blocks_3_4/';
        block_grouping_folder_for_saving = 'overlapBlocksFilesAcrossSessions_AfterInjection';
        num_block_suffix = '3';
    elseif strcmp(currentFile, 'overlapBlocksFiles_BeforeInjection_3_4') &&  strcmp(monkey, 'Linus')
        % For overlap blocks before injection
        block_grouping_folder = 'Overlap_blocks_3_4/';
        block_grouping_folder_for_saving = 'overlapBlocksFilesAcrossSessions_BeforeInjection_3_4';
        num_block_suffix = '1';
    elseif strcmp(currentFile, 'overlapBlocksFiles_AfterInjection_3_4') &&  strcmp(monkey, 'Linus')
        % For overlap blocks after injection
        block_grouping_folder = 'Overlap_blocks_3_4/';
        block_grouping_folder_for_saving = 'overlapBlocksFilesAcrossSessions_AfterInjection_3_4';
        num_block_suffix = '3';
    elseif strcmp(currentFile, 'allBlocksFiles_BeforeInjection')
        % For all blocks before injection
        block_grouping_folder = 'All_blocks/';
        block_grouping_folder_for_saving = 'allBlocksFilesAcrossSessions_BeforeInjection';
        num_block_suffix = '';
    elseif strcmp(currentFile, 'allBlocksFiles_AfterInjection')
        % For all blocks after injection
        block_grouping_folder = 'All_blocks/';
        block_grouping_folder_for_saving = 'allBlocksFilesAcrossSessions_AfterInjection';
        num_block_suffix = '';
    else
        error('Unknown value for givenListOfRequiredFiles.');
    end
    
    % Save the results in the structure array
    grouping_folder(s).block_grouping_folder = block_grouping_folder;
    grouping_folder(s).block_grouping_folder_for_saving = block_grouping_folder_for_saving;
    grouping_folder(s).num_block_suffix = num_block_suffix;
    
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
cvSplitFolder_to_save = 'Average_Dynamics';

if  strcmp(typeOfDecoding, 'сollected_files_across_sessions')
    
    % Construct the block grouping folder for saving
    if isempty(grouping_folder.block_grouping_folder_for_saving)
        % For specific block files, construct the folder with block number suffix
        grouping_folder.block_grouping_folder_for_saving = sprintf('%sFilesAcrossSessions_Block_%s/', lower(block_grouping_folder_prefix), num_block_suffix);
    end
    
    % create output folder
    type_of_decoding = 'Cross_decoding';
    type_of_folder = 'average_across_session';
    typeOfDecoding_monkey = [monkey_prefix type_of_folder];
    OUTPUT_PATH_binned_data_for_saving = fullfile(OUTPUT_PATH_binned, typeOfDecoding_monkey, type_of_decoding, grouping_folder.block_grouping_folder, settings.num_cv_splits_approach_folder);
    % Check if cvSplitFolder_to_save folder exists, if not, create it
    if ~exist(OUTPUT_PATH_binned_data_for_saving, 'dir')
        mkdir(OUTPUT_PATH_binned_data_for_saving);
    end
    
    [dateOfRecording, target_brain_structure, target_state, given_labels_to_use, data_for_plotting_averages, settings, OUTPUT_PATH_binned_data_for_saving, numOfData] = collectingAveragesAcrossSessions(monkey, injection, typeOfSessions, dateOfRecording, target_brain_structure, target_state, given_labels_to_use, num_block{1}, OUTPUT_PATH_binned_data_for_saving, block_grouping_folder, type_of_decoding);
    plotingAveragesAcrossSessions(dateOfRecording, target_brain_structure, target_state, given_labels_to_use, data_for_plotting_averages, settings, OUTPUT_PATH_binned_data_for_saving, numOfData, curves_per_session)
    
    
    
elseif strcmp(typeOfDecoding, 'two_group_combination')
    
    
    
    
    
    % Create a combined folder name by comparing parts
    parts_1 = strsplit(grouping_folder(1).block_grouping_folder_for_saving, '_');
    parts_2 = strsplit(grouping_folder(2).block_grouping_folder_for_saving, '_');
    
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
    type_of_decoding = 'Cross_decoding';
    type_of_folder = 'average_across_session';
    typeOfDecoding_monkey = [monkey_prefix type_of_folder];
    OUTPUT_PATH_binned_data_for_saving = fullfile(OUTPUT_PATH_binned, typeOfDecoding_monkey, typeOfDecoding, type_of_decoding);
    % Check if cvSplitFolder_to_save folder exists, if not, create it
    if ~exist(OUTPUT_PATH_binned_data_for_saving, 'dir')
        mkdir(OUTPUT_PATH_binned_data_for_saving);
    end
    
    %     [dateOfRecording, target_brain_structure, target_state, combinedLabel, data_for_plotting_averages, settings, OUTPUT_PATH_binned_data_for_saving, numOfData] = collectingAveragesAcrossSessions(monkey, injection, typeOfSessions, dateOfRecording, target_brain_structure, target_state, combinedLabel, num_block, OUTPUT_PATH_binned_data_for_saving, block_grouping_folder);
    %     plotingAveragesAcrossSessions(dateOfRecording, target_brain_structure, target_state, combinedLabel, data_for_plotting_averages, settings, OUTPUT_PATH_binned_data_for_saving, numOfData, curves_per_session)
    
    
    % Collecting data before injection
    [dateOfRecording, target_brain_structure, target_state, combinedLabel, data_for_plotting_averages_before, settings, ~, numOfData_before] = collectingAveragesAcrossSessions(monkey, injection, typeOfSessions, dateOfRecording, target_brain_structure, target_state, combinedLabel, num_block{1}, OUTPUT_PATH_binned_data_for_saving, grouping_folder(1).block_grouping_folder, type_of_decoding);
    
    % Collecting data after injection
    [~, ~, ~, ~, data_for_plotting_averages_after, ~, ~, numOfData_after] = collectingAveragesAcrossSessions(monkey, injection, typeOfSessions, dateOfRecording, target_brain_structure, target_state, combinedLabel, num_block{2}, OUTPUT_PATH_binned_data_for_saving, grouping_folder(2).block_grouping_folder, type_of_decoding);
    
    % Plotting both sets of data on the same figure
    plotingCombinedAveragesAcrossSessions(dateOfRecording, target_brain_structure, target_state, combinedLabel, data_for_plotting_averages_before, data_for_plotting_averages_after, settings, OUTPUT_PATH_binned_data_for_saving, numOfData_before, numOfData_after, curves_per_session);
    
else
    partOfName = dateOfRecording;
end


% % Load required files for each session or merged files
% OUTPUT_PATH_list_of_required_files = [OUTPUT_PATH_binned dateOfRecording '/List_of_required_files/sdndt_Sim_LIP_dPul_NDT_' partOfName '_list_of_required_files.mat'];
% load(OUTPUT_PATH_list_of_required_files);

end


function [dateOfRecording, target_brain_structure, target_state, combinedLabel, data_for_plotting_averages, settings, OUTPUT_PATH_binned_data_for_saving, numOfData] = collectingAveragesAcrossSessions(monkey, injection, typeOfSessions, dateOfRecording, target_brain_structure, target_state, combinedLabel, num_block, OUTPUT_PATH_binned_data_for_saving, block_grouping_folder, type_of_decoding)

%% Path
% Call the function to get the dates
allDateOfRecording = filelist_of_days_from_Simultaneous_dPul_PPC_recordings(monkey, injection, typeOfSessions);


% Call the settings function with the chosen set
[base_path, INPUT_PATH, OUTPUT_PATH_raster, OUTPUT_PATH_binned, monkey_prefix, settings] = sdndt_Sim_LIP_dPul_NDT_settings(monkey, injection, typeOfSessions);

%%

% Define a colormap for the sessions
session_colors_RGB = [
    0.6350, 0.0780, 0.1840;   % Red for the first session
    0.8500, 0.3250, 0.0980;   % Orange for the second session
    0.9290, 0.6940, 0.1250;   % Yellow for the third session
    0.4660, 0.6740, 0.1880;   % Green for the fourth session
    0.3010, 0.7450, 0.9330;   % Cyan for the fifth session
    0, 0.4470, 0.7410;        % Blue for the sixth session
    0.4940, 0.1840, 0.5560;   % Violet for the seventh session
    ];

session_colors_Appearance = {
    'Red';     % Red for the first session
    'Orange';  % Orange for the second session
    'Yellow';  % Yellow for the third session
    'Green';   % Green for the fourth session
    'Cyan';    % Cyan for the fifth session
    'Blue';    % Blue for the sixth session
    'Violet';  % Violet for the seventh session
    };


% Create a structure array to store session information
data_for_plotting_averages.session_info = struct('number', {}, 'name', {}, 'color_RGB', {}, 'color_appearance', {});

for i = 1:numel(dateOfRecording)
    data_for_plotting_averages.session_info(i).number = i;
    data_for_plotting_averages.session_info(i).name = dateOfRecording{i};
    data_for_plotting_averages.session_info(i).color_RGB = session_colors_RGB (i, :);
    data_for_plotting_averages.session_info(i).color_appearance = session_colors_Appearance(i, :);
end

% Initialize variables to keep track of the highest value and its folder
highestValue = 0;
highestFolder = '';

% Initialize decodingResultsFilePath
data_for_plotting_averages.decodingResultsFilePath = '';  % Initialize as an empty string

% Initialize cell arrays to store data across sessions
all_mean_decoding_results = {}; % to store mean decoding results
sites_to_use = {};
numOfUnits = {};
numOfTrials = {};
session_num_cv_splits_Info = {};
data_for_plotting_averages.session_info_combined = {};
label_counts_cell = cell(1, numel(dateOfRecording)); % Initialize a cell array to store label_counts for each day

totalNumOfUnits = 0; % Initialize the total number of units
totalNumOfTrials = 0; % Initialize the total number of trials

sum_first_numbers = 0; % Initialize variables to store sums of the first and second numbers
sum_second_numbers = 0;

%pattern_block = ['test_' num_block];
% Save the original value of num_block
initial_num_block = num_block;

for numOfData = 1:numel(dateOfRecording)
    
    current_dateOfRecording = dateOfRecording{numOfData};
    
    % Return num_block to the initial value before each iteration
    num_block = initial_num_block;
    
    % Check if the current date is ‘20201112’
    if strcmp(current_dateOfRecording, '20201112') && strcmp(num_block, 'block_3')
        num_block = 'block_2';  % ude block 2 for the ‘20201112’
    end
    
    pattern_block = ['test_.*' num_block '.*'];
    
    current_dateOfRecording_monkey = [monkey_prefix current_dateOfRecording];
    OUTPUT_PATH_binned_data = fullfile(OUTPUT_PATH_binned, current_dateOfRecording_monkey, type_of_decoding, settings.num_cv_splits_approach_folder,  block_grouping_folder);
    
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
    %
    %
    %         % Sort folders based on values outside parentheses (in descending order)
    %         [~, sorted_idx] = sort(values_outside_parentheses, 'descend');
    
    % Iterate over sorted folders and check for the file
    data_for_plotting_averages.decodingResultsFilePath = '';
    session_num_cv_splits_Info = '';
    
    % Initialize a flag to check if the file is found
    fileFound = false;
    
    for idx = sorted_idx
        cvSplitFolderName = cvSplitsFolders(idx).name;
        cvSplitFolderPath = fullfile(OUTPUT_PATH_binned_data, cvSplitFolderName);
        
        % List the contents of the current folder
        decodingResultsFiles = dir(fullfile(cvSplitFolderPath, '*_DECODING_RESULTS.mat'));
        
        % Check if the required file exists in this folder
        for fileIndex = 1:numel(decodingResultsFiles)
            data_for_plotting_averages.decodingResultsFilename = decodingResultsFiles(fileIndex).name;
            
            % Check if the file name contains the desired target structure, state, and label
            if contains(data_for_plotting_averages.decodingResultsFilename, target_brain_structure) && ...
                    contains(data_for_plotting_averages.decodingResultsFilename, target_state) && ...
                    contains(data_for_plotting_averages.decodingResultsFilename, combinedLabel) && ...
                    ~isempty(regexp(data_for_plotting_averages.decodingResultsFilename, pattern_block, 'once'))
                %contains(data_for_plotting_averages.decodingResultsFilename, ['test_' num_block]) % find test_block_X
                % Construct the full path to the DECODING_RESULTS.mat file
                
                
                
                
                data_for_plotting_averages.decodingResultsFilePath = fullfile(cvSplitFolderPath, data_for_plotting_averages.decodingResultsFilename);
                
                % Now you have the path to the suitable DECODING_RESULTS.mat file
                % You can process or load this file as needed
                fileFound = true;  % Set flag to true
                
                % Extract data about session and num_cv_splits
                num_cv_splits = str2double(extractBetween(cvSplitFolderName, 'num_cv_splits_', '('));
                session_num_cv_splits_Info = sprintf('Session: %s, num_cv_splits: %d\n', dateOfRecording{numOfData}, num_cv_splits);
                
                
                break; % Exit the loop once the file is found
            end
            
            
            % end
        end
        
        %             % Exit the loop if the file is found
        %             if ~isempty(decodingResultsFilePath)
        %                 break;
        %             end
        
        if fileFound
            break; % Exit the loop if the file is found
        end
    end
    
    
    % Concatenate information about all sessions into a single string
    data_for_plotting_averages.session_info_combined{end+1} = [session_num_cv_splits_Info];
    
    
    
    
    % If no file was found in any folder, display error message
    if isempty(data_for_plotting_averages.decodingResultsFilePath)
        
        data_for_plotting_averages.session_info(numOfData) = [];
        
        % disp('ERROR: No suitable decoding results file found.');
        disp(['No suitable decoding results file found for session: ', current_dateOfRecording]);
        continue; % Move to the next iteration of the loop
        
    else
        
        % Load the file
        loadedData = load(data_for_plotting_averages.decodingResultsFilePath);
        
        % Now you can access the data from the loaded file using the appropriate fields or variables
        % For example, if there is a variable named 'results' in the loaded file, you can access it as follows:
        mean_decoding_results = loadedData.DECODING_RESULTS.NORMALIZED_RANK_RESULTS.mean_decoding_results;
        
        % Append mean decoding results to the cell array
        all_mean_decoding_results{end+1} = mean_decoding_results;
        
        % Process the loaded data as needed
        
        % Load additional data if necessary
        [filepath, filename, fileext] = fileparts(data_for_plotting_averages.decodingResultsFilePath); % Get the path and filename components
        desired_part = fullfile(filepath, filename); % Concatenate the path and filename without the extension
        binned_file_name = [desired_part '.mat']; % Add '.mat' to the desired part
        % Specify substrings to remove
        substrings_to_remove = {'_DECODING_RESULTS'}; % Add more patterns as needed
        for substring = substrings_to_remove % Remove specified substrings using strrep
            binned_file_name = strrep(binned_file_name, substring{1}, '');
        end
        load(binned_file_name);
    end
    %end
    
    %   session_num_cv_splits_Info{end+1} = sprintf('Session: %s, num_cv_splits: %d\n', dateOfRecording{numOfData}, num_cv_splits);
    
    
    %% Number of units
    sites_to_use{end+1} = loadedData.DECODING_RESULTS.DS_PARAMETERS.sites_to_use;
    numOfUnits{end+1} = size(sites_to_use{end}, 2);  % Calculate the number of units
    unitsForCurrentDay = size(sites_to_use{end}, 2); % Calculate the number of units for the current day
    totalNumOfUnits = totalNumOfUnits + unitsForCurrentDay;  % Add the units for the current day to the total
    
    
    
    
    
    %     %% Number of trials
    %     trial_type_side = binned_labels.trial_type_side;
    %     label_names_to_use = loadedData.DECODING_RESULTS.DS_PARAMETERS.label_names_to_use;
    
    
    %% Number of trials
    trial_type_side = binned_labels.trial_type_side;
    
    %Initialisation of counters for each combination
    label_counts_training_R = 0;
    label_counts_training_L = 0;
    label_counts_test_R = 0;
    label_counts_test_L = 0;
    
    % Extract labels from combinedLabel
    relevant_labels = strsplit(combinedLabel, '_'); % receive {'instr', 'R', 'instr', 'L'}
    
    uniqueLabels = strcat(relevant_labels(1:2:end), '_', relevant_labels(2:2:end)); % Combine in pairs
    
    
    
    % Create a structure with the required order dynamically
    ordered_fields = {[uniqueLabels{2} '_training'], [uniqueLabels{1} '_training'], ...
        [uniqueLabels{2} '_test'], [uniqueLabels{1} '_test']};
    
    % Existence check and initialisation of values if they have not yet been created
    if ~exist('total_NumOfTrials', 'var')
        total_NumOfTrials = struct();
    end
    for i = 1:numel(ordered_fields)
        field_name = ordered_fields{i};
        if ~isfield(total_NumOfTrials, field_name)
            total_NumOfTrials.(field_name) = 0;  % Initialise with default values
        end
    end
    
    % Reorder the structure according to the desired order of fields
    total_NumOfTrials = orderfields(total_NumOfTrials, ordered_fields);
    
    
    
    % Extract labels from combinedLabel
    relevant_labels = strsplit(combinedLabel, '_'); % receive {'instr', 'R', 'instr', 'L'}
    
    % We use only trial_type_side{1} for counting
    labels_at_site = unique(trial_type_side{1}); % Access to unique labels on trial_type_side{1}
    
    % We use only trial_type_side{1} for counting
    labels_at_site = trial_type_side{1};
    
    % Search all labels in labels_at_site
    for i = 1:numel(labels_at_site)
        % Retrieve the current label as a string
        label_str = labels_at_site{i};
        
        % Count workouts and tests for R and L separately
        if contains(label_str, 'training') && contains(label_str, relevant_labels{1}) && contains(label_str, relevant_labels{2}) % instr_R
            label_counts_training_R = label_counts_training_R + 1; % Increase the counter by 1
        elseif contains(label_str, 'training') && contains(label_str, relevant_labels{3}) && contains(label_str, relevant_labels{4}) % instr_L
            label_counts_training_L = label_counts_training_L + 1;
        elseif contains(label_str, 'test') && contains(label_str, relevant_labels{1}) && contains(label_str, relevant_labels{2}) % instr_R
            label_counts_test_R = label_counts_test_R + 1;
        elseif contains(label_str, 'test') && contains(label_str, relevant_labels{3}) && contains(label_str, relevant_labels{4}) % instr_L
            label_counts_test_L = label_counts_test_L + 1;
        end
    end
    
    
    
    % Create an empty structure to store the number of attempts for the current session
    session_counts = struct();
    
    % Dynamically create fields for each unique label
    for i = 1:numel(uniqueLabels)
        % Form the names of the training and test marks
        training_field = [uniqueLabels{i} '_training'];
        test_field = [uniqueLabels{i} '_test'];
        
        % Fill the session_counts fields with values for the current session
        session_counts.(training_field) = eval(['label_counts_training_' uniqueLabels{i}(end)]);
        session_counts.(test_field) = eval(['label_counts_test_' uniqueLabels{i}(end)]);
    end
    
    % Save the session_counts structure for the current session
    NumOfTrials_per_session{numOfData} = session_counts;
    
    
    % Update total_NumOfTrials
    for i = 1:numel(ordered_fields)
        field_name = ordered_fields{i};
        if isfield(total_NumOfTrials, field_name)
            total_NumOfTrials.(field_name) = total_NumOfTrials.(field_name) + session_counts.(field_name);
        else
            total_NumOfTrials.(field_name) = session_counts.(field_name);
        end
    end
    
    
    
end

% Initialisation of variables for counting the total number of training and test data
totalNumOfTrials_training = 0;
totalNumOfTrials_test = 0;

% Dynamic summation of values for all training and test marks
for i = 1:numel(uniqueLabels)
    
    training_field = [uniqueLabels{i} '_training'];
    test_field = [uniqueLabels{i} '_test'];
    
    % Checking and adding a value for training data
    if isfield(total_NumOfTrials, training_field)
        totalNumOfTrials_training = totalNumOfTrials_training + total_NumOfTrials.(training_field);
    end
    
    % Checking and adding a value for test data
    if isfield(total_NumOfTrials, test_field)
        totalNumOfTrials_test = totalNumOfTrials_test + total_NumOfTrials.(test_field);
    end
end



%% Convert cell array to vector
block_numbers = cell2mat(binned_labels.block{1, 1});

% Obtaining unique values with preserving the order
[unique_blocks, idx] = unique(block_numbers, 'stable');

% Initialisation of variables
test_blocks = [];
training_blocks = [];

% Define the position of block 1 in unique_blocks
block1_index = find(unique_blocks == 1);

if block1_index == 1
    % Block 1 is the first, so it's a training block
    training_blocks = unique_blocks(1); % All blocks are training blocks
    test_blocks = unique_blocks(2:end); % No test blocks
else
    % Block 1 is not the first block, so it is a test block
    training_blocks = unique_blocks(1:end-1);
    test_blocks = unique_blocks(end); % Test block
end

% Forming a row for training blocks
data_for_plotting_averages.training_block = join(arrayfun(@(x) ['block_' num2str(x)], training_blocks, 'UniformOutput', false), '_');
data_for_plotting_averages.test_block = join(arrayfun(@(x) ['block_' num2str(x)], test_blocks, 'UniformOutput', false), '_');

%% Preparing for the plotting numOfTrials and numOfUnits

% Sum up the values in the cell array numOfUnits
numOfUnits_and_numOfTrials_info_training = sprintf('Num of Units: %s\nNum of Trials: %s\n', num2str(totalNumOfUnits), num2str(totalNumOfTrials_training));
numOfUnits_and_numOfTrials_info_test = sprintf('Num of Units: %s\nNum of Trials: %s\n', num2str(totalNumOfUnits), num2str(totalNumOfTrials_test));

% Display the label counts information
labelCountsInfo_test = '';
labelCountsInfo_training = '';

% Iterate over all possible label combinations and add information
for i = 1:2:numel(relevant_labels)-1
    % Combine labels in pairs like 'instr_R', 'instr_L', 'choice_R', etc.
    label_var = [relevant_labels{i} '_' relevant_labels{i+1}];
    
    % Check for the presence of this label in total_NumOfTrials
    if isfield(total_NumOfTrials, [label_var '_test'])
        labelCountsInfo_test = [labelCountsInfo_test, sprintf('\nNum of %s: %d', label_var, total_NumOfTrials.(sprintf('%s_test', label_var)))];
    end
    if isfield(total_NumOfTrials, [label_var '_training'])
        labelCountsInfo_training = [labelCountsInfo_training, sprintf('\nNum of %s: %d', label_var, total_NumOfTrials.(sprintf('%s_training', label_var)))];
    end
end

% Prepare final output data for plotting
data_for_plotting_averages.numOfUnits_and_numOfTrials_info_labelsAppears_training = [numOfUnits_and_numOfTrials_info_training, labelCountsInfo_training];
data_for_plotting_averages.numOfUnits_and_numOfTrials_info_labelsAppears_test = [numOfUnits_and_numOfTrials_info_test, labelCountsInfo_test];





%% location of the curve on the graph

% Concatenate mean decoding results from all days into one variable
mean_decoding_results = horzcat(all_mean_decoding_results{:});
data_for_plotting_averages.mean_decoding_results_100 = mean_decoding_results*100;
%  plot(mean_decoding_results_100)


% Calculate the total number of time points
numTimePoints = size(data_for_plotting_averages.mean_decoding_results_100, 1);
median_value = (numTimePoints + 1) / 2; % Median value

% Calculate the bin duration in milliseconds
step_size = loadedData.DECODING_RESULTS.DS_PARAMETERS.binned_site_info.binning_parameters.sampling_interval; % milliseconds

% Calculate the offset to center the graph around the median
offset = 500 - median_value * step_size;

% Generate the time values for each bin centered around the median
data_for_plotting_averages.timeValues_500 = (1:numTimePoints) * step_size + offset;
data_for_plotting_averages.timeValues_0 = data_for_plotting_averages.timeValues_500 - 500;


end


function plotingAveragesAcrossSessions(dateOfRecording, target_brain_structure, target_state, combinedLabel, data_for_plotting_averages, settings, OUTPUT_PATH_binned_data_for_saving, numOfData, curves_per_session)
%% Plot the results

if isequal(curves_per_session, 'Same')
    lightBlueColor = [0.5, 0.5, 1.0]; % RGB triplet representing a lighter shade of blue
    plot(timeValues, mean_decoding_results_100, 'LineWidth', 1, 'Color', lightBlueColor);
    
elseif isequal(curves_per_session, 'Color')
    %plot(timeValues, mean_decoding_results_100, 'LineWidth', 1);
    hold on;
    for i = 1:numel(data_for_plotting_averages.session_info)
        plot(data_for_plotting_averages.timeValues_0, data_for_plotting_averages.mean_decoding_results_100(:, i), 'LineWidth', 1, 'Color', data_for_plotting_averages.session_info(i).color_RGB);
    end
    hold off;
elseif isequal(curves_per_session, 'nis') % no individual session
    % plot without individual session labels
end


tickPositions = -500:200:500;
%tickPositions = 0:200:1000; % Calculate the tick positions every 200 ms
xticks(tickPositions);  % Set the tick positions on the X-axis

xlabel('Time (ms)', 'FontSize', 17); % Set the font size to 14 for the xlabel
ylabel('Classification Accuracy', 'FontSize', 18); % Set the font size to 14 for the ylabel


box off;  % Remove the box around the axes
ax = gca; % Display only the X and Y axes
ax.YAxis.Visible = 'on';  % Show Y-axis
ax.XAxis.Visible = 'on';  % Show X-axis

xline(0, 'LineWidth', 1); % Vertical line with thickness 1
yline(50, 'LineWidth', 1); % Horizontal line with thickness 1

% xline(0);
% xline(500); % draw a vertical line at 500
% yline(50); % draw a horizontal line at 50
settings.time_lim = [-500 500];
set(gca,'Xlim',settings.time_lim, 'Ylim',settings.y_lim); % limitation of the X (from 0 to 1000) and Y (from 20 to 100) axes

% change the size of the figure
set(gcf,'position',[490,400,930,710]) % [x0,y0,width,height]

%         % Add text using the annotation function
%         positionOfAnnotation = [0.76, 0.5, 0.26, 0.26]; % [x position, y position, size x, size y]
%         annotation('textbox', positionOfAnnotation, 'String', numOfUnits_and_numOfTrials_info_labelsAppears, ...
%             'FontSize', 10, 'HorizontalAlignment', 'left','FitBoxToText','on');
%         set(gca, 'Position', [0.1, 0.13, 0.65, 0.72] ) % change the position of the axes to fit the annotation into the figure too.




%% Create a title

% Extracting blocks from a cell
[block_info_training, block_info_test] = extractAndModifyBlocks(data_for_plotting_averages);

target_info = [target_brain_structure '; ' target_state];
VS_sign = ['Training: ' block_info_training ', Test: ' block_info_test];



[modifiedLabel1, modifiedLabel2] = modifyLabel(combinedLabel);

[t,s] = title(modifiedLabel2, target_info);
t.FontSize = 15;
s.FontSize = 12;


% Fixation of units of measurement in a coordinate system
set(t, 'Units', 'normalized');
set(s, 'Units', 'normalized');

% Setting fixed positions for title and sub-title
set(t, 'Position', [0.5, 1.16, 0]);
set(s, 'Position', [0.5, 1.12, 0]);



%% Create annotation

% Training
positionOfAnnotation = [0.78, 0.5, 0.26, 0.26]; % [x position, y position, size x, size y]
annotation('textbox', positionOfAnnotation, 'String', data_for_plotting_averages.numOfUnits_and_numOfTrials_info_labelsAppears_training, ...
    'FontSize', 12, 'HorizontalAlignment', 'left', 'FitBoxToText','on', 'Color', [0, 0, 0.8039]);

annotation('textbox', [0.78, 0.55, 0.26, 0.26], 'String', 'Training:', ...
    'FontSize', 13, 'EdgeColor', 'none', 'HorizontalAlignment', 'left');


% Test
positionOfAnnotation = [0.78, 0.2, 0.26, 0.26]; % [x position, y position, size x, size y]
annotation('textbox', positionOfAnnotation, 'String', data_for_plotting_averages.numOfUnits_and_numOfTrials_info_labelsAppears_test, ...
    'FontSize', 12, 'HorizontalAlignment', 'left', 'FitBoxToText','on', 'Color', [0, 0, 0.8039]);

annotation('textbox', [0.78, 0.25, 0.26, 0.26], 'String', 'Test:', ...
    'FontSize', 13, 'EdgeColor', 'none', 'HorizontalAlignment', 'left');


set(gca, 'Position', [0.1, 0.093, 0.65, 0.73] ) % change the position of the axes to fit the annotation into the figure too.



% Plot an annotation with information about the blocks
axPos = get(gca, 'Position');   % Dimensions of current axes
centerX = axPos(1) + axPos(3) / 2; % Find the centre of the horizontal and vertical axes
centerY = axPos(2) + axPos(4) / 2;

% annotation('textbox', [centerX - 0.23, centerY + 0.26, 0.2, 0.2], ... % [annotationPosX, annotationPosY, 0.1, 0.1]
%     'String', block_info_training, 'FontSize', 11, 'EdgeColor', 'none', 'HorizontalAlignment', 'center', 'Color', [0, 0, 0.8039]);

% annotation('textbox', [centerX + 0.05, centerY + 0.26, 0.2, 0.2], ...
%     'String', block_info_test, 'FontSize', 11, 'EdgeColor', 'none', 'HorizontalAlignment', 'center', 'Color', [0, 0, 0.8039]);

annotation('textbox', [centerX - 0.2 , centerY + 0.26, 0.4, 0.2], ...   % 'textbox', [x position, y position, size x, size y]
    'String', VS_sign, 'FontSize', 11, 'EdgeColor', 'none', 'HorizontalAlignment', 'center');




%% Setting of axes
ax = gca;
ax.XAxis.FontSize = 14; % Font size for X-axis labels
ax.YAxis.FontSize = 14; % Font size for Y-axis labels


% Shift Y-axis number signatures to the left (in this case, a positive value moves them away from the axis)
ax.YAxis.TickLabelInterpreter = 'none'; % Remove TeX interpretation (if it interferes)
ax.YAxis.TickLength = [0.02, 0.02]; % Setting the length of ticks (divisions)

% Visual indentation for numbers (TickLabels) on the Y axis
ax.YRuler.TickLabelGapOffset = 19;  % Setting the indentation of numbers on the Y-axis from the axis itself

% Setting axis captions and axis dimensions
xlabel('Time (ms)', 'FontSize', 19);
ylabel('Classification Accuracy', 'FontSize', 19);




% Draw annotation window only on the last iteration
if numOfData == numel(dateOfRecording)
    
    
    if isequal(curves_per_session, 'Color')
        % Label each line with the session name
        % colorOrder = get(gca, 'ColorOrder');
        xPosition = data_for_plotting_averages.timeValues_0(1);  % X position for the annotations (same for all)
        yPosition = 100 - 4*(numel(dateOfRecording)-1) : 4 : 100;  % Y positions for the annotations (spaced vertically)
        
        for i = numel(data_for_plotting_averages.session_info):-1:1
            %lineColor = colorOrder(rem(i - 1, size(colorOrder, 1)) + 1, :);
            session_name = data_for_plotting_averages.session_info(i).name;
            lineColor = data_for_plotting_averages.session_info(i).color_RGB;  % Get session color from session_info
            
            % Convert RGB values to ColorSpec string
            colorSpec = ['Color[', num2str(lineColor), ']'];
            
            %             text(xPosition, yPosition(i), dateOfRecording{i}, ...
            %                 'Color', lineColor, 'FontSize', 10, 'HorizontalAlignment', 'left');
            
            % Place the session name and color in the text
            text(xPosition, yPosition(numel(dateOfRecording) - i + 1), session_name, ...
                'Interpreter', 'tex', ...  % Enable LaTeX interpreter
                'Color', lineColor, ...    % Set text color
                'FontSize', 10, ...
                'FontWeight', 'bold', ...  % Make text bold
                'VerticalAlignment', 'top');  % Align text to the top
        end
    end
    
    
    
    
    
    
    % Modernisation of the basic file name using an existing file name
    meanResultsFilename = generateMeanFilename(data_for_plotting_averages.decodingResultsFilename); % Remove "_DECODING_RESULTS".
    
    
    %% Perform Wilcoxon Signed-Rank Test
    % Null hypothesis - there is no statistically significant difference between the before and after inactivation data
    % A small p-value (typically ≤ 0.05) suggests that the differences are statistically significant
    % h = 0: Fail to reject the null hypothesis, indicating that there is no statistically significant difference between the before and after inactivation data.
    % h = 1: Reject the null hypothesis, indicating that there is a statistically significant difference between the before and after inactivation data
 %   [p_crit_Wilcoxon] = perform_wilcoxon_test(data_for_plotting_averages.mean_decoding_results_100, data_for_plotting_averages.timeValues_0, meanResultsFilename, OUTPUT_PATH_binned_data_for_saving);
    
    
    % test_Wilcoxon_annotation = ['Wilcoxon (p = 0.05),'];
%     test_Wilcoxon_annotation = sprintf('Wilcoxon (* - p<%.2f),', p_crit_Wilcoxon);
%     annotation('textbox', [centerX - 0.1, centerY + 0.23, 0.2, 0.2], ...
%         'String', test_Wilcoxon_annotation, 'FontSize', 11, 'EdgeColor', 'none', 'HorizontalAlignment', 'center');
    
    
    %% Perform cluster-based permutation test
    % [clusters, p_values, t_sums, permutation_distribution ] = permutest( decoding_before, decoding_after, 1, 0.05, 500);
    
    num_permutations = 500; % Количество перестановок
    [p_crit_permutation] = perform_one_sample_permutation_test(data_for_plotting_averages.mean_decoding_results_100, num_permutations);
    
    % test_Perut_annotation = sprintf('Permutest (* - p<%.2f)', p_crit_permutation);
    % annotation('textbox', [centerX - 0.01, centerY + 0.22, 0.2, 0.2], ...
    %     'String', test_Perut_annotation, 'FontSize', 10, 'EdgeColor', 'none', 'HorizontalAlignment', 'center', 'Color', [0.2, 0.6, 0.2]);
    
    
    
    %% Plotting the average curve
    
    % Calculate the average dynamics by day
    average_dynamics_by_day = mean(data_for_plotting_averages.mean_decoding_results_100, 2);
    
    % Calculate the standard error of the mean (SEM)
    sem = std(data_for_plotting_averages.mean_decoding_results_100, 0, 2) / sqrt(size(data_for_plotting_averages.mean_decoding_results_100, 2));
    
    % Define a darker shade of blue
    darkBlueColor = [0, 0, 0.5];
    
    % Plot the average dynamics with error bars on the same figure
    hold on; % Add the new plot to the existing one
    %             plot_average_dynamics = errorbar(timeValues, average_dynamics_by_day, sem, 'LineWidth', 2, 'Color', darkBlueColor); % Use a thicker line and blue color for the average dynamics with error bars
    %             plot_average_dynamics.LineWidth = 1;
    [hp1 hp2] =  ig_errorband(data_for_plotting_averages.timeValues_0, average_dynamics_by_day, sem, 0);
    hp1.Color = [0, 0, 0.5]; % darkBlueColor
    hp2.FaceColor = [0, 0, 0.5]; % darkBlueColor
    
    plot(data_for_plotting_averages.timeValues_0, average_dynamics_by_day, 'LineWidth', 3, 'Color', darkBlueColor);
    hold off;
    
    session_info_combined_for_text_Num_CV_Splits = strjoin(data_for_plotting_averages.session_info_combined, '\n');
    
    
    
    
    %% Saving
    % Save the session information to a text file
    name_of_txt_Num_CV_Splits = ['Sessions_Num_CV_Splits_Info_' meanResultsFilename(21:end-4) '.txt'];
    sessionInfoFilePath_Num_CV_Splits = fullfile(OUTPUT_PATH_binned_data_for_saving, name_of_txt_Num_CV_Splits);
    fid = fopen(sessionInfoFilePath_Num_CV_Splits, 'w');
    fprintf(fid, session_info_combined_for_text_Num_CV_Splits);
    fclose(fid);
    
    
    
    
    % Making up an ending to the name of the picture depending on the colour of the curve
    if isequal(curves_per_session, 'Color')
        Color_curves_name = '_Color';
    elseif isequal(curves_per_session, 'Same')
        Color_curves_name = '';
    elseif isequal(curves_per_session, 'nis') % no individual session
        Color_curves_name = '_nis';
    end
    
    
    % Save the pic
    path_name_to_save = fullfile (OUTPUT_PATH_binned_data_for_saving,[meanResultsFilename(1:end-4) '_AverageDynamics' Color_curves_name '_Stat_0.png']);
    saveas(gcf, path_name_to_save);
    
    close(gcf);
end

end



function plotingCombinedAveragesAcrossSessions(dateOfRecording, target_brain_structure, target_state, combinedLabel, data_for_plotting_averages_before, data_for_plotting_averages_after, settings, OUTPUT_PATH_binned_data_for_saving, numOfData_before, numOfData_after, curves_per_session);
%% Plot the results

% Define a colormap for the sessions before inactivation
% RGB palette for 7 shades of blue
bluePalette = [
    0.2549, 0.4118, 0.8824;  % Royal Blue
    0.1176, 0.5647, 1;  % Dodger Blue
    0, 0.7490, 1;  % Deep Sky Blue
    0.3922, 0.5843, 0.9294;  % Cornflower Blue
    0.2745, 0.5098, 0.7059;  % Steel Blue
    0.5294, 0.8078, 0.9216;  % Sky Blue
    0.6902, 0.7686, 0.8706;  % Light Steel Blue
    ];


session_colors_Appearance_Blue = {
    'Royal Blue';     % Royal Blue for the first session
    'Dodger Blue';  % Dodger Blue for the second session
    'Deep Sky Blue';  % Deep Sky Blue for the third session
    'Cornflower Blue';   % Cornflower Blue for the fourth session
    'Steel Blue';    % Steel Blue for the fifth session
    'Sky Blue';    % Sky Blue for the sixth session
    'Light Steel Blue';  % Light Steel Blue for the seventh session
    };

% Updating session_info for data_for_plotting_averages_before
numSessionsBefore = numel(data_for_plotting_averages_before.session_info);
for b = 1:numSessionsBefore
    if b <= size(bluePalette, 1)
        % Update RGB values from the blue palette
        data_for_plotting_averages_before.session_info(b).color_RGB = bluePalette(b, :);
        data_for_plotting_averages_before.session_info(b).color_appearance = session_colors_Appearance_Blue(b, :);
    else
        % If blue palette is not enough for all sessions, use the last color of the palette
        data_for_plotting_averages_before.session_info(b).color_RGB = bluePalette(end, :);
        data_for_plotting_averages_before.session_info(b).color_appearance = session_colors_Appearance_Blue(end, :);
    end
end

% Define a colormap for the sessions
% RGB palette for 7 shades of red
redPalette = [
    0.9804, 0.5020, 0.4471;  % Salmon
    0.9412, 0.5020, 0.5020;  % Light Coral
    0.8039, 0.3608, 0.3608;  % Indian Red
    1.0000, 0.3882, 0.2784;  % Tomato
    1.0000, 0.4980, 0.3137;  % Coral
    1.0000, 0.6275, 0.4784;  % Light Salmon
    0.9137, 0.5882, 0.4784;  % Dark Salmon
    ];

session_colors_Appearance_Red = {
    'Salmon';     % Red for the first session
    'Light Coral';  % Orange for the second session
    'Indian Red';  % Yellow for the third session
    'Tomato';   % Green for the fourth session
    'Coral';    % Cyan for the fifth session
    'Light Salmon';    % Blue for the sixth session
    'Dark Salmon';  % Violet for the seventh session
    };


% Get the number of sessions for data_for_plotting_averages_after
numSessionsAfter = numel(data_for_plotting_averages_after.session_info);

% Replacing RGB values with values from the red palette
for r = 1:numSessionsAfter
    if r <= size(redPalette, 1)
        % Replacing RGB values from the red palette
        data_for_plotting_averages_after.session_info(r).color_RGB = redPalette(r, :);
        data_for_plotting_averages_after.session_info(r).color_appearance = session_colors_Appearance_Red(r, :);
    else
        % If there is not enough red palette for all sessions, use the last colour of the palette
        data_for_plotting_averages_after.session_info(r).color_RGB = redPalette(end, :);
        data_for_plotting_averages_after.session_info(r).color_appearance = session_colors_Appearance_Red(end, :);
    end
end



if isequal(curves_per_session, 'Same')
    
    hold on
    
    % before inactivation
    numSessionsBefore = size(data_for_plotting_averages_before.mean_decoding_results_100, 2); % Determination of shades of blue
    blueShades = linspace(0.8, 1, numSessionsBefore); % gradient from darker to lighter colour
    %     plot(data_for_plotting_averages_before.timeValues, data_for_plotting_averages_before.mean_decoding_results_100, ...
    %     'LineWidth', 1, 'Color', [0, 0, 1]); % RGB triplet for blue
    
    for i = 1:numSessionsBefore
        plot(data_for_plotting_averages_before.timeValues, data_for_plotting_averages_before.mean_decoding_results_100(:, i), ...
            'LineWidth', 1, 'Color', [0, 0.4470, blueShades(i)]);
    end
    
    
    % after inactivation
    numSessionsAfter = size(data_for_plotting_averages_after.mean_decoding_results_100, 2); % Determination of shades of red
    redShades = linspace(0.8, 1, numSessionsAfter); % gradient from darker to lighter colour
    
    % plot(data_for_plotting_averages_after.timeValues, data_for_plotting_averages_after.mean_decoding_results_100, ...
    %     'LineWidth', 1, 'Color', [1, 0, 0]); % RGB triplet for red
    
    for i = 1:numSessionsAfter
        plot(data_for_plotting_averages_after.timeValues, data_for_plotting_averages_after.mean_decoding_results_100(:, i), ...
            'LineWidth', 1, 'Color', [redShades(i), 0.0780, 0.1840]);
    end
    
    hold off
    
elseif isequal(curves_per_session, 'Color')
    
    % Plotting before inactivation
    hold on;
    numSessionsBefore = numel(data_for_plotting_averages_before.session_info);
    for i = 1:numSessionsBefore
        plot(data_for_plotting_averages_before.timeValues, data_for_plotting_averages_before.mean_decoding_results_100(:, i), ...
            'LineWidth', 1, 'Color', data_for_plotting_averages_before.session_info(i).color_RGB);
    end
    
    % Plotting after inactivation
    numSessionsAfter = numel(data_for_plotting_averages_after.session_info);
    for i = 1:numSessionsAfter
        plot(data_for_plotting_averages_after.timeValues, data_for_plotting_averages_after.mean_decoding_results_100(:, i), ...
            'LineWidth', 1, 'Color', data_for_plotting_averages_after.session_info(i).color_RGB);
    end
    
    hold off;
    
    
    
elseif isequal(curves_per_session, 'nis') % no individual session
    % plot without individual session labels
end



tickPositions = 0:200:1000; % Calculate the tick positions every 200 ms
xticks(tickPositions);  % Set the tick positions on the X-axis

xlabel('Time (ms)', 'FontSize', 30); % Set the font size to 14 for the xlabel
ylabel('Classification Accuracy', 'FontSize', 35); % Set the font size to 14 for the ylabel


box off;  % Remove the box around the axes
ax = gca; % Display only the X and Y axes
ax.YAxis.Visible = 'on';  % Show Y-axis
ax.XAxis.Visible = 'on';  % Show X-axis

ax.FontSize = 12; % Set the font size for the axis tick labels

xline(500); % draw a vertical line at 500
yline(50); % draw a horizontal line at 50
set(gca,'Xlim',settings.time_lim, 'Ylim',settings.y_lim); % limitation of the X (from 0 to 1000) and Y (from 20 to 100) axes

% change the size of the figure
set(gcf,'position',[450,400,800,650]) % [x0,y0,width,height]

%         % Add text using the annotation function
%         positionOfAnnotation = [0.76, 0.5, 0.26, 0.26]; % [x position, y position, size x, size y]
%         annotation('textbox', positionOfAnnotation, 'String', numOfUnits_and_numOfTrials_info_labelsAppears, ...
%             'FontSize', 10, 'HorizontalAlignment', 'left','FitBoxToText','on');
%         set(gca, 'Position', [0.1, 0.13, 0.65, 0.72] ) % change the position of the axes to fit the annotation into the figure too.

% create a title
block_info_before = char(regexp(data_for_plotting_averages_before.decodingResultsFilePath, 'block_\d+', 'match'));
block_info_after = char(regexp(data_for_plotting_averages_after.decodingResultsFilePath, 'block_\d+', 'match'));

% Reshape the character array into a single row
block_info_combined_before = reshape(block_info_before.', 1, []);
block_info_combined_after = reshape(block_info_after.', 1, []);


target_info = [target_brain_structure '; ' target_state];
block_info_before = [block_info_combined_before];
VS_sign = [' vs '];
block_info_after = [block_info_combined_after];





combinedLabel_for_Title = rearrangeCombinedLabel(combinedLabel);

%[t,s] = title(combinedLabel_for_Title, {target_info; block_info});
[t, s] = title(combinedLabel_for_Title, target_info);
t.FontSize = 14;
s.FontSize = 11;




drawnow; % Ensure the title position is updated





% Change title position
%Increase the vertical position of the combinedLabel_for_Title
titlePos = get(t, 'Position');
titlePos(2) = titlePos(2) + 10; % Increase the vertical position by 5
set(t, 'Position', titlePos);

% Increase the vertical position of the target_info
sPos = get(s, 'Position');
sPos(2) = sPos(2) + 10; % Increase the vertical position by 5
set(s, 'Position', sPos);







% Draw annotation window only on the last iteration
%if numOfData == numel(dateOfRecording)

% Before inactivation
positionOfAnnotation = [0.76, 0.5, 0.26, 0.26]; % [x position, y position, size x, size y]
annotation('textbox', positionOfAnnotation, 'String', data_for_plotting_averages_before.numOfUnits_and_numOfTrials_info_labelsAppears, ...
    'FontSize', 12, 'HorizontalAlignment', 'left', 'FitBoxToText','on', 'Color', [0, 0, 0.8039]);



% After inactivation
positionOfAnnotation = [0.76, 0.2, 0.26, 0.26]; % [x position, y position, size x, size y]
annotation('textbox', positionOfAnnotation, 'String', data_for_plotting_averages_after.numOfUnits_and_numOfTrials_info_labelsAppears, ...
    'FontSize', 12, 'HorizontalAlignment', 'left', 'FitBoxToText','on', 'Color', [0.8627, 0.0784, 0.2353]);


set(gca, 'Position', [0.1, 0.09, 0.65, 0.72] ) % change the position of the axes to fit the annotation into the figure too.




% Plot an annotation with information about the blocks
axPos = get(gca, 'Position');   % Dimensions of current axes
centerX = axPos(1) + axPos(3) / 2; % Find the centre of the horizontal and vertical axes
centerY = axPos(2) + axPos(4) / 2;

annotation('textbox', [centerX - 0.23, centerY + 0.26, 0.2, 0.2], ... % [annotationPosX, annotationPosY, 0.1, 0.1]
    'String', block_info_before, 'FontSize', 11, 'EdgeColor', 'none', 'HorizontalAlignment', 'center', 'Color', [0, 0, 0.8039]);

annotation('textbox', [centerX + 0.05, centerY + 0.26, 0.2, 0.2], ...
    'String', block_info_after, 'FontSize', 11, 'EdgeColor', 'none', 'HorizontalAlignment', 'center', 'Color', [0.8627, 0.0784, 0.2353]);

annotation('textbox', [centerX - 0.1 , centerY + 0.26, 0.2, 0.2], ...
    'String', VS_sign, 'FontSize', 11, 'EdgeColor', 'none', 'HorizontalAlignment', 'center');



% Plot an annotation with information about munber of sessions
numOfSessions_before = size(data_for_plotting_averages_before.session_info,2);
numOfSessions_after = size(data_for_plotting_averages_after.session_info,2);

numOfSessions_before_annotation = sprintf('Num of Sessions: %d', numOfSessions_before);
numOfSessions_after_annotation = sprintf('Num of Sessions: %d', numOfSessions_after);

annotation('textbox', [centerX - 0.28, centerY + 0.31, 0.2, 0.2], ... % [annotationPosX, annotationPosY, 0.1, 0.1]
    'String', numOfSessions_before_annotation, 'FontSize', 11, 'EdgeColor', 'none', 'HorizontalAlignment', 'center', 'Color', [0, 0, 0.8039]);

annotation('textbox', [centerX + 0.08, centerY + 0.31, 0.2, 0.2], ...
    'String', numOfSessions_after_annotation, 'FontSize', 11, 'EdgeColor', 'none', 'HorizontalAlignment', 'center', 'Color', [0.8627, 0.0784, 0.2353]);





% plotting session names on the graph
session_info_before = {data_for_plotting_averages_before.session_info.name};
session_info_after = {data_for_plotting_averages_after.session_info.name};
combined_session_info = union(session_info_before, session_info_after, 'stable'); combined_session_info = combined_session_info';

if isequal(curves_per_session, 'Color')
    % Label each line with the session name
    % colorOrder = get(gca, 'ColorOrder');
    xPosition = data_for_plotting_averages_before.timeValues(1);  % X position for the annotations (same for all)
    yPosition = 100 - 4*(numel(combined_session_info)-1) : 4 : 100;  % Y positions for the annotations (spaced vertically)
    
    for i = numel(combined_session_info):-1:1
        
        session_name = combined_session_info{i};
        
        text(xPosition, yPosition(numel(combined_session_info) - i + 1), session_name, ...
            'Interpreter', 'none', ...  % Disable interpreter to avoid processing special characters
            'Color', 'k', ...    % Set text color to black
            'FontSize', 9, ...
            'VerticalAlignment', 'top');  % Align text to the top
    end
end



%% creating a universal name for the output file

% Modernisation of the basic file name using an existing file name
meanResultsFilename_before = generateMeanFilename(data_for_plotting_averages_before.decodingResultsFilename); % Remove "_DECODING_RESULTS".
meanResultsFilename_after = generateMeanFilename(data_for_plotting_averages_after.decodingResultsFilename);


% Find differences in the filenames
[diff_1, diff_2, common_prefix, common_suffix] = find_filename_differences(meanResultsFilename_before, meanResultsFilename_after);

% Create the name of the output file
basicNameForOutputFile = [common_prefix diff_1 '_and_' diff_2 common_suffix(1:end-4)];
basicNameForOutputFile = [basicNameForOutputFile, '_same_cv'];
%output_file_Statistical_results = [output_folder common_prefix diff_1 '_and_' diff_2 common_suffix '_Wilcoxon_Signed-Rank_Test.txt'];


%% Perform Wilcoxon Signed-Rank Test
% Null hypothesis (H₀): The difference between paired samples X and Y has a median equal to zero. In other words, it states that there is no significant difference between the two samples X and Y.
% Alternative hypothesis (H₁): The difference between paired samples X and Y has a median different from zero. That is, there is a significant difference between the two samples X and Y.

% A small p-value (typically ≤ 0.05) suggests that the differences are statistically significant
% h = 0: Fail to reject the null hypothesis, indicating that there is no statistically significant difference between the before and after inactivation data.
% h = 1: Reject the null hypothesis, indicating that there is a statistically significant difference between the before and after inactivation data
[p_crit_Wilcoxon] = perform_paired_wilcoxon_test(data_for_plotting_averages_before.mean_decoding_results_100, data_for_plotting_averages_after.mean_decoding_results_100, data_for_plotting_averages_before.timeValues, basicNameForOutputFile, OUTPUT_PATH_binned_data_for_saving);

% test_Wilcoxon_annotation = ['Wilcoxon (p = 0.05),'];
test_Wilcoxon_annotation = sprintf('Wilcoxon (* - p<%.2f),', p_crit_Wilcoxon);
annotation('textbox', [centerX - 0.18, centerY + 0.22, 0.2, 0.2], ...
    'String', test_Wilcoxon_annotation, 'FontSize', 10, 'EdgeColor', 'none', 'HorizontalAlignment', 'center');


%% Perform cluster-based permutation test
% [clusters, p_values, t_sums, permutation_distribution ] = permutest( decoding_before, decoding_after, 1, 0.05, 500);


[p_crit_permutation] = perform_permutation_test(data_for_plotting_averages_before.mean_decoding_results_100, data_for_plotting_averages_after.mean_decoding_results_100, data_for_plotting_averages_before.timeValues, basicNameForOutputFile, OUTPUT_PATH_binned_data_for_saving)

%test_Perut_annotation = ['Permutest (p = 0.05)'];
test_Perut_annotation = sprintf('Permutest (* - p<%.2f)', p_crit_permutation);
annotation('textbox', [centerX - 0.01, centerY + 0.22, 0.2, 0.2], ...
    'String', test_Perut_annotation, 'FontSize', 10, 'EdgeColor', 'none', 'HorizontalAlignment', 'center', 'Color', [0.2, 0.6, 0.2]);

%% Plotting the average curve

% Calculate the average dynamics by day
average_dynamics_by_day_before = mean(data_for_plotting_averages_before.mean_decoding_results_100, 2);
average_dynamics_by_day_after = mean(data_for_plotting_averages_after.mean_decoding_results_100, 2);

% Calculate the standard error of the mean (SEM)
sem_before = std(data_for_plotting_averages_before.mean_decoding_results_100, 0, 2) / sqrt(size(data_for_plotting_averages_before.mean_decoding_results_100, 2));
sem_after = std(data_for_plotting_averages_after.mean_decoding_results_100, 0, 2) / sqrt(size(data_for_plotting_averages_after.mean_decoding_results_100, 2));



darkBlueColor = [0, 0, 0.5]; % Define a darker shade of blue
darkRedColor = [0.6350 0.0780 0.1840];


% Plot the average dynamics with error bars on the same figure
hold on; % Add the new plot to the existing one
%             plot_average_dynamics = errorbar(timeValues, average_dynamics_by_day, sem, 'LineWidth', 2, 'Color', darkBlueColor); % Use a thicker line and blue color for the average dynamics with error bars
%             plot_average_dynamics.LineWidth = 1;
[hp1_bef, hp2_bef] =  ig_errorband(data_for_plotting_averages_before.timeValues, average_dynamics_by_day_before, sem_before, 0);
hp1_bef.Color = [0, 0, 0.5]; % darkBlueColor
hp2_bef.FaceColor = [0, 0, 0.5]; % darkBlueColor

[hp1_aft hp2_aft] =  ig_errorband(data_for_plotting_averages_after.timeValues, average_dynamics_by_day_after, sem_after, 0);
hp1_aft.Color = [0.6350 0.0780 0.1840]; % darkRedColor
hp2_aft.FaceColor = [0.6350 0.0780 0.1840]; % darkRedColor

plot(data_for_plotting_averages_before.timeValues, average_dynamics_by_day_before, 'LineWidth', 3, 'Color', darkBlueColor);
plot(data_for_plotting_averages_after.timeValues, average_dynamics_by_day_after, 'LineWidth', 3, 'Color', darkRedColor);
hold off;

session_info_combined_for_text_Num_CV_Splits_before = strjoin(data_for_plotting_averages_before.session_info_combined, '\n');
session_info_combined_for_text_Num_CV_Splits_after = strjoin(data_for_plotting_averages_after.session_info_combined, '\n');

drawnow;

%% Saving
% Save the session information to a text file
name_of_txt_Num_CV_Splits = ['Sessions_Num_CV_Splits_Info_' basicNameForOutputFile '.txt'];
sessionInfoFilePath_Num_CV_Splits = fullfile(OUTPUT_PATH_binned_data_for_saving, name_of_txt_Num_CV_Splits);
fid = fopen(sessionInfoFilePath_Num_CV_Splits, 'w');
fprintf(fid, '%s:\n', block_info_before);
fprintf(fid, '\n');
fprintf(fid, '%s\n', session_info_combined_for_text_Num_CV_Splits_before);
fprintf(fid, '\n');
fprintf(fid, '%s:\n', block_info_after);
fprintf(fid, '\n');
fprintf(fid, '%s\n', session_info_combined_for_text_Num_CV_Splits_after);
fclose(fid);




% Making up an ending to the name of the picture depending on the colour of the curve
if isequal(curves_per_session, 'Color')
    Color_curves_name = '_Color';
elseif isequal(curves_per_session, 'Same')
    Color_curves_name = '';
elseif isequal(curves_per_session, 'nis') % no individual session
    Color_curves_name = '_nis';
end


% Save the pic
path_name_to_save = fullfile (OUTPUT_PATH_binned_data_for_saving,[basicNameForOutputFile '_AverageDynamics' Color_curves_name '_Stat.png']);
saveas(gcf, path_name_to_save);

close(gcf);
%end

end


function combinedLabel = combine_label_segments(labelSegments)
% Combine segments 1 and 2, and segments 3 and 4
combinedSegments = {strjoin(labelSegments(1:2), '_'), strjoin(labelSegments(3:4), '_')};
combinedLabel = strjoin(combinedSegments, ' '); % Join the combined segments with a space
end

function combinedLabel_for_Title = rearrangeCombinedLabel(combinedLabel)
% Split the combinedLabel string into individual labels
labels = strsplit(combinedLabel, ' ');
sortedLabels = sort(labels); % Sort the labels alphabetically
combinedLabel_for_Title = strjoin(sortedLabels, ' '); % Concatenate the sorted labels into a single string
end

function meanResultsFilename = generateMeanFilename(decodingResultsFilename)
% Extract filename parts
[~, filename, ext] = fileparts(decodingResultsFilename);
parts = strsplit(filename, '_');

% Remove parts related to decoding results
parts_to_keep = parts(~contains(parts, {'DECODING', 'RESULTS'}));

% Replace NDT with MEAN
parts = strrep(parts_to_keep, 'NDT', 'MEAN');

% Construct new filename
meanResultsFilename = strjoin(parts, '_');
meanResultsFilename = [meanResultsFilename, ext];
end


function [p_crit] = perform_wilcoxon_test(mean_decoding_results_100, timeValues, meanResultsFilename, OUTPUT_PATH_binned_data_for_saving)
% Perform Wilcoxon Signed-Rank Test
% Input:
%   - mean_decoding_results_100: Matrix of mean decoding results
%   - timeValues: Time values corresponding to each bin
%   - meanResultsFilename: Filename for saving results
%   - OUTPUT_PATH_binned_data_for_saving: Output path for saving files

% Output:
%    returns the p-value of a two-sided Wilcoxon signed rank test

p_crit = 0.05;

% Initialize arrays to store p-values and test statistics
p_values = zeros(size(mean_decoding_results_100, 1), 1);
stats = zeros(size(mean_decoding_results_100, 1), 1);

% Loop through each bin (row) and perform the signrank test
for binIndex = 1:size(mean_decoding_results_100, 1)
    % Extract the values for the current bin across all sessions
    currentBinValues = mean_decoding_results_100(binIndex, :);
    
    % Perform the signrank test
    [p_values(binIndex), h, stat] = signrank(currentBinValues);
    
    % Store the test statistics (signed rank sum)
    stats(binIndex) = stat.signedrank;
end

% Plot asterisks for significant p-values
% hold on;
% for binIndex = 1:size(mean_decoding_results_100, 1)
%     if p_values(binIndex) < 0.05
%         % Find the y position (above the highest point in the bin)
%         yMax = max(mean_decoding_results_100(binIndex, :));
%         % Add a small offset for the asterisk position
%         yAsterisk = yMax + 2;
%         xAsterisk = timeValues(binIndex); % X position corresponding to the bin
%         text(xAsterisk, yAsterisk, '*', 'Color', 'k', 'FontSize', 14, 'HorizontalAlignment', 'center');
%     end
% end
% hold off;

% Plot asterisks for significant p-values
hold on;
for binIndex = 1:size(mean_decoding_results_100, 1)
    if p_values(binIndex) < p_crit
        
        % Find the y position (above the highest point in the bin)
        yMax = max(mean_decoding_results_100(binIndex, :));
        yMin = min(mean_decoding_results_100(binIndex, :));
        
        % Add a small offset for the asterisk position
        %yAsterisk = yMax + 2;
        %if yMin > 45
        yAsterisk = 42;
        % else
        % yAsterisk = yMin - 3;
        % end
        
        xAsterisk = timeValues(binIndex); % X position corresponding to the bin
        text(xAsterisk, yAsterisk, '*', 'Color', 'k', 'FontSize', 23, 'HorizontalAlignment', 'center');
    end
end
hold off;

% Save the results of Wilcoxon to a text file
name_of_txt_Statistics_Wilcoxon = ['Statistics_Wilcoxon_Splits_Info_' meanResultsFilename(1:end-4) '.txt'];
sessionInfoFilePath_Statistics_Wilcoxon = fullfile(OUTPUT_PATH_binned_data_for_saving, name_of_txt_Statistics_Wilcoxon);
fileID = fopen(sessionInfoFilePath_Statistics_Wilcoxon, 'w');

fprintf(fileID, 'Wilcoxon Signed-Rank Test result:\n');
fprintf(fileID, '\nh = %d (0: fail to reject null, 1: reject null)\n', h);

if h == 0 % Interpretation
    fprintf(fileID, 'Interpretation: Fail to reject the null hypothesis: No significant difference between the paired samples.\n');
else
    fprintf(fileID, 'Interpretation: Reject the null hypothesis: Significant difference between the paired samples.\n');
end

fprintf(fileID, '\nP-values for each bin:\n');
fprintf(fileID, '%.4f\n', p_values);

fprintf(fileID, '\nTest statistics (W) for each bin:\n');
fprintf(fileID, '%.4f\n', stats);

fclose(fileID);
end


function [p_value] = perform_one_sample_permutation_test(data, num_permutations, hypothesized_median)
% Set default hypothesized median if not provided
if nargin < 3
    hypothesized_median = 0; % Default to testing if median is zero
end

% Calculate observed test statistic (e.g., mean deviation from hypothesized median)
observed_statistic = sum(data - hypothesized_median);

% Initialize count for how often permuted statistics exceed the observed statistic
exceed_count = 0;

% Run permutations
for i = 1:num_permutations
    % Randomly flip signs of the data
    permuted_data = data .* (2 * (rand(size(data)) > 0.5) - 1);
    
    % Calculate test statistic for permuted data
    permuted_statistic = sum(permuted_data - hypothesized_median);
    
    % Count if permuted statistic exceeds or equals observed statistic
    if abs(permuted_statistic) >= abs(observed_statistic)
        exceed_count = exceed_count + 1;
    end
end

% Calculate p-value as the proportion of permuted statistics that exceed the observed statistic
p_value = exceed_count / num_permutations;
end




function [diff_1, diff_2, common_prefix, common_suffix] = find_filename_differences(filename_prefix_1, filename_prefix_2)
% Split the filenames into parts
parts_1 = strsplit(filename_prefix_1, '_');
parts_2 = strsplit(filename_prefix_2, '_');

% Initialize variables to store the common prefix and suffix
common_prefix = '';
common_suffix = '';

% Find the common prefix
i = 1;
while i <= min(length(parts_1), length(parts_2)) && strcmp(parts_1{i}, parts_2{i})
    common_prefix = [common_prefix, parts_1{i}, '_'];
    i = i + 1;
end

% Find the common suffix
j = 1;
while j <= min(length(parts_1), length(parts_2)) && strcmp(parts_1{end - j + 1}, parts_2{end - j + 1})
    common_suffix = ['_', parts_1{end - j + 1}, common_suffix];
    j = j + 1;
end

% Isolate the different parts
diff_1 = strjoin(parts_1(i:end-j+1), '_');
diff_2 = strjoin(parts_2(i:end-j+1), '_');

% Add 'block' prefix if not already present
%     if ~startsWith(diff_1, 'block')
%         diff_1 = ['block_', diff_1];
%     end
if ~startsWith(diff_2, 'block')
    diff_2 = ['block_', diff_2];
end

% Remove any leading or trailing underscores
if ~isempty(diff_1) && diff_1(1) == '_'
    diff_1 = diff_1(2:end);
end
if ~isempty(diff_2) && diff_2(1) == '_'
    diff_2 = diff_2(2:end);
end
if ~isempty(diff_1) && diff_1(end) == '_'
    diff_1 = diff_1(1:end-1);
end
if ~isempty(diff_2) && diff_2(end) == '_'
    diff_2 = diff_2(1:end-1);
end
end



function [p_crit]= perform_paired_wilcoxon_test (mean_decoding_results_100_before, mean_decoding_results_100_after, timeValues, meanResultsFilename, OUTPUT_PATH_binned_data_for_saving)

% Perform Wilcoxon Signed-Rank Test
% Input:
%   - mean_decoding_results_100: Matrix of mean decoding results
%   - timeValues: Time values corresponding to each bin
%   - meanResultsFilename: Filename for saving results
%   - OUTPUT_PATH_binned_data_for_saving: Output path for saving files

% Output:
%     returns the p-value of a paired, two-sided test for the null hypothesis that x – y comes from a distribution with zero median

p_crit = 0.05;

% Initialize arrays to store p-values and test statistics
p_values = zeros(size(mean_decoding_results_100_before, 1), 1);
stats = zeros(size(mean_decoding_results_100_before, 1), 1);

% Loop through each bin (row) and perform the signrank test
for binIndex = 1:size(mean_decoding_results_100_before, 1)
    % Extract the values for the current bin across all sessions
    currentBinValues_before = mean_decoding_results_100_before(binIndex, :);
    currentBinValues_after = mean_decoding_results_100_after(binIndex, :);
    
    % Perform the signrank test
    [p_values(binIndex), h, stat] = signrank(currentBinValues_before, currentBinValues_after);
    
    % Store the test statistics (signed rank sum)
    stats(binIndex) = stat.signedrank;
end

% Plot asterisks for significant p-values
hold on;
for binIndex = 1:size(mean_decoding_results_100_before, 1)
    if p_values(binIndex) < p_crit
        
        % Find the y position (above the highest point in the bin)
        yMax_bef = max(mean_decoding_results_100_before(binIndex, :));
        yMax_aft = max(mean_decoding_results_100_after(binIndex, :));
        yMax = max(yMax_bef, yMax_aft);
        
        yMin_bef = min(mean_decoding_results_100_before(binIndex, :));
        yMin_aft = min(mean_decoding_results_100_after(binIndex, :));
        yMin = max(yMin_bef, yMin_aft);
        
        % Add a small offset for the asterisk position
        %yAsterisk = yMax + 2;
        if yMin > 45
            yAsterisk = 44;
        else
            yAsterisk = yMin - 2;
        end
        
        xAsterisk = timeValues(binIndex); % X position corresponding to the bin
        text(xAsterisk, yAsterisk, '*', 'Color', 'k', 'FontSize', 23, 'HorizontalAlignment', 'center');
    end
end
hold off;

% Save the results of Wilcoxon to a text file
name_of_txt_Statistics_Wilcoxon = ['Statistics_Wilcoxon_Splits_Info_' meanResultsFilename '.txt'];
sessionInfoFilePath_Statistics_Wilcoxon = fullfile(OUTPUT_PATH_binned_data_for_saving, name_of_txt_Statistics_Wilcoxon);
fileID = fopen(sessionInfoFilePath_Statistics_Wilcoxon, 'w');

fprintf(fileID, 'Wilcoxon Signed-Rank Test result:\n');
% fprintf(fileID, '\nh = %d (0: fail to reject null, 1: reject null)\n', h);
%
% if h == 0 % Interpretation
%     fprintf(fileID, 'Interpretation: Fail to reject the null hypothesis: No significant difference between the paired samples.\n');
% else
%     fprintf(fileID, 'Interpretation: Reject the null hypothesis: Significant difference between the paired samples.\n');
% end
%
% fprintf(fileID, '\nP-values for each bin:\n');
% fprintf(fileID, '%.4f\n', p_values);
%
% fprintf(fileID, '\nTest statistics (W) for each bin:\n');
% fprintf(fileID, '%.4f\n', stats);

fprintf(fileID, '\nh = 0: No significant difference between the paired samples\n');
fprintf(fileID, 'h = 1: Significant difference between the paired samples\n');

% Initialize an array to store significant bin indices
significant_bins = [];

for binIndex = 1:size(mean_decoding_results_100_before, 1)
    fprintf(fileID, '\nBin %d:\n', binIndex);
    fprintf(fileID, 'h = %d\n', p_values(binIndex) < 0.05);
    fprintf(fileID, 'P-value: %.4f\n', p_values(binIndex));
    fprintf(fileID, 'Test statistic (W): %.4f\n', stats(binIndex));
    
    if p_values(binIndex) < 0.05
        fprintf(fileID, 'Interpretation: Significant difference between the paired samples.\n');
        significant_bins = [significant_bins, binIndex]; % Add significant bin index
    else
        fprintf(fileID, 'Interpretation: No significant difference between the paired samples.\n');
    end
end

% Provide a summary of significant bins at the end of the file
if ~isempty(significant_bins)
    fprintf(fileID, '\nSummary: Significant difference between paired samples for bins: %s\n', num2str(significant_bins));
else
    fprintf(fileID, '\nSummary: No significant differences found between paired samples for any bins.\n');
end

fclose(fileID);

end


function [p_crit] = perform_permutation_test(mean_decoding_results_100_before, mean_decoding_results_100_after, timeValues, meanResultsFilename, OUTPUT_PATH_binned_data_for_saving)

p_crit = 0.05; % Significance level


% Initialize arrays to store clusters, p-values, and significant bin indices
all_clusters = {};
all_p_values = [];
significant_bins = [];


% Loop through each bin (row) and perform the signrank test
for binIndex = 1:size(mean_decoding_results_100_before, 1)
    % Extract the values for the current bin across all sessions
    currentBinValues_before = mean_decoding_results_100_before(binIndex, :);
    currentBinValues_after = mean_decoding_results_100_after(binIndex, :);
    
    
    % Perform the permutest
    % 1 - direction of the test (1 means two-sided test)
    % 0.05 is the significance level
    % 500 - number of permutations
    [clusters, p_values, t_sums, permutation_distribution] = permutest(currentBinValues_before, currentBinValues_after, 1, 0.05, 500, true);
    
    % Store clusters and p-values
    all_clusters{binIndex} = clusters;
    all_p_values(binIndex) = min(p_values); % Assume we use the minimum p-value for the bin
    
    % Selection of significant clusters
    valid_clusters = [clusters{p_values < p_crit}];
    
    % Plotting of significant clusters
    hold on;
    if ~isempty(valid_clusters)
        % plot(timeValues(binIndex), 50, 'r*', 'MarkerSize', 10);
        
        % Find the y position (above the highest point in the bin)
        yMin_bef = min(mean_decoding_results_100_before(binIndex, :));
        yMin_aft = min(mean_decoding_results_100_after(binIndex, :));
        yMin = max(yMin_bef, yMin_aft);
        
        % Add a small offset for the asterisk position
        %yAsterisk = yMax + 2;
        if yMin > 45
            yAsterisk = 45;
        else
            yAsterisk = yMin - 2;
        end
        
        yAsterisk = 41;
        xAsterisk = timeValues(binIndex);
        text(xAsterisk, yAsterisk, '*', 'Color', [0.2, 0.6, 0.2], 'FontSize', 23, 'HorizontalAlignment', 'center');
    end
    hold off;
end

% Save the results of Wilcoxon to a text file
name_of_txt_Permutation_test = ['Permutation_test_Splits_Info_' meanResultsFilename '.txt'];
sessionInfoFilePath_Statistics_Permutation = fullfile(OUTPUT_PATH_binned_data_for_saving, name_of_txt_Permutation_test);
fileID = fopen(sessionInfoFilePath_Statistics_Permutation, 'w');

fprintf(fileID, 'Permutation Test result:\n');
fprintf(fileID, '\nFor each bin, the permutation test is conducted to determine whether there is a significant difference \n');
fprintf(fileID, 'between the decoding results before and after inactivation.\n');
fprintf(fileID, '\nClusters: represent groups of consecutive bins where significant differences were found\n');
fprintf(fileID, '   - Empty cell: if there are no significant clusters\n');
fprintf(fileID, '   - Numerical values: indices (e.g., time points or bins) where meaningful differences are found\n');
fprintf(fileID, '\np-values: indicate the statistical significance of these differences\n');
fprintf(fileID, '\n__________________________________________________________________________________________________\n');

%fprintf(fileID, '\nclusters - identified clusters of significant differences between two datasets\n');

% Loop through each bin and write results to the file
for binIndex = 1:size(mean_decoding_results_100_before, 1)
    fprintf(fileID, '\nBin %d:\n', binIndex);
    fprintf(fileID, 'P-value: %.4f\n', all_p_values(binIndex));
    fprintf(fileID, 'Clusters: %s\n', mat2str(cell2mat(all_clusters{binIndex})));
    
    if all_p_values(binIndex) < p_crit
        fprintf(fileID, 'Interpretation: Significant difference between the paired samples in this bin.\n');
        significant_bins = [significant_bins, binIndex]; % Add significant bin index
    else
        fprintf(fileID, 'Interpretation: No significant difference between the paired samples in this bin.\n');
    end
end


% Provide a summary of significant bins at the end of the file
if ~isempty(significant_bins)
    fprintf(fileID, '\nSummary: Significant differences between paired samples were found in bins: %s\n', num2str(significant_bins));
else
    fprintf(fileID, '\nSummary: No significant differences were found between paired samples for any bins.\n');
end
fclose(fileID);
end


function [modifiedLabel1, modifiedLabel2] = modifyLabel(combinedLabel)
modifiedLabel1 = strrep(combinedLabel, '_', ' ');
parts = strsplit(combinedLabel, '_');

% Create a string with permutation of elements
if length(parts) == 4
    modifiedLabel2 = [parts{3} '_' parts{4} ' ' parts{1} '_' parts{2}];
else
    error('Input must contain exactly 4 parts separated by underscores.');
end
end


function [modified_training_block, modified_test_block] = extractAndModifyBlocks(data)
% Extract blocks from the cell
training_block_str = data.training_block{1};
test_block_str = data.test_block{1};

% Checking for more than one block
blocks_training = strsplit(training_block_str, '_');
blocks_test = strsplit(test_block_str, '_');

% Initialisation of variables for modified blocks
modified_training_block = training_block_str; % Default original
modified_test_block = test_block_str;

% If more than 2 blocks in a training session
if length(blocks_training) > 2
    modified_training_block = modifyBlock(blocks_training);
end

% If more than 2 blocks in a test
if length(blocks_test) > 2
    modified_test_block = modifyBlock(blocks_test);
end
end

% Function for modifying blocks
function modifiedBlock = modifyBlock(someBlock)
% Combine blocks into a string with the required format
modifiedBlock = [someBlock{1} '_' someBlock{2} ' ' someBlock{3} '_' someBlock{4}];
end