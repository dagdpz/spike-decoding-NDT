function sdndt_Sim_LIP_dPul_NDT_statistics(monkey, injection, typeOfDecoding)

% The code converts the received raster data into binned data and then performs decoding.

% HOW TO CALL THE FUNCTION?
% If we decode within a session:
% sdndt_Sim_LIP_dPul_NDT_statistics('Bacchus', '0', 'each_session_separately');

% If we decode across sessions:
% sdndt_Sim_LIP_dPul_NDT_statistics('Bacchus', '0', 'merged_files_across_sessions');




%% MODIFIABLE PARAMETERS
% injection: '0' - control sessions, '1' - inactivation sessions (for inactivation experiment),
%            '2' - for functional interaction experiment

% typeOfDecoding: 'each_session_separately', 'merged_files_across_sessions'
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

file_for_group_1 = {%'overlapBlocksFiles_BeforeInjection', 
    'overlapBlocksFiles_BeforeInjection_3_4'};
file_for_group_2 = {%'overlapBlocksFiles_AfterInjection',
    'overlapBlocksFiles_AfterInjection_3_4'};

% Ensure both groups have the same length
if length(file_for_group_1) ~= length(file_for_group_2)
    error('Both groups must have the same number of elements.');
end

% Create the structure to hold the combinations
combinations_gr_1_and_gr_2_structure = struct();

% Loop through the file groups and create the structure fields
for i = 1:length(file_for_group_1)
    combinations_gr_1_and_gr_2_structure(i).group_1 = file_for_group_1{i};
    combinations_gr_1_and_gr_2_structure(i).group_2 = file_for_group_2{i};
end


%% Define typeOfSessions
% Calculate typeOfSessions based on the injection parameter
if strcmp(injection, '1')
    if strcmp(monkey, 'Linus')
        % typeOfSessions = {'right'};
        typeOfSessions = {'right', 'left' %, ... 
            %'all'
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
approach_to_use = {'all_approach', 'overlap_approach'};


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
numFile_for_group_1 = length(combinations_gr_1_and_gr_2_structure);


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

totalIterations = totalIterations * numApproach * numFile_for_group_1 * numCombinations * numLabels * numFieldNames * numTypesOfSessions;
overallProgress = 0; % Initialize progress


%% Loop through each combination of injection, target_brain_structure, and label

% Process each combination of group_1 and group_2
for file_gr_1_index = 1:numFile_for_group_1
    current_file = file_for_group_1{file_gr_1_index}; % Get the current file
    
    current_file_group_1 = combinations_gr_1_and_gr_2_structure(file_gr_1_index).group_1;
    current_file_group_2 = combinations_gr_1_and_gr_2_structure(file_gr_1_index).group_2;
    
    % Skip processing if the injection is 0 or 1 and the current files match the specified conditions
    if ~((strcmp(injection, '0') || strcmp(injection, '1')) && ...
            (strcmp(current_file_group_1, 'secondBlockFiles') || strcmp(current_file_group_1, 'allBlocksFiles') || strcmp(current_file_group_1, 'overlapBlocksFiles') || ...
            strcmp(current_file_group_2, 'secondBlockFiles') || strcmp(current_file_group_2, 'allBlocksFiles') || strcmp(current_file_group_2, 'overlapBlocksFiles')))
        
        
        for comb_index = 1:numCombinations
            current_comb = combinations_inj_and_target_brain_structure(comb_index);
            current_injection = current_comb.injection;
            current_target_brain_structure = current_comb.target_brain_structure;
            
            
            % Loop through each label in approach_to_use
            for approach_index = 1:numApproach
                current_approach = approach_to_use{approach_index};
                if contains(current_file_group_1, 'overlap') && contains(current_file_group_2, 'overlap')
                    current_approach = 'overlap_approach';
                end
                
                % Loop through each label in labels_to_use
                for label_index = 1:numLabels
                    current_label = labels_to_use{label_index};
                    
                    
                    
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
                            
                            %                             for comp_gr_index = 1:numComparisonGroups
                            %                                 current_comparison_group = comparison_groups{comp_gr_index};
                            
                            if strcmp(typeOfDecoding, 'each_session_separately') % typeOfDecoding
                                
                                current_set_of_date = datesForSessions{j}; % Get the corresponding set of dates !!!!!
                                % totalIterations = totalIterations + numel(current_set_of_date) * numLabels * numApproach * numFieldNames;
                                
                                
                                for numDays = 1:numel(current_set_of_date)
                                    current_date = current_set_of_date{numDays};
                                    
                                    % Call the internal decoding function for each day
                                    sdndt_Sim_LIP_dPul_NDT_statistics_internal(monkey, current_injection, current_type_of_session, typeOfDecoding, current_date, current_target_brain_structure, target_state, current_label, current_approach, current_file_group_1, current_file_group_2); % typeOfSessions{j}
                                    
                                    
                                    % Update progress for each iteration
                                    overallProgress = overallProgress + 1;
                                    waitbar(overallProgress / totalIterations, h, sprintf('Processing... %.2f%%', overallProgress / totalIterations * 100));
                                    
                                end
                                
                                
                            else % strcmp(typeOfDecoding, 'merged_files_across_sessions')
                                current_date = [];
                                % Call the internal decoding function only once
                                sdndt_Sim_LIP_dPul_NDT_statistics_internal(monkey, current_injection, current_type_of_session, current_date, typeOfDecoding, current_target_brain_structure, target_state, current_label, current_approach, current_file_group_1, current_file_group_2);
                                
                                
                                % Update progress for each iteration
                                overallProgress = overallProgress + 1;
                                waitbar(overallProgress / totalIterations, h, sprintf('Processing... %.2f%%', overallProgress / totalIterations * 100));
                                
                                
                            end % if strcmp(typeOfDecoding, 'each_session_separately')
                            % end % comp_gr_index = 1:numComparisonGroups
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



function sdndt_Sim_LIP_dPul_NDT_statistics_internal(monkey, injection, typeOfSessions, typeOfDecoding, dateOfRecording, target_brain_structure, target_state, given_labels_to_use, given_approach, given_file_group_1, given_file_group_2)


% Call the settings function with the chosen set
[base_path, INPUT_PATH, OUTPUT_PATH_raster, OUTPUT_PATH_binned, monkey_prefix, settings] = sdndt_Sim_LIP_dPul_NDT_settings(monkey, injection, typeOfSessions);

file_for_group = [OUTPUT_PATH_binned monkey_prefix dateOfRecording];


% Define folder pair mappings
folder_mapping = struct( ...
    'each_session_separately', struct( ...
    'overlapBlocksFiles_BeforeInjection', 'Overlap_blocks_BeforeInjection', ...
    'overlapBlocksFiles_AfterInjection', 'Overlap_blocks_AfterInjection', ...
    'overlapBlocksFiles_BeforeInjection_3_4', 'Overlap_blocks_BeforeInjection_3_4', ...
    'overlapBlocksFiles_AfterInjection_3_4', 'Overlap_blocks_AfterInjection_3_4' ...
    ), ...
    'merged_files_across_sessions', struct( ...
    'overlapBlocksFiles_BeforeInjection', 'overlapBlocksFilesAcrossSessions_BeforeInjection', ...
    'overlapBlocksFiles_AfterInjection', 'overlapBlocksFilesAcrossSessions_AfterInjection', ...
    'overlapBlocksFiles_BeforeInjection_3_4', 'overlapBlocksFilesAcrossSessions_BeforeInjection_3_4', ...
    'overlapBlocksFiles_AfterInjection_3_4', 'overlapBlocksFilesAcrossSessions_AfterInjection_3_4' ...
    ) ...
    );

% Determine folder pairs based on typeOfDecoding and file groups
if isfield(folder_mapping, typeOfDecoding)
    current_mapping = folder_mapping.(typeOfDecoding);
    if isfield(current_mapping, given_file_group_1) && isfield(current_mapping, given_file_group_2)
        folder_pairs = {current_mapping.(given_file_group_1), current_mapping.(given_file_group_2)};
    else
        error('Unknown given_file_group_1 or given_file_group_2 for %s.', typeOfDecoding);
    end
else
    error('Unknown typeOfDecoding.');
end

% 
% % Create a combined folder name for the two file groups
% combined_folder_name = sprintf('%s_and_%s', folder_pairs{1}, folder_pairs{2});


% Create a combined folder name by comparing parts
parts_1 = strsplit(folder_pairs{1}, '_');
parts_2 = strsplit(folder_pairs{2}, '_');

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

%% find grouping_folder

% Loop through given_file_group_1 and given_file_group_2
for fg_idx = 1:2
    if fg_idx == 1
        givenListOfRequiredFiles = given_file_group_1;
    else
        givenListOfRequiredFiles = given_file_group_2;
    end
    
    % Initialize block_grouping_folder and block_grouping_folder_for_saving
    block_grouping_folder_in_each_session = '';
    block_grouping_folder_in_all_session = '';
    
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
    
    % Extract the block number suffix from givenListOfRequiredFiles
    if strcmp(givenListOfRequiredFiles, 'firstBlockFiles')
        num_block_suffix = '1';
        block_grouping_folder_in_each_session = sprintf('%sBy_block', block_grouping_folder_prefix);
    elseif strcmp(givenListOfRequiredFiles, 'secondBlockFiles')
        num_block_suffix = '2';
        block_grouping_folder_in_each_session = sprintf('%sBy_block', block_grouping_folder_prefix);
    elseif strcmp(givenListOfRequiredFiles, 'thirdBlockFiles')
        num_block_suffix = '3';
        block_grouping_folder_in_each_session = sprintf('%sBy_block', block_grouping_folder_prefix);
    elseif strcmp(givenListOfRequiredFiles, 'fourthBlockFiles')
        num_block_suffix = '4';
        block_grouping_folder_in_each_session = sprintf('%sBy_block', block_grouping_folder_prefix);
    elseif strcmp(givenListOfRequiredFiles, 'fifthBlockFiles')
        num_block_suffix = '5';
        block_grouping_folder_in_each_session = sprintf('%sBy_block', block_grouping_folder_prefix);
    elseif strcmp(givenListOfRequiredFiles, 'sixthBlockFiles')
        num_block_suffix = '6';
        block_grouping_folder_in_each_session = sprintf('%sBy_block', block_grouping_folder_prefix);
    elseif strcmp(givenListOfRequiredFiles, 'overlapBlocksFiles_BeforeInjection')
        % For overlap blocks before injection
        block_grouping_folder_in_each_session = 'Overlap_blocks_BeforeInjection/';
        block_grouping_folder_in_all_session = 'overlapBlocksFilesAcrossSessions_BeforeInjection';
        num_block_suffix = '';
    elseif strcmp(givenListOfRequiredFiles, 'overlapBlocksFiles_AfterInjection')
        % For overlap blocks after injection
        block_grouping_folder_in_each_session = 'Overlap_blocks_AfterInjection/';
        block_grouping_folder_in_all_session = 'overlapBlocksFilesAcrossSessions_AfterInjection';
        num_block_suffix = '';
    elseif strcmp(givenListOfRequiredFiles, 'overlapBlocksFiles_BeforeInjection_3_4')
        % For overlap blocks before injection
        block_grouping_folder_in_each_session = 'Overlap_blocks_BeforeInjection_3_4/';
        block_grouping_folder_in_all_session = 'overlapBlocksFilesAcrossSessions_BeforeInjection_3_4';
        num_block_suffix = '';
    elseif strcmp(givenListOfRequiredFiles, 'overlapBlocksFiles_AfterInjection_3_4')
        % For overlap blocks after injection
        block_grouping_folder_in_each_session = 'Overlap_blocks_AfterInjection_3_4/';
        block_grouping_folder_in_all_session = 'overlapBlocksFilesAcrossSessions_AfterInjection_3_4';
        num_block_suffix = '';
    elseif strcmp(givenListOfRequiredFiles, 'allBlocksFiles_BeforeInjection')
        % For all blocks before injection
        block_grouping_folder_in_each_session = 'All_blocks_BeforeInjection/';
        block_grouping_folder_in_all_session = 'allBlocksFilesAcrossSessions_BeforeInjection';
        num_block_suffix = '';
    elseif strcmp(givenListOfRequiredFiles, 'allBlocksFiles_AfterInjection')
        % For all blocks after injection
        block_grouping_folder_in_each_session = 'All_blocks_AfterInjection/';
        block_grouping_folder_in_all_session = 'allBlocksFilesAcrossSessions_AfterInjection';
        num_block_suffix = '';
    else
        error('Unknown value for givenListOfRequiredFiles.');
    end
    
    
    
    % Construct the block grouping folder for saving
    if isempty(block_grouping_folder_in_all_session)
        % For specific block files, construct the folder with block number suffix
        block_grouping_folder_in_all_session = sprintf('%sFilesAcrossSessions_Block_%s/', lower(block_grouping_folder_prefix), num_block_suffix);
    end
    
    
    % Construct num_block
    if isempty(num_block_suffix)
        num_block = '';
    else
        % For specific block files, construct num_block
        num_block = sprintf('block_%s', num_block_suffix);
    end
    
    
    % Preprocess given_labels_to_use
    given_labels_to_use_split = strsplit(given_labels_to_use, '_');
    combinedLabel = combine_label_segments(given_labels_to_use_split);
    
    
    
    
    if  strcmp(typeOfDecoding, 'each_session_separately')
        
        % Call the new function to find the decoding results file
        [decodingResultsFilePath, session_num_cv_splits_Info, mean_decoding_results, loadedData] = find_decoding_results_file(monkey_prefix, dateOfRecording, OUTPUT_PATH_binned, block_grouping_folder_in_each_session, target_brain_structure, target_state, combinedLabel, num_block);
        
        
        %%%%% Here you can perform your analysis for normal distribution on
        % `mean_decoding_results` and other loaded data.
        output_folder = [file_for_group '/' folder_pairs{fg_idx} '/Normality_Test_Results/' ]
        if ~exist(output_folder, 'dir')
            mkdir(output_folder);
        end
        
        % Receive the name of required file
        [~, fileName, ext] = fileparts(decodingResultsFilePath);
        %fileWithExtension = strcat(fileName, ext);  % Concatenate the filename and extension
        splitFileName = strsplit(fileName, '_DECODING_RESULTS'); % Split the filename at '_DECODING_RESULTS'
        requiredPart = splitFileName{1}; % Take the first part of the split result
        
        % Check our data for normality
        check_normality(mean_decoding_results, output_folder, requiredPart);
        
        % Store the data for further analysis (e.g., t-test)
        if fg_idx == 1
            data_file_group_1 = mean_decoding_results;
            requiredPart_group_1 = requiredPart;
        else
            data_file_group_2 = mean_decoding_results;
            requiredPart_group_2 = requiredPart;
        end
        
    end
    
    
end
% Calculate the differences between paired observations
differences = data_file_group_2 - data_file_group_1;


%% Perform paired t-test

% Perform paired t-test using the new function
output_folder_Statistical_results = [file_for_group '/Statistics/' combined_folder_name '/'];
if ~exist(output_folder_Statistical_results, 'dir')
    mkdir(output_folder_Statistical_results);
end

perform_paired_ttest(data_file_group_1, data_file_group_2, requiredPart_group_1, requiredPart_group_2, output_folder_Statistical_results);


%% Perform Wilcoxon Signed-Rank Test
perform_paired_wilcoxon_test(data_file_group_1, data_file_group_2, requiredPart_group_1, requiredPart_group_2, output_folder_Statistical_results); 


%% left-tailed t-test
perform_left_tailed_ttest(data_file_group_1, data_file_group_2, requiredPart_group_1, requiredPart_group_2, output_folder_Statistical_results);


end



% function data = load_data_from_folder(folder_path)
% % Load all data files from the specified folder
% data_files = dir(fullfile(folder_path, '*.mat'));
% data = [];
% 
% for k = 1:length(data_files)
%     file_path = fullfile(folder_path, data_files(k).name);
%     file_data = load(file_path);
%     data = [data; file_data]; % Assuming each file contains a single variable
% end
% end


function check_normality(data, output_folder, filename_prefix)

if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end


% Create filenames for saving
plot_file = fullfile(output_folder, [filename_prefix, '_Normality_plot.png']);
results_file = fullfile(output_folder, [filename_prefix, '_Normality_test_results.txt']);


% Plot Histogram
figure;
subplot(2, 2, 1);
histfit(data);
title('Histogram with Normal Fit');

% Plot Box Plot
subplot(2, 2, 2);
boxplot(data);
title('Box Plot');

% Plot Q-Q Plot
% A Q-Q plot compares the quantiles of your data against the quantiles of a normal distribution.
% If the data points roughly follow a straight line, the data can be considered normally distributed.
subplot(2, 2, 3);
qqplot(data);
title('Q-Q Plot');


% Open a text file for writing
fid = fopen(results_file, 'w');


% Shapiro-Wilk Test
% The null hypothesis - the data are normally distributed
% For TAIL =  0 (2-sided test), alternative: X is not normal.
% H = 0 => Do not reject the null hypothesis at significance level ALPHA (default = 0.05)
% H = 1 => Reject the null hypothesis at significance level ALPHA (default = 0.05)
% If p-value < alpha (where alpha is your chosen significance level, typically 0.05), you reject the null hypothesis
% W - it ranges between 0 and 1. Values close to 1 indicate the data are more likely to be normally distributed
[h_sw, p_sw, w] = sdndt_Sim_LIP_dPul_NDT_swtest(data, 0.05, 0);
if h_sw == 1 % Determine the interpretation based on the test result
    interpretation_sw = 'The data do not follow a normal distribution.';
else
    interpretation_sw = 'The data follow a normal distribution.';
end
% Write Shapiro-Wilk Test results
fprintf(fid, 'Shapiro-Wilk Test:\n');
fprintf(fid, 'h = %d\np-value = %.4f\nW = %.4f\n', h_sw, p_sw, w);
fprintf(fid, 'Interpretation: %s\n\n', interpretation_sw);

subplot(2, 2, 4);  % Display Shapiro-Wilk Test results
text(0.1, 0.5, sprintf('Shapiro-Wilk Test\nh = %d\np-value = %.4f\nW = %.4f', h_sw, p_sw, w));
axis off;
title('Shapiro-Wilk Test');

% Save the plot as a PNG file
saveas(gcf, plot_file);

% Kolmogorov-Smirnov Test
% The null hypothesis - the data are normally distributed
% TAIL - 'unequal' - two-sided test (Default)
% H = 0: Do not reject the null hypothesis
% H = 1: Reject the null hypothesis
% The p-value (pValue) should be greater than the chosen significance level (e.g., alpha = 0.05), indicating that there is no significant evidence against the null hypothesis
[h_ks, p_ks] = kstest(data);
if h_ks == 0
    interpretation_ks = 'The data could be normally distributed.';
else
    interpretation_ks = 'The data do not follow a normal distribution.';
end
fprintf(fid, 'Kolmogorov-Smirnov Test:\n');
fprintf(fid, 'h = %d\np-value = %.4f\n', h_ks, p_ks);
fprintf(fid, 'Interpretation: %s\n\n', interpretation_ks);


% Anderson-Darling Test
% A variation of the K-S test that gives more weight to the tails of the distribution.
% It's particularly useful for small sample sizes.
% h = 0: the data could be normally distributed
% p > alpha (typically 0.05) the data could be normally distributed
[h_ad, ~, ~] = my_adtest(data);
if h_ad == 0
    interpretation_ad = 'The data could be normally distributed.';
else
    interpretation_ad = 'The data do not follow a normal distribution.';
end
fprintf(fid, 'Anderson-Darling Test:\n');
fprintf(fid, 'h = %d\n', h_ad);
fprintf(fid, 'Interpretation: %s\n\n', interpretation_ad);


% Jarque-Bera Test
% h = 0 - the data could be normally distributed
% p > alpha (typically 0.05) suggesting that the data could be normally distributed
[h_jb, p_jb] = my_jbtest(data);
if h_jb == 0
    interpretation_jb = 'The data could be normally distributed.';
else
    interpretation_jb = 'The data do not follow a normal distribution.';
end
fprintf(fid, 'Jarque-Bera Test:\n');
fprintf(fid, 'h = %d\np-value = %.4f\n', h_jb, p_jb);
fprintf(fid, 'Interpretation: %s\n', interpretation_jb);


% Close the text file
fclose(fid);

% Close the figure
close(gcf);
end


function [h, p, adstat] = my_adtest(x)
% Anderson-Darling test for normality
% Inputs:
% x - data vector
% Outputs:
% h - hypothesis test result (0 = fail to reject, 1 = reject)

[h, p, adstat] = adtest(x);
end

function [h, p] = my_jbtest(x)
% Jarque-Bera test for normality
% Inputs:
% x - data vector
% Outputs:
% h - hypothesis test result (0 = fail to reject, 1 = reject)
% p - p-value

[~, p, ~, ~] = jbtest(x); % Call MATLAB's built-in jbtest function
h = p < 0.05; % Set a significance level (0.05) for the test
end



function combinedLabel = combine_label_segments(labelSegments)
% Combine segments 1 and 2, and segments 3 and 4
combinedSegments = {strjoin(labelSegments(1:2), '_'), strjoin(labelSegments(3:4), '_')};
combinedLabel = strjoin(combinedSegments, ' '); % Join the combined segments with a space
end


function perform_paired_ttest(data_file_group_1, data_file_group_2, filename_prefix_1, filename_prefix_2, output_folder)
% Null Hypothesis (H0): Assumes there is no difference between the means of the two groups.
% Alternative Hypothesis (H1): Assumes there is a difference between the means of the two groups.
% p-value: A small p-value (< 0.05) suggests that the observed data is unlikely under the null hypothesis, leading to its rejection.

% h = 1: Reject the null hypothesis (there is a significant difference).
% h = 0: Fail to reject the null hypothesis (no significant difference).
% p-value: If less than 0.05, indicates strong evidence against the null hypothesis, so you reject it.
% Positive t-statistic: The mean of the first sample (before inactivation) is less than the mean of the second sample (after inactivation), suggesting a positive effect.
% Negative t-statistic: The mean of the first sample (before inactivation) is greater than the mean of the second sample (after inactivation), suggesting a negative effect.

% Find differences in the filenames
[diff_1, diff_2, common_prefix, common_suffix] = find_filename_differences(filename_prefix_1, filename_prefix_2);


% Perform paired t-test
[h, p, ci, stats] = ttest(data_file_group_1, data_file_group_2);

% Create the full path to the output file
output_file_Statistical_results = [output_folder common_prefix diff_1 '_and_' diff_2 common_suffix '_Paired_T-test_results.txt'];

% Open a text file for writing
fid = fopen(output_file_Statistical_results, 'w');

% Write the results to the text file
fprintf(fid, 'Paired t-test result:\n');
fprintf(fid, 'h = %d\n', h);
fprintf(fid, 'p-value = %.4f\n', p);
fprintf(fid, 't-statistic = %.4f\n', stats.tstat);
fprintf(fid, 'Degrees of freedom = %d\n', stats.df);
fprintf(fid, 'Confidence interval = [%.4f, %.4f]\n', ci(1), ci(2));

% Interpret the results
if h == 1
    if stats.tstat > 0
        fprintf(fid, 'Interpretation: The inactivation has a significant positive effect on the mean decoding results.\n');
    else
        fprintf(fid, 'Interpretation: The inactivation has a significant negative effect on the mean decoding results.\n');
    end
else
    fprintf(fid, 'Interpretation: There is no significant effect of inactivation on the mean decoding results.\n');
end

% Close the text file
fclose(fid);

% Close the figure
close(gcf);
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


function perform_paired_wilcoxon_test(data_file_group_1, data_file_group_2, filename_prefix_1, filename_prefix_2, output_folder)

% Null hypothesis - there is no statistically significant difference between the before and after inactivation data
% A small p-value (typically ≤ 0.05) suggests that the differences are statistically significant
% h = 0: Fail to reject the null hypothesis, indicating that there is no statistically significant difference between the before and after inactivation data.
% h = 1: Reject the null hypothesis, indicating that there is a statistically significant difference between the before and after inactivation data


% Find differences in the filenames
[diff_1, diff_2, common_prefix, common_suffix] = find_filename_differences(filename_prefix_1, filename_prefix_2);

[p, h, stats] = signrank(data_file_group_1, data_file_group_2);

% Create the full path to the output file
output_file_Statistical_results = [output_folder common_prefix diff_1 '_and_' diff_2 common_suffix '_Wilcoxon_Signed-Rank_Test.txt'];

% Open a text file for writing
fid = fopen(output_file_Statistical_results, 'w');

% Write the results to the text file
fprintf(fid, 'Wilcoxon Signed-Rank Test result:\n');
fprintf(fid, 'p-value = %.4f\n', p);
fprintf(fid, 'Test statistic (W) = %.4f\n', stats.signedrank);
fprintf(fid, 'h = %d (0: fail to reject null, 1: reject null)\n', h);


% Interpretation
if h == 0
    fprintf(fid, 'Interpretation: Fail to reject the null hypothesis: No significant difference between the paired samples.\n');
else
    fprintf(fid, 'Interpretation: Reject the null hypothesis: Significant difference between the paired samples.\n');
end

% Close the text file
fclose(fid);

% Close the figure
close(gcf);

end 

function perform_left_tailed_ttest(data_file_group_1, data_file_group_2, filename_prefix_1, filename_prefix_2, output_folder)
% As I hypothesize that inactivation negatively  affects the decoding results, I will use a left-tailed t-test
% Perform left-tailed t-test

% If h_left = 1, null hypothesis (that inactivation does not affect decoding results) is rejected
% The critical t-value (tcrit) indicates the threshold beyond which you would reject the null hypothesis.

% Find differences in the filenames
[diff_1, diff_2, common_prefix, common_suffix] = find_filename_differences(filename_prefix_1, filename_prefix_2);

% Calculate the differences between paired observations
differences = data_file_group_1 - data_file_group_2;

[h_left, ~, ~, stats_left] = ttest(differences, 0, 'Tail', 'left');


% Create the full path to the output file
output_file_Statistical_results = [output_folder common_prefix diff_1 '_and_' diff_2 common_suffix '_Left-tailed_T-test.txt'];

% Open a text file for writing
fid = fopen(output_file_Statistical_results, 'w');

% Display the left-tailed t-test result
fprintf(fid, 'Left-tailed t-test result:\n');
fprintf(fid, 'h = %d\n', h_left);
fprintf(fid, 't-statistic = %.4f\n', stats_left.tstat);
fprintf(fid, 'Degrees of freedom = %d\n', stats_left.df);

% Interpret the results
    if h_left == 1
        if stats_left.tstat < 0
            fprintf(fid, 'Interpretation: The inactivation has a significant negative effect on the mean decoding results.\n');
        else
            fprintf(fid, 'Interpretation: The inactivation has a significant positive effect on the mean decoding results.\n');
        end
    else
        fprintf(fid, 'Interpretation: There is no significant effect of inactivation on the mean decoding results.\n');
    end

    % Explain the figure
    fprintf(fid, '\nFigure Explanation:\n');
    fprintf(fid, 'The figure displays the Student''s t-distribution for the degrees of freedom calculated from the data.\n');
    fprintf(fid, 'The x-axis represents the t values, and the y-axis represents the probability density.\n');
    fprintf(fid, 'The critical t value (dashed line) indicates the threshold beyond which we reject the null hypothesis.\n');
    fprintf(fid, 'The t-statistic from our test is marked on the plot. If the t-statistic lies to the left of the critical t value, the test is significant at the 5%% level.\n');

% Plot the Student's t-distribution, t-statistic, and critical t-value
figure;
nu = stats_left.df;
k = linspace(-15, 15, 300);
tdistpdf = tpdf(k, nu);
tval = stats_left.tstat;
tvalpdf = tpdf(tval, nu);
tcrit = tinv(0.05, nu); % Critical value for left-tailed test

plot(k, tdistpdf);
hold on;
scatter(tval, tvalpdf, 'filled');
xline(tcrit, '--');
%legend({'Mean Decoding Results', 't-Statistic', 'Critical Cutoff'}, 'Location', 'best', 'Interpreter', 'none');
legend({'Mean Decoding Results', 't-Statistic', 'Critical Cutoff'}, 'Location', 'northeast', 'Interpreter', 'none');

title('Left-Tailed t-Test Distribution');
xlabel('t Value');
ylabel('Probability Density');
hold off;

% Save the figure
output_file_figure = [output_folder common_prefix diff_1 '_and_' diff_2 common_suffix '_Left-tailed_T-test.png'];
saveas(gcf, output_file_figure);


% Close the figure
close(gcf);

% Close the file after writing
fclose(fid);

end



function [decodingResultsFilePath, session_num_cv_splits_Info, mean_decoding_results, loadedData] = find_decoding_results_file(monkey_prefix, dateOfRecording, OUTPUT_PATH_binned, block_grouping_folder, target_brain_structure, target_state, combinedLabel, num_block)

current_dateOfRecording_monkey = [monkey_prefix dateOfRecording];
OUTPUT_PATH_binned_data = fullfile(OUTPUT_PATH_binned, current_dateOfRecording_monkey, block_grouping_folder);

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
decodingResultsFilePath = '';
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
        decodingResultsFilename = decodingResultsFiles(fileIndex).name;
        
        % Check if the file name contains the desired target structure, state, and label
        if contains(decodingResultsFilename, target_brain_structure) && ...
                contains(decodingResultsFilename, target_state) && ...
                contains(decodingResultsFilename, combinedLabel) && ...
                contains(decodingResultsFilename, num_block)
            % Construct the full path to the DECODING_RESULTS.mat file
            
            
            decodingResultsFilePath = fullfile(cvSplitFolderPath, decodingResultsFilename);
            
            % Now you have the path to the suitable DECODING_RESULTS.mat file
            % You can process or load this file as needed
            fileFound = true;  % Set flag to true
            
            % Extract data about session and num_cv_splits
            num_cv_splits = str2double(extractBetween(cvSplitFolderName, 'num_cv_splits_', '('));
            session_num_cv_splits_Info = sprintf('Session: %s, num_cv_splits: %d\n', dateOfRecording, num_cv_splits);
            
            
            break; % Exit the loop once the file is found
        end
        
        
        % end
    end
    
    
    if fileFound
        break; % Exit the loop if the file is found
    end
end



loadedData = load(decodingResultsFilePath);

% Now you can access the data from the loaded file using the appropriate fields or variables
% For example, if there is a variable named 'results' in the loaded file, you can access it as follows:
mean_decoding_results = loadedData.DECODING_RESULTS.NORMALIZED_RANK_RESULTS.mean_decoding_results;

end
