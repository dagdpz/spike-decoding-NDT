function sdndt_Sim_LIP_dPul_NDT_cross_decoding(monkey, injection, typeOfDecoding)

% The code converts the received raster data into binned data and then performs decoding.

% HOW TO CALL THE FUNCTION?
% If we decode within a session:
% sdndt_Sim_LIP_dPul_NDT_cross_decoding('Bacchus', '1', 'each_session_separately');

% If we decode across sessions:
% sdndt_Sim_LIP_dPul_NDT_cross_decoding('Bacchus', '1', 'merged_files_across_sessions');




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
%listOfRequiredFiles = {%'firstBlockFiles', 'secondBlockFiles', ...
%     'thirdBlockFiles', 'fourthBlockFiles', ...
%     'fifthBlockFiles', 'sixthBlockFiles', ...
%  'overlapBlocksFiles_BeforeInjection',
% 'overlapBlocksFiles_AfterInjection' %, ...
%  'overlapBlocksFiles_BeforeInjection_3_4',  'overlapBlocksFiles_AfterInjection_3_4'%, ...
%     'allBlocksFiles_BeforeInjection', 'allBlocksFiles_AfterInjection'
% };  %'allBlocksFiles', 'overlapBlocksFiles', ...

if strcmp(monkey, 'Bacchus')
    training_listOfRequiredFiles = {'overlapBlocksFiles_BeforeInjection', 'overlapBlocksFiles_AfterInjection'};
    test_listOfRequiredFiles = {'overlapBlocksFiles_AfterInjection', 'overlapBlocksFiles_BeforeInjection'};
elseif strcmp(monkey, 'Linus')
    training_listOfRequiredFiles = {'overlapBlocksFiles_BeforeInjection_3_4', 'overlapBlocksFiles_AfterInjection_3_4'};
    test_listOfRequiredFiles = {'overlapBlocksFiles_AfterInjection_3_4', 'overlapBlocksFiles_BeforeInjection_3_4'};
end

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
if any(contains(training_listOfRequiredFiles, {'overlapBlocksFiles_BeforeInjection_3_4', 'overlapBlocksFiles_AfterInjection_3_4', 'overlapBlocksFiles_BeforeInjection', 'overlapBlocksFiles_AfterInjection', 'overlapBlocksFiles'})) ||...
        any(contains(test_listOfRequiredFiles, {'overlapBlocksFiles_BeforeInjection_3_4', 'overlapBlocksFiles_AfterInjection_3_4', 'overlapBlocksFiles_BeforeInjection', 'overlapBlocksFiles_AfterInjection', 'overlapBlocksFiles'}))
    approach_to_use = {'overlap_approach'};
elseif any(contains(training_listOfRequiredFiles, {'allBlocksFiles_BeforeInjection', 'allBlocksFiles_AfterInjection', 'allBlocksFiles'}))
    any(contains(test_listOfRequiredFiles, {'allBlocksFiles_BeforeInjection', 'allBlocksFiles_AfterInjection', 'allBlocksFiles'}))
    approach_to_use = {'all_approach'};
else
    approach_to_use = {'all_approach', 'overlap_approach'};
end

%% Define target_state parameters
targetParams = struct();

% Define target_state parameters
targetParams.cueON = 6;
targetParams.GOSignal = 4;

% Calculate the number of target state parameters (number of fields)
numFieldNames = numel(fieldnames(targetParams));

%% Define labels_to_use as a cell array containing both values
labels_to_use = {'instr_R_instr_L', 'choice_R_choice_L'};



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
numFiles = numel(training_listOfRequiredFiles); % Add this line to get the number of files

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

totalIterations = totalIterations * numApproach * numFiles * numCombinations * numLabels * numFieldNames * numTypesOfSessions;
overallProgress = 0; % Initialize progress


%% Loop through each combination of injection, target_brain_structure, and label

for file_index = 1:numFiles % Loop through each file in listOfRequiredFiles
    current_training_file = training_listOfRequiredFiles{file_index}; % Get the current file
    current_test_file = test_listOfRequiredFiles{file_index};
    
    % Skip processing the second block if the injection is 0 or 1
    if ~((strcmp(injection, '0') || strcmp(injection, '1')) && ...
            (strcmp(current_training_file, 'secondBlockFiles') || strcmp(current_training_file, 'allBlocksFiles') || strcmp(current_training_file , 'overlapBlocksFiles')) || ...
            (strcmp(current_test_file, 'secondBlockFiles') || strcmp(current_test_file, 'allBlocksFiles') || strcmp(current_test_file , 'overlapBlocksFiles')))
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
                            
                            
                            if strcmp(typeOfDecoding, 'each_session_separately') % typeOfDecoding
                                
                                current_set_of_date = datesForSessions{j}; % Get the corresponding set of dates !!!!!
                                % totalIterations = totalIterations + numel(current_set_of_date) * numLabels * numApproach * numFieldNames;
                                
                                
                                for numDays = 1:numel(current_set_of_date)
                                    current_date = current_set_of_date{numDays};
                                    
                                    % Call the internal decoding function for each day
                                    sdndt_Sim_LIP_dPul_NDT_cross_decoding_internal(monkey, current_injection, current_type_of_session, typeOfDecoding, current_date, current_target_brain_structure, target_state, current_label, current_approach, current_training_file, current_test_file); % typeOfSessions{j}
                                    
                                    
                                    % Update progress for each iteration
                                    overallProgress = overallProgress + 1;
                                    waitbar(overallProgress / totalIterations, h, sprintf('Processing... %.2f%%', overallProgress / totalIterations * 100));
                                    
                                end
                                
                                
                            else % strcmp(typeOfDecoding, 'merged_files_across_sessions')
                                current_date = [];
                                % Call the internal decoding function only once
                                sdndt_Sim_LIP_dPul_NDT_cross_decoding_internal(monkey, current_injection, current_type_of_session, current_date, typeOfDecoding, current_target_brain_structure, target_state, current_label, current_approach, current_training_file, current_test_file);
                                
                                
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





function sdndt_Sim_LIP_dPul_NDT_cross_decoding_internal(monkey, injection, typeOfSessions, typeOfDecoding, dateOfRecording, target_brain_structure, target_state, given_labels_to_use, given_approach, training_givenListOfRequiredFiles, test_givenListOfRequiredFiles)
% ADDITIONAL SETTINGS
% The same as for sdndt_Sim_LIP_dPul_NDT_decoding function, except :
% target_state: 6 - cue on , 4 - target acquisition


%% Checking for mistakes while calling the function

if contains(injection, '0') && ...
        ((contains(training_givenListOfRequiredFiles, 'overlapBlocksFiles_AfterInjection') || contains(training_givenListOfRequiredFiles, 'overlapBlocksFiles_BeforeInjection')) || ...
        (contains(test_givenListOfRequiredFiles, 'overlapBlocksFiles_AfterInjection') || contains(test_givenListOfRequiredFiles, 'overlapBlocksFiles_BeforeInjection')))
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

if ~(target_state == 6 || target_state == 4) % Check if target_state is either 6 or 4
    error('Target state must be either 6 (cue on) or 4 (target acquisition).');
end

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
if ~(ismember(training_givenListOfRequiredFiles, allowed_blocks) || ismember(test_givenListOfRequiredFiles, allowed_blocks)) % Check if the provided block name is in the list of allowed blocks
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

if  strcmp(dateOfRecording, 'merged_files_across_sessions')
    partOfName = 'allSessionsBlocksFiles';
else
    partOfName = dateOfRecording;
end



% Check if dateOfRecording is valid
%     if ~strcmp(dateOfRecording, 'merged_files_across_sessions') && ~strcmp(dateOfRecording, 'each_session_separately')
if ~strcmp(dateOfRecording, 'merged_files_across_sessions') && ~any(strcmp(dateOfRecording, allDateOfRecording))
    error('Invalid dateOfRecording. It must be ''merged_files_across_sessions'' or one of the dates in allDateOfRecording.');
end


% Load required files for each session or merged files
%    if strcmp(dateOfRecording, 'merged_files_across_sessions')
OUTPUT_PATH_list_of_required_files = [OUTPUT_PATH_raster monkey_prefix dateOfRecording '/List_of_required_files/sdndt_Sim_LIP_dPul_NDT_' partOfName '_list_of_required_files.mat'];
%     else % strcmp(dateOfRecording, 'each_session_separately')
%         OUTPUT_PATH_list_of_required_files = [OUTPUT_PATH_raster current_date '/List_of_required_files/sdndt_Sim_LIP_dPul_NDT_' partOfName '_list_of_required_files.mat'];
%     end
load(OUTPUT_PATH_list_of_required_files);


%% Prepearing for Binned_data
% Add the path to the NDT so add_ndt_paths_and_init_rand_generator can be called
toolbox_basedir_name = 'Y:\Sources\ndt.1.0.4';
addpath(toolbox_basedir_name);
% Add the NDT paths using add_ndt_paths_and_init_rand_generator
add_ndt_paths_and_init_rand_generator;



% Select a prefix depending on the approach
if strcmp(given_approach, 'all_approach')
    training_givenListOfRequiredFiles_with_approach = ['all_' training_givenListOfRequiredFiles];
    test_givenListOfRequiredFiles_with_approach = ['all_' test_givenListOfRequiredFiles];
elseif strcmp(given_approach, 'overlap_approach')
    training_givenListOfRequiredFiles_with_approach = ['overlap_' training_givenListOfRequiredFiles];
    test_givenListOfRequiredFiles_with_approach = ['overlap_' test_givenListOfRequiredFiles];
end


% Selection of a list of files for specific values of given_approach and givenListOfRequiredFiles variables .
switch training_givenListOfRequiredFiles
    case {'firstBlockFiles', 'secondBlockFiles', 'thirdBlockFiles', 'fourthBlockFiles', 'fifthBlockFiles', 'sixthBlockFiles'}
        training_listOfRequiredFiles = list_of_required_files.(training_givenListOfRequiredFiles_with_approach);
    case {'allBlocksFiles', 'allBlocksFiles_AfterInjection', 'allBlocksFiles_BeforeInjection',...
            'overlapBlocksFiles', 'overlapBlocksFiles_AfterInjection', 'overlapBlocksFiles_BeforeInjection'...
            'overlapBlocksFiles_AfterInjection_3_4', 'overlapBlocksFiles_BeforeInjection_3_4'}
        training_listOfRequiredFiles = list_of_required_files.(training_givenListOfRequiredFiles);
    otherwise
        error(['Unknown list of required files for ' given_approach '.']);
end

switch test_givenListOfRequiredFiles
    case {'firstBlockFiles', 'secondBlockFiles', 'thirdBlockFiles', 'fourthBlockFiles', 'fifthBlockFiles', 'sixthBlockFiles'}
        test_listOfRequiredFiles = list_of_required_files.(test_givenListOfRequiredFiles_with_approach);
    case {'allBlocksFiles', 'allBlocksFiles_AfterInjection', 'allBlocksFiles_BeforeInjection',...
            'overlapBlocksFiles', 'overlapBlocksFiles_AfterInjection', 'overlapBlocksFiles_BeforeInjection'...
            'overlapBlocksFiles_AfterInjection_3_4', 'overlapBlocksFiles_BeforeInjection_3_4'}
        test_listOfRequiredFiles = list_of_required_files.(test_givenListOfRequiredFiles);
    otherwise
        error(['Unknown list of required files for ' given_approach '.']);
end


% Check if listOfRequiredFiles is empty
if isempty(training_listOfRequiredFiles) || isempty(test_listOfRequiredFiles)
    % If empty, complete the code and start the loop again for the next value of current_date
    return; % Exit the function without throwing an error
end


switch target_state
    case 6
        target_state_name = 'cueON';
    case 4
        target_state_name = 'GOsignal';
    otherwise
        %fprintf('Invalid target_state value: %d\n', target_state);
        % You might want to handle the case when target_state is neither 6 nor 4
end


switch target_brain_structure
    case 'dPul_L'
        target_brain_structure = 'dPul_L';
    case 'LIP_L'
        target_brain_structure = 'LIP_L';
    case 'LIP_R'
        target_brain_structure = 'LIP_R';
    otherwise
        if strcmp(injection, '0')
            target_brain_structure = 'LIP_L_dPul_L';
        elseif strcmp(injection, '1')
            target_brain_structure = 'LIP_L_LIP_R';
        else
            error('Invalid injection parameter. Use ''0'' or ''1'' for injection.');
        end
end


%     % Upload the necessary files: only cueON or only GOsignal
%     file_list = dir(fullfile(OUTPUT_PATH_raster, ['*' target_state_name '*.mat'])); %  Use dir to list all files in the directory
%     for f = 1:numel(file_list) % Loop through the files and load them
%         file_path = fullfile(OUTPUT_PATH_raster, file_list(f).name);
%         load(file_path);
%     end

all_target_brain_structure = {'dPul_L', 'LIP_L', 'LIP_R'};

switch target_brain_structure
    case 'dPul_L'
        search_target_brain_structure_among_raster_data = 'dPul_L';
    case 'LIP_L'
        search_target_brain_structure_among_raster_data = 'LIP_L';
    otherwise
        % Check if target_brain_structure is in all_brain_structures
        if any(strcmp(target_brain_structure, all_target_brain_structure))
            search_target_brain_structure_among_raster_data = target_brain_structure;
        else
            search_target_brain_structure_among_raster_data = [];
        end
end



% For training
training_targetBlock = extractBlockInformation(training_listOfRequiredFiles);
[training_targetBlockUsed, training_targetBlockUsed_among_raster_data] = processBlockInformation(training_targetBlock, list_of_required_files, training_givenListOfRequiredFiles, dateOfRecording);
training_block_grouping_folder = createBlockGroupingFolder(dateOfRecording, allDateOfRecording, training_givenListOfRequiredFiles, given_approach, list_of_required_files);

% For test
test_targetBlock = extractBlockInformation(test_listOfRequiredFiles);
[test_targetBlockUsed, test_targetBlockUsed_among_raster_data] = processBlockInformation(test_targetBlock, list_of_required_files, test_givenListOfRequiredFiles, dateOfRecording);
test_block_grouping_folder = createBlockGroupingFolder(dateOfRecording, allDateOfRecording, test_givenListOfRequiredFiles, given_approach, list_of_required_files);


grouping_folder = 'Cross_decoding';


% create prefix to save binned data
% (prefix will contain info about all blocks)
OUTPUT_PATH_binned_dateOfRecording = [OUTPUT_PATH_binned monkey_prefix dateOfRecording '/'];


% Create num_cv_splits_folder
num_cv_splits_folder = sprintf('num_cv_splits_%d(%d)', settings.num_cv_splits, settings.num_cv_splits * settings.num_times_to_repeat_each_label_per_cv_split);

num_cv_splits_approach = settings.num_cv_splits_approach_folder;

if isequal(dateOfRecording, 'merged_files_across_sessions')
additional_folder = 'two_group_combination/';
else 
    additional_folder = '';
end

Binned_data_dir = [OUTPUT_PATH_binned_dateOfRecording additional_folder grouping_folder '/' num_cv_splits_approach num_cv_splits_folder '/'];
training_save_prefix_name = [Binned_data_dir 'Binned_Sim_LIP_dPul__NDT_data_for_' target_brain_structure '_' target_state_name '_' training_targetBlockUsed];
test_save_prefix_name = [Binned_data_dir 'Binned_Sim_LIP_dPul__NDT_data_for_' target_brain_structure '_' target_state_name '_' test_targetBlockUsed];

if ~exist(Binned_data_dir,'dir')
    mkdir(Binned_data_dir);
end


%% creating folders for sorting files when running across all sessions.
% Call the function for each category

copyFilesAcrossSessions(dateOfRecording, allDateOfRecording, training_givenListOfRequiredFiles, training_givenListOfRequiredFiles_with_approach, training_block_grouping_folder, training_listOfRequiredFiles, list_of_required_files, OUTPUT_PATH_raster, monkey_prefix, given_approach);
copyFilesAcrossSessions(dateOfRecording, allDateOfRecording, test_givenListOfRequiredFiles, test_givenListOfRequiredFiles_with_approach, test_block_grouping_folder, test_listOfRequiredFiles, list_of_required_files, OUTPUT_PATH_raster, monkey_prefix, given_approach);



%% Combining blocks, creating a metablock if 'overlapBlocksFiles'
% for both: for singal session and all sessions (control and injection)

% Create meta_block_folder if block_grouping_folder meets the conditions

[training_meta_block_folder] = handleMetaBlocks(training_givenListOfRequiredFiles, list_of_required_files, dateOfRecording, training_block_grouping_folder, OUTPUT_PATH_raster, monkey_prefix, target_state_name, search_target_brain_structure_among_raster_data, target_brain_structure, training_listOfRequiredFiles);
[test_meta_block_folder] = handleMetaBlocks(test_givenListOfRequiredFiles, list_of_required_files, dateOfRecording, test_block_grouping_folder, OUTPUT_PATH_raster, monkey_prefix, target_state_name, search_target_brain_structure_among_raster_data, target_brain_structure, test_listOfRequiredFiles);


%%  Make Binned_data

% If no files are found for either 'LIP_L' or 'LIP_R', return to the beginning
if ~(any(contains(training_listOfRequiredFiles, search_target_brain_structure_among_raster_data)) || ...
        any(contains(test_listOfRequiredFiles, search_target_brain_structure_among_raster_data)))
    disp(['No files found for ' search_target_brain_structure_among_raster_data '. Returning to the beginning.']);
    return;
end


% Training
training_Raster_data_dir = getRasterDataDir(training_meta_block_folder, training_block_grouping_folder, OUTPUT_PATH_raster, monkey_prefix, dateOfRecording, training_block_grouping_folder);
training_raster_data_directory_name =  [training_Raster_data_dir  '*' search_target_brain_structure_among_raster_data '_trial_state_' target_state_name '_' training_targetBlockUsed_among_raster_data '*'];
training_binned_data_file_name = create_binned_data_from_raster_data(training_raster_data_directory_name, training_save_prefix_name, settings.bin_width, settings.step_size);
training_binned_data = load(training_binned_data_file_name);  % load the binned data
[~, training_filename_binned_data, ~] = fileparts(training_binned_data_file_name);



% Test
test_Raster_data_dir = getRasterDataDir(test_meta_block_folder, test_block_grouping_folder, OUTPUT_PATH_raster, monkey_prefix, dateOfRecording, test_block_grouping_folder);
test_raster_data_directory_name =  [test_Raster_data_dir  '*' search_target_brain_structure_among_raster_data '_trial_state_' target_state_name '_' test_targetBlockUsed_among_raster_data '*'];
test_binned_data_file_name = create_binned_data_from_raster_data(test_raster_data_directory_name, test_save_prefix_name, settings.bin_width, settings.step_size);
test_binned_data = load(test_binned_data_file_name);  % load the binned data
[~, test_filename_binned_data, ~] = fileparts(test_binned_data_file_name);



% smooth the data
[training_binned_data_smooth] = smooth_and_save_binned_data(training_binned_data_file_name, Binned_data_dir, settings); % For training
[test_binned_data_smooth] = smooth_and_save_binned_data(test_binned_data_file_name, Binned_data_dir, settings); % For test


%% Adding training and test data to one variable 

training_and_test_save_prefix_name = ['Binned_Sim_LIP_dPul__NDT_data_for_' target_brain_structure '_' target_state_name '_' given_labels_to_use '_train_' training_targetBlockUsed '_test_' test_targetBlockUsed '_smoothed.mat'];
[training_and_test_binned_labels] = merge_training_and_test_data(training_binned_data_smooth, test_binned_data_smooth, training_givenListOfRequiredFiles, test_givenListOfRequiredFiles, Binned_data_dir, training_and_test_save_prefix_name);


%% Prepearing for decoding

switch given_labels_to_use
    case 'instr_R_instr_L'
        labels_to_use = {'instr_R_training', 'instr_L_training', 'instr_R_test', 'instr_L_test'};
        labels_to_use_k = {'instr_R', 'instr_L'};
    case 'choice_R_choice_L'
        labels_to_use = {'choice_R_training', 'choice_L_training', 'choice_R_test', 'choice_L_test'};
        labels_to_use_k = {'choice_R', 'choice_L'};
%     case 'instr_R_choice_R'
%         labels_to_use = {'instr_R', 'choice_R'};
%     otherwise % 'instr_L_choice_L'
%         labels_to_use = {'instr_L', 'choice_L'};
end

% if all(ismember(given_training_labels_to_use, 'instr_R_instr_L')) && all(ismember(given_test_labels_to_use, 'choice_R_choice_L'))
%     the_training_label_names = {{'instr_R'}, {'instr_L'}}; % need cell array of cells because of the expected format for generalization_DS
%     the_test_label_names = {{'choice_R'}, {'choice_L'}};
%     string_to_add_to_filename = '_Train_instr_Test_choice';
% elseif all(ismember(given_training_labels_to_use, 'choice_R_choice_L')) && all(ismember(given_test_labels_to_use, 'instr_R_instr_L'))
%     the_training_label_names = {{'choice_R'}, {'choice_L'}}; % need cell array of cells because of the expected format for generalization_DS
%     the_test_label_names = {{'instr_R'}, {'instr_L'}};
%     string_to_add_to_filename = '_Train_choice_Test_instr';
% end


% Формируем новую строку, комбинируя элементы с нужными разделителями
parts = split(given_labels_to_use, '_');
labels_to_use_string = [parts{1} '_' parts{2} ' ' parts{3} '_' parts{4}];



% Determining how many times each condition was repeated
for k = 1:250
    inds_of_sites_with_at_least_k_repeats = find_sites_with_k_label_repetitions(test_binned_data.binned_labels.trial_type_side , k, labels_to_use_k);
    num_sites_with_k_repeats(k) = length(inds_of_sites_with_at_least_k_repeats);
    % number of columns - how many times the stimulus was presented (number of repetitions);
    % the value in each column - how many units has this number of repetitions
end


%% Create a file with information about the number of stimulus repetitions for N number of units

% Create a file with information about stimulus repetitions for training
[training_lines_output] = create_stimulus_repetition_file(Binned_data_dir, target_brain_structure, target_state_name, training_targetBlockUsed, given_labels_to_use, num_sites_with_k_repeats);

%  Create a file with information about stimulus repetitions for test
[test_lines_output] = create_stimulus_repetition_file(Binned_data_dir, target_brain_structure, target_state_name, test_targetBlockUsed, given_labels_to_use, num_sites_with_k_repeats);



%% Detection of possible number of num_cv_splits

% Automatic detection of the maximum possible number of num_cv_splits
% Determine the maximum number of units and repetitions

num_cv_splits_training = detect_num_cv_splits(num_cv_splits_approach, training_givenListOfRequiredFiles, training_lines_output, settings, training_block_grouping_folder, OUTPUT_PATH_binned_dateOfRecording, target_brain_structure, target_state_name, labels_to_use_string, dateOfRecording);
num_cv_splits_test = detect_num_cv_splits(num_cv_splits_approach, test_givenListOfRequiredFiles, test_lines_output, settings, test_block_grouping_folder, OUTPUT_PATH_binned_dateOfRecording, target_brain_structure, target_state_name, labels_to_use_string, dateOfRecording);

% Checking num_cv_splits equality for training and test
if isequal(num_cv_splits_approach, 'same_num_cv_splits/')
    if num_cv_splits_training == num_cv_splits_test
        num_cv_splits = num_cv_splits_test;
        disp('Training and test num_cv_splits are identical. Proceeding...');
    else       
        min_cv_splits = min(num_cv_splits_training, num_cv_splits_test);
        num_cv_splits = min_cv_splits;        
    end
end


% num_cv_splits = 6; % for Linus: Lin_20210709

%% moving binned files from the old folder to the new one if the num_cv_splits variable did not correspond to the specified settings.num_cv_splits
% Check if num_cv_splits is different from settings.num_cv_splits
if num_cv_splits ~= settings.num_cv_splits
    
    % Move files from unsuitable directory to new one to match new num_cv_splits_folder
    Binned_data_dir_old = [Binned_data_dir];
    old_dir = [Binned_data_dir_old];
    
    num_cv_splits_folder = sprintf('num_cv_splits_%d(%d)', num_cv_splits, num_cv_splits * settings.num_times_to_repeat_each_label_per_cv_split);
    Binned_data_dir = [OUTPUT_PATH_binned_dateOfRecording additional_folder grouping_folder '/' num_cv_splits_approach num_cv_splits_folder '/'];
    if ~exist(Binned_data_dir,'dir')
        mkdir(Binned_data_dir);
    end
    
    new_dir = fileparts(Binned_data_dir); % Get the parent directory of the new folder
    movefile([old_dir '/*'], new_dir);  % 'f' для перезаписи
    
    
    % Delete old unnecessary folder
    folder_name_to_delete = sprintf('num_cv_splits_%d(%d)', settings.num_cv_splits, settings.num_cv_splits * settings.num_times_to_repeat_each_label_per_cv_split);
    dir_to_delete = fullfile(OUTPUT_PATH_binned_dateOfRecording, additional_folder, grouping_folder, num_cv_splits_approach, folder_name_to_delete);
    if exist(dir_to_delete, 'dir') % Delete the directory
        rmdir(dir_to_delete, 's'); % 's' option deletes the directory and all its contents
    end
    
end



%%  Begin the decoding analysis
%  6.  Create a datasource object
specific_label_name_to_use = 'trial_type_side';
% num_cv_splits = settings.num_cv_splits; % 20 cross-validation runs


[the_training_label_names, the_test_label_names] = createLabelNames(given_labels_to_use);



% If the data is run across sessions, the data was not recorded at the simultaneously
%(by default, the data is recorded at the simultaneously in the sdndt_Sim_LIP_dPul_NDT_settings.m:
% settings.create_simultaneously_recorded_populations = 1;)
if isequal(dateOfRecording, 'merged_files_across_sessions')%&& ...
    settings.create_simultaneously_recorded_populations = 0; % data are not recorded simultaneously
elseif (isequal(typeOfDecoding, 'each_session_separately'))&& ...
        (isequal(training_givenListOfRequiredFiles, 'allBlocksFiles_AfterInjection') || isequal(test_givenListOfRequiredFiles, 'allBlocksFiles_AfterInjection'))
    settings.create_simultaneously_recorded_populations = 0;
end



% Create a datasource that takes our binned data, and specifies that we want to decode
ds = generalization_DS([new_dir '/' training_and_test_save_prefix_name], specific_label_name_to_use, num_cv_splits, the_training_label_names, the_test_label_names);

%ds = generalization_DS([Binned_data_dir filename_binned_data '_smoothed.mat'], specific_label_name_to_use, num_cv_splits, the_training_label_names, the_test_label_names);
%ds = basic_DS([Binned_data_dir filename_binned_data '_smoothed.mat'], specific_label_name_to_use, num_cv_splits);

% can have multiple repetitions of each label in each cross-validation split (which is a faster way to run the code that uses most of the data)
ds.num_times_to_repeat_each_label_per_cv_split = settings.num_times_to_repeat_each_label_per_cv_split;

% optionally can specify particular sites to use
% Take only sites with enough repetitions of each condition:
% for example, if num_cv_splits=20 and ds.num_times_to_repeat_each_label_per_cv_split=2 (20*2 = 40), take only the units of neurons that had 40 presentations of the stimulus:
%ds.sites_to_use = find_sites_with_k_label_repetitions(training_and_test_binned_labels.trial_type_side, num_cv_splits*ds.num_times_to_repeat_each_label_per_cv_split, labels_to_use); % shows how many units are taken for decoding (size, 2)
ds.sites_to_use = find_sites_with_k_label_repetitions(test_binned_data.binned_labels.trial_type_side, num_cv_splits*ds.num_times_to_repeat_each_label_per_cv_split, labels_to_use_k); % shows how many units are taken for decoding (size, 2)


% flag, which specifies that the data was recorded at the simultaneously
% create_simultaneously_recorded_populations = 1; % data are recorded simultaneously
% ds.create_simultaneously_recorded_populations = settings.create_simultaneously_recorded_populations;

% % can do the decoding on a subset of labels
% ds.label_names_to_use = labels_to_use; % {'instr_R', 'instr_L'} {'choice_R', 'choice_L'}

% Creating a feature-preprocessor (FP) object
% create a feature preprocessor that z-score normalizes each neuron
% note that the FP objects are stored in a cell array, which allows multiple FP objects to be used in one analysis
the_feature_preprocessors{1} = zscore_normalize_FP;

% other useful options:

% can include a feature-selection features preprocessor to only use the top k most selective neurons
% fp = select_or_exclude_top_k_features_FP;
% fp.num_features_to_use = 50;   % use only the 25 most selective neurons as determined by a univariate one-way ANOVA
% the_feature_preprocessors{2} = fp;
% string_to_add_to_filename = ['_top_ num2str(fp.num_features_to_use) '_units_'];



% Creating a classifier (CL) object
% create the CL object
the_classifier = max_correlation_coefficient_CL;
% the_classifier = libsvm_CL;
% the_classifier.multiclass_classificaion_scheme = 'one_vs_all';

% Creating a cross-validator (CV) object
% create the CV object
the_cross_validator = standard_resample_CV(ds, the_classifier, the_feature_preprocessors);

% Set how many times the outer 'resample' loop is run
the_cross_validator.num_resample_runs = settings.num_resample_runs;


% other useful options:

% can greatly speed up the run-time of the analysis by not creating a full TCT matrix (i.e., only trainging and testing the classifier on the same time bin)
the_cross_validator.test_only_at_training_times = 1;


% Running the decoding analysis and saving the results
DECODING_RESULTS = the_cross_validator.run_cv_decoding;




save_file_name = [Binned_data_dir training_and_test_save_prefix_name(1:end-4) '_DECODING_RESULTS.mat'];
save(save_file_name, 'DECODING_RESULTS');

% Save num_cv_splits to a .mat file
save_num_cv_splits_file = [Binned_data_dir 'num_cv_splits'  training_and_test_save_prefix_name(30:end-13) '.mat'];
save(save_num_cv_splits_file, 'num_cv_splits');




% Save unit_ID as a txt-file
% Define the prefix for the file name
prefix_for_file_with_units_IDs = ['units_IDs' training_and_test_save_prefix_name(30:end-13)];

% Define the file name
file_name = fullfile(Binned_data_dir, [prefix_for_file_with_units_IDs '.txt']);
fileID = fopen(file_name, 'w'); % Open the file for writing
fprintf(fileID, 'unit_ID:\n\n'); % Write header ‘unit_ID:’

for i = 1:numel(DECODING_RESULTS.DS_PARAMETERS.binned_site_info.unit_ID) % Write each unit_ID in a column
    fprintf(fileID, '%s\n', DECODING_RESULTS.DS_PARAMETERS.binned_site_info.unit_ID{i});
end
fprintf(fileID, '\nIn total: %d units\n', numel(DECODING_RESULTS.DS_PARAMETERS.binned_site_info.unit_ID));
fclose(fileID);





% Plot decoding
sdndt_Sim_LIP_dPul_NDT_plot_cross_decoding_results(monkey, injection, typeOfSessions, save_file_name, training_binned_data_smooth.binned_labels.block{1,1}, test_binned_data_smooth.binned_labels.block{1,1});
%end

end



%% Supporting functions




function targetBlock = extractBlockInformation(listOfRequiredFiles)
% Initialize cell array to hold block information
blockInformation = cell(1, numel(listOfRequiredFiles));

% Loop through the list of required files
for h = 1:numel(listOfRequiredFiles)
    parts = strsplit(listOfRequiredFiles{h}, '_'); % Split the file name into parts using underscores
    blockIndex = find(contains(parts, 'block'), 1, 'last'); % Find the index of the part containing 'block'
    
    if ~isempty(blockIndex) % Extract the block information
        blockInfo = strjoin(parts(blockIndex:end), '_');
        blockInformation{h} = blockInfo;
    else
        blockInformation{h} = 'No block information found';
    end
end

% Find unique block information and remove '.mat' extensions
uniqueBlockInformation = strrep(strjoin(unique(blockInformation)), '.mat', '');
targetBlock = uniqueBlockInformation; % Return the unique block information
end


function [targetBlockUsed, targetBlockUsed_among_raster_data] = processBlockInformation(targetBlock, list_of_required_files, givenListOfRequiredFiles, dateOfRecording)
all_targetBlock = {'block_1', 'block_2', 'block_3', 'block_4', 'block_5', 'block_6'};

% Defining the target block
if ismember(targetBlock, all_targetBlock)
    targetBlockUsed = targetBlock;
else
    blocks = strsplit(targetBlock, ' '); % Split the targetBlock string into individual blocks
    for i = 1:numel(blocks)
        blocks{i} = ['block_' strrep(blocks{i}, 'block_', '')]; % Add the 'block_' prefix to each block
    end
    targetBlockUsed = strjoin(blocks, '_'); % Concatenate the blocks with underscores
end

% Determining which block to use among raster  data
if ismember(targetBlock, all_targetBlock)
    targetBlockUsed_among_raster_data = targetBlock;
elseif (isfield(list_of_required_files, 'allBlocksFiles') && isequal(givenListOfRequiredFiles,'allBlocksFiles')) || ...
        ((isfield(list_of_required_files, 'overlapBlocksFiles') && strcmp(dateOfRecording, 'merged_files_across_sessions') && isequal(givenListOfRequiredFiles, 'overlapBlocksFiles')) || ...
        (isfield(list_of_required_files, 'overlapBlocksFiles_AfterInjection') && isequal(givenListOfRequiredFiles, 'overlapBlocksFiles_AfterInjection')) || ...
        (isfield(list_of_required_files, 'overlapBlocksFiles_AfterInjection_3_4') && isequal(givenListOfRequiredFiles, 'overlapBlocksFiles_AfterInjection_3_4')) || ...
        (isfield(list_of_required_files, 'allBlocksFiles_AfterInjection') && isequal(givenListOfRequiredFiles, 'allBlocksFiles_AfterInjection')))
    targetBlockUsed_among_raster_data = [];
else
    targetBlockUsed_among_raster_data = targetBlockUsed;
end
end

function block_grouping_folder = createBlockGroupingFolder(dateOfRecording, allDateOfRecording, givenListOfRequiredFiles, given_approach, list_of_required_files)
% Initialize block_grouping_folder
block_grouping_folder = '';

% Check if the date is 'merged_files_across_sessions'
if isequal(dateOfRecording, 'merged_files_across_sessions')
    % Define block file names
    block_file_names = {'firstBlockFiles', 'secondBlockFiles', 'thirdBlockFiles', 'fourthBlockFiles', 'fifthBlockFiles', 'sixthBlockFiles'};
    
    if any(strcmp(givenListOfRequiredFiles, block_file_names))
        % Determine the approach-based folder name
        if strcmp(given_approach, 'all_approach')
            approach_based_folder_name = 'all_FilesAcrossSessions_';
        elseif strcmp(given_approach, 'overlap_approach')
            approach_based_folder_name = 'overlap_FilesAcrossSessions_';
        else
            error('Unknown approach. Please use either ''all_approach'' or ''overlap_approach''.');
        end
        
        % Determine the block-based folder name
        switch givenListOfRequiredFiles
            case 'firstBlockFiles'
                block_based_folder_name = 'Block_1';
            case 'secondBlockFiles'
                block_based_folder_name = 'Block_2';
            case 'thirdBlockFiles'
                block_based_folder_name = 'Block_3';
            case 'fourthBlockFiles'
                block_based_folder_name = 'Block_4';
            case 'fifthBlockFiles'
                block_based_folder_name = 'Block_5';
            case 'sixthBlockFiles'
                block_based_folder_name = 'Block_6';
            otherwise
                error('Unknown list of required files.');
        end
        
        block_grouping_folder = [approach_based_folder_name block_based_folder_name '/'];
    end
    
    % Check for 'allBlocksFiles'-group files
    if isempty(block_grouping_folder)
        if isequal(givenListOfRequiredFiles, 'allBlocksFiles')
            block_grouping_folder = 'allBlocksFilesAcrossSessions/';
        elseif isequal(givenListOfRequiredFiles, 'allBlocksFiles_AfterInjection')
            block_grouping_folder = 'allBlocksFilesAcrossSessions_AfterInjection/';
        elseif isequal(givenListOfRequiredFiles, 'allBlocksFiles_BeforeInjection')
            block_grouping_folder = 'allBlocksFilesAcrossSessions_BeforeInjection/';
        elseif isequal(givenListOfRequiredFiles, 'overlapBlocksFiles')
            block_grouping_folder = 'overlapBlocksFilesAcrossSessions/';
        elseif isequal(givenListOfRequiredFiles, 'overlapBlocksFiles_AfterInjection')
            block_grouping_folder = 'overlapBlocksFilesAcrossSessions_AfterInjection/';
        elseif isequal(givenListOfRequiredFiles, 'overlapBlocksFiles_BeforeInjection')
            block_grouping_folder = 'overlapBlocksFilesAcrossSessions_BeforeInjection/';
        elseif isequal(givenListOfRequiredFiles, 'overlapBlocksFiles_AfterInjection_3_4')
            block_grouping_folder = 'overlapBlocksFilesAcrossSessions_AfterInjection_3_4/';
        elseif isequal(givenListOfRequiredFiles, 'overlapBlocksFiles_BeforeInjection_3_4')
            block_grouping_folder = 'overlapBlocksFilesAcrossSessions_BeforeInjection_3_4/';
        end
    end
    
    % Handle specific date recordings with specific files
elseif ismember(dateOfRecording, allDateOfRecording) && isfield(list_of_required_files, 'overlapBlocksFiles_BeforeInjection') && isequal(givenListOfRequiredFiles, 'overlapBlocksFiles_BeforeInjection')
    block_grouping_folder = 'Overlap_blocks_BeforeInjection/';
    
elseif ismember(dateOfRecording, allDateOfRecording) && isfield(list_of_required_files, 'overlapBlocksFiles_AfterInjection') && isequal(givenListOfRequiredFiles, 'overlapBlocksFiles_AfterInjection')
    block_grouping_folder = 'Overlap_blocks_AfterInjection/';
    
elseif ismember(dateOfRecording, allDateOfRecording) && isfield(list_of_required_files, 'overlapBlocksFiles_BeforeInjection_3_4') && isequal(givenListOfRequiredFiles, 'overlapBlocksFiles_BeforeInjection_3_4')
    block_grouping_folder = 'Overlap_blocks_BeforeInjection_3_4/';
    
elseif ismember(dateOfRecording, allDateOfRecording) && isfield(list_of_required_files, 'overlapBlocksFiles_AfterInjection_3_4') && isequal(givenListOfRequiredFiles, 'overlapBlocksFiles_AfterInjection_3_4')
    block_grouping_folder = 'Overlap_blocks_AfterInjection_3_4/';
    
elseif ismember(dateOfRecording, allDateOfRecording) && isfield(list_of_required_files, 'allBlocksFiles_BeforeInjection') && isequal(givenListOfRequiredFiles, 'allBlocksFiles_BeforeInjection')
    block_grouping_folder = 'All_blocks_BeforeInjection/';
    
elseif ismember(dateOfRecording, allDateOfRecording) && isfield(list_of_required_files, 'allBlocksFiles_AfterInjection') && isequal(givenListOfRequiredFiles, 'allBlocksFiles_AfterInjection')
    block_grouping_folder = 'All_blocks_AfterInjection/';
    
    % Handle cases when the date is not in allDateOfRecording
elseif ~isequal(dateOfRecording, allDateOfRecording)
    if isfield(list_of_required_files, 'overlapBlocksFiles') && isequal(givenListOfRequiredFiles, 'overlapBlocksFiles')
        block_grouping_folder = 'Overlap_blocks/';
    elseif isfield(list_of_required_files, 'allBlocksFiles') && isequal(givenListOfRequiredFiles, 'allBlocksFiles')
        block_grouping_folder = 'All_blocks/';
    elseif isequal(given_approach, 'overlap_approach')
        block_grouping_folder = 'Overlap_By_block/';
    elseif isequal(given_approach, 'all_approach')
        block_grouping_folder = 'All_By_block/';
    end
end
end

function copyFilesAcrossSessions(dateOfRecording, allDateOfRecording, givenListOfRequiredFiles, givenListOfRequiredFiles_with_approach, block_grouping_folder, listOfRequiredFiles, list_of_required_files, OUTPUT_PATH_raster, monkey_prefix, given_approach)
% Check if the recording date is 'merged_files_across_sessions'
if strcmp(dateOfRecording, 'merged_files_across_sessions')
    % Check for overlap or all blocks (before/after injection)
    if isequal(givenListOfRequiredFiles, 'overlapBlocksFiles_BeforeInjection') || ...
            isequal(givenListOfRequiredFiles, 'overlapBlocksFiles_AfterInjection') || ...
            isequal(givenListOfRequiredFiles, 'overlapBlocksFiles_BeforeInjection_3_4') || ...
            isequal(givenListOfRequiredFiles, 'overlapBlocksFiles_AfterInjection_3_4') || ...
            isequal(givenListOfRequiredFiles, 'allBlocksFiles_BeforeInjection') || ...
            isequal(givenListOfRequiredFiles, 'allBlocksFiles_AfterInjection')
        
        copyFilesForCategory(givenListOfRequiredFiles, [OUTPUT_PATH_raster monkey_prefix dateOfRecording '/' block_grouping_folder], listOfRequiredFiles, list_of_required_files);
        
        % Check for individual block files (first, second, etc.)
    elseif isequal(givenListOfRequiredFiles, 'firstBlockFiles') || ...
            isequal(givenListOfRequiredFiles, 'secondBlockFiles') || ...
            isequal(givenListOfRequiredFiles, 'thirdBlockFiles') || ...
            isequal(givenListOfRequiredFiles, 'fourthBlockFiles') || ...
            isequal(givenListOfRequiredFiles, 'fifthBlockFiles') || ...
            isequal(givenListOfRequiredFiles, 'sixthBlockFiles')
        
        copyFilesForCategory(givenListOfRequiredFiles_with_approach, [OUTPUT_PATH_raster monkey_prefix dateOfRecording '/' block_grouping_folder], listOfRequiredFiles, list_of_required_files);
    end
    
    % Check if the recording date is in the list of all recordings
elseif ismember(dateOfRecording, allDateOfRecording)
    % Handle overlap or all blocks (before/after injection)
    if isequal(givenListOfRequiredFiles, 'overlapBlocksFiles_AfterInjection') || ...
            isequal(givenListOfRequiredFiles, 'overlapBlocksFiles_BeforeInjection') || ...
            isequal(givenListOfRequiredFiles, 'overlapBlocksFiles_AfterInjection_3_4') || ...
            isequal(givenListOfRequiredFiles, 'overlapBlocksFiles_BeforeInjection_3_4') || ...
            isequal(givenListOfRequiredFiles, 'allBlocksFiles_AfterInjection') || ...
            isequal(givenListOfRequiredFiles, 'allBlocksFiles_BeforeInjection')
        
        copyFilesForCategory(givenListOfRequiredFiles, [OUTPUT_PATH_raster monkey_prefix dateOfRecording '/' block_grouping_folder], listOfRequiredFiles, list_of_required_files);
        
        % Handle approach-specific cases for block files
    elseif strcmp(given_approach, 'overlap_approach') && ...
            (isequal(givenListOfRequiredFiles, 'firstBlockFiles') || ...
            isequal(givenListOfRequiredFiles, 'secondBlockFiles') || ...
            isequal(givenListOfRequiredFiles, 'thirdBlockFiles') || ...
            isequal(givenListOfRequiredFiles, 'fourthBlockFiles') || ...
            isequal(givenListOfRequiredFiles, 'fifthBlockFiles') || ...
            isequal(givenListOfRequiredFiles, 'sixthBlockFiles'))
        
        copyFilesForCategory(givenListOfRequiredFiles_with_approach, [OUTPUT_PATH_raster monkey_prefix dateOfRecording '/' block_grouping_folder], listOfRequiredFiles, list_of_required_files);
    end
end
end


function copyFilesForCategory(categoryName, destinationFolder, listOfRequiredFiles, list_of_required_files)
if isfield(list_of_required_files, categoryName) && isequal(listOfRequiredFiles, list_of_required_files.(categoryName))
    % Create the destination folder if it doesn't exist
    if ~exist(destinationFolder, 'dir')
        mkdir(destinationFolder);
    end
    
    % Copy files
    for h = 1:numel(listOfRequiredFiles)
        currentFilePath = listOfRequiredFiles{h}; % Get the current file path
        [~, currentFileName, currentFileExt] = fileparts(currentFilePath); % Generate the destination path by replacing the initial part of the path
        destinationPath = fullfile(destinationFolder, [currentFileName currentFileExt]);
        copyfile(currentFilePath, destinationPath); % Copy the file to the destination folder
    end
end
end



function [meta_block_folder] = handleMetaBlocks(givenListOfRequiredFiles, list_of_required_files, dateOfRecording, block_grouping_folder, OUTPUT_PATH_raster, monkey_prefix, target_state_name, search_target_brain_structure_among_raster_data, target_brain_structure, listOfRequiredFiles)
% Initialize meta_block_folder as an empty string
meta_block_folder = '';

% Check if block_grouping_folder is a meta-block (e.g. overlapBlocksFiles)
if isequal(block_grouping_folder, 'overlapBlocksFilesAcrossSessions/') || ...
        isequal(block_grouping_folder, 'overlapBlocksFilesAcrossSessions_AfterInjection/') || ...
        isequal(block_grouping_folder, 'overlapBlocksFilesAcrossSessions_AfterInjection_3_4/')
    
    % Forming paths
    OUTPUT_PATH_raster_dateOfRecording = [OUTPUT_PATH_raster monkey_prefix dateOfRecording '/'];
    OUTPUT_PATH_raster_dateOfRecording_Overlap_blocks = [OUTPUT_PATH_raster_dateOfRecording block_grouping_folder];
    
    % Create a folder for metablocks
    meta_block_folder = [OUTPUT_PATH_raster_dateOfRecording_Overlap_blocks, 'metaFiles/'];
    if ~exist(meta_block_folder, 'dir')
        mkdir(meta_block_folder);
    end
    
elseif isequal(block_grouping_folder, 'Overlap_blocks_AfterInjection/') || ...
        isequal(block_grouping_folder, 'Overlap_blocks_AfterInjection_3_4/')
    
    %  Forming paths
    OUTPUT_PATH_raster_dateOfRecording = [OUTPUT_PATH_raster monkey_prefix dateOfRecording '/'];
    OUTPUT_PATH_raster_dateOfRecording_Overlap_blocks = [OUTPUT_PATH_raster_dateOfRecording block_grouping_folder];
    
    % Create a folder for metablocks
    meta_block_folder = [OUTPUT_PATH_raster_dateOfRecording_Overlap_blocks, 'metaFiles/'];
    if ~exist(meta_block_folder, 'dir')
        mkdir(meta_block_folder);
    end
else
    % If there are no conditions to create metablocks, we just form a path
    OUTPUT_PATH_raster_dateOfRecording = [OUTPUT_PATH_raster monkey_prefix dateOfRecording '/'];
    OUTPUT_PATH_raster_dateOfRecording_Overlap_blocks = [OUTPUT_PATH_raster_dateOfRecording block_grouping_folder];
end

% Combining files into meta-blocks
if (isfield(list_of_required_files, 'overlapBlocksFiles') && isequal(givenListOfRequiredFiles, 'overlapBlocksFiles')) || ...
        (isfield(list_of_required_files, 'overlapBlocksFiles_AfterInjection') && isequal(givenListOfRequiredFiles, 'overlapBlocksFiles_AfterInjection')) || ...
        (isfield(list_of_required_files, 'overlapBlocksFiles_AfterInjection_3_4') && isequal(givenListOfRequiredFiles, 'overlapBlocksFiles_AfterInjection_3_4'))
    
    % Call the function to merge files into blocks
    mergeFilesInBlockGroup(listOfRequiredFiles, target_state_name, search_target_brain_structure_among_raster_data, target_brain_structure, OUTPUT_PATH_raster_dateOfRecording_Overlap_blocks, meta_block_folder);
end
end



function mergeFilesInBlockGroup(listOfRequiredFiles, target_state_name, search_target_brain_structure_among_raster_data, target_brain_structure, OUTPUT_PATH_raster_dateOfRecording_Overlap_blocks, meta_block_folder)

% Extract unique prefixes from the filenames
% if (isfield(list_of_required_files, 'overlapBlocksFiles') && isequal(listOfRequiredFiles, list_of_required_files.overlapBlocksFiles)) || ...
%         (isfield(list_of_required_files, 'overlapBlocksFiles_AfterInjection') && isequal(listOfRequiredFiles, list_of_required_files.overlapBlocksFiles_AfterInjection))

unique_prefixes = {};
for idx = 1:length(listOfRequiredFiles)
    current_file_parts = strsplit(listOfRequiredFiles{idx}, '_');
    current_prefix = strjoin(current_file_parts(1:10), '_');
    
    % Check if the current_prefix is not already in unique_prefixes
    if ~any(strcmp(unique_prefixes, current_prefix))
        unique_prefixes{end+1} = current_prefix;
    end
end

for prefix_idx = 1:length(unique_prefixes)
    current_prefix = unique_prefixes{prefix_idx};
    
    % Filter files based on the target_brain_structure, target_state, and listOfRequiredFiles
    current_group_files = listOfRequiredFiles(startsWith(listOfRequiredFiles, current_prefix) ...
        & contains(listOfRequiredFiles, target_state_name));
    
    if ~isempty(search_target_brain_structure_among_raster_data)
        % Filter files based on the target_brain_structure
        current_group_files = current_group_files(contains(current_group_files, search_target_brain_structure_among_raster_data));
    end
    
    % Ensure that only files with the correct target_brain_structure are included
    current_group_files = current_group_files(contains(current_group_files, ['_' target_brain_structure '_']));
    
    % Check if any files are present in the current group before proceeding
    if ~isempty(current_group_files)
        % Initialize cell arrays to store data from each file
        extracted_raster_data = cell(length(current_group_files), 1);
        extracted_raster_labels = cell(length(current_group_files), 1);
        extracted_raster_site_info = cell(length(current_group_files), 1);
        
        % Loop through each file in the list
        for c = 1:length(current_group_files)
            % Get the current file from the list
            current_file = current_group_files{c};
            
            % Load the data from the current file
            data = load(current_file);
            
            % Extract variables from the loaded data
            extracted_raster_data{c} = data.raster_data;
            extracted_raster_labels{c} = data.raster_labels;
            extracted_raster_site_info{c} = data.raster_site_info;
        end
        
        % Check if files can be merged based on relevant parts of the filenames
        can_be_merged = true(length(current_group_files), 1);
        reference_parts = strsplit(current_group_files{1}, '_');
        
        for p = 2:length(current_group_files)
            current_parts = strsplit(current_group_files{p}, '_');
            can_be_merged(p) = isequal(reference_parts(1:9), current_parts(1:9));
        end
        
        % Filter out files that cannot be merged
        extracted_raster_data = extracted_raster_data(can_be_merged);
        extracted_raster_labels = extracted_raster_labels(can_be_merged);
        extracted_raster_site_info = extracted_raster_site_info(can_be_merged);
        
        % Proceed with merging only if there are files that can be merged
        if any(can_be_merged)
            % Concatenate raster_data using vertcat
            raster_data = vertcat(extracted_raster_data{:});
            
            % Concatenate raster_labels fields separately
            raster_labels = struct(); % Initialize an empty struct for raster_labels
            fields_to_concatenate = {'trial_type', 'sideSelected', 'trial_type_side', 'stimulus_position_X_coordinate', 'stimulus_position_Y_coordinate', 'perturbation', 'block', 'run'};
            
            for field = fields_to_concatenate
                field_name = char(field);
                % Extract the values for the current field from each cell in the cell array
                field_values = cellfun(@(x) x.(field_name), extracted_raster_labels, 'UniformOutput', false);
                % Concatenate the values into a single array and assign to the struct
                raster_labels.(field_name) = [field_values{:}];
            end
            
            % Use the raster_site_info from the first file since they are assumed to be the same
            raster_site_info = extracted_raster_site_info{1};
            
            % Create a new filename for the merged file (using the first file's name)
            [~, base_name, ~] = fileparts(current_group_files{1});
            
            % Extract block numbers from filenames
            % Initialize cell array to store block numbers
            block_numbers = {};
            
            % Iterate through each filename in the current_group_files cell array
            for idx = 1:length(current_group_files)
                % Get the current filename
                filename = current_group_files{idx};
                
                % Extract the block number using the extractBlockNumber function
                block_number = extractBlockNumber(filename);
                
                % Append the extracted block number to the block_numbers cell array
                if ~isempty(block_number)
                    block_numbers{end+1} = block_number;
                end
            end
            
            % Remove duplicate block numbers and sort
            block_numbers = unique(block_numbers);
            
            % Construct the merged filename with block numbers
            if isempty(meta_block_folder)
                % If meta_block_folder is empty, use OUTPUT_PATH_raster_dateOfRecording_Overlap_blocks
                merged_filename = fullfile(OUTPUT_PATH_raster_dateOfRecording_Overlap_blocks, [regexprep(base_name, '_block_\d+', '') '_' strjoin(block_numbers, '_') '.mat']);
            else
                % Otherwise, use meta_block_folder
                merged_filename = fullfile(meta_block_folder, [regexprep(base_name, '_block_\d+', '') '_' strjoin(block_numbers, '_') '.mat']);
            end
            
            % Save the merged data to a new file
            save(merged_filename, 'raster_data', 'raster_labels', 'raster_site_info');
        end
    end
end
% else
%     disp('The cell arrays are not equal.');
% end  % if (isfield(list_of_required_files, 'overlapBlocksFiles')
%
end


function Raster_data_dir = getRasterDataDir(meta_block_folder, block_grouping_folder, OUTPUT_PATH_raster, monkey_prefix, dateOfRecording, block_grouping_folder_specific)
% Если meta_block_folder пустая, то используем пути в зависимости от block_grouping_folder
if isempty(meta_block_folder)
    if strcmp(block_grouping_folder, 'All_By_block/')
        % Если block_grouping_folder 'All_By_block/', то путь не зависит от block_grouping_folder_specific
        Raster_data_dir = [OUTPUT_PATH_raster, monkey_prefix, dateOfRecording '/'];
    else
        % Если блок не 'All_By_block/', то добавляем block_grouping_folder_specific
        Raster_data_dir = [OUTPUT_PATH_raster, monkey_prefix, dateOfRecording '/' block_grouping_folder_specific];
    end
else
    % Если meta_block_folder не пустая, то используем её как путь
    Raster_data_dir = meta_block_folder;
end
end



function block_number = extractBlockNumber(filename)
[~, filename, ~] = fileparts(filename);
parts = strsplit(filename, '_');
% Find the part containing the block number
block_idx = find(contains(parts, 'block'));
if ~isempty(block_idx)
    block_number = strjoin(parts(block_idx:end), '_');
else
    block_number = ''; % Handle case where block number is not found
end
end


function [num_cv_splits] = find_num_cv_splits(folder_where_search_CV_file, target_brain_structure, target_state_name, labels_to_use_string, dateOfRecording)

% List the contents of the All_blocks_BeforeInjection folder
cvSplitsFolders = dir(folder_where_search_CV_file);

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
data_for_plotting_averages.decodingResultsFilePath = '';
session_num_cv_splits_Info = '';

% Initialize a flag to check if the file is found
fileFound = false;

for idx = sorted_idx
    cvSplitFolderName = cvSplitsFolders(idx).name;
    cvSplitFolderPath = fullfile(folder_where_search_CV_file, cvSplitFolderName);
    
    % List the contents of the current folder
    decodingResultsFiles = dir(fullfile(cvSplitFolderPath, 'num_cv_splits_for_*.mat'));
    
    % Check if the required file exists in this folder
    for fileIndex = 1:numel(decodingResultsFiles)
        data_for_plotting_averages.decodingResultsFilename = decodingResultsFiles(fileIndex).name;
        
        % Check if the file name contains the desired target structure, state, and label
        if contains(data_for_plotting_averages.decodingResultsFilename, target_brain_structure) && ...
                contains(data_for_plotting_averages.decodingResultsFilename, target_state_name) && ...
                contains(data_for_plotting_averages.decodingResultsFilename, labels_to_use_string) %&& ...
            %contains(data_for_plotting_averages.decodingResultsFilename, num_block)
            
            
            data_for_plotting_averages.decodingResultsFilePath = fullfile(cvSplitFolderPath, data_for_plotting_averages.decodingResultsFilename);
            
            % Now you have the path to the suitable DECODING_RESULTS.mat file
            % You can process or load this file as needed
            fileFound = true;  % Set flag to true
            
            % Extract data about session and num_cv_splits
            num_cv_splits = str2double(extractBetween(cvSplitFolderName, 'num_cv_splits_', '('));
            
            break; % Exit the loop once the file is found
        end
    end
    
    
    if fileFound
        break; % Exit the loop if the file is found
    end
end



% If no file was found in any folder, display error message
if isempty(data_for_plotting_averages.decodingResultsFilePath)
    
    data_for_plotting_averages.session_info = [];
    
    % disp('ERROR: No suitable decoding results file found.');
    disp(['No suitable decoding results file found for session: ', dateOfRecording]);
    %continue; % Move to the next iteration of the loop
    
else
    
    % Load the file
    loaded_num_cv_splits = load(data_for_plotting_averages.decodingResultsFilePath);
    num_cv_splits = loaded_num_cv_splits.num_cv_splits;
    
end

end


function [smooth_binned_data] = smooth_and_save_binned_data(binned_data_file_name, Binned_data_dir, settings)
% Loading data from a file
load(binned_data_file_name, 'binned_data', 'binned_labels', 'binned_site_info');

% Smoothing the data
binned_data = arrayfun(@(x) smoothdata(binned_data{x}, 2, settings.smoothing_method, settings.smoothing_window), 1:length(binned_data), 'UniformOutput', false);

% Extract file name without path and extension
[~, filename_binned_data, ~] = fileparts(binned_data_file_name);


% Saving smoothed data to a new file
smooth_binned_data_file_name = [Binned_data_dir filename_binned_data '_smoothed.mat'];
save(smooth_binned_data_file_name, 'binned_data', 'binned_labels', 'binned_site_info');

% Loading a newly saved file
smooth_binned_data = load(smooth_binned_data_file_name, 'binned_data', 'binned_labels', 'binned_site_info');

end


function [lines_output] = create_stimulus_repetition_file(Binned_data_dir, target_brain_structure, target_state_name, targetBlockUsed, labels_to_use_string, num_sites_with_k_repeats)
% Create a prefix for the file name
prefix_for_file_with_num_sites_with_k_repeats = ['num_sites_with_k_repeats_for_' target_brain_structure '_' target_state_name '_' targetBlockUsed '_' labels_to_use_string];

% Determine the full file name
file_name = fullfile(Binned_data_dir, [prefix_for_file_with_num_sites_with_k_repeats '.txt']);
fileID = fopen(file_name, 'w');  % Open the file for writing

% Initialise the array for storing strings
lines_output = {};

% Going through each group of units
for group = unique(num_sites_with_k_repeats)
    last_occurrence = find(num_sites_with_k_repeats == group, 1, 'last'); % Find the last occurrence of the group
    if ~isempty(last_occurrence) % Check that the occurrence is not empty
        % Add the string with information to the array
        lines_output{end+1} = sprintf('%d units has %d repetitions of the stimuli', group, last_occurrence);
    end
end

lines_output = flip(lines_output);  % Reverse the row order

% Write lines to file
for i = 1:numel(lines_output)
    fprintf(fileID, '%s\n', lines_output{i});
end

fclose(fileID);  % Close the file
end


function num_cv_splits = detect_num_cv_splits(num_cv_splits_approach, givenListOfRequiredFiles, lines_output, settings, block_grouping_folder, OUTPUT_PATH_binned_dateOfRecording, target_brain_structure, target_state_name, labels_to_use_string, dateOfRecording)

% Initialize num_cv_splits as empty
num_cv_splits = [];

%% Detection of possible number of num_cv_splits

% Check if 'same_num_cv_splits/' and given list is before injection
if isequal(num_cv_splits_approach, 'same_num_cv_splits/') && ...
        (isequal(givenListOfRequiredFiles, 'overlapBlocksFiles_BeforeInjection') || isequal(givenListOfRequiredFiles, 'overlapBlocksFiles_BeforeInjection_3_4'))
    
    % Use lines_output passed into the function
    data_from_text_document = [];
    for i = 1:numel(lines_output)
        line_parts = split(lines_output{i}, {' units has ', ' repetitions of the stimuli'});
        data_from_text_document = [data_from_text_document; str2double(line_parts{1}), str2double(line_parts{2})];
    end
    
    % Extract number of units and repetitions
    num_units = data_from_text_document(:, 1);
    num_repetitions = data_from_text_document(:, 2);
    
    % Filter out rows where the number of repetitions is less than required
    valid_indices = num_repetitions >= 4 * settings.num_times_to_repeat_each_label_per_cv_split;
    num_units = num_units(valid_indices);
    num_repetitions = num_repetitions(valid_indices);
    
    % Check if all units are zeros
    if all(num_units == 0)
        return;
    end
    
    % Determine the maximum number of units and repetitions
    max_units = max(num_units);
    max_repetitions_index = find(num_units == max_units, 1);
    max_repetitions = num_repetitions(max_repetitions_index);
    
    % Calculate the maximum possible num_cv_splits
    max_cv_splits = max_repetitions / settings.num_times_to_repeat_each_label_per_cv_split;
    
    % Ensure num_cv_splits is an even number and less than 16
    num_cv_splits = min(floor(max_cv_splits), 16);
    
    % Make sure num_cv_splits is even
    if mod(num_cv_splits, 2) ~= 0
        num_cv_splits = num_cv_splits - 1;
    end
    
    % Check if num_cv_splits is less than 4
    if num_cv_splits < 4
        return;
    end
    
    % Check if 'same_num_cv_splits/' and given list is after injection
elseif isequal(num_cv_splits_approach, 'same_num_cv_splits/') && ...
        (isequal(givenListOfRequiredFiles, 'overlapBlocksFiles_AfterInjection') || isequal(givenListOfRequiredFiles, 'overlapBlocksFiles_AfterInjection_3_4'))
    
    % Modify block_grouping_folder
    block_grouping_folder_Before = strrep(block_grouping_folder, 'After', 'Before');
    
    % Search for CV files
    folder_where_search_CV_file = [OUTPUT_PATH_binned_dateOfRecording block_grouping_folder_Before num_cv_splits_approach];
    [num_cv_splits] = find_num_cv_splits(folder_where_search_CV_file, target_brain_structure, target_state_name, labels_to_use_string, dateOfRecording);
end
end


function [binned_labels] = merge_training_and_test_data(training_binned_data_smooth, test_binned_data_smooth, training_givenListOfRequiredFiles, test_givenListOfRequiredFiles, Binned_data_dir, save_prefix_name)

% Get the number of cells in binned_data
num_cells = length(training_binned_data_smooth.binned_data);

% Initialisation of the merged variables
binned_data = cell(1, num_cells);
binned_labels.trial_type = cell(1, num_cells);
binned_labels.sideSelected = cell(1, num_cells);
binned_labels.trial_type_side = cell(1, num_cells);
binned_labels.perturbation = cell(1, num_cells);
binned_labels.block = cell(1, num_cells);
binned_labels.run = cell(1, num_cells);

binned_site_info.recording_channel = [];
binned_site_info.session_ID = cell(1, num_cells);
binned_site_info.unit_ID = cell(1, num_cells);
binned_site_info.block_unit = cell(1, num_cells);
binned_site_info.perturbation_site = cell(1, num_cells);
binned_site_info.SNR_rating = [];
binned_site_info.Single_rating = []; 
binned_site_info.stability_rating = []; 
binned_site_info.site_ID = cell(1, num_cells);
binned_site_info.target  = cell(1, num_cells);
binned_site_info.grid_x = [];
binned_site_info.grid_y = [];
binned_site_info.electrode_depth = [];
binned_site_info.binning_parameters.raster_file_directory_name = [];
binned_site_info.binning_parameters.bin_width = [];
binned_site_info.binning_parameters.sampling_interval = [];
binned_site_info.binning_parameters.start_time = [];
binned_site_info.binning_parameters.end_time = [];
binned_site_info.binning_parameters.the_bin_start_times = [];
binned_site_info.binning_parameters.the_bin_widths = [];

% Go through each cell and combine the data
for num_units = 1:num_cells
    % Concatenation of training and test data by row (by trails)
    binned_data{num_units} = [training_binned_data_smooth.binned_data{num_units}; test_binned_data_smooth.binned_data{num_units}];
    
    % Add suffixes for trial_type
    training_labels_trial_type = strcat(training_binned_data_smooth.binned_labels.trial_type{num_units}, '_training');
    test_labels_trial_type = strcat(test_binned_data_smooth.binned_labels.trial_type{num_units}, '_test');
    binned_labels.trial_type{num_units} = [training_labels_trial_type, test_labels_trial_type];
    
    % Add suffixes for sideSelected
    training_labels_sideSelected = strcat(training_binned_data_smooth.binned_labels.sideSelected{num_units}, '_training');
    test_labels_sideSelected = strcat(test_binned_data_smooth.binned_labels.sideSelected{num_units}, '_test');
    binned_labels.sideSelected{num_units} = [training_labels_sideSelected, test_labels_sideSelected];
    
    % Add suffixes for trial_type_side
    training_labels_trial_type_side = strcat(training_binned_data_smooth.binned_labels.trial_type_side{num_units}, '_training');
    test_labels_trial_type_side = strcat(test_binned_data_smooth.binned_labels.trial_type_side{num_units}, '_test');
    binned_labels.trial_type_side{num_units} = [training_labels_trial_type_side, test_labels_trial_type_side];
    
    % Merge the other labels
    binned_labels.perturbation{num_units} = [training_binned_data_smooth.binned_labels.perturbation{num_units}, test_binned_data_smooth.binned_labels.perturbation{num_units}];
    binned_labels.block{num_units} = [training_binned_data_smooth.binned_labels.block{num_units}, test_binned_data_smooth.binned_labels.block{num_units}];
    binned_labels.run{num_units} = [training_binned_data_smooth.binned_labels.run{num_units}, test_binned_data_smooth.binned_labels.run{num_units}];
end

% Check for 'overlap' in file names
if contains(training_givenListOfRequiredFiles, 'overlap') && contains(test_givenListOfRequiredFiles, 'overlap')
    % If the names contain 'overlap', copy the values of the recording_channel
    binned_site_info.recording_channel = training_binned_data_smooth.binned_site_info.recording_channel;
end

% Check the identity between training and test data
for num_units = 1:num_cells
    if isequal(training_binned_data_smooth.binned_site_info.session_ID{num_units}, test_binned_data_smooth.binned_site_info.session_ID{num_units})
        % If match, add to the final structure
        binned_site_info.session_ID{num_units} = training_binned_data_smooth.binned_site_info.session_ID{num_units};
        binned_site_info.unit_ID{num_units} = training_binned_data_smooth.binned_site_info.unit_ID{num_units};
        binned_site_info.block_unit{num_units} = training_binned_data_smooth.binned_site_info.block_unit{num_units};
        binned_site_info.perturbation_site{num_units} = training_binned_data_smooth.binned_site_info.perturbation_site{num_units};
        binned_site_info.site_ID{num_units} = training_binned_data_smooth.binned_site_info.site_ID{num_units};
    end
end

% Check the identity 
if isequal(training_binned_data_smooth.binned_site_info.SNR_rating, test_binned_data_smooth.binned_site_info.SNR_rating)
    % If values are the same, add them
    binned_site_info.SNR_rating = training_binned_data_smooth.binned_site_info.SNR_rating;
    binned_site_info.Single_rating  = training_binned_data_smooth.binned_site_info.Single_rating;
    binned_site_info.stability_rating  = training_binned_data_smooth.binned_site_info.stability_rating;
    binned_site_info.target = training_binned_data_smooth.binned_site_info.target;
    binned_site_info.grid_x = training_binned_data_smooth.binned_site_info.grid_x;
    binned_site_info.grid_y = training_binned_data_smooth.binned_site_info.grid_y;
    binned_site_info.electrode_depth = training_binned_data_smooth.binned_site_info.electrode_depth;
    binned_site_info.binning_parameters.raster_file_directory_name = training_binned_data_smooth.binned_site_info.binning_parameters.raster_file_directory_name;
    binned_site_info.binning_parameters.bin_width = training_binned_data_smooth.binned_site_info.binning_parameters.bin_width;
    binned_site_info.binning_parameters.sampling_interval = training_binned_data_smooth.binned_site_info.binning_parameters.sampling_interval;
    binned_site_info.binning_parameters.start_time = training_binned_data_smooth.binned_site_info.binning_parameters.start_time;
    binned_site_info.binning_parameters.end_time = training_binned_data_smooth.binned_site_info.binning_parameters.end_time;
    binned_site_info.binning_parameters.the_bin_start_times = training_binned_data_smooth.binned_site_info.binning_parameters.the_bin_start_times;
    binned_site_info.binning_parameters.the_bin_widths = training_binned_data_smooth.binned_site_info.binning_parameters.the_bin_widths;
end

% Save the merged data
save([Binned_data_dir  save_prefix_name], 'binned_data', 'binned_labels', 'binned_site_info');

end



function [the_training_label_names, the_test_label_names] = createLabelNames(given_labels_to_use)
    % Split the string by the ‘_’ character
    parts = split(given_labels_to_use, '_');

    % Assign values to variables
    label1 = parts{1} + "_" + parts{2};  % 'instr_R' or 'choice_R'
    label2 = parts{3} + "_" + parts{4};  % 'instr_L' or 'choice_L'

    % Create variables for ‘_training’ and ‘_test’
    the_training_label_names = cell(1, 2);
    the_test_label_names = cell(1, 2);

    the_training_label_names{1} = {char(label1 + '_training')};  % Create a cell with a cell inside
    the_training_label_names{2} = {char(label2 + '_training')}; 

    the_test_label_names{1} = {char(label1 + '_test')};          
    the_test_label_names{2} = {char(label2 + '_test')};          

end
