function sdndt_Sim_LIP_dPul_NDT_daboxplot(injection, typeOfDecoding, method_of_decoding)

% For across session analysis, you just need to average individual session
% sdndt_Sim_LIP_dPul_NDT_daboxplot('1', 'сollected_files_across_sessions', 'Decoding')

 
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

% method_of_decoding:  'Decoding', 'Cross_decoding'

%%

% Start timing the execution
startTime = tic;



%% list of monkeys
monkey_list = {'Bacchus', 'Linus'};


%% Define the list of required files

%     if strcmp(monkey, 'Bacchus')
%         listOfRequiredFiles.group_1 = { 'overlapBlocksFiles_BeforeInjection', 'thirdBlockFiles'};
%        listOfRequiredFiles.group_2 = {'overlapBlocksFiles_AfterInjection', 'fourthBlockFiles'};
%     elseif strcmp(monkey, 'Linus')
%          listOfRequiredFiles.group_1 = { 'overlapBlocksFiles_BeforeInjection_3_4', 'thirdBlockFiles'};
%        listOfRequiredFiles.group_2 = {'overlapBlocksFiles_AfterInjection_3_4', 'fourthBlockFiles'};
%     end

listOfRequiredFiles_all = struct();
for monkey_idx = 1:numel(monkey_list)
    monkey = monkey_list{monkey_idx};
    
    if strcmp(monkey, 'Bacchus')
        listOfRequiredFiles.group_1 = {'overlapBlocksFiles_BeforeInjection', 'thirdBlockFiles'};
        listOfRequiredFiles.group_2 = {'overlapBlocksFiles_AfterInjection', 'fourthBlockFiles'};
    elseif strcmp(monkey, 'Linus')
        listOfRequiredFiles.group_1 = {'overlapBlocksFiles_BeforeInjection_3_4', 'thirdBlockFiles'};
        listOfRequiredFiles.group_2 = {'overlapBlocksFiles_AfterInjection_3_4', 'fourthBlockFiles'};
    end
    listOfRequiredFiles_all.(monkey) = listOfRequiredFiles;
end

%% Define typeOfSessions
% Calculate typeOfSessions based on the injection parameter
if strcmp(injection, '1')
    typeOfSessions = {'right'}; % For control and injection experiments
    
    %     if strcmp(monkey, 'Linus')
    %         % typeOfSessions = {'right'};
    %         typeOfSessions = {'right' %, 'left', 'all'
    %             }; % For control and injection experiments
    %     elseif strcmp(monkey, 'Bacchus')
    %         typeOfSessions = {'right'};
    %     end
    
elseif strcmp(injection, '0') || strcmp(injection, '2')
    typeOfSessions = {''}; % For the functional interaction experiment
else
    error('Invalid injection value. Use ''0'', ''1'', or ''2''.');
end

% Calculate the number of session types
numTypesOfSessions = numel(typeOfSessions);


%% Define approach parameters

%allRequiredFiles = [listOfRequiredFiles.group_1, listOfRequiredFiles.group_2];
allRequiredFiles = [listOfRequiredFiles_all.Linus.group_1, listOfRequiredFiles_all.Linus.group_2, ...
    listOfRequiredFiles_all.Bacchus.group_1, listOfRequiredFiles_all.Bacchus.group_2];


if any(contains(allRequiredFiles, {'overlapBlocksFiles_BeforeInjection_3_4', 'overlapBlocksFiles_AfterInjection_3_4', ...
        'overlapBlocksFiles_BeforeInjection', 'overlapBlocksFiles_AfterInjection', ...
        'overlapBlocksFiles'}))
    approach_to_use = {'overlap_approach'};
elseif any(contains(allRequiredFiles, {'allBlocksFiles_BeforeInjection', 'allBlocksFiles_AfterInjection', ...
        'allBlocksFiles'}))
    approach_to_use = {'all_approach'};
else
    approach_to_use = {'overlap_approach'};
end

%% Define target_state parameters
targetParams = struct();

% Define target_state parameters
targetParams.cueON = 'cueON';
targetParams.GOsignal = 'GOsignal';

% Calculate the number of target state parameters (number of fields)
numFieldNames = numel(fieldnames(targetParams))/2;

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
    numTypeBlocks = numel(listOfRequiredFiles.group_1); % Get the number of files in the group
    
    % Check that the file groups for both monkeys are the same
    if numel(listOfRequiredFiles_all.Linus.group_1) ~= numel(listOfRequiredFiles_all.Bacchus.group_1)
        error('Groups for Linus and Bacchus must have the same number of files.');
    end
    
    %     % Check that both groups have the same number of files
    %     if numel(listOfRequiredFiles.group_1) ~= numel(listOfRequiredFiles.group_2)
    %         error('group_1 and group_2 must have the same number of files.');
    %     end
    
end



numTypeBlocks = numel(listOfRequiredFiles_all.Linus.group_1);

% Calculate total number of iterations
totalIterations = numApproach * numTypeBlocks * numCombinations * numLabels * numFieldNames * numTypesOfSessions;
overallProgress = 0; % Initialize progress


for file_index = 1:numTypeBlocks % Loop through each file in listOfRequiredFiles
    if strcmp(typeOfDecoding, 'сollected_files_across_sessions')
        %         current_file_1 = listOfRequiredFiles.group_1{file_index};
        %         current_file_2 = listOfRequiredFiles.group_2{file_index}; % Get the current file
        
        %         current_file_1_monk_1 = listOfRequiredFiles_all.Linus.group_1{file_index};
        %         current_file_2_monk_1 = listOfRequiredFiles_all.Linus.group_2{file_index};
        %         current_file_1_monk_2 = listOfRequiredFiles_all.Bacchus.group_1{file_index};
        %         current_file_2_monk_2 = listOfRequiredFiles_all.Bacchus.group_2{file_index};
        
        % Initialising arrays to store the files of all monkeys
        current_file_1_all_monkeys = cell(1, numel(monkey_list));
        current_file_2_all_monkeys = cell(1, numel(monkey_list));
        
        % Cycle for each monkey
        for monkey_idx = 1:numel(monkey_list)
            monkey = monkey_list{monkey_idx};
            % Extract data for the current monkey
            current_file_1_all_monkeys{monkey_idx} = listOfRequiredFiles_all.(monkey).group_1{file_index};
            current_file_2_all_monkeys{monkey_idx} = listOfRequiredFiles_all.(monkey).group_2{file_index};
        end
        
    end
    
    
    
    
    
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
                
                %                     datesForSessions = {}; % Initialize datesForSessions as an empty cell array
                %                     if strcmp(injection, '1')
                %                         for type = 1:numel(typeOfSessions)
                %                             % Get the dates for the corresponding injection and session types
                %                             datesForSessions{end+1} = filelist_of_days_from_Simultaneous_dPul_PPC_recordings(monkey, injection, typeOfSessions{type});
                %                         end
                %                     elseif  strcmp(injection, '0') || strcmp(injection, '2')
                %                         datesForSessions = filelist_of_days_from_Simultaneous_dPul_PPC_recordings(monkey, injection, typeOfSessions);
                %                     end
                
                
                datesForSessions_all = struct();
                for monkey_idx = 1:numel(monkey_list)
                    monkey = monkey_list{monkey_idx};
                    
                    if strcmp(injection, '1')
                        for type = 1:numel(typeOfSessions)
                            datesForSessions_all.(monkey){type} = filelist_of_days_from_Simultaneous_dPul_PPC_recordings(monkey, injection, typeOfSessions{type});
                        end
                    elseif strcmp(injection, '0') || strcmp(injection, '2')
                        datesForSessions_all.(monkey) = filelist_of_days_from_Simultaneous_dPul_PPC_recordings(monkey, injection, typeOfSessions);
                    end
                end
                
                
                % Loop through each target_state parameter
                fieldNames = fieldnames(targetParams);
                %                     numFieldNames = numel(fieldNames);
                %                     numTypesOfSessions = numel(typeOfSessions);
                %
                %                     for i = 1:numFieldNames
                %                         target_state_name = fieldNames{i};
                %                         target_state = targetParams.(target_state_name);
                
                for j = 1:numTypesOfSessions
                    % Call the main decoding function based on dateOfRecording
                    
                    % current_set_of_date = datesForSessions{j}; % Get the corresponding set of dates !!!!!
                    current_type_of_session = typeOfSessions{j}; % Get the corresponding type of session !!!!!
                    %  current_set_of_date = datesForSessions{j}; % Get the corresponding set of dates !!!!!
                    
                    
                    % Универсальный подход для обработки данных всех обезьян
                    current_set_of_dates_all = struct();
                    for monkey_idx = 1:numel(monkey_list)
                        monkey = monkey_list{monkey_idx}; % Текущая обезьяна
                        % Получаем данные для текущей обезьяны
                        current_set_of_dates_all.(monkey) = datesForSessions_all.(monkey){j};
                    end
                    
                    
                    
                    
                    % Call the internal decoding function only once
                    sdndt_Sim_LIP_dPul_NDT_daboxplot_internal(monkey_list, current_injection, current_type_of_session, typeOfDecoding, method_of_decoding, ...
                        current_set_of_dates_all, current_target_brain_structure, fieldNames, current_label, current_approach, ...
                        current_file_1_all_monkeys, current_file_2_all_monkeys);
                    
                    
                    %  sdndt_Sim_LIP_dPul_NDT_daboxplot_internal(monkey, current_injection, current_type_of_session, typeOfDecoding, method_of_decoding, ...
                    %  current_set_of_date, current_target_brain_structure, fieldNames, current_label, current_approach, current_file_1, current_file_2, curves_per_session);
                    
                    % Update progress for each iteration
                    overallProgress = overallProgress + 1;
                    waitbar(overallProgress / totalIterations, h, sprintf('Processing... %.2f%%', overallProgress / totalIterations * 100));
                    
                    
                    
                    
                end % for j = 1:numTypesOfSessions
                %  end % for i = 1:numFieldNames
            end % for label_index = 1:numLabels
        end % approach_index = 1:numApproach
    end % for comb_index = 1:numCombinations
    
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





%function sdndt_Sim_LIP_dPul_NDT_daboxplot_internal(monkey, injection, typeOfSessions, typeOfDecoding, method_of_decoding, dateOfRecording, target_brain_structure, target_state, given_labels_to_use, current_approach, givenListOfRequiredFiles_gr_1, givenListOfRequiredFiles_gr_2, curves_per_session)
function sdndt_Sim_LIP_dPul_NDT_daboxplot_internal(monkey_list, injection, typeOfSessions, typeOfDecoding, method_of_decoding, dateOfRecording, target_brain_structure, target_state, given_labels_to_use, current_approach, givenListOfRequiredFiles_gr_1, givenListOfRequiredFiles_gr_2)



%% Path
% Call the function to get the dates
% allDateOfRecording = filelist_of_days_from_Simultaneous_dPul_PPC_recordings(monkey, injection, typeOfSessions);

% allDateOfRecording = {};
% for i = 1:length(monkey_list)
%     current_monkey = monkey_list{i}; % Текущая обезьяна
%     dates_for_current_monkey = filelist_of_days_from_Simultaneous_dPul_PPC_recordings(current_monkey, injection, typeOfSessions);
%     allDateOfRecording = [allDateOfRecording, dates_for_current_monkey(:)];
% end


% Call the settings function with the chosen set
[base_path, ~, OUTPUT_PATH_raster, OUTPUT_PATH_binned, ~, settings] = sdndt_Sim_LIP_dPul_NDT_settings(monkey_list{1}, injection, typeOfSessions);
%[base_path, ~, OUTPUT_PATH_raster, OUTPUT_PATH_binned, monkey_prefix, settings] = sdndt_Sim_LIP_dPul_NDT_settings(monkey, injection, typeOfSessions);



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


% [grouping_folder_gr_1, num_block_gr_1] = processRequiredFiles(monkey, current_approach, ...
%     block_grouping_folder_prefix, givenListOfRequiredFiles_gr_1);
% [grouping_folder_gr_2, num_block_gr_2] = processRequiredFiles(monkey, current_approach, ...
%     block_grouping_folder_prefix, givenListOfRequiredFiles_gr_2);

% Initialising the structure for storing data
grouping_data = struct();

for monkey_idx = 1:length(monkey_list)
    current_monkey = monkey_list{monkey_idx};
    
    % for group 1 (for current monkeys)
    data_gr_1 = processRequiredFiles(current_monkey, current_approach, ...
        block_grouping_folder_prefix, givenListOfRequiredFiles_gr_1{monkey_idx});
    
    %  for group 1 (for current monkeys)
    data_gr_2 = processRequiredFiles(current_monkey, current_approach, ...
        block_grouping_folder_prefix, givenListOfRequiredFiles_gr_2{monkey_idx});
    
    % Saving data to a structure
    grouping_data.(current_monkey).gr_1 = data_gr_1;
    grouping_data.(current_monkey).gr_2 = data_gr_2;
end





% Preprocess given_labels_to_use
given_labels_to_use_split = strsplit(given_labels_to_use, '_');
combinedLabel = combine_label_segments(given_labels_to_use_split);



%%
cvSplitFolder_to_save = 'Average_Dynamics';

if  strcmp(typeOfDecoding, 'сollected_files_across_sessions')
    %
    %     % Construct the block grouping folder for saving
    %     if isempty(grouping_folder.block_grouping_folder_for_saving)
    %         % For specific block files, construct the folder with block number suffix
    %         grouping_folder.block_grouping_folder_for_saving = sprintf('%sFilesAcrossSessions_Block_%s/', lower(block_grouping_folder_prefix), num_block_suffix);
    %     end
    %
    %     % create output folder
    %     type_of_decoding = 'Cross_decoding';
    %     type_of_folder = 'average_across_session';
    %     typeOfDecoding_monkey = [monkey_prefix type_of_folder];
    %     OUTPUT_PATH_binned_data_for_saving = fullfile(OUTPUT_PATH_binned, typeOfDecoding_monkey, type_of_decoding, grouping_folder.block_grouping_folder, settings.num_cv_splits_approach_folder);
    %     % Check if cvSplitFolder_to_save folder exists, if not, create it
    %     if ~exist(OUTPUT_PATH_binned_data_for_saving, 'dir')
    %         mkdir(OUTPUT_PATH_binned_data_for_saving);
    %     end
    %
    %     [dateOfRecording, target_brain_structure, target_state, given_labels_to_use, data_for_plotting_averages, settings, OUTPUT_PATH_binned_data_for_saving, numOfData] = collectingAveragesAcrossSessions(monkey, injection, typeOfSessions, dateOfRecording, target_brain_structure, target_state, given_labels_to_use, num_block{1}, OUTPUT_PATH_binned_data_for_saving, block_grouping_folder, type_of_decoding);
    %     plotingAveragesAcrossSessions(dateOfRecording, target_brain_structure, target_state, given_labels_to_use, data_for_plotting_averages, settings, OUTPUT_PATH_binned_data_for_saving, numOfData, curves_per_session)
    %
    %
    %
    % elseif strcmp(typeOfDecoding, 'сollected_files_across_sessions')
    
    
    
   % Define monkey_prefix
    if length(monkey_list) == 2
        monkey_prefix = 'Both_';  % Если две обезьяны, указываем префикс "Both"
    else
        monkey_prefix = monkey_list{1};  % Если одна обезьяна, используем её имя
    end
    
    % create output folder
    type_of_graphs = 'dabox_plot';
    type_of_folder = 'average_across_session';
    typeOfDecoding_monkey = [monkey_prefix type_of_folder];
    OUTPUT_PATH_binned_data_for_saving = fullfile(OUTPUT_PATH_binned, typeOfDecoding_monkey, method_of_decoding, type_of_graphs);
    % Check if cvSplitFolder_to_save folder exists, if not, create it
    if ~exist(OUTPUT_PATH_binned_data_for_saving, 'dir')
        mkdir(OUTPUT_PATH_binned_data_for_saving);
    end
    
    %     [dateOfRecording, target_brain_structure, target_state, combinedLabel, data_for_plotting_averages, settings, OUTPUT_PATH_binned_data_for_saving, numOfData] = collectingAveragesAcrossSessions(monkey, injection, typeOfSessions, dateOfRecording, target_brain_structure, target_state, combinedLabel, num_block, OUTPUT_PATH_binned_data_for_saving, block_grouping_folder);
    %     plotingAveragesAcrossSessions(dateOfRecording, target_brain_structure, target_state, combinedLabel, data_for_plotting_averages, settings, OUTPUT_PATH_binned_data_for_saving, numOfData, curves_per_session)
    
    
    for monkey_idx = 1:length(monkey_list)
        current_monkey = monkey_list{monkey_idx};
        
        % Before injection (group 1)
        [~, target_brain_structure, target_state, combinedLabel, ...
            data_for_plotting_averages_before.(current_monkey), settings, ~] = collectingAveragesAcrossSessions( ...
            current_monkey, injection, typeOfSessions, dateOfRecording.(current_monkey), typeOfDecoding, method_of_decoding, ...
            target_brain_structure, target_state, combinedLabel, grouping_data.(current_monkey).gr_1, ...
            OUTPUT_PATH_binned_data_for_saving, type_of_graphs);
        
        
        % After injection (group 2)
        [~, ~, ~, ~, data_for_plotting_averages_after.(current_monkey), ~, ~] = collectingAveragesAcrossSessions( ...
            current_monkey, injection, typeOfSessions, dateOfRecording.(current_monkey), typeOfDecoding, method_of_decoding, ...
            target_brain_structure, target_state, combinedLabel, grouping_data.(current_monkey).gr_2, ...
            OUTPUT_PATH_binned_data_for_saving, type_of_graphs);
        
        % % Collecting data before injection
        % [dateOfRecording, target_brain_structure, target_state, combinedLabel, data_for_plotting_averages_before, settings, ~, numOfData_before] = collectingAveragesAcrossSessions(monkey, injection, typeOfSessions, dateOfRecording, typeOfDecoding, method_of_decoding, target_brain_structure, target_state, combinedLabel, num_block_gr_1, OUTPUT_PATH_binned_data_for_saving, grouping_folder_gr_1, type_of_graphs);
        %
        %     % Collecting data after injection
        %     [~, ~, ~, ~, data_for_plotting_averages_after, ~, ~, numOfData_after] = collectingAveragesAcrossSessions(monkey, injection, typeOfSessions, dateOfRecording, typeOfDecoding, method_of_decoding, target_brain_structure, target_state, combinedLabel, num_block_gr_2, OUTPUT_PATH_binned_data_for_saving, grouping_folder_gr_2, type_of_graphs);
        
        
        
    end
    
    
    
    % Plotting both sets of data on the same figure
    daboxplotAveragesAcrossSessions(monkey_list, typeOfDecoding, dateOfRecording, target_brain_structure, target_state, combinedLabel, data_for_plotting_averages_before, data_for_plotting_averages_after, settings, OUTPUT_PATH_binned_data_for_saving);
    
else
    partOfName = dateOfRecording;
end


% % Load required files for each session or merged files
% OUTPUT_PATH_list_of_required_files = [OUTPUT_PATH_binned dateOfRecording '/List_of_required_files/sdndt_Sim_LIP_dPul_NDT_' partOfName '_list_of_required_files.mat'];
% load(OUTPUT_PATH_list_of_required_files);

end



function [grouping_folder] = processRequiredFiles(monkey, current_approach, ...
    block_grouping_folder_prefix, currentFile)



% Initialize the result structure
grouping_folder = struct();
num_block = {};



% Determine block-specific settings based on current file
if strcmp(currentFile, 'firstBlockFiles') && strcmp(current_approach, 'overlap_approach')
    num_block_suffix = '1';
    block_grouping_folder = sprintf('%sBy_block', block_grouping_folder_prefix);
elseif strcmp(currentFile, 'secondBlockFiles')
    num_block_suffix = '2';
    block_grouping_folder = sprintf('%sBy_block', block_grouping_folder_prefix);
elseif strcmp(currentFile, 'thirdBlockFiles') && strcmp(current_approach, 'overlap_approach')
    block_grouping_folder = sprintf('%sBy_block', block_grouping_folder_prefix);
    num_block_suffix = '3';
    block_data = 'block: 3';
elseif strcmp(currentFile, 'fourthBlockFiles') && strcmp(current_approach, 'overlap_approach')
    block_grouping_folder = sprintf('%sBy_block', block_grouping_folder_prefix);
    num_block_suffix = '4';
    block_data = 'block: 4';
elseif strcmp(currentFile, 'fifthBlockFiles')
    num_block_suffix = '5';
    block_grouping_folder = sprintf('%sBy_block', block_grouping_folder_prefix);
elseif strcmp(currentFile, 'sixthBlockFiles')
    num_block_suffix = '6';
    block_grouping_folder = sprintf('%sBy_block', block_grouping_folder_prefix);
elseif strcmp(currentFile, 'overlapBlocksFiles_BeforeInjection') && strcmp(monkey, 'Bacchus')
    block_grouping_folder = 'Overlap_blocks_BeforeInjection/';
    block_grouping_folder_for_saving = 'Overlap_blocks_3_4';
    num_block_suffix = '1';
    block_data = 'block: 1';
elseif strcmp(currentFile, 'overlapBlocksFiles_AfterInjection') && strcmp(monkey, 'Bacchus')
    block_grouping_folder = 'Overlap_blocks_AfterInjection/';
    block_grouping_folder_for_saving = 'Overlap_blocks_3_4';
    num_block_suffix = '3';
    block_data = 'block: 3,4';
elseif strcmp(currentFile, 'overlapBlocksFiles_BeforeInjection_3_4') && strcmp(monkey, 'Linus')
    block_grouping_folder = 'Overlap_blocks_BeforeInjection_3_4/';
    block_grouping_folder_for_saving = 'Overlap_blocks_3_4';
    num_block_suffix = '1';
    block_data = 'block: 1';
elseif strcmp(currentFile, 'overlapBlocksFiles_AfterInjection_3_4') && strcmp(monkey, 'Linus')
    block_grouping_folder = 'Overlap_blocks_AfterInjection_3_4/';
    block_grouping_folder_for_saving = 'Overlap_blocks_3_4';
    num_block_suffix = '3';
    block_data = 'block: 3,4';
elseif strcmp(currentFile, 'allBlocksFiles_BeforeInjection')
    block_grouping_folder = 'All_blocks/';
    block_grouping_folder_for_saving = 'allBlocksFilesAcrossSessions_BeforeInjection';
    num_block_suffix = '';
elseif strcmp(currentFile, 'allBlocksFiles_AfterInjection')
    block_grouping_folder = 'All_blocks/';
    block_grouping_folder_for_saving = 'allBlocksFilesAcrossSessions_AfterInjection';
    num_block_suffix = '';
else
    error('Unknown value for givenListOfRequiredFiles.');
end

% Save the results in the structure array
grouping_folder.block_grouping_folder = block_grouping_folder;
if exist('block_grouping_folder_for_saving', 'var')
    grouping_folder.block_grouping_folder_for_saving = block_grouping_folder_for_saving;
else
    grouping_folder.block_grouping_folder_for_saving = '';
end
grouping_folder.num_block_suffix = num_block_suffix;
grouping_folder.block_data = block_data;

% Construct num_block
if isempty(num_block_suffix)
    grouping_folder.num_block = ''; % Use curly braces for cell array assignment
else
    grouping_folder.num_block = sprintf('block_%s', num_block_suffix);
end


end

function combinedLabel = combine_label_segments(labelSegments)
% Combine segments 1 and 2, and segments 3 and 4
combinedSegments = {strjoin(labelSegments(1:2), '_'), strjoin(labelSegments(3:4), '_')};
combinedLabel = strjoin(combinedSegments, ' '); % Join the combined segments with a space
end



function [dateOfRecording, target_brain_structure, target_state, combinedLabel, data_for_plotting_averages, settings, OUTPUT_PATH_binned_data_for_saving] = collectingAveragesAcrossSessions(monkey, injection, typeOfSessions, dateOfRecording, typeOfDecoding, method_of_decoding, target_brain_structure, target_state, combinedLabel, block_grouping, OUTPUT_PATH_binned_data_for_saving, type_of_decoding)

%% Path
% Call the function to get the dates
allDateOfRecording = filelist_of_days_from_Simultaneous_dPul_PPC_recordings(monkey, injection, typeOfSessions);


% Call the settings function with the chosen set
[base_path, INPUT_PATH, OUTPUT_PATH_raster, OUTPUT_PATH_binned, monkey_prefix, settings] = sdndt_Sim_LIP_dPul_NDT_settings(monkey, injection, typeOfSessions);

%%

% Цикл по всем состояниям в target_state
for stateIdx = 1:numel(target_state)
    current_target_state = target_state{stateIdx};
    
    % Initialize decodingResultsFilePath
    data_for_plotting_averages.(current_target_state).decodingResultsFilePath = '';  % Initialize as an empty string
    
    
    % Initializing the structure for the current state
    if ~isfield(data_for_plotting_averages, current_target_state)
        data_for_plotting_averages.(current_target_state) = struct();
    end
    
    % Saving the current state 
    data_for_plotting_averages.(current_target_state).target_state = current_target_state;
    
    
    
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
    % data_for_plotting_averages.(current_target_state).session_info = struct('number', {}, 'name', {}, 'color_RGB', {}, 'color_appearance', {});
    
    if ~isfield(data_for_plotting_averages.(current_target_state), 'session_info')
        data_for_plotting_averages.(current_target_state).session_info = struct('number', {}, 'name', {}, 'color_RGB', {}, 'color_appearance', {});
    end
    
    
    
    for i = 1:numel(dateOfRecording)
        data_for_plotting_averages.(current_target_state).session_info(i).number = i;
        data_for_plotting_averages.(current_target_state).session_info(i).name = dateOfRecording{i};
        data_for_plotting_averages.(current_target_state).session_info(i).color_RGB = session_colors_RGB (i, :);
        data_for_plotting_averages.(current_target_state).session_info(i).color_appearance = session_colors_Appearance(i, :);
    end
    
    
    
    
    
    
    
    % Initialize variables to keep track of the highest value and its folder
    highestValue = 0;
    highestFolder = '';
    
    
    % Initialize cell arrays to store data across sessions
    all_mean_decoding_results = {}; % to store mean decoding results
    sites_to_use = {};
    numOfUnits = {};
    numOfTrials = {};
    session_num_cv_splits_Info = {};
    data_for_plotting_averages.(current_target_state).session_info_combined = {};
    label_counts_cell = cell(1, numel(dateOfRecording)); % Initialize a cell array to store label_counts for each day
    
    totalNumOfUnits = 0; % Initialize the total number of units
    totalNumOfTrials = 0; % Initialize the total number of trials
    
    sum_first_numbers = 0; % Initialize variables to store sums of the first and second numbers
    sum_second_numbers = 0;
    
    %pattern_block = ['test_' num_block];
    % Save the original value of num_block
    initial_num_block = block_grouping.num_block;
    
    % target_state =  'cueON'
    
    for numOfData = 1:numel(dateOfRecording)
        
        current_dateOfRecording = dateOfRecording{numOfData};
        
        % Return num_block to the initial value before each iteration
        num_block = initial_num_block;
        
        % Check if the current date is ‘20201112’
        if strcmp(current_dateOfRecording, '20201112') && strcmp(num_block, 'block_3')
            num_block = 'block_2';  % ude block 2 for the ‘20201112’
        end
        
        %  pattern_block = ['test_.*' num_block '.*'];
        
        if strcmp(method_of_decoding, 'Cross_decoding')
            % For cross-decoding we use a more universal template
            pattern_block = ['test_.*' num_block '.*'];
        else
            % For decoding
            pattern_block = ['.*' num_block '.*'];
        end
        
        current_dateOfRecording_monkey = [monkey_prefix current_dateOfRecording];
        OUTPUT_PATH_binned_data = fullfile(OUTPUT_PATH_binned, current_dateOfRecording_monkey, block_grouping.block_grouping_folder, settings.num_cv_splits_approach_folder);
        
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
        data_for_plotting_averages.(current_target_state).decodingResultsFilePath = '';
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
                data_for_plotting_averages.(current_target_state).decodingResultsFilename = decodingResultsFiles(fileIndex).name;
                
                % Check if the file name contains the desired target structure, state, and label
                if contains(data_for_plotting_averages.(current_target_state).decodingResultsFilename, target_brain_structure) && ...
                        contains(data_for_plotting_averages.(current_target_state).decodingResultsFilename, current_target_state) && ...
                        contains(data_for_plotting_averages.(current_target_state).decodingResultsFilename, combinedLabel) && ...
                        ~isempty(regexp(data_for_plotting_averages.(current_target_state).decodingResultsFilename, pattern_block, 'once'))
                    %  contains(data_for_plotting_averages.decodingResultsFilename, num_block)
                    % ~isempty(regexp(data_for_plotting_averages.decodingResultsFilename, pattern_block, 'once')) %
                    
                    %contains(data_for_plotting_averages.decodingResultsFilename, ['test_' num_block]) % find test_block_X
                    % Construct the full path to the DECODING_RESULTS.mat file
                    
                    
                    
                    
                    data_for_plotting_averages.(current_target_state).decodingResultsFilePath = fullfile(cvSplitFolderPath, data_for_plotting_averages.(current_target_state).decodingResultsFilename);
                    
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
        data_for_plotting_averages.(current_target_state).session_info_combined{end+1} = [session_num_cv_splits_Info];
        
        
        
        
        % If no file was found in any folder, display error message
        if isempty(data_for_plotting_averages.(current_target_state).decodingResultsFilePath)
            
            data_for_plotting_averages.(current_target_state).session_info(numOfData) = [];
            
            % disp('ERROR: No suitable decoding results file found.');
            disp(['No suitable decoding results file found for session: ', current_dateOfRecording]);
            continue; % Move to the next iteration of the loop
            
        else
            
            % Load the file
            loadedData = load(data_for_plotting_averages.(current_target_state).decodingResultsFilePath);
            
            % Now you can access the data from the loaded file using the appropriate fields or variables
            % For example, if there is a variable named 'results' in the loaded file, you can access it as follows:
            mean_decoding_results = loadedData.DECODING_RESULTS.NORMALIZED_RANK_RESULTS.mean_decoding_results;
            
            % Append mean decoding results to the cell array
            all_mean_decoding_results{end+1} = mean_decoding_results;
            
            % Process the loaded data as needed
            
            % Load additional data if necessary
            [filepath, filename, fileext] = fileparts(data_for_plotting_averages.(current_target_state).decodingResultsFilePath); % Get the path and filename components
            desired_part = fullfile(filepath, filename); % Concatenate the path and filename without the extension
            binned_file_name = [desired_part '.mat']; % Add '.mat' to the desired part
            % Specify substrings to remove
            
            if strcmp(method_of_decoding, 'Decoding')
                combinedLabel_remove = ['_' combinedLabel];
            else
                combinedLabel_remove = '';
            end
            
            substrings_to_remove = {[combinedLabel_remove, '_DECODING_RESULTS']}; % Add more patterns as needed
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
        
        
        
        %% Number of units
        sites_to_use{end+1} = loadedData.DECODING_RESULTS.DS_PARAMETERS.sites_to_use;
        numOfUnits{end+1} = size(sites_to_use{end}, 2);  % Calculate the number of units
        unitsForCurrentDay = size(sites_to_use{end}, 2); % Calculate the number of units for the current day
        totalNumOfUnits = totalNumOfUnits + unitsForCurrentDay;  % Add the units for the current day to the total
        
        
        
        
        
        %% Number of trials
        trial_type_side = binned_labels.trial_type_side;
        label_names_to_use = loadedData.DECODING_RESULTS.DS_PARAMETERS.label_names_to_use;
        
        label_counts = zeros(size(label_names_to_use)); % Initialize counters
        unique_sequences = containers.Map('KeyType', 'char', 'ValueType', 'logical'); % Map to store unique sequences
        
        for x = 1:length(sites_to_use{end}) % Loop through sites_to_use and count occurrences of labels_names_to_use in trial_type_side
            % site_index = sites_to_use{:, x};
            site_index = sites_to_use{end}(x); % Access the site index directly
            labels_at_site = trial_type_side{1, site_index}; % Access the_labels at the specified site_index
            
            % Convert cell array to a string for easy comparison
            sequence_str = strjoin(labels_at_site, ',');
            
            % Check if the sequence is unique
            if ~isKey(unique_sequences, sequence_str)
                unique_sequences(sequence_str) = true; % Mark as seen
                for y = 1:length(label_names_to_use)
                    % Count occurrences of unique_labels in labels_at_site
                    label_counts(y) = label_counts(y) + sum(strcmp(labels_at_site, label_names_to_use{y}));
                end
            end
        end
        
        numOfTrials{end+1} = sum(label_counts);
        label_counts_cell{numOfData} = label_counts; % Store label_counts for the current day
        
        
        % Accumulate the trial counts for the current day to the total
        totalNumOfTrials = totalNumOfTrials + numOfTrials{end};
        
        % After processing each day, accumulate the sums of the first and second numbers
        sum_first_numbers = sum_first_numbers + label_counts_cell{numOfData}(1);
        sum_second_numbers = sum_second_numbers + label_counts_cell{numOfData}(2);
        first_second_numbers = [sum_first_numbers sum_second_numbers];
        
        
        
        
        
        
    end
    
    
    
    %% prepearing fot the plotting numOfTrials and numOfUnits
    
    % Sum up the values in the cell array numOfUnits
    numOfUnits_and_numOfTrials_info = sprintf('Num of Units: %s\nNum of Trials: %s\n', num2str(totalNumOfUnits), num2str(totalNumOfTrials));
    
    % Display the label counts information
    labelCountsInfo = '';
    for g = 1:length(label_names_to_use)
        % Concatenate the label name and the total count
        labelCountsInfo = [labelCountsInfo, sprintf('\nNum of %s: %d', label_names_to_use{g}, first_second_numbers(g))];
    end
    
    % to display the complete information
    data_for_plotting_averages.(current_target_state).numOfUnits_and_numOfTrials_info_labelsAppears = [numOfUnits_and_numOfTrials_info, labelCountsInfo];
    %numOfUnits_and_numOfTrials_info_labelsAppears = sprintf('%s%s', numOfUnits_and_numOfTrials_info, labelCountsInfo);
    
    
    % Extract constant part from the filename
    constant_part = regexprep(filename, '_DECODING_RESULTS$', '');
    title_for_extracted_window = [monkey(1:3) '_Extracted_window_for_'];
    
    if strcmp(current_target_state, 'cueON') % Add prefix and condition-specific suffix
        output_filename.Cue = [title_for_extracted_window 'Cue_' constant_part];
    elseif strcmp(current_target_state, 'GOsignal')
        output_filename.Delay = [title_for_extracted_window 'Delay_' constant_part];
        output_filename.PostSac = [title_for_extracted_window 'PostSac_' constant_part];
    end
    
    
    
    
    if strcmp(current_target_state, 'cueON')
        % For the ‘cueON’
        time_window_Cue.window_start = 20;
        time_window_Cue.window_end = 200;
        
        OUTPUT_PATH_binned_data_for_saving_txt = [OUTPUT_PATH_binned_data_for_saving '/' output_filename.Cue ];
        loadedData_Cue = loadedData.DECODING_RESULTS;
        
        % Function call for one time window
        [selected_data_Cue, selected_bins_Cue, bin_times_Cue] = ...
            extract_window_from_data_epoch(typeOfDecoding, all_mean_decoding_results, loadedData_Cue, time_window_Cue, OUTPUT_PATH_binned_data_for_saving_txt);
        
        mean_decoding_results_Cue = horzcat(selected_data_Cue{:});
        data_for_plotting_averages.(current_target_state).mean_decoding_results_Cue = mean(mean_decoding_results_Cue,1);
        mean_decoding_results_100_Cue = mean_decoding_results_Cue*100;
        data_for_plotting_averages.(current_target_state).mean_decoding_results_100_Cue = mean(mean_decoding_results_100_Cue,1);
        
        data_for_plotting_averages.(current_target_state).selected_bins_Cue = selected_bins_Cue;
        data_for_plotting_averages.(current_target_state).bin_times_Cue = bin_times_Cue;
        
        data_for_plotting_averages.(current_target_state).block_data_Cue = block_grouping.block_data;
        
        
    elseif strcmp(current_target_state, 'GOsignal')
        % For ‘GOsignal’ state, two time windows
        
        % 1. Time window ‘Delay’ (-150 to 0 ms)
        time_window_Delay.window_start = -150;
        time_window_Delay.window_end = 0;
        
        OUTPUT_PATH_binned_data_for_saving_txt = [OUTPUT_PATH_binned_data_for_saving '/' output_filename.Delay ];
        loadedData_Delay = loadedData.DECODING_RESULTS;
        
        [selected_data_Delay, selected_bins_Delay, bin_times_Delay] = ...
            extract_window_from_data_epoch(typeOfDecoding, all_mean_decoding_results, loadedData_Delay, time_window_Delay, OUTPUT_PATH_binned_data_for_saving_txt);
        
        mean_decoding_results_Delay = horzcat(selected_data_Delay{:});
        data_for_plotting_averages.(current_target_state).mean_decoding_results_Delay = mean(mean_decoding_results_Delay,1);
        mean_decoding_results_100_Delay = mean_decoding_results_Delay*100;
        data_for_plotting_averages.(current_target_state).mean_decoding_results_100_Delay = mean(mean_decoding_results_100_Delay,1);
        
        data_for_plotting_averages.(current_target_state).selected_bins_Delay = selected_bins_Delay;
        data_for_plotting_averages.(current_target_state).bin_times_Delay = bin_times_Delay;
        
        data_for_plotting_averages.(current_target_state).block_data_Delay = block_grouping.block_data;
        
        
        % 2. ‘PostSac’ time window (200 to 350 ms)
        time_window_PostSac.window_start = 200;
        time_window_PostSac.window_end = 350;
        
        OUTPUT_PATH_binned_data_for_saving_txt = [OUTPUT_PATH_binned_data_for_saving '/' output_filename.PostSac ];
        loadedData_PostSac = loadedData.DECODING_RESULTS;
        
        [selected_data_PostSac, selected_bins_PostSac, bin_times_PostSac] = ...
            extract_window_from_data_epoch(typeOfDecoding, all_mean_decoding_results, loadedData_PostSac, time_window_PostSac, OUTPUT_PATH_binned_data_for_saving_txt);
        
        mean_decoding_results_PostSac = horzcat(selected_data_PostSac{:});
        data_for_plotting_averages.(current_target_state).mean_decoding_results_PostSac = mean(mean_decoding_results_PostSac,1);
        mean_decoding_results_100_PostSac = mean_decoding_results_PostSac*100;
        data_for_plotting_averages.(current_target_state).mean_decoding_results_100_PostSac = mean(mean_decoding_results_100_PostSac,1);
        
        data_for_plotting_averages.(current_target_state).selected_bins_PostSac = selected_bins_PostSac;
        data_for_plotting_averages.(current_target_state).bin_times_PostSac = bin_times_PostSac;
        
        data_for_plotting_averages.(current_target_state).block_data_PostSac = block_grouping.block_data;
        
    end % strcmp(target_state, 'cueON')
    
    
    
end % stateIdx = 1:numel(target_state)




end



% different color scheme, a color flip, different outlier symbol
% subplot(3,2,4)
% h = daboxplot(data2,'groups',group_inx,'xtlabels', condition_names,...
%     'colors',c,'fill',0,'whiskers',0,'scatter',2,'outsymbol','k*',...
%     'outliers',1,'scattersize',16,'flipcolors',1,'boxspacing',1.2,...
%     'legend',group_names);
% ylabel('Performance');
% xl = xlim; xlim([xl(1), xl(2)+0.75]); % make more space for the legend
% set(gca,'FontSize',9);



% extract_window_from_data_epoch



function [selected_data, selected_bins, bin_times_selected] = ...
    extract_window_from_data_epoch(typeOfDecoding, all_mean_decoding_results, DECODING_RESULTS, time_window, output_filename)
%EXTRACT_WINDOW_FROM_DATA_EPOCH Extracts data for a specified time window.
%   Inputs:
%   - typeOfDecoding: Type of decoding being used.
%   - all_mean_decoding_results: Cell array containing decoding results.
%   - DECODING_RESULTS: Structure containing binning information.
%   - time_window: Structure with fields window_start and window_end (in ms).
%   - output_filename: Name of the output .txt file to save results.
%
%   Outputs:
%   - selected_data: Data corresponding to the selected bins.
%   - selected_bins: Indices of the selected bins.
%   - bin_times_selected: Start times of the selected bins.


% Adjust bin times if decoding across sessions
if strcmp(typeOfDecoding, 'сollected_files_across_sessions')
    DECODING_RESULTS.DS_PARAMETERS.binned_site_info.binning_parameters.the_bin_start_times = DECODING_RESULTS.DS_PARAMETERS.binned_site_info.binning_parameters.the_bin_start_times - 500;
end

% Extract bin start times and bin width
bin_start_times = DECODING_RESULTS.DS_PARAMETERS.binned_site_info.binning_parameters.the_bin_start_times;
bin_width = DECODING_RESULTS.DS_PARAMETERS.binned_site_info.binning_parameters.bin_width;

% Compute bin end times
bin_end_times = bin_start_times + bin_width;

% Find bins fully within the specified time window
valid_bins = find((bin_start_times >= time_window.window_start) & (bin_end_times <= time_window.window_end));

% If valid bins exist, extend the range by one bin on each side
if ~isempty(valid_bins)
    extended_valid_bins = unique([max(1, valid_bins(1)-1), valid_bins, min(length(bin_start_times), valid_bins(end)+1)]);
else
    % If no bins are found, return empty results and issue a warning
    warning('No bins found within the specified time window.');
    selected_data = {};
    selected_bins = [];
    bin_start_times_selected = [];
    return;
end

% Selected bins
selected_bins = extended_valid_bins;

% Start and end times for the selected bins
bin_times_selected.bin_start_times_selected = bin_start_times(selected_bins);
bin_times_selected.bin_end_times_selected = bin_end_times(selected_bins);

% Extract data for selected bins from all_mean_decoding_results
num_conditions = length(all_mean_decoding_results);
selected_data = cell(1, num_conditions);

for i = 1:num_conditions
    selected_data{i} = all_mean_decoding_results{i}(selected_bins);
end

% Prepare output text for saving to a file
output_text = sprintf('Selected Bin Indices:\n%s\n\n', mat2str(selected_bins));
output_text = [output_text, sprintf('Start Times of Selected Bins (ms):\n%s\n\n', mat2str(bin_times_selected.bin_start_times_selected))];
output_text = [output_text, sprintf('End Times of Selected Bins (ms):\n%s\n\n', mat2str(bin_times_selected.bin_end_times_selected))];

% Write output text to the specified file
try
    % Append .txt to the output filename
    output_filename_txt = [output_filename '.txt'];
    
    % Open the file for writing
    fid = fopen(output_filename_txt, 'w');
    
    % Write the output text to the file
    fprintf(fid, '%s', output_text);
    
    % Close the file
    fclose(fid);
    
catch
    % Warn user if the file could not be written
    warning('Could not write results to file: %s', output_filename_txt);
end
end



function daboxplotAveragesAcrossSessions(monkey, typeOfDecoding, dateOfRecording, target_brain_structure, target_state, combinedLabel, data_for_plotting_averages_before, data_for_plotting_averages_after, settings, OUTPUT_PATH_binned_data_for_saving);
%% Plot the results

% Define a colormap for the sessions before inactivation
% RGB palette for 7 shades of blue

color_fig1.color_RGB = [
    0.4666, 0.6627, 0.3098;  % dark light green
    0.2921, 0.5058, 0.2921;  % dark green
    0.2705, 0.5058, 0.6627;  % dark light blue
    0.1745, 0.3313, 0.5058;  % dark blue
    ];

color_fig1.colors_appearance = {
    'dark light green';  % for the first data group (Monkey 1)
    'dark green';        % for the second data group (Monkey 1)
    'dark light blue';   % for the first data group (Monkey 2)
    'dark blue';         % for the second data group (Monkey 2)
    };



color_fig2.color_RGB = [
    0.6666, 0.8627, 0.5098;  % light green
    0.3921, 0.7058, 0.3921;  % green
    0.4705, 0.7058, 0.8627;  % light blue
    0.2745, 0.4313, 0.7058;  % blue
    ];


color_fig2.colors_appearance = {
    'light green';     % for the first group of data (Monkey 1)
    'green';           % for the second group of data (Monkey 1)
    'light blue';      % for the first group of data (Monkey 2)
    'blue';            % for the first group of data (Monkey 2)
    };




% group_names = {'Before, M_1', 'After, M_1' , 'M_2', 'M_2'};
epoch_names = {'Cue', 'Delay', 'PostSac'};
epochs_str = strjoin(epoch_names, '_'); % Join epoch names with underscores


% Initialize an empty string for concatenation
monkey_str = '';

% Loop through all monkey names
for i = 1:length(monkey)
    % Extract the first three characters of each monkey's name
    monkey_str = strcat(monkey_str, monkey{i}(1:3));
    % Add an underscore if it's not the last name
    if i < length(monkey)
        monkey_str = strcat(monkey_str, '_');
    end
end






% Name of monkey 
first_letters = cellfun(@(x) x(1), monkey, 'UniformOutput', false); % Take first letter 


blocks_before = {};
blocks_after = {};

for monkey_idx = 1:length(monkey)
    current_monkey = monkey{monkey_idx};
    
    % Extracting the data for this monkey
    data_before = data_for_plotting_averages_before.(current_monkey);
    data_after = data_for_plotting_averages_after.(current_monkey);
    
    % First group of data
    blocks_before = [blocks_before; unique({
        data_before.cueON.block_data_Cue, ...
        data_before.GOsignal.block_data_Delay, ...
        data_before.GOsignal.block_data_PostSac
    })];
    
    % Second group of data
    blocks_after = [blocks_after; unique({
        data_after.cueON.block_data_Cue, ...
        data_after.GOsignal.block_data_Delay, ...
        data_after.GOsignal.block_data_PostSac
    })];
end

% Remove duplicate blocks
blocks_before = unique(blocks_before);
blocks_after = unique(blocks_after);

% Replace colon with underscore
blocks_before_clean = strrep(blocks_before{1}, 'block: ', ''); % Убираем "block: "
blocks_after_clean = strrep(blocks_after{1}, 'block: ', '');   % Убираем "block: "
block_str = ['block_', blocks_before_clean, '_and_block_', strrep(blocks_after_clean, ',', '_')];





% Check whether all blocks are identical within the first and second data groups
if numel(blocks_before) == 1
    block_label_before = blocks_before{1};
else
    error('The blocks for first group of data are different. Check the data!');
end

if numel(blocks_after) == 1
    block_label_after = blocks_after{1};
else
    error('The blocks for second group of data are different. Check the data!');
end

% Create group_names
group_names = {
    ['Monkey: ' first_letters{1} ', ' block_label_before], ...
    ['Monkey: ' first_letters{1} ', ' block_label_after], ...
    ['Monkey: ' first_letters{2} ', ' block_label_before], ...
    ['Monkey: ' first_letters{2} ', ' block_label_after]
    };




% Get the number of sessions for data_for_plotting_averages_after
% numSessionsAfter = numel(data_for_plotting_averages_after.session_info);




% Initialization of the data variable
data = {};

% For each monkeys
for monkey_idx = 1:length(monkey)
    current_monkey = monkey{monkey_idx};
    
    % Create the first cell with data_for_plotting_averages_before for the current monkey
    data_before = [
        data_for_plotting_averages_before.(current_monkey).cueON.mean_decoding_results_100_Cue(:), ...
        data_for_plotting_averages_before.(current_monkey).GOsignal.mean_decoding_results_100_Delay(:), ...
        data_for_plotting_averages_before.(current_monkey).GOsignal.mean_decoding_results_100_PostSac(:)
    ];

    % Create the second cell with data_for_plotting_averages_before for the current monkey
    data_after = [
        data_for_plotting_averages_after.(current_monkey).cueON.mean_decoding_results_100_Cue(:), ...
        data_for_plotting_averages_after.(current_monkey).GOsignal.mean_decoding_results_100_Delay(:), ...
        data_for_plotting_averages_after.(current_monkey).GOsignal.mean_decoding_results_100_PostSac(:)
    ];

    % Combine the data of this monkey into the corresponding cells in the variable data
    if monkey_idx == 1
        % For the first monkey (data for first and second data group)
        data{1} = data_before;
        data{2} = data_after;
    elseif monkey_idx == 2
        % For the second monkey (data for first and second data group)
        data{3} = data_before;
        data{4} = data_after;
    end
end



% Initialize a vector to store the number of sessions per monkey
num_sessions = zeros(1, length(data) / 2); % Divide by 2 since each monkey has two groups (before and after)

% Loop through the data and count the number of sessions for each monkey
for monkey_idx = 1:length(data) / 2
    % Extract data for "before" and "after" conditions
    data_before = data{(monkey_idx - 1) * 2 + 1};
    data_after = data{monkey_idx * 2};
    
    % Check the number of rows in either condition to count sessions
    num_sessions(monkey_idx) = size(data_before, 1); % Rows represent the number of sessions
end

% Create a string to use in the annotation
session_annotation = "";
for monkey_idx = 1:length(num_sessions)
    session_annotation = session_annotation + ...
        sprintf('Monkey %s: %d sessions\n', first_letters{monkey_idx}, num_sessions(monkey_idx));
end



% Initializing
session_annotation_Bac = "";
session_annotation_Lin = "";

% Info about session
for monkey_idx = 1:length(num_sessions)
    if monkey_idx == 1
        % for Bacchus
        session_annotation_Bac = sprintf('Monkey %s: %d sessions\n', first_letters{monkey_idx}, num_sessions(monkey_idx));
    elseif monkey_idx == 2
        % for Linus
        session_annotation_Lin = sprintf('Monkey %s: %d sessions\n', first_letters{monkey_idx}, num_sessions(monkey_idx));
    end
end



% Initializing the structure 
monkey_Units_Trials_info = struct();

for monkey_idx = 1:length(monkey)
    current_monkey = monkey{monkey_idx};

    info_str_after = data_for_plotting_averages_after.(current_monkey).cueON.numOfUnits_and_numOfTrials_info_labelsAppears;
    info_str_before = data_for_plotting_averages_before.(current_monkey).cueON.numOfUnits_and_numOfTrials_info_labelsAppears;
    
    monkey_Units_Trials_info.(current_monkey).before = info_str_before;
    monkey_Units_Trials_info.(current_monkey).after = info_str_after;
end






%% Plot

% title
title_text = sprintf('%s; %s', target_brain_structure, strrep(combinedLabel, ' ', ', '));

% plot 
f1 = create_boxplot(data, epoch_names, group_names, title_text, session_annotation_Bac, session_annotation_Lin, monkey_Units_Trials_info, color_fig1.color_RGB, 0, 50, 0, 1, 1);
f2 = create_boxplot(data, epoch_names, group_names, title_text, session_annotation_Bac, session_annotation_Lin, monkey_Units_Trials_info, color_fig2.color_RGB, 1, 40, 0, 0.7, 0);

% save
filename1 = sprintf('boxplot_for_%s_%s_%s_%s_%s_%s_clear_boxes.png', monkey_str, typeOfDecoding, target_brain_structure, epochs_str, block_str, combinedLabel);
saveas(f1, fullfile(OUTPUT_PATH_binned_data_for_saving, filename1));
filename2 = sprintf('boxplot_for_%s_%s_%s_%s_%s_%s_color_boxes.png', monkey_str, typeOfDecoding, target_brain_structure, epochs_str, block_str, combinedLabel);
saveas(f2, fullfile(OUTPUT_PATH_binned_data_for_saving, filename2));



close(f1);
close(f2);


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % different color scheme, a color flip, different outlier symbol
% % 1. different color scheme, a color flip, different outlier symbol
% f1 = figure;
% h = daboxplot(data,'xtlabels', epoch_names,...
%     'colors',color_fig1.color_RGB,'fill',0,'whiskers',0,'scatter',2,'outsymbol','k+',...
%     'outliers',1,'scattersize',50,'flipcolors',1,'boxspacing',1.5, 'boxwidth', 0.8, ...
%      'legend',group_names);
% xl = xlim; xlim([xl(1), xl(2)+1.1]); % make more space for the legend
% 
% 
% set(gca,'FontSize',13);
% set(gcf,'position',[550, 185, 925, 805])  % set(gcf,'position',[610,420,770,500])
% set(gca, 'Position', [0.08, 0.045, 0.9, 0.52])  % set(gca, 'Position', [0.08, 0.08, 0.9, 0.8] )
% tickPositions = 50:10:100; % Calculate the tick positions every 200 ms
% yticks(tickPositions);
% ylim([50 100])
% ylabel('Classification Accuracy', 'Position', [0.2, 75]) % move the label of OY axis  away from the Y axis [X Y same as axis] !!
% title_text = sprintf('%s; %s', target_brain_structure, strrep(combinedLabel, ' ', ', ')); % Create the title
% title(title_text);
% h_title = title(title_text);
% title_pos = get(h_title, 'Position'); % Get the current coordinates of the heading position
% set(h_title, 'Position', [title_pos(1) - 0.5, title_pos(2) + 1.4, title_pos(3)]); % Move the title to the left (decrease the X-coordinate)
% 
% annotation('textbox', [0.11, 0.87, 0.2, 0.1], 'String', session_annotation_Bac, ...
%     'FitBoxToText', 'on', 'FontSize', 11, 'EdgeColor', 'none', 'FontWeight', 'bold'); % No box around the annotation
% 
% annotation('textbox', [0.55, 0.87, 0.2, 0.1], 'String', session_annotation_Lin, ...
%     'FitBoxToText', 'on', 'FontSize', 11, 'EdgeColor', 'none', 'FontWeight', 'bold'); % No box around the annotation
% 
% 
%  
% annotation('textbox', [0.12, 0.73, 0.3, 0.2], 'String', monkey_Units_Trials_info.Bacchus.before, ...
%     'FitBoxToText', 'on', 'FontSize', 10, 'EdgeColor', 'none', 'Color', [0.4666, 0.6627, 0.3098], 'FontWeight', 'bold');
% 
% annotation('textbox', [0.12, 0.58, 0.3, 0.2], 'String', monkey_Units_Trials_info.Bacchus.after, ...
%     'FitBoxToText', 'on', 'FontSize', 10, 'EdgeColor', 'none', 'Color', [0.2921, 0.5058, 0.2921], 'FontWeight', 'bold');
% 
% annotation('textbox', [0.56, 0.73, 0.3, 0.2], 'String', monkey_Units_Trials_info.Linus.before, ...
%     'FitBoxToText', 'on', 'FontSize', 10, 'EdgeColor', 'none', 'Color', [0.2705, 0.5058, 0.6627], 'FontWeight', 'bold');
% 
% annotation('textbox', [0.56, 0.58, 0.3, 0.2], 'String', monkey_Units_Trials_info.Linus.after, ...
%     'FitBoxToText', 'on', 'FontSize', 10, 'EdgeColor', 'none', 'Color', [0.1745, 0.3313, 0.5058], 'FontWeight', 'bold');
% 
% 
% filename1 = sprintf('boxplot_for_%s_%s_%s_%s_%s_%s_clear_boxes.png', monkey_str, typeOfDecoding, target_brain_structure, epochs_str, block_str, combinedLabel);
% 
% 
% 
% 
% % 2. transparent boxplots with no whiskers and jittered datapoints underneath
% f2 = figure;
% h = daboxplot(data,'scatter',2,'whiskers',0,'boxalpha',0.7,...
%     'xtlabels', epoch_names, 'colors',color_fig2.color_RGB, 'outsymbol','k*', ...
%     'scattersize',40, 'flipcolors',0, 'boxspacing',1.5, 'boxwidth', 0.8);
% xl = xlim; xlim([xl(1), xl(2)+1.1]);       % make space for the legend
% legend([h.bx(1,:)],group_names);            % add the legend manually
% 
% set(gca,'FontSize',13);
% set(gcf,'position',[550, 185, 925, 805]) % set(gcf,'position',[610,420,770,650])
% set(gca, 'Position', [0.08, 0.045, 0.9, 0.52])
% %tickPositions = 50:10:100; % Calculate the tick positions every 200 ms
% yticks(tickPositions);
% ylim([50 100])
% ylabel('Classification Accuracy', 'Position', [0.2, 75]) % move the label of OY axis  away from the Y axis
% h_title = title(title_text);
% title_pos = get(h_title, 'Position'); % Get the current coordinates of the header position
% set(h_title, 'Position', [title_pos(1) - 0.5, title_pos(2) + 1.4, title_pos(3)]); % Move the title to the left (decrease the X-coordinate)
% 
% % titlePos = get(t, 'Position');
% % titlePos(2) = titlePos(2) + 10; % Increase the vertical position by 5
% % set(t, 'Position', titlePos);
% 
% annotation('textbox', [0.11, 0.87, 0.2, 0.1], 'String', session_annotation_Bac, ...
%     'FitBoxToText', 'on', 'FontSize', 11, 'EdgeColor', 'none', 'FontWeight', 'bold'); % No box around the annotation
% 
% annotation('textbox', [0.55, 0.87, 0.2, 0.1], 'String', session_annotation_Lin, ...
%     'FitBoxToText', 'on', 'FontSize', 11, 'EdgeColor', 'none', 'FontWeight', 'bold'); % No box around the annotation
% 
% 
% 
% annotation('textbox', [0.12, 0.73, 0.3, 0.2], 'String', monkey_Units_Trials_info.Bacchus.before, ...
%     'FitBoxToText', 'on', 'FontSize', 10, 'EdgeColor', 'none', 'Color', [0.4666, 0.6627, 0.3098], 'FontWeight', 'bold');
% 
% annotation('textbox', [0.12, 0.58, 0.3, 0.2], 'String', monkey_Units_Trials_info.Bacchus.after, ...
%     'FitBoxToText', 'on', 'FontSize', 10, 'EdgeColor', 'none', 'Color', [0.2921, 0.5058, 0.2921], 'FontWeight', 'bold');
% 
% annotation('textbox', [0.56, 0.73, 0.3, 0.2], 'String', monkey_Units_Trials_info.Linus.before, ...
%     'FitBoxToText', 'on', 'FontSize', 10, 'EdgeColor', 'none', 'Color', [0.2705, 0.5058, 0.6627], 'FontWeight', 'bold');
% 
% annotation('textbox', [0.56, 0.58, 0.3, 0.2], 'String', monkey_Units_Trials_info.Linus.after, ...
%     'FitBoxToText', 'on', 'FontSize', 10, 'EdgeColor', 'none', 'Color', [0.1745, 0.3313, 0.5058], 'FontWeight', 'bold');
% 
% 
% 
% 
% 
% 
% filename2 = sprintf('boxplot_for_%s_%s_%s_%s_%s_%s_color_boxes.png', monkey_str, typeOfDecoding, target_brain_structure, epochs_str, block_str, combinedLabel);
% 
% % Save the figures
% saveas(f1, fullfile(OUTPUT_PATH_binned_data_for_saving, filename1));
% saveas(f2, fullfile(OUTPUT_PATH_binned_data_for_saving, filename2));
% 
% 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%close(gcf);
%end

end


function f = create_boxplot(data, epoch_names, group_names, title_text, session_annotation_Bac, session_annotation_Lin, monkey_Units_Trials_info, color_fig, fill_flag, scatter_size, whisker_flag, box_alpha, flipcolors_flag)
   % Plot a graph with parameters
    f = figure;
    h = daboxplot(data, 'xtlabels', epoch_names, ...
        'colors', color_fig, 'fill', fill_flag, 'whiskers', whisker_flag, 'boxalpha',box_alpha, 'scatter', 2, 'outsymbol', 'k*', ...
        'outliers', 1, 'scattersize', scatter_size, 'flipcolors', flipcolors_flag, 'boxspacing', 1.5, 'boxwidth', 0.8, ...
        'legend', group_names);

    xl = xlim; xlim([xl(1), xl(2) + 1.0]); % make more space for the legend
    set(gca, 'FontSize', 13);
    set(gcf, 'position', [550, 185, 925, 805])  % set(gcf,'position',[610,420,770,500])
    set(gca, 'Position', [0.08, 0.045, 0.9, 0.52])  % set(gca, 'Position', [0.08, 0.08, 0.9, 0.8] )
    tickPositions = 20:10:100; % Calculate the tick positions every 200 ms
    yticks(tickPositions);
    ylim([20 100])
    ylabel('Classification Accuracy', 'Position', [0.2, 75]) % move the label of OY axis  away from the Y axis [X Y same as axis]

    % Title
    title(title_text);
    h_title = title(title_text);
    title_pos = get(h_title, 'Position'); % Get the current coordinates of the heading position
    set(h_title, 'Position', [title_pos(1) - 0.5, title_pos(2) + 1.4, title_pos(3)]); % Move the title to the left (decrease the X-coordinate)

    % Adding annotations
    add_annotations(session_annotation_Bac, session_annotation_Lin, monkey_Units_Trials_info);
end



function add_annotations(session_annotation_Bac, session_annotation_Lin, monkey_Units_Trials_info)
    % Adding annotations for Bacchus (session info)
    annotation('textbox', [0.11, 0.87, 0.2, 0.1], 'String', session_annotation_Bac, ...
        'FitBoxToText', 'on', 'FontSize', 11, 'EdgeColor', 'none', 'FontWeight', 'bold'); % No box around the annotation

    % Adding annotations for Linus (session info)
    annotation('textbox', [0.57, 0.87, 0.2, 0.1], 'String', session_annotation_Lin, ...
        'FitBoxToText', 'on', 'FontSize', 11, 'EdgeColor', 'none', 'FontWeight', 'bold'); % No box around the annotation

    
    
    % Coloring the annotation for Bacchus (before) in light green
    annotation('textbox', [0.13, 0.73, 0.3, 0.2], 'String', monkey_Units_Trials_info.Bacchus.before, ...
        'FitBoxToText', 'on', 'FontSize', 10, 'EdgeColor', 'none', 'Color', [0.4666, 0.6627, 0.3098], 'FontWeight', 'bold');

    % Coloring the annotation for Bacchus (after) in dark green
    annotation('textbox', [0.13, 0.58, 0.3, 0.2], 'String', monkey_Units_Trials_info.Bacchus.after, ...
        'FitBoxToText', 'on', 'FontSize', 10, 'EdgeColor', 'none', 'Color', [0.2921, 0.5058, 0.2921], 'FontWeight', 'bold');

    % Coloring the annotation for Linus (before) in light blue
    annotation('textbox', [0.59, 0.73, 0.3, 0.2], 'String', monkey_Units_Trials_info.Linus.before, ...
        'FitBoxToText', 'on', 'FontSize', 10, 'EdgeColor', 'none', 'Color', [0.2705, 0.5058, 0.6627], 'FontWeight', 'bold');

    % Coloring the annotation for Linus (after) in dark blue
    annotation('textbox', [0.59, 0.58, 0.3, 0.2], 'String', monkey_Units_Trials_info.Linus.after, ...
        'FitBoxToText', 'on', 'FontSize', 10, 'EdgeColor', 'none', 'Color', [0.1745, 0.3313, 0.5058], 'FontWeight', 'bold');
end
