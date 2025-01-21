function sdndt_Sim_LIP_dPul_NDT_daboxplot(injection, typeOfDecoding, method_of_decoding)

% For across session analysis, you just need to average individual session
% sdndt_Sim_LIP_dPul_NDT_daboxplot('1', 'сollected_files_across_sessions', 'Decoding')
% sdndt_Sim_LIP_dPul_NDT_daboxplot('1', 'merged_files_across_sessions', 'Cross_decoding');


% monkey: 'Linus', 'Bacchus'
%
% injection: '0' - control sessions, '1' - inactivation sessions (for inactivation experiment),
%            '2' - for functional interaction experiment
%
% typeOfDecoding: 'сollected_files_across_sessions' - to plot only one data set (e.g. "train: block 3, test: block 4")
%                 'two_group_combination' - to plot,two data sets (e.g. "train: block 3, test: block 4" and
%                                           "train: block 4, test: block 3" at the same graph) - NOT CREATED YET
%
% method_of_decoding:  'Decoding', 'Cross_decoding'

%%

% Start timing the execution
startTime = tic;



%% list of monkeys
monkey_list = {'Bacchus', 'Linus'};


%% Define the list of required files

listOfRequiredFiles_all = struct();
exclude_session = false;
for monkey_idx = 1:numel(monkey_list)
    monkey = monkey_list{monkey_idx};
    
    % If you take ‘thirdBlockFiles’ and 'fourthBlockFiles' in the analysis,
    % then you should remove the '20210709' session from the filelist_of_days_from_Simultaneous_dPul_PPC_recordings.m file .
    
    if strcmp(monkey, 'Bacchus')
        listOfRequiredFiles.group_1 = { 'overlapBlocksFiles_BeforeInjection' , ...
            'thirdBlockFiles'
            };
        listOfRequiredFiles.group_2 = {'overlapBlocksFiles_AfterInjection', ...
            'fourthBlockFiles'
            };
    elseif strcmp(monkey, 'Linus')
        listOfRequiredFiles.group_1 = { 'overlapBlocksFiles_BeforeInjection_3_4', ...
            'thirdBlockFiles'
            };
        listOfRequiredFiles.group_2 = { 'overlapBlocksFiles_AfterInjection_3_4', ...
            'fourthBlockFiles'
            };
    end
    listOfRequiredFiles_all.(monkey) = listOfRequiredFiles;
    
    % Check if 'thirdBlockFiles' or 'fourthBlockFiles' are present
    if any(strcmp('thirdBlockFiles', listOfRequiredFiles.group_1)) || ...
            any(strcmp('fourthBlockFiles', listOfRequiredFiles.group_2))
        exclude_session = true;
    end
end

%% Define typeOfSessions
% Calculate typeOfSessions based on the injection parameter
if strcmp(injection, '1')
    typeOfSessions = {'right'}; % For control and injection experiments
    
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
    %      combinations_inj_and_target_brain_structure = struct('injection', { injection}, 'target_brain_structure', {'LIP_R'});
    
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
    
end



numTypeBlocks = numel(listOfRequiredFiles_all.Linus.group_1);

% Calculate total number of iterations
totalIterations = numApproach * numTypeBlocks * numCombinations * numLabels * numFieldNames * numTypesOfSessions;
overallProgress = 0; % Initialize progress


for file_index = 1:numTypeBlocks % Loop through each file in listOfRequiredFiles
    
    % if strcmp(typeOfDecoding, 'сollected_files_across_sessions')
    
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
    
    % Determine whether session '20210709' should be excluded for the current iteration
    exclude_session = any(strcmp('thirdBlockFiles', current_file_1_all_monkeys)) || ...
        any(strcmp('fourthBlockFiles', current_file_2_all_monkeys));
    % end
    
    
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
                
                
                
                datesForSessions_all = struct();
                for monkey_idx = 1:numel(monkey_list)
                    monkey = monkey_list{monkey_idx};
                    
                    %                                         if strcmp(injection, '1')
                    %                                             for type = 1:numel(typeOfSessions)
                    %                                                 datesForSessions_all.(monkey){type} = filelist_of_days_from_Simultaneous_dPul_PPC_recordings(monkey, injection, typeOfSessions{type});
                    %                                             end
                    %                                         elseif strcmp(injection, '0') || strcmp(injection, '2')
                    %                                             datesForSessions_all.(monkey) = filelist_of_days_from_Simultaneous_dPul_PPC_recordings(monkey, injection, typeOfSessions);
                    %                                         end
                    
                    
                    %                     if strcmp(injection, '1')
                    %                         for type = 1:numel(typeOfSessions)
                    %                             datesForSessions_all.(monkey){type} = filelist_of_days_from_Simultaneous_dPul_PPC_recordings(monkey, injection, typeOfSessions{type});
                    %                             if exclude_session
                    %                                 datesForSessions_all.(monkey){type} = datesForSessions_all.(monkey){type}(~strcmp(datesForSessions_all.(monkey){type}, '20210709'));
                    %                             end
                    %                         end
                    %                     elseif strcmp(injection, '0') || strcmp(injection, '2')
                    %                         datesForSessions_all.(monkey) = filelist_of_days_from_Simultaneous_dPul_PPC_recordings(monkey, injection, typeOfSessions);
                    %                         if exclude_session
                    %                             datesForSessions_all.(monkey) = datesForSessions_all.(monkey)(~strcmp(datesForSessions_all.(monkey), '20210709'));
                    %                         end
                    %                     end
                    
                    
                    if strcmp(injection, '1')
                        for type = 1:numel(typeOfSessions)
                            datesForSessions_all.(monkey){type} = filelist_of_days_from_Simultaneous_dPul_PPC_recordings(monkey, injection, typeOfSessions{type});
                            if exclude_session
                                datesForSessions_all.(monkey){type} = datesForSessions_all.(monkey){type}(~strcmp(datesForSessions_all.(monkey){type}, '20210709'));
                            end
                        end
                    elseif strcmp(injection, '0') || strcmp(injection, '2')
                        datesForSessions_all.(monkey) = filelist_of_days_from_Simultaneous_dPul_PPC_recordings(monkey, injection, typeOfSessions);
                        if exclude_session
                            datesForSessions_all.(monkey) = datesForSessions_all.(monkey)(~strcmp(datesForSessions_all.(monkey), '20210709'));
                        end
                    end
                    
                    
                end
                
                
                
                
                % Loop through each target_state parameter
                fieldNames = fieldnames(targetParams);
                
                
                for j = 1:numTypesOfSessions
                    % Call the main decoding function based on dateOfRecording
                    
                    current_type_of_session = typeOfSessions{j}; % Get the corresponding type of session !!!!!
                    
                    
                    
                    % Universal approach to processing all monkey data
                    current_set_of_dates_all = struct();
                    for monkey_idx = 1:numel(monkey_list)
                        monkey = monkey_list{monkey_idx}; % current monkey
                        % Getting data for the current monkey
                        current_set_of_dates_all.(monkey) = datesForSessions_all.(monkey){j};
                    end
                    
                    
                    
                    
                    % Call the internal decoding function only once
                    sdndt_Sim_LIP_dPul_NDT_daboxplot_internal(monkey_list, current_injection, current_type_of_session, typeOfDecoding, method_of_decoding, ...
                        current_set_of_dates_all, current_target_brain_structure, fieldNames, current_label, current_approach, ...
                        current_file_1_all_monkeys, current_file_2_all_monkeys);
                    
                    
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
block_grouping_folder_crossdec = '';

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
    data_gr_1 = processRequiredFiles(current_monkey, typeOfDecoding, current_approach, ...
        block_grouping_folder_prefix, givenListOfRequiredFiles_gr_1{monkey_idx});
    
    %  for group 1 (for current monkeys)
    data_gr_2 = processRequiredFiles(current_monkey, typeOfDecoding, current_approach, ...
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

% if  strcmp(typeOfDecoding, 'сollected_files_across_sessions')
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
    monkey_prefix = 'Both_';  % If there are two monkeys, we specify the prefix "Both"
else
    monkey_prefix = monkey_list{1};  % If there is one monkey, we use its name.
end

% create output folder
type_of_graphs = 'dabox_plot';

if strcmp(typeOfDecoding, 'сollected_files_across_sessions')
    type_of_folder = 'average_across_session';
elseif strcmp(typeOfDecoding, 'merged_files_across_sessions')
    type_of_folder = 'merged_files_across_sessions';
end
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
daboxplotAveragesAcrossSessions(monkey_list, typeOfDecoding, method_of_decoding, dateOfRecording, target_brain_structure, target_state, combinedLabel, data_for_plotting_averages_before, data_for_plotting_averages_after, settings, OUTPUT_PATH_binned_data_for_saving);

% else
%     partOfName = dateOfRecording;
% end


% % Load required files for each session or merged files
% OUTPUT_PATH_list_of_required_files = [OUTPUT_PATH_binned dateOfRecording '/List_of_required_files/sdndt_Sim_LIP_dPul_NDT_' partOfName '_list_of_required_files.mat'];
% load(OUTPUT_PATH_list_of_required_files);

end



function [grouping_folder] = processRequiredFiles(monkey, typeOfDecoding, current_approach, ...
    block_grouping_folder_prefix, currentFile)



% Initialize the result structure
grouping_folder = struct();
num_block = {};



% Determine block-specific settings based on current file
if strcmp(currentFile, 'firstBlockFiles') && strcmp(current_approach, 'overlap_approach')
    
    num_block_suffix = '1';
    if strcmp(typeOfDecoding, 'сollected_files_across_sessions')
        block_grouping_folder = sprintf('%sBy_block', block_grouping_folder_prefix);
        block_grouping_folder_crossdec = sprintf('%sBy_block', block_grouping_folder_prefix);
    elseif strcmp(typeOfDecoding, 'merged_files_across_sessions')
        [prefix, ~] = strtok(current_approach, '_');
        block_grouping_folder = sprintf('%s_FilesAcrossSessions_Block_%s', prefix, num_block_suffix);
        block_grouping_folder_crossdec = sprintf('%sBy_block', block_grouping_folder_prefix);
    end
    block_data = 'block: 1';
    
elseif strcmp(currentFile, 'thirdBlockFiles') && strcmp(current_approach, 'overlap_approach')
    
    num_block_suffix = '3';
    if strcmp(typeOfDecoding, 'сollected_files_across_sessions')
        block_grouping_folder = sprintf('%sBy_block', block_grouping_folder_prefix);
        block_grouping_folder_crossdec = sprintf('%sBy_block', block_grouping_folder_prefix);
    elseif strcmp(typeOfDecoding, 'merged_files_across_sessions')
        [prefix, ~] = strtok(current_approach, '_');
        block_grouping_folder = sprintf('%s_FilesAcrossSessions_Block_%s', prefix, num_block_suffix);
        block_grouping_folder_crossdec = sprintf('%sBy_block', block_grouping_folder_prefix);
    end
    block_data = 'block: 3';
    
elseif strcmp(currentFile, 'fourthBlockFiles') && strcmp(current_approach, 'overlap_approach')
    
    num_block_suffix = '4';
    if strcmp(typeOfDecoding, 'сollected_files_across_sessions')
        block_grouping_folder = sprintf('%sBy_block', block_grouping_folder_prefix);
        block_grouping_folder_crossdec = sprintf('%sBy_block', block_grouping_folder_prefix);
    elseif strcmp(typeOfDecoding, 'merged_files_across_sessions')
        [prefix, ~] = strtok(current_approach, '_');
        block_grouping_folder = sprintf('%s_FilesAcrossSessions_Block_%s', prefix, num_block_suffix);
        block_grouping_folder_crossdec = sprintf('%sBy_block', block_grouping_folder_prefix);
    end
    block_data = 'block: 4';
    
elseif strcmp(currentFile, 'overlapBlocksFiles_BeforeInjection') && strcmp(monkey, 'Bacchus')
    
    num_block_suffix = '1';
    if strcmp(typeOfDecoding, 'сollected_files_across_sessions')
        block_grouping_folder = 'Overlap_blocks_BeforeInjection/';
        block_grouping_folder_crossdec = 'Overlap_blocks_3_4';
    elseif strcmp(typeOfDecoding, 'merged_files_across_sessions')
        block_grouping_folder = 'overlapBlocksFilesAcrossSessions_BeforeInjection';
        block_grouping_folder_crossdec = 'Overlap_blocks_3_4';
    end
    block_data = 'block: 1';
    
elseif strcmp(currentFile, 'overlapBlocksFiles_AfterInjection') && strcmp(monkey, 'Bacchus')
    
    num_block_suffix = '3';
    if strcmp(typeOfDecoding, 'сollected_files_across_sessions')
        block_grouping_folder = 'Overlap_blocks_AfterInjection/';
        block_grouping_folder_crossdec = 'Overlap_blocks_3_4';
    elseif strcmp(typeOfDecoding, 'merged_files_across_sessions')
        block_grouping_folder = 'overlapBlocksFilesAcrossSessions_AfterInjection/';
        block_grouping_folder_crossdec = 'Overlap_blocks_3_4';
    end
    block_data = 'block: 3,4';
    
elseif strcmp(currentFile, 'overlapBlocksFiles_BeforeInjection_3_4') && strcmp(monkey, 'Linus')
    
    num_block_suffix = '1';
    if strcmp(typeOfDecoding, 'сollected_files_across_sessions')
        block_grouping_folder = 'Overlap_blocks_BeforeInjection_3_4/';
        block_grouping_folder_crossdec = 'Overlap_blocks_3_4';
    elseif strcmp(typeOfDecoding, 'merged_files_across_sessions')
        block_grouping_folder = 'overlapBlocksFilesAcrossSessions_BeforeInjection_3_4/';
        block_grouping_folder_crossdec = 'Overlap_blocks_3_4';
    end
    block_data = 'block: 1';
    
elseif strcmp(currentFile, 'overlapBlocksFiles_AfterInjection_3_4') && strcmp(monkey, 'Linus')
    
    num_block_suffix = '3';
    if strcmp(typeOfDecoding, 'сollected_files_across_sessions')
        block_grouping_folder = 'Overlap_blocks_AfterInjection_3_4/';
        block_grouping_folder_crossdec = 'Overlap_blocks_3_4';
    elseif strcmp(typeOfDecoding, 'merged_files_across_sessions')
        block_grouping_folder = 'overlapBlocksFilesAcrossSessions_AfterInjection_3_4/';
        block_grouping_folder_crossdec = 'Overlap_blocks_3_4';
    end
    block_data = 'block: 3,4';
    
else
    error('Unknown value for givenListOfRequiredFiles.');
end

% Save the results in the structure array
grouping_folder.block_grouping_folder = block_grouping_folder;
if exist('block_grouping_folder_crossdec', 'var')
    grouping_folder.block_grouping_folder_crossdec = block_grouping_folder_crossdec;
else
    grouping_folder.block_grouping_folder_crossdec = '';
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
%allDateOfRecording = filelist_of_days_from_Simultaneous_dPul_PPC_recordings(monkey, injection, typeOfSessions);


% Call the settings function with the chosen set
[base_path, INPUT_PATH, OUTPUT_PATH_raster, OUTPUT_PATH_binned, monkey_prefix, settings] = sdndt_Sim_LIP_dPul_NDT_settings(monkey, injection, typeOfSessions);




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
    
    totalNumOfUnits = 0; % Initialize the total number of units
    totalNumOfTrials = 0; % Initialize the total number of trials
    
    sum_first_numbers = 0; % Initialize variables to store sums of the first and second numbers
    sum_second_numbers = 0;
    
    %pattern_block = ['test_' num_block];
    % Save the original value of num_block
    initial_num_block = block_grouping.num_block;
    
    % target_state =  'cueON'
    
    if strcmp(typeOfDecoding, 'сollected_files_across_sessions')
        
        for numOfData = 1:numel(dateOfRecording)
            
            % Initialize
            label_counts_cell = cell(1, numel(dateOfRecording)); % Initialize a cell array to store label_counts for each day
            
            
            
            current_dateOfRecording = dateOfRecording{numOfData};
            
            % Return num_block to the initial value before each iteration
            num_block = initial_num_block;
            
            % Check if the current date is ‘20201112’
            if strcmp(current_dateOfRecording, '20201112') && strcmp(num_block, 'block_3')
                num_block = 'block_2';  % ude block 2 for the ‘20201112’
            end
            
            if strcmp(current_dateOfRecording, '20201112') && strcmp(num_block, 'block_4')
                num_block = 'block_3';  % ude block 2 for the ‘20201112’
            end
            
            %  pattern_block = ['test_.*' num_block '.*'];
            
            current_dateOfRecording_monkey = [monkey_prefix current_dateOfRecording];
            
            if strcmp(method_of_decoding, 'Cross_decoding')
                % For cross-decoding we use a more universal template
                pattern_block = ['test_.*' num_block '.*'];
                OUTPUT_PATH_binned_data = fullfile(OUTPUT_PATH_binned, current_dateOfRecording_monkey, method_of_decoding, settings.num_cv_splits_approach_folder, block_grouping.block_grouping_folder_crossdec);
                combinedLabel = strrep(combinedLabel, ' ', '_');
                
            else
                % For decoding
                pattern_block = ['.*' num_block '.*'];
                OUTPUT_PATH_binned_data = fullfile(OUTPUT_PATH_binned, current_dateOfRecording_monkey, block_grouping.block_grouping_folder, settings.num_cv_splits_approach_folder);
                
            end
            
            
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
            
            
            %% Number of trials
            
            if strcmp(method_of_decoding, 'Decoding')
                
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
                
                
                
                
            elseif strcmp(method_of_decoding, 'Cross_decoding')
                
                % Number of trials
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
            
        end
        
    elseif strcmp(typeOfDecoding, 'merged_files_across_sessions')
        
        
        
        % Return num_block to the initial value before each iteration
        num_block = initial_num_block;
        
        
        current_dateOfRecording_monkey = [monkey_prefix typeOfDecoding];
        
        if strcmp(method_of_decoding, 'Cross_decoding')
            % For cross-decoding we use a more universal template
            pattern_block = ['test_.*' num_block '.*'];
            two_group_folder = 'two_group_combination';
            OUTPUT_PATH_binned_data = fullfile(OUTPUT_PATH_binned, current_dateOfRecording_monkey, two_group_folder, method_of_decoding, settings.num_cv_splits_approach_folder, block_grouping.block_grouping_folder_crossdec);
            combinedLabel = strrep(combinedLabel, ' ', '_');
            
        else
            % For Decoding
            pattern_block = ['.*' num_block '.*'];
            if contains(block_grouping.block_grouping_folder, 'BlocksFilesAcrossSessions_BeforeInjection') || ...
                    contains(block_grouping.block_grouping_folder, 'BlocksFilesAcrossSessions_AfterInjection')
                
                OUTPUT_PATH_binned_data = fullfile(OUTPUT_PATH_binned, current_dateOfRecording_monkey, block_grouping.block_grouping_folder, settings.num_cv_splits_approach_folder);
            else
                OUTPUT_PATH_binned_data = fullfile(OUTPUT_PATH_binned, current_dateOfRecording_monkey, block_grouping.block_grouping_folder);
                
            end
        end
            
            
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
                        session_num_cv_splits_Info = sprintf('Session: %s, num_cv_splits: %d\n', typeOfDecoding, num_cv_splits);
                        
                        
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
            
            
            %% Number of units
            sites_to_use{end+1} = loadedData.DECODING_RESULTS.DS_PARAMETERS.sites_to_use;
            numOfUnits{end+1} = size(sites_to_use{end}, 2);  % Calculate the number of units
            unitsForCurrentDay = size(sites_to_use{end}, 2); % Calculate the number of units for the current day
            totalNumOfUnits = totalNumOfUnits + unitsForCurrentDay;  % Add the units for the current day to the total
            
            
            %% Number of trials
            
            if strcmp(method_of_decoding, 'Decoding')
                
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
                
                totalNumOfTrials = sum(label_counts);
                first_second_numbers = label_counts; % Store label_counts for the current day
                
                
                
                
                
            elseif strcmp(method_of_decoding, 'Cross_decoding')
                
                % Number of trials
                trial_type_side = binned_labels.trial_type_side;
                
                % Collect all the labels and put them into strings
                all_labels_as_strings = cellfun(@(x) strjoin(sort(x)), trial_type_side, 'UniformOutput', false);
                
                % Finding unique sequences
                [unique_sequences, ~, group_indices] = unique(all_labels_as_strings);
                
                % Convert rows back to cells (if necessary)
                unique_sequences_as_cells = cellfun(@(x) strsplit(x), unique_sequences, 'UniformOutput', false);
                
                
                % Extract labels from combinedLabel
                relevant_labels = strsplit(combinedLabel, '_'); % receive {'instr', 'R', 'instr', 'L'}
                
                uniqueLabels = strcat(relevant_labels(1:2:end), '_', relevant_labels(2:2:end)); % Combine in pairs
                
                
                % Step 2: Counting labels for each unique sequence
                label_counts_per_sequence = cell(size(unique_sequences));
                
                for seq_idx = 1:numel(unique_sequences_as_cells)
                    % Labels in the current unique sequence
                    labels_at_site = unique_sequences_as_cells{seq_idx};
                    
                    % Initialisation of counters for the current unique sequence
                    count_instr_R_training = 0;
                    count_instr_L_training = 0;
                    count_instr_R_test = 0;
                    count_instr_L_test = 0;
                    
                   
                    for i = 1:numel(labels_at_site)
                        % Current label
                        label_str = labels_at_site{i};
                        
                        % Counting by category
                        if contains(label_str, 'training') && contains(label_str, 'instr_R') % для instr_R training
                            count_instr_R_training = count_instr_R_training + 1;
                        elseif contains(label_str, 'training') && contains(label_str, 'instr_L') % для instr_L training
                            count_instr_L_training = count_instr_L_training + 1;
                        elseif contains(label_str, 'test') && contains(label_str, 'instr_R') % для instr_R test
                            count_instr_R_test = count_instr_R_test + 1;
                        elseif contains(label_str, 'test') && contains(label_str, 'instr_L') % для instr_L test
                            count_instr_L_test = count_instr_L_test + 1;
                        end
                    end
                    
                    % Save the counting results for the current sequence
                    label_counts_per_sequence{seq_idx} = struct('instr_R_training', count_instr_R_training, ...
                        'instr_L_training', count_instr_L_training, ...
                        'instr_R_test', count_instr_R_test, ...
                        'instr_L_test', count_instr_L_test);
                end
                
                
                % Step 3: Initialising the structure for the totals
                total_NumOfTrials = struct();
                
                % Dynamically create fields for each label from uniqueLabels
                fields = {};
                for i = 1:numel(uniqueLabels)
                    fields{end+1} = [uniqueLabels{i} '_training'];
                    fields{end+1} = [uniqueLabels{i} '_test'];
                end
                
                % Initializing the field structure with zeros
                for i = 1:numel(fields)
                    field_name = fields{i};
                    total_NumOfTrials.(field_name) = 0;
                end
                
                for seq_idx = 1:numel(label_counts_per_sequence)
                    % Get the structure for the current unique sequence
                    current_counts = label_counts_per_sequence{seq_idx};
                    
                    % For each field, check and add a value
                    for i = 1:numel(fields)
                        field_name = fields{i};
                        
                        % Check if this field exists in current_counts
                        if isfield(current_counts, field_name)
                            total_NumOfTrials.(field_name) = total_NumOfTrials.(field_name) + current_counts.(field_name);
                        end
                    end
                end
                
            end
            
            
        end
        
        
        
        %% prepearing fot the plotting numOfTrials and numOfUnits
        
        
        if strcmp(method_of_decoding, 'Decoding')
            
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
            
            
            
            
            
        elseif strcmp(method_of_decoding, 'Cross_decoding')
            
            % Initialisation of variables for counting the total number of training and test data
            totalNumOfTrials_training = 0;
            totalNumOfTrials_test = 0;
            
            categories = {'Cue', 'Delay', 'PostSac'};
            label_counts = struct();
            
            
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
            
            
            
            
            % Convert cell array to vector
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
            
            
            % Preparing for the plotting numOfTrials and numOfUnits
            
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
            data_for_plotting_averages.(current_target_state).numOfUnits_and_numOfTrials_info_labelsAppears_training = [numOfUnits_and_numOfTrials_info_training, labelCountsInfo_training];
            data_for_plotting_averages.(current_target_state).numOfUnits_and_numOfTrials_info_labelsAppears_test = [numOfUnits_and_numOfTrials_info_test, labelCountsInfo_test];
            
            
        end
        
        
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
            if strcmp(typeOfDecoding, 'сollected_files_across_sessions')
                [selected_data_Cue, selected_bins_Cue, bin_times_Cue] = ...
                    extract_window_from_data_epoch(typeOfDecoding, method_of_decoding, all_mean_decoding_results, loadedData_Cue, time_window_Cue, OUTPUT_PATH_binned_data_for_saving_txt);
                mean_decoding_results_Cue = horzcat(selected_data_Cue{:});
            elseif strcmp(typeOfDecoding, 'merged_files_across_sessions')
                [selected_data_Cue, selected_bins_Cue, bin_times_Cue] = ...
                    extract_window_from_data_epoch(typeOfDecoding, method_of_decoding, loadedData.DECODING_RESULTS.NORMALIZED_RANK_RESULTS.decoding_results, loadedData_Cue, time_window_Cue, OUTPUT_PATH_binned_data_for_saving_txt);
                mean_decoding_results_Cue = selected_data_Cue';
            end
            
            % mean_decoding_results_Cue = horzcat(selected_data_Cue{:});
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
            
            if strcmp(typeOfDecoding, 'сollected_files_across_sessions')
                [selected_data_Delay, selected_bins_Delay, bin_times_Delay] = ...
                    extract_window_from_data_epoch(typeOfDecoding, method_of_decoding, all_mean_decoding_results, loadedData_Delay, time_window_Delay, OUTPUT_PATH_binned_data_for_saving_txt);
                mean_decoding_results_Delay = horzcat(selected_data_Delay{:});
            elseif strcmp(typeOfDecoding, 'merged_files_across_sessions')
                [selected_data_Delay, selected_bins_Delay, bin_times_Delay] = ...
                    extract_window_from_data_epoch(typeOfDecoding, method_of_decoding, loadedData.DECODING_RESULTS.NORMALIZED_RANK_RESULTS.decoding_results, loadedData_Delay, time_window_Delay, OUTPUT_PATH_binned_data_for_saving_txt);
                mean_decoding_results_Delay = selected_data_Delay';
            end
            
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
            
            
            if strcmp(typeOfDecoding, 'сollected_files_across_sessions')
                [selected_data_PostSac, selected_bins_PostSac, bin_times_PostSac] = ...
                    extract_window_from_data_epoch(typeOfDecoding, method_of_decoding, all_mean_decoding_results, loadedData_PostSac, time_window_PostSac, OUTPUT_PATH_binned_data_for_saving_txt);
                mean_decoding_results_PostSac = horzcat(selected_data_PostSac{:});
            elseif strcmp(typeOfDecoding, 'merged_files_across_sessions')
                [selected_data_PostSac, selected_bins_PostSac, bin_times_PostSac] = ...
                    extract_window_from_data_epoch(typeOfDecoding, method_of_decoding, loadedData.DECODING_RESULTS.NORMALIZED_RANK_RESULTS.decoding_results, loadedData_PostSac, time_window_PostSac, OUTPUT_PATH_binned_data_for_saving_txt);
                mean_decoding_results_PostSac = selected_data_PostSac';
            end
            
            data_for_plotting_averages.(current_target_state).mean_decoding_results_PostSac = mean(mean_decoding_results_PostSac,1);
            mean_decoding_results_100_PostSac = mean_decoding_results_PostSac*100;
            data_for_plotting_averages.(current_target_state).mean_decoding_results_100_PostSac = mean(mean_decoding_results_100_PostSac,1);
            
            data_for_plotting_averages.(current_target_state).selected_bins_PostSac = selected_bins_PostSac;
            data_for_plotting_averages.(current_target_state).bin_times_PostSac = bin_times_PostSac;
            
            data_for_plotting_averages.(current_target_state).block_data_PostSac = block_grouping.block_data;
            
        end % strcmp(target_state, 'cueON')
        
        
        
    end % stateIdx = 1:numel(target_state)
    
    
    
    
end





    function [selected_data, selected_bins, bin_times_selected] = ...
            extract_window_from_data_epoch(typeOfDecoding, method_of_decoding, all_mean_decoding_results, DECODING_RESULTS, time_window, output_filename)
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
        if strcmp(typeOfDecoding, 'сollected_files_across_sessions') || (strcmp(typeOfDecoding, 'merged_files_across_sessions') && strcmp(method_of_decoding, 'Decoding'))
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
        if strcmp(typeOfDecoding, 'сollected_files_across_sessions')
            num_conditions = length(all_mean_decoding_results);
            selected_data = cell(1, num_conditions);
            
            for i = 1:num_conditions
                selected_data{i} = all_mean_decoding_results{i}(selected_bins);
            end
            
        elseif strcmp(typeOfDecoding, 'merged_files_across_sessions')
            
            % Вычисление средних значений по второму измерению
            mean_result_2D = mean(all_mean_decoding_results, 2);
            
            % Удаляем лишнее измерение, чтобы получить матрицу размером 50x37
            mean_result_2D = squeeze(mean_result_2D);
            
            num_conditions = size(mean_result_2D, 2);
            selected_data = cell(1, num_conditions);
            
            for i = 1:num_conditions
                selected_data = mean_result_2D(:, selected_bins);
            end
            
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



    function daboxplotAveragesAcrossSessions(monkey, typeOfDecoding, method_of_decoding, dateOfRecording, target_brain_structure, target_state, combinedLabel, data_for_plotting_averages_before, data_for_plotting_averages_after, settings, OUTPUT_PATH_binned_data_for_saving);
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
        blocks_before_clean = strrep(blocks_before{1}, 'block: ', ''); % remove "block: "
        blocks_after_clean = strrep(blocks_after{1}, 'block: ', '');
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
        if strcmp(method_of_decoding, 'Decoding')
            pre_label_training = '';
            pre_label_test = '';
        elseif strcmp(method_of_decoding, 'Cross_decoding')
            pre_label_training = 'train '
            pre_label_test = 'test '
        end
        
        
        group_names = {
            ['Monkey: ' first_letters{1} ', ' pre_label_test block_label_before], ...
            ['Monkey: ' first_letters{1} ', ' pre_label_test block_label_after], ...
            ['Monkey: ' first_letters{2} ', ' pre_label_test block_label_before], ...
            ['Monkey: ' first_letters{2} ', ' pre_label_test block_label_after]
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
        
        
        detailsForNameOfFiles = [monkey_str '_' typeOfDecoding '_' target_brain_structure '_' epochs_str '_' block_str '_' combinedLabel];
        
        summary_of_Wilcoxon_test  = add_signrank_test(data, OUTPUT_PATH_binned_data_for_saving, monkey, epoch_names, detailsForNameOfFiles)
        
        
        
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
            if strcmp(typeOfDecoding, 'сollected_files_across_sessions')
                session_annotation = session_annotation + ...
                    sprintf('Monkey %s: %d sessions\n', first_letters{monkey_idx}, num_sessions(monkey_idx));
            elseif strcmp(typeOfDecoding, 'merged_files_across_sessions')
                session_annotation = session_annotation + ...
                    sprintf('Monkey %s: %d resamples\n', first_letters{monkey_idx}, num_sessions(monkey_idx));
            end
        end
        
        
        
        % Initializing
        session_annotation_Bac = "";
        session_annotation_Lin = "";
        
        % Info about session
        for monkey_idx = 1:length(num_sessions)
            if strcmp(typeOfDecoding, 'сollected_files_across_sessions')
                if monkey_idx == 1
                    % for Bacchus
                    session_annotation_Bac = sprintf('Monkey %s: %d sessions\n', first_letters{monkey_idx}, num_sessions(monkey_idx));
                elseif monkey_idx == 2
                    % for Linus
                    session_annotation_Lin = sprintf('Monkey %s: %d sessions\n', first_letters{monkey_idx}, num_sessions(monkey_idx));
                end
            elseif strcmp(typeOfDecoding, 'merged_files_across_sessions')
                if monkey_idx == 1
                    % for Bacchus
                    session_annotation_Bac = sprintf('Monkey %s: %d resamples\n', first_letters{monkey_idx}, num_sessions(monkey_idx));
                elseif monkey_idx == 2
                    % for Linus
                    session_annotation_Lin = sprintf('Monkey %s: %d resamples\n', first_letters{monkey_idx}, num_sessions(monkey_idx));
                end
            end
        end
        
        
        
        % Initializing the structure
        monkey_Units_Trials_info = struct();
        
        for monkey_idx = 1:length(monkey)
            current_monkey = monkey{monkey_idx};
            
            if strcmp(method_of_decoding, 'Decoding')
                info_str_after = data_for_plotting_averages_after.(current_monkey).cueON.numOfUnits_and_numOfTrials_info_labelsAppears;
                info_str_before = data_for_plotting_averages_before.(current_monkey).cueON.numOfUnits_and_numOfTrials_info_labelsAppears;
                
                monkey_Units_Trials_info.(current_monkey).before = info_str_before;
                monkey_Units_Trials_info.(current_monkey).after = info_str_after;
                
            elseif strcmp(method_of_decoding, 'Cross_decoding')
                
                info_str_after_training = data_for_plotting_averages_after.(current_monkey).cueON.numOfUnits_and_numOfTrials_info_labelsAppears_training;
                info_str_after_test = data_for_plotting_averages_after.(current_monkey).cueON.numOfUnits_and_numOfTrials_info_labelsAppears_test;
                info_str_before_training = data_for_plotting_averages_before.(current_monkey).cueON.numOfUnits_and_numOfTrials_info_labelsAppears_training;
                info_str_before_test = data_for_plotting_averages_before.(current_monkey).cueON.numOfUnits_and_numOfTrials_info_labelsAppears_test;
                
                monkey_Units_Trials_info.(current_monkey).before_training = info_str_before_training;
                monkey_Units_Trials_info.(current_monkey).after_training = info_str_after_training;
                monkey_Units_Trials_info.(current_monkey).before_test = info_str_before_test;
                monkey_Units_Trials_info.(current_monkey).after_test = info_str_after_test;
            end
            
            
        end
        
        
        
        
        %% Plot
        
        % title
        if strcmp(method_of_decoding, 'Decoding')
            title_text = sprintf('%s; %s', target_brain_structure, strrep(combinedLabel, ' ', ', '));
        elseif strcmp(method_of_decoding, 'Cross_decoding')
            [modifiedLabel1, modifiedLabel2] = modifyLabel(combinedLabel);
            title_text = sprintf('%s; %s', target_brain_structure, strrep(modifiedLabel2, ' ', ', '));
        end
        
        % plot
        f1 = create_boxplot(typeOfDecoding, method_of_decoding, data, summary_of_Wilcoxon_test, epoch_names, group_names, title_text, session_annotation_Bac, session_annotation_Lin, monkey_Units_Trials_info, color_fig1.color_RGB, 0, 50, 0, 1, 1);
        f2 = create_boxplot(typeOfDecoding, method_of_decoding, data, summary_of_Wilcoxon_test, epoch_names, group_names, title_text, session_annotation_Bac, session_annotation_Lin, monkey_Units_Trials_info, color_fig2.color_RGB, 1, 40, 0, 0.7, 0);
        
        % save
        filename1 = sprintf('boxplot_for_%s_clear_boxes_Lines.png', detailsForNameOfFiles);
        saveas(f1, fullfile(OUTPUT_PATH_binned_data_for_saving, filename1));
        filename2 = sprintf('boxplot_for_%s_color_boxes_Lines.png', detailsForNameOfFiles);
        saveas(f2, fullfile(OUTPUT_PATH_binned_data_for_saving, filename2));
        
        
        close(f1);
        close(f2);
        
        
    end


    function f = create_boxplot(typeOfDecoding, method_of_decoding, data, summary_of_Wilcoxon_test, epoch_names, group_names, title_text, session_annotation_Bac, session_annotation_Lin, monkey_Units_Trials_info, color_fig, fill_flag, scatter_size, whisker_flag, box_alpha, flipcolors_flag)
        % Plot a graph with parameters
        
        f = figure;
        h = daboxplot(data, 'xtlabels', epoch_names,  ...
            'colors', color_fig, 'fill', fill_flag, 'whiskers', whisker_flag, 'boxalpha',box_alpha, 'scatter', 2, 'outsymbol', 'rx', ...
            'outliers', 1, 'scattersize', scatter_size, ... % 'withinlines',1,
            'flipcolors', flipcolors_flag, 'boxspacing', 1.5, 'boxwidth', 0.8, ...
            'legend', group_names);
        
        
        
        set(gca, 'XTickLabel', []);  % Removing the standard marks
        xt = get(gca, 'XTick'); % get the positions of the labels on the X axis
        
        for i = 1:numel(xt)
            x_pos = (xt(i) / 4.55) - 0.02;
            annotation('textbox', [x_pos, 0.05, 0, 0], 'String', epoch_names{i}, 'FontSize', 16, ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', 'EdgeColor', 'none', 'FontWeight', 'bold');
        end
        
        
        
        
        if strcmp(method_of_decoding, 'Decoding')
            xl_flag = 1.0;
        elseif strcmp(method_of_decoding, 'Cross_decoding')
            xl_flag = 1.2;
        end
        xl = xlim; xlim([xl(1), xl(2) + xl_flag]); % make more space for the legend
        set(gca, 'FontSize', 14);
        set(gcf, 'position', [550, 185, 925, 805])  % set(gcf,'position',[610,420,770,500])
        set(gca, 'Position', [0.08, 0.045, 0.9, 0.52])  % set(gca, 'Position', [0.08, 0.08, 0.9, 0.8] )
        
       if strcmp(typeOfDecoding, 'сollected_files_across_sessions')
            tickPositions = 20:10:100; % Calculate the tick positions every 200 ms
            yticks(tickPositions);
            ylim([20 100])
            ylabel('Classification Accuracy', 'Position', [0.2, 60]) % move the label of OY axis  away from the Y axis [X Y same as axis]
            
       
        elseif strcmp(typeOfDecoding, 'merged_files_across_sessions')
            tickPositions = 20:10:105; % Calculate the tick positions every 200 ms
            yticks(tickPositions);
            ylim([20 105])
            ylabel('Classification Accuracy', 'Position', [0.2, 65]) % move the label of OY axis  away from the Y axis [X Y same as axis]
            
       end
        
        % Title
        title(title_text);
        h_title = title(title_text);
        title_pos = get(h_title, 'Position'); % Get the current coordinates of the heading position
        set(h_title, 'Position', [title_pos(1) - 0.5, title_pos(2) + 3, title_pos(3)]); % Move the title to the left (decrease the X-coordinate)
        
        % Adding annotations
        add_annotations(method_of_decoding, session_annotation_Bac, session_annotation_Lin, monkey_Units_Trials_info);
        
        
        
        
        gpos = h.gpos; % We get the position of each group
        cpos = h.cpos; % Positions for each category
        monkeys = fieldnames(summary_of_Wilcoxon_test); % Getting the names of monkeys
        
        
        % Adding custom withinlines for statistical comparisons
        hold on;
        
        for monkey_idx = 1:numel(monkeys)
            before_idx = (monkey_idx - 1) * 2 + 1; % Index of the first cell (data before / training)
            after_idx = before_idx + 1;           % Index of the second cell (data after / test)
            
            for col = 1:numel(epoch_names)
                % Get the group positions for before and after
                x_pos_before = gpos(before_idx, col);
                x_pos_after = gpos(after_idx, col);
                
                % Retrieve data for the current column
                data_before = data{before_idx}(:, col);
                data_after = data{after_idx}(:, col);
                
                % Check that data lengths match
                n_points = min(length(data_before), length(data_after));
                
                % Draw lines connecting each point in data_before to its pair in data_after
                for i = 1:n_points
                    line_handle = plot([x_pos_before, x_pos_after], [data_before(i), data_after(i)], '-', ...
                        'Color', [0.8, 0.8, 0.8], 'LineWidth', 1); % Light gray color
                    % Send the line to the back
                    uistack(line_handle, 'bottom');
                end
            end
        end
        
        
        
        
        % We obtain indices for each of the epoch
        epoch_indices = containers.Map();
        
        for i = 1:length(epoch_names)
            % Find the index for each epoch
            epoch_name = epoch_names{i};
            
            if ismember(epoch_name, epoch_names)
                idx = find(strcmp(epoch_name, epoch_names));
                epoch_indices(epoch_name) = cpos(idx);
            end
        end
        
        
        hold on;
        
        for monkey_idx = 1:numel(monkeys)
            monkey_name = monkeys{monkey_idx};
            monkey_summary = summary_of_Wilcoxon_test.(monkey_name);
            
            for epoch_idx = 1:numel(epoch_names)
                epoch_name = epoch_names{epoch_idx};
                epoch_summary = monkey_summary.(epoch_name);
                
                % Extract p_value and hypothesis result
                p_value = epoch_summary.p_value;
                h = epoch_summary.hypothesis_rejected;
                
                if h == 1 % If the difference is significant
                    if monkey_idx == 1
                        % For the first monkey, take the first and second rows from gpos for each epoch
                        x_pos_before = gpos(1, epoch_idx);
                        x_pos_after = gpos(2, epoch_idx);
                    else
                        %For the second monkey, we take the third and fourth rows from gpos for each epoch
                        x_pos_before = gpos(3, epoch_idx);
                        x_pos_after = gpos(4, epoch_idx);
                    end
                    
                    % Determine the maximum value on the Y axis for a given monkey and epoch
                    y_max = max([data{(monkey_idx - 1) * 2 + 1}(:, epoch_idx);
                        data{(monkey_idx - 1) * 2 + 2}(:, epoch_idx)]) + 5; % Y-axis lift
                    
                    % Draw brackets for significance
                    plot([x_pos_before, x_pos_after], [y_max, y_max], 'k-', 'LineWidth', 1.5); % Horizontal line
                    plot([x_pos_before, x_pos_before], [y_max - 2, y_max], 'k-', 'LineWidth', 1.5); % Left vertical line
                    plot([x_pos_after, x_pos_after], [y_max - 2, y_max], 'k-', 'LineWidth', 1.5); % Right vertical line
                    
                    % Add a star above the bracket
                    text(mean([x_pos_before, x_pos_after]), y_max + 1, '*', 'HorizontalAlignment', 'center', 'FontSize', 16, 'FontWeight', 'bold');
                    
                    
                end
            end
        end
        
        % Get all elements from the current legend
        %legend_items = findobj(gcf, 'Type', 'line');  %We get all the lines on the chart
        
        current_legend = legend;  %Get the current legend
        legend_labels = current_legend.String; % Get labels from the current legend
        
        % Remove all elements that start with 'data' (e.g. 'data1', 'data2', 'data3', ...)
        valid_labels = legend_labels(~cellfun(@(x) ~isempty(regexp(x, '^data\d*$', 'once')), legend_labels));
        
        % Update the legend, leaving only those labels that are in valid_labels
        current_legend.String = valid_labels;
        
        
    end



    function add_annotations(method_of_decoding, session_annotation_Bac, session_annotation_Lin, monkey_Units_Trials_info)
        
        
        if strcmp(method_of_decoding, 'Decoding')
            
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
            
            
            
        elseif strcmp(method_of_decoding, 'Cross_decoding')
            
            % Adding annotations for Bacchus (session info)
            annotation('textbox', [0.11, 0.88, 0.2, 0.1], 'String', session_annotation_Bac, ...
                'FitBoxToText', 'on', 'FontSize', 11, 'EdgeColor', 'none', 'FontWeight', 'bold'); % No box around the annotation
            
            % Adding annotations for Linus (session info)
            annotation('textbox', [0.57, 0.88, 0.2, 0.1], 'String', session_annotation_Lin, ...
                'FitBoxToText', 'on', 'FontSize', 11, 'EdgeColor', 'none', 'FontWeight', 'bold'); % No box around the annotation
            
            
            % Add "test" and "training" below the Bacchus annotation
            annotation('textbox', [0.04, 0.84, 0.2, 0.1], 'String', 'Training:', ...
                'FitBoxToText', 'on', 'FontSize', 10, 'EdgeColor', 'none', 'FontWeight', 'normal', 'FontWeight', 'bold'); % Training text
            annotation('textbox', [0.20, 0.84, 0.2, 0.1], 'String', 'Test:', ...
                'FitBoxToText', 'on', 'FontSize', 10, 'EdgeColor', 'none', 'FontWeight', 'normal', 'FontWeight', 'bold'); % Test text
            
            annotation('textbox', [0.51, 0.84, 0.2, 0.1], 'String', 'Training:', ...
                'FitBoxToText', 'on', 'FontSize', 10, 'EdgeColor', 'none', 'FontWeight', 'normal', 'FontWeight', 'bold'); % Training text
            annotation('textbox', [0.67, 0.84, 0.2, 0.1], 'String', 'Test:', ...
                'FitBoxToText', 'on', 'FontSize', 10, 'EdgeColor', 'none', 'FontWeight', 'normal', 'FontWeight', 'bold'); % Test text
            
            
            
            % Coloring the annotation for Bacchus (before) in light green
            annotation('textbox', [0.04, 0.71, 0.3, 0.2], 'String', monkey_Units_Trials_info.Bacchus.before_training, ...
                'FitBoxToText', 'on', 'FontSize', 10, 'EdgeColor', 'none', 'Color', [0.4666, 0.6627, 0.3098], 'FontWeight', 'bold');
            annotation('textbox', [0.20, 0.71, 0.3, 0.2], 'String', monkey_Units_Trials_info.Bacchus.before_test, ...
                'FitBoxToText', 'on', 'FontSize', 10, 'EdgeColor', 'none', 'Color', [0.4666, 0.6627, 0.3098], 'FontWeight', 'bold');
            
            % Coloring the annotation for Bacchus (after) in dark green
            annotation('textbox', [0.04, 0.56, 0.3, 0.2], 'String', monkey_Units_Trials_info.Bacchus.after_training, ...
                'FitBoxToText', 'on', 'FontSize', 10, 'EdgeColor', 'none', 'Color', [0.2921, 0.5058, 0.2921], 'FontWeight', 'bold');
            annotation('textbox', [0.20, 0.56, 0.3, 0.2], 'String', monkey_Units_Trials_info.Bacchus.after_test, ...
                'FitBoxToText', 'on', 'FontSize', 10, 'EdgeColor', 'none', 'Color', [0.2921, 0.5058, 0.2921], 'FontWeight', 'bold');
            
            % Coloring the annotation for Linus (before) in light blue
            annotation('textbox', [0.51, 0.71, 0.3, 0.2], 'String', monkey_Units_Trials_info.Linus.before_training, ...
                'FitBoxToText', 'on', 'FontSize', 10, 'EdgeColor', 'none', 'Color', [0.2705, 0.5058, 0.6627], 'FontWeight', 'bold');
            annotation('textbox', [0.67, 0.71, 0.3, 0.2], 'String', monkey_Units_Trials_info.Linus.before_test, ...
                'FitBoxToText', 'on', 'FontSize', 10, 'EdgeColor', 'none', 'Color', [0.2705, 0.5058, 0.6627], 'FontWeight', 'bold');
            
            % Coloring the annotation for Linus (after) in dark blue
            annotation('textbox', [0.51, 0.56, 0.3, 0.2], 'String', monkey_Units_Trials_info.Linus.after_training, ...
                'FitBoxToText', 'on', 'FontSize', 10, 'EdgeColor', 'none', 'Color', [0.1745, 0.3313, 0.5058], 'FontWeight', 'bold');
            annotation('textbox', [0.67, 0.56, 0.3, 0.2], 'String', monkey_Units_Trials_info.Linus.after_test, ...
                'FitBoxToText', 'on', 'FontSize', 10, 'EdgeColor', 'none', 'Color', [0.1745, 0.3313, 0.5058], 'FontWeight', 'bold');
            
        end
    end

    function results_summary = add_signrank_test(data, OUTPUT_PATH_binned_data_for_saving, monkey, epoch_names, detailsForNameOfFiles)
        % Full file path
        full_file_path = [OUTPUT_PATH_binned_data_for_saving '/Wilcoxon_test_results_' detailsForNameOfFiles '.txt'];
        
        % Open file for writing
        fileID = fopen(full_file_path, 'w');
        
        % Check if the file was opened successfully
        if fileID == -1
            error('Error: Failed to open the file for writing. Check the path and access.');
        end
        
        % Title in the file
        fprintf(fileID, 'Statistical Analysis Results (Signrank Test)\n');
        fprintf(fileID, '=================================================\n\n');
        
        % Define p-value threshold
        alpha = 0.05;
        fprintf(fileID, 'Note: A p-value less than %.2f indicates significant differences.\n', alpha);
        fprintf(fileID, '\n');
        
        % Initialize results summary
        results_summary = struct();
        
        % Iterate through monkeys
        for monkey_idx = 1:numel(monkey)
            current_monkey = monkey{monkey_idx};
            fprintf(fileID, 'Results for %s:\n', current_monkey);
            fprintf(fileID, '-----------------------------------------\n\n');
            
            % Determine cell indices for the current monkey
            before_idx = (monkey_idx - 1) * 2 + 1; % Index of the first cell (data before / training)
            after_idx = before_idx + 1;           % Index of the second cell (data after / test)
            
            % Initialize monkey-specific results
            monkey_results = struct();
            
            % Iterate through columns (Cue, Delay, PostSac)
            for col = 1:numel(epoch_names)
                epoch_name = epoch_names{col};
                
                % Retrieve data for the current column
                data_before = data{before_idx}(:, col);
                data_after = data{after_idx}(:, col);
                
                % Initialize epoch-specific results
                epoch_results = struct();
                
                % Check that the data is not empty
                if ~isempty(data_before) && ~isempty(data_after)
                    % Perform signrank test
                    [p_value, h] = signrank(data_before, data_after);
                    
                    % Determine interpretation
                    if p_value < alpha
                        interpretation = 'Significant difference detected.';
                    else
                        interpretation = 'No significant difference.';
                    end
                    
                    % Write the results to a file
                    fprintf(fileID, 'Epoch: %s\n', epoch_name);
                    fprintf(fileID, 'P-value: %.4f\n', p_value);
                    fprintf(fileID, 'Hypothesis rejected (h=1): %d\n', h);
                    fprintf(fileID, '%s\n', interpretation);
                    fprintf(fileID, 'Data Before: %s\n', mat2str(data_before, 4));
                    fprintf(fileID, 'Data After: %s\n', mat2str(data_after, 4));
                    fprintf(fileID, '-----------------------------------------\n\n');
                    
                    % Save results to summary
                    epoch_results.p_value = p_value;
                    epoch_results.hypothesis_rejected = h;
                    epoch_results.interpretation = interpretation;
                    epoch_results.data_before = data_before;
                    epoch_results.data_after = data_after;
                else
                    % If the data is empty, write a message
                    fprintf(fileID, 'Epoch: %s\n', epoch_name);
                    fprintf(fileID, 'Data is empty.\n');
                    fprintf(fileID, '-----------------------------------------\n\n');
                    
                    % Save empty data to summary
                    epoch_results.p_value = NaN;
                    epoch_results.hypothesis_rejected = NaN;
                    epoch_results.interpretation = 'Data is empty.';
                    epoch_results.data_before = [];
                    epoch_results.data_after = [];
                end
                
                % Add epoch results to monkey results
                monkey_results.(epoch_name) = epoch_results;
            end
            
            % Add monkey results to summary
            results_summary.(current_monkey) = monkey_results;
            
            % Add separator between monkeys
            fprintf(fileID, '\n\n');
        end
        
        % Close the file
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

