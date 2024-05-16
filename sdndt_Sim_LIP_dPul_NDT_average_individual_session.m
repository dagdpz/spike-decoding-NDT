function sdndt_Sim_LIP_dPul_NDT_average_individual_session(monkey, injection, typeOfDecoding, curves_per_session)

% For across session analysis, you just need to average individual session
% sdndt_Sim_LIP_dPul_NDT_average_individual_session('Bacchus', '1', 'merged_files_across_sessions', 'nis')


% monkey: 'Linus', 'Bacchus'
% injection: '0' - control sessions, '1' - inactivation sessions (for inactivation experiment),
%            '2' - for functional interaction experiment
% typeOfDecoding: 'each_session_separately' or 'merged_files_across_sessions'
% curves_per_session: 'Same' - showing individual sessions (monochrome) on the graph
%                     'Color' - showing individual sessions (with individual color) on the graph
%                     'nis' (no individual session) - without plotting individual sessions on the graph

%%
% Start timing the execution
startTime = tic;


%% Define the list of required files
listOfRequiredFiles = {%'firstBlockFiles', 'secondBlockFiles', 'thirdBlockFiles', ...
%     'fourthBlockFiles', 'fifthBlockFiles', 'sixthBlockFiles', ...
%     'overlapBlocksFiles_BeforeInjection',
    'overlapBlocksFiles_AfterInjection' %, ...
    %'allBlocksFiles_BeforeInjection',
    'allBlocksFiles_AfterInjection'
    
    %'allBlocksFiles', 'overlapBlocksFiles'
    };


%% Define typeOfSessions
% Calculate typeOfSessions based on the injection parameter
if strcmp(injection, '1')
    if strcmp(monkey, 'Linus')
        typeOfSessions = {'left', 'right', 'all'}; % For control and injection experiments
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


%% Define valid combinations of injection and target_brain_structure
if strcmp(injection, '1') || strcmp(injection, '0')
    combinations_inj_and_target_brain_structure = struct('injection', {injection, injection}, 'target_brain_structure', {'LIP_L', 'LIP_R'});
    %   combinations_inj_and_target_brain_structure = struct('injection', { injection}, 'target_brain_structure', {'LIP_L'});
    
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
numTypeBlocks = numel(listOfRequiredFiles); % Add this line to get the number of files


% Calculate total number of iterations
totalIterations = numApproach * numTypeBlocks * numCombinations * numLabels * numFieldNames * numTypesOfSessions;
overallProgress = 0; % Initialize progress


for file_index = 1:numTypeBlocks % Loop through each file in listOfRequiredFiles
    current_file = listOfRequiredFiles{file_index}; % Get the current file
    
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
                    %                 else % strcmp(typeOfDecoding, 'merged_files_across_sessions')
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
                            
                            if strcmp(typeOfDecoding, 'each_session_separately') % typeOfDecoding
                                
                                for numDays = 1:numel(current_set_of_date)
                                    current_date = current_set_of_date{numDays};
                                    
                                    % Call the internal decoding function for each day
                                    sdndt_Sim_LIP_dPul_NDT_avarage_internal(monkey, current_injection, current_type_of_session, typeOfDecoding, current_date, current_target_brain_structure, target_state, current_label, current_approach, current_file, curves_per_session); % typeOfSessions{j}
                                    
                                    %                                     % Update progress bar
                                    %                                     progress = ((file_index - 1) * numCombinations * numLabels * numFieldNames * numTypesOfSessions * numel(current_set_of_date) + ...
                                    %                                         (comb_index - 1) * numLabels * numFieldNames * numTypesOfSessions * numel(current_set_of_date) + ...
                                    %                                         (label_index - 1) * numFieldNames * numTypesOfSessions * numel(current_set_of_date) + ...
                                    %                                         (i - 1) * numTypesOfSessions * numel(current_set_of_date) + ...
                                    %                                         (j - 1) * numel(current_set_of_date) + numDays) / ...
                                    %                                         (numFiles * numCombinations * numLabels * numFieldNames * numTypesOfSessions * numel(current_set_of_date));
                                    %                                     waitbar(progress, h, sprintf('Processing... %.2f%%', progress * 100));
                                    
                                    % Update progress for each iteration
                                    overallProgress = overallProgress + 1;
                                    waitbar(overallProgress / totalIterations, h, sprintf('Processing... %.2f%%', overallProgress / totalIterations * 100));
                                    
                                end
                                
                                
                            else % strcmp(typeOfDecoding, 'merged_files_across_sessions')
                                current_date = [];
                                % Call the internal decoding function only once
                                sdndt_Sim_LIP_dPul_NDT_avarage_internal(monkey, current_injection, current_type_of_session, typeOfDecoding, current_set_of_date, current_target_brain_structure, target_state, current_label, current_approach, current_file, curves_per_session);
                                
                                %                             % Update progress bar for merged files scenario
                                %                             progress = ((file_index - 1) * numCombinations + (comb_index - 1)) / (numFiles * numCombinations);
                                %                             waitbar(progress, h, sprintf('Processing... %.2f%%', progress * 100));
                                
                                % Update progress for each combination
                                %                                 overallProgress = ((file_index - 1) * numCombinations * numLabels * numFieldNames * numTypesOfSessions + ...
                                %                                     (comb_index - 1) * numLabels * numFieldNames * numTypesOfSessions + ...
                                %                                     (label_index - 1) * numFieldNames * numTypesOfSessions + ...
                                %                                     (i - 1) * numTypesOfSessions + ...
                                %                                     (j - 1)) / ...
                                %                                     (numFiles * numCombinations * numLabels * numFieldNames * numTypesOfSessions);
                                %
                                %                                 % Update progress bar
                                %                                 waitbar(overallProgress, h, sprintf('Processing... %.2f%%', overallProgress * 100));
                                
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





function sdndt_Sim_LIP_dPul_NDT_avarage_internal(monkey, injection, typeOfSessions, typeOfDecoding, dateOfRecording, target_brain_structure, target_state, given_labels_to_use, current_approach, givenListOfRequiredFiles, curves_per_session)




%% Path
% Call the function to get the dates
allDateOfRecording = filelist_of_days_from_Simultaneous_dPul_PPC_recordings(monkey, injection, typeOfSessions);


% Call the settings function with the chosen set
[base_path, INPUT_PATH, OUTPUT_PATH_raster, OUTPUT_PATH_binned, monkey_prefix, settings] = sdndt_Sim_LIP_dPul_NDT_settings(monkey, injection, typeOfSessions);

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

% Extract the block number suffix from givenListOfRequiredFiles
if strcmp(givenListOfRequiredFiles, 'firstBlockFiles')
    num_block_suffix = '1';
    block_grouping_folder = sprintf('%sBy_block', block_grouping_folder_prefix);
elseif strcmp(givenListOfRequiredFiles, 'secondBlockFiles')
    num_block_suffix = '2';
    block_grouping_folder = sprintf('%sBy_block', block_grouping_folder_prefix);
elseif strcmp(givenListOfRequiredFiles, 'thirdBlockFiles')
    num_block_suffix = '3';
    block_grouping_folder = sprintf('%sBy_block', block_grouping_folder_prefix);
elseif strcmp(givenListOfRequiredFiles, 'fourthBlockFiles')
    num_block_suffix = '4';
    block_grouping_folder = sprintf('%sBy_block', block_grouping_folder_prefix);
elseif strcmp(givenListOfRequiredFiles, 'fifthBlockFiles')
    num_block_suffix = '5';
    block_grouping_folder = sprintf('%sBy_block', block_grouping_folder_prefix);
elseif strcmp(givenListOfRequiredFiles, 'sixthBlockFiles')
    num_block_suffix = '6';
    block_grouping_folder = sprintf('%sBy_block', block_grouping_folder_prefix);
elseif strcmp(givenListOfRequiredFiles, 'overlapBlocksFiles_BeforeInjection')
    % For overlap blocks before injection
    block_grouping_folder = 'Overlap_blocks_BeforeInjection/';
    block_grouping_folder_for_saving = 'overlapBlocksFilesAcrossSessions_BeforeInjection';
    num_block_suffix = '';
elseif strcmp(givenListOfRequiredFiles, 'overlapBlocksFiles_AfterInjection')
    % For overlap blocks after injection
    block_grouping_folder = 'Overlap_blocks_AfterInjection/';
    block_grouping_folder_for_saving = 'overlapBlocksFilesAcrossSessions_AfterInjection';
    num_block_suffix = '';
elseif strcmp(givenListOfRequiredFiles, 'allBlocksFiles_BeforeInjection')
    % For all blocks before injection
    block_grouping_folder = 'All_blocks_BeforeInjection/';
    block_grouping_folder_for_saving = 'allBlocksFilesAcrossSessions_BeforeInjection';
    num_block_suffix = '';
elseif strcmp(givenListOfRequiredFiles, 'allBlocksFiles_AfterInjection')
    % For all blocks after injection
    block_grouping_folder = 'All_blocks_AfterInjection/';
    block_grouping_folder_for_saving = 'allBlocksFilesAcrossSessions_AfterInjection';
    num_block_suffix = '';
else
    error('Unknown value for givenListOfRequiredFiles.');
end



% Construct the block grouping folder for saving
if isempty(block_grouping_folder_for_saving)
    % For specific block files, construct the folder with block number suffix
    block_grouping_folder_for_saving = sprintf('%sFilesAcrossSessions_Block_%s/', lower(block_grouping_folder_prefix), num_block_suffix);
end


% Construct num_block
if isempty(num_block_suffix)
    % For overlap or all blocks files, num_block is empty
    %     if strcmp(givenListOfRequiredFiles, 'allBlocksFiles_AfterInjection') || strcmp(givenListOfRequiredFiles, 'overlapBlocksFiles_AfterInjection')
    %          num_block = '...';
    %     else
    %         num_block = '1';
    %     end
    num_block = '';
else
    % For specific block files, construct num_block
    num_block = sprintf('block_%s', num_block_suffix);
end


% Preprocess given_labels_to_use
given_labels_to_use_split = strsplit(given_labels_to_use, '_');
combinedLabel = combine_label_segments(given_labels_to_use_split);



%%
if  strcmp(typeOfDecoding, 'merged_files_across_sessions')
    
    % Initialize variables to keep track of the highest value and its folder
    highestValue = 0;
    highestFolder = '';
    
    % Initialize decodingResultsFilePath
    decodingResultsFilePath = '';  % Initialize as an empty string
    
    % Initialize cell array ...
    all_mean_decoding_results = {}; % to store mean decoding results
    sites_to_use = {};
    numOfUnits = {};
    numOfTrials = {};
    session_num_cv_splits_Info = {};
    session_info_combined = {};
    label_counts_cell = cell(1, numel(dateOfRecording)); % Initialize a cell array to store label_counts for each day
    
    totalNumOfUnits = 0; % Initialize the total number of units
    totalNumOfTrials = 0; % Initialize the total number of trials
    
    sum_first_numbers = 0; % Initialize variables to store sums of the first and second numbers
    sum_second_numbers = 0;
    
    for numOfData = 1:numel(dateOfRecording)
        
        current_dateOfRecording = dateOfRecording{numOfData};
        current_dateOfRecording_monkey = [monkey_prefix current_dateOfRecording];
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
        %
        %
        %         % Sort folders based on values outside parentheses (in descending order)
        %         [~, sorted_idx] = sort(values_outside_parentheses, 'descend');
        
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
                    
                    
                    
                    %                     % If certain conditions are met (e.g., processing specific block files),
                    %                     % you can add an additional filter based on the block number here
                    %                     if isequal(givenListOfRequiredFiles, 'firstBlockFiles') && contains(decodingResultsFilename, 'block_1') || ...
                    %                             isequal(givenListOfRequiredFiles, 'secondBlockFiles') && contains(decodingResultsFilename, 'block_2') || ...
                    %                             isequal(givenListOfRequiredFiles, 'thirdBlockFiles') && contains(decodingResultsFilename, 'block_3') || ...
                    %                             isequal(givenListOfRequiredFiles, 'fourthBlockFiles') && contains(decodingResultsFilename, 'block_4') || ...
                    %                             isequal(givenListOfRequiredFiles, 'fifthBlockFiles') && contains(decodingResultsFilename, 'block_5') || ...
                    %                             isequal(givenListOfRequiredFiles, 'sixthBlockFiles') && contains(decodingResultsFilename, 'block_6')
                    %
                    %                         % Construct the full path to the DECODING_RESULTS.mat file
                    %                         decodingResultsFilePath = fullfile(cvSplitFolderPath, decodingResultsFilename);
                    %
                    %                         % Now you have the path to the suitable DECODING_RESULTS.mat file
                    %                         % You can process or load this file as needed
                    %                         fileFound = true;  % Set flag to true
                    %
                    %                         % Extract data about session and num_cv_splits
                    %                         num_cv_splits = str2double(extractBetween(cvSplitFolderName, 'num_cv_splits_', '('));
                    %                         session_num_cv_splits_Info = sprintf('Session: %s, num_cv_splits: %d\n', dateOfRecording{numOfData}, num_cv_splits);
                    %
                    %                         break; % Exit the loop once the file is found
                    %
                    %
                    %                     else
                    decodingResultsFilePath = fullfile(cvSplitFolderPath, decodingResultsFilename);
                    
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
        session_info_combined{end+1} = [session_num_cv_splits_Info];
        
        
        
        
        % If no file was found in any folder, display error message
        if isempty(decodingResultsFilePath)
            % disp('ERROR: No suitable decoding results file found.');
            disp(['No suitable decoding results file found for session: ', current_dateOfRecording]);
            continue; % Move to the next iteration of the loop
        else
            % Load the file
            loadedData = load(decodingResultsFilePath);
            
            % Now you can access the data from the loaded file using the appropriate fields or variables
            % For example, if there is a variable named 'results' in the loaded file, you can access it as follows:
            mean_decoding_results = loadedData.DECODING_RESULTS.NORMALIZED_RANK_RESULTS.mean_decoding_results;
            
            % Append mean decoding results to the cell array
            all_mean_decoding_results{end+1} = mean_decoding_results;
            
            % Process the loaded data as needed
            
            % Load additional data if necessary
            [filepath, filename, fileext] = fileparts(decodingResultsFilePath); % Get the path and filename components
            desired_part = fullfile(filepath, filename); % Concatenate the path and filename without the extension
            binned_file_name = [desired_part '.mat']; % Add '.mat' to the desired part
            % Specify substrings to remove
            substrings_to_remove = {'_instr_R instr_L_DECODING_RESULTS', '_choice_R choice_L_DECODING_RESULTS', '_instr_R choice_R_DECODING_RESULTS', '_instr_L choice_L_DECODING_RESULTS'}; % Add more patterns as needed
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
        first_second_numbers = [sum_first_numbers sum_second_numbers]
        
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
        numOfUnits_and_numOfTrials_info_labelsAppears = [numOfUnits_and_numOfTrials_info, labelCountsInfo];
        %numOfUnits_and_numOfTrials_info_labelsAppears = sprintf('%s%s', numOfUnits_and_numOfTrials_info, labelCountsInfo);
        
        %% location of the curve on the graph
        
        % Concatenate mean decoding results from all days into one variable
        mean_decoding_results = horzcat(all_mean_decoding_results{:});
        mean_decoding_results_100 = mean_decoding_results*100
        %  plot(mean_decoding_results_100)
        
        
        % Calculate the total number of time points
        numTimePoints = size(mean_decoding_results_100, 1);
        median_value = (numTimePoints + 1) / 2; % Median value
        
        % Calculate the bin duration in milliseconds
        step_size = loadedData.DECODING_RESULTS.DS_PARAMETERS.binned_site_info.binning_parameters.sampling_interval; % milliseconds
        
        % Calculate the offset to center the graph around the median
        offset = 500 - median_value * step_size;
        
        % Generate the time values for each bin centered around the median
        timeValues = (1:numTimePoints) * step_size + offset;
        
        
        %% Plot the results
        
        if isequal(curves_per_session, 'Same')
            lightBlueColor = [0.5, 0.5, 1.0]; % RGB triplet representing a lighter shade of blue
            plot(timeValues, mean_decoding_results_100, 'LineWidth', 1, 'Color', lightBlueColor);
            
        elseif isequal(curves_per_session, 'Color')
            plot(timeValues, mean_decoding_results_100, 'LineWidth', 1);
            
        elseif isequal(curves_per_session, 'nis') % no individual session
            % plot without individual session labels
        end
        
        
        
        tickPositions = 0:200:1000; % Calculate the tick positions every 200 ms
        xticks(tickPositions);  % Set the tick positions on the X-axis
        
        xlabel('Time (ms)', 'FontSize', 18); % Set the font size to 14 for the xlabel
        ylabel('Classification Accuracy', 'FontSize', 18); % Set the font size to 14 for the ylabel
        
        
        box off;  % Remove the box around the axes
        ax = gca; % Display only the X and Y axes
        ax.YAxis.Visible = 'on';  % Show Y-axis
        ax.XAxis.Visible = 'on';  % Show X-axis
        
        xline(500); % draw a vertical line at 500
        yline(50); % draw a horizontal line at 50
        set(gca,'Xlim',settings.time_lim, 'Ylim',settings.y_lim); % limitation of the X (from 0 to 1000) and Y (from 20 to 100) axes
        
        % change the size of the figure
        set(gcf,'position',[450,400,700,500]) % [x0,y0,width,height]
        
        %         % Add text using the annotation function
        %         positionOfAnnotation = [0.76, 0.5, 0.26, 0.26]; % [x position, y position, size x, size y]
        %         annotation('textbox', positionOfAnnotation, 'String', numOfUnits_and_numOfTrials_info_labelsAppears, ...
        %             'FontSize', 10, 'HorizontalAlignment', 'left','FitBoxToText','on');
        %         set(gca, 'Position', [0.1, 0.13, 0.65, 0.72] ) % change the position of the axes to fit the annotation into the figure too.
        
        % create a title
        block_info = char(regexp(decodingResultsFilePath, 'block_\d+', 'match'));
        
        % Reshape the character array into a single row
        block_info_combined = reshape(block_info.', 1, []);
        
        % Convert the character array to a string
        %block_info_combined = string(block_info_combined);
        
        
        target_and_block_info = [target_brain_structure '; ' block_info_combined '; ' target_state];
        
        combinedLabel_for_Title = rearrangeCombinedLabel(combinedLabel);
        
        [t,s] = title(combinedLabel_for_Title, target_and_block_info);
        t.FontSize = 15;
        s.FontSize = 12;
        
        
        
        % Draw annotation window only on the last iteration
        if numOfData == numel(dateOfRecording)
            positionOfAnnotation = [0.76, 0.5, 0.26, 0.26]; % [x position, y position, size x, size y]
            annotation('textbox', positionOfAnnotation, 'String', numOfUnits_and_numOfTrials_info_labelsAppears, ...
                'FontSize', 10, 'HorizontalAlignment', 'left','FitBoxToText','on');
            set(gca, 'Position', [0.1, 0.13, 0.65, 0.72] ) % change the position of the axes to fit the annotation into the figure too.
            
            
            
            if isequal(curves_per_session, 'Color')
                % Label each line with the session name
                colorOrder = get(gca, 'ColorOrder');
                xPosition = timeValues(1);  % X position for the annotations (same for all)
                yPosition = 100 - 4*(numel(dateOfRecording)-1) : 4 : 100;  % Y positions for the annotations (spaced vertically)
                
                for i = 1:numel(dateOfRecording)
                    lineColor = colorOrder(rem(i - 1, size(colorOrder, 1)) + 1, :);
                    %                 text(timeValues(end), mean_decoding_results_100(end, i), dateOfRecording{i}, ...
                    %                     'Color', lineColor, 'FontSize', 11, 'HorizontalAlignment', 'left');
                    text(xPosition, yPosition(i), dateOfRecording{i}, ...
                        'Color', lineColor, 'FontSize', 10, 'HorizontalAlignment', 'left');
                end
            end
            
            
            
            % changing file name
            meanResultsFilename = generateMeanFilename(decodingResultsFilename)
            
            % Calculate the average dynamics by day
            average_dynamics_by_day = mean(mean_decoding_results_100, 2);
            
            % Calculate the standard error of the mean (SEM)
            sem = std(mean_decoding_results_100, 0, 2) / sqrt(size(mean_decoding_results_100, 2));
            
            % Define a darker shade of blue
            darkBlueColor = [0, 0, 0.5];
            
            % Plot the average dynamics with error bars on the same figure
            hold on; % Add the new plot to the existing one
            %             plot_average_dynamics = errorbar(timeValues, average_dynamics_by_day, sem, 'LineWidth', 2, 'Color', darkBlueColor); % Use a thicker line and blue color for the average dynamics with error bars
            %             plot_average_dynamics.LineWidth = 1;
            [hp1 hp2] =  ig_errorband(timeValues, average_dynamics_by_day, sem, 0);
            hp1.Color = [0, 0, 0.5]; % darkBlueColor
            hp2.FaceColor = [0, 0, 0.5]; % darkBlueColor
            
            plot(timeValues, average_dynamics_by_day, 'LineWidth', 3, 'Color', darkBlueColor);
            hold off;
            
            session_info_combined_for_text = strjoin(session_info_combined, '\n');
            
            cvSplitFolder_to_save = 'Average_Dynamics';
            
            % save
            typeOfDecoding_monkey = [monkey_prefix typeOfDecoding];
            OUTPUT_PATH_binned_data_for_saving = fullfile(OUTPUT_PATH_binned, typeOfDecoding_monkey, block_grouping_folder_for_saving, cvSplitFolder_to_save);
            % Check if cvSplitFolder_to_save folder exists, if not, create it
            if ~exist(OUTPUT_PATH_binned_data_for_saving, 'dir')
                mkdir(OUTPUT_PATH_binned_data_for_saving);
            end
            
            % Save the session information to a text file
            name_of_txt = ['Sessions_Num_CV_Splits_Info_' meanResultsFilename(1:end-4) '.txt'];
            sessionInfoFilePath = fullfile(OUTPUT_PATH_binned_data_for_saving, name_of_txt);
            fid = fopen(sessionInfoFilePath, 'w');
            fprintf(fid, session_info_combined_for_text);
            fclose(fid);
            
            
            if isequal(curves_per_session, 'Color')
                Color_curves_name = '_Color';
            elseif isequal(curves_per_session, 'Same')
                Color_curves_name = '';
            elseif isequal(curves_per_session, 'nis') % no individual session
                Color_curves_name = '_nis';
            end
            
            
            % Save the pic
            path_name_to_save = fullfile (OUTPUT_PATH_binned_data_for_saving,[meanResultsFilename(1:end-4) '_AverageDynamics' Color_curves_name '.png']);
            saveas(gcf, path_name_to_save);
            
            close(gcf);
        end
        
    end
    
    
else
    partOfName = dateOfRecording;
end


% % Load required files for each session or merged files
% OUTPUT_PATH_list_of_required_files = [OUTPUT_PATH_binned dateOfRecording '/List_of_required_files/sdndt_Sim_LIP_dPul_NDT_' partOfName '_list_of_required_files.mat'];
% load(OUTPUT_PATH_list_of_required_files);

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
