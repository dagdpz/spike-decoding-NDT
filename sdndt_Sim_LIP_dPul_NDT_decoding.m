function sdndt_Sim_LIP_dPul_NDT_decoding(monkey, injection, typeOfDecoding)

% The code converts the received raster data into binned data and then performs decoding.

% HOW TO CALL THE FUNCTION?
% If we decode within a session:
% sdndt_Sim_LIP_dPul_NDT_decoding('Bacchus', '0', 'each_session_separately');

% If we decode across sessions:
% sdndt_Sim_LIP_dPul_NDT_decoding('Bacchus', '0', 'merged_files_across_sessions');




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
listOfRequiredFiles = {%'firstBlockFiles', 'secondBlockFiles', ...
    %     'thirdBlockFiles', 'fourthBlockFiles', ...
    %     'fifthBlockFiles', 'sixthBlockFiles', ...
     %  'overlapBlocksFiles_BeforeInjection',         
     'overlapBlocksFiles_AfterInjection' %, ...
   %  'overlapBlocksFiles_BeforeInjection_3_4',  'overlapBlocksFiles_AfterInjection_3_4'%, ...
    %     'allBlocksFiles_BeforeInjection', 'allBlocksFiles_AfterInjection'
    };  %'allBlocksFiles', 'overlapBlocksFiles', ...

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
targetParams.cueON = 6;
targetParams.GOSignal = 4;

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
numFiles = numel(listOfRequiredFiles); % Add this line to get the number of files

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
                    
                    %                     % Check if decoding should be performed for each session separately
                    %                     if strcmp(typeOfDecoding, 'each_session_separately')
                    %                         datesForSessions = {}; % Initialize datesForSessions as an empty cell array
                    %                         if strcmp(injection, '1')
                    %                             for type = 1:numel(typeOfSessions)
                    %                                 % Get the dates for the corresponding injection and session types
                    %                                 datesForSessions{end+1} = filelist_of_days_from_Simultaneous_dPul_PPC_recordings(monkey, injection, typeOfSessions{type});
                    %                             end
                    %                         elseif  strcmp(injection, '0') || strcmp(injection, '2')
                    %                             datesForSessions = filelist_of_days_from_Simultaneous_dPul_PPC_recordings(monkey, injection, typeOfSessions);
                    %                         end
                    %                     else % strcmp(typeOfDecoding, 'merged_files_across_sessions')
                    %                         datesForSessions = {''}; % Set a default value if decoding across sessions
                    %                     end
                    
                    
                    
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
                                    sdndt_Sim_LIP_dPul_NDT_decoding_internal(monkey, current_injection, current_type_of_session, typeOfDecoding, current_date, current_target_brain_structure, target_state, current_label, current_approach, current_file); % typeOfSessions{j}
                                    
                                  
                                    % Update progress for each iteration
                                    overallProgress = overallProgress + 1;
                                    waitbar(overallProgress / totalIterations, h, sprintf('Processing... %.2f%%', overallProgress / totalIterations * 100));
                                    
                                end
                                
                                
                            else % strcmp(typeOfDecoding, 'merged_files_across_sessions')
                                current_date = [];
                                % Call the internal decoding function only once
                                sdndt_Sim_LIP_dPul_NDT_decoding_internal(monkey, current_injection, current_type_of_session, current_date, typeOfDecoding, current_target_brain_structure, target_state, current_label, current_approach, current_file);
                                
                               
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





function sdndt_Sim_LIP_dPul_NDT_decoding_internal(monkey, injection, typeOfSessions, typeOfDecoding, dateOfRecording, target_brain_structure, target_state, given_labels_to_use, given_approach, givenListOfRequiredFiles)
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
    givenListOfRequiredFiles_with_approach = ['all_' givenListOfRequiredFiles];
elseif strcmp(given_approach, 'overlap_approach')
    givenListOfRequiredFiles_with_approach = ['overlap_' givenListOfRequiredFiles];
end


% Selection of a list of files for specific values of given_approach and givenListOfRequiredFiles variables .
switch givenListOfRequiredFiles
    case {'firstBlockFiles', 'secondBlockFiles', 'thirdBlockFiles', 'fourthBlockFiles', 'fifthBlockFiles', 'sixthBlockFiles'}
        listOfRequiredFiles = list_of_required_files.(givenListOfRequiredFiles_with_approach);
    case {'allBlocksFiles', 'allBlocksFiles_AfterInjection', 'allBlocksFiles_BeforeInjection',...
            'overlapBlocksFiles', 'overlapBlocksFiles_AfterInjection', 'overlapBlocksFiles_BeforeInjection'...
            'overlapBlocksFiles_AfterInjection_3_4', 'overlapBlocksFiles_BeforeInjection_3_4'}
        listOfRequiredFiles = list_of_required_files.(givenListOfRequiredFiles);
    otherwise
        error(['Unknown list of required files for ' given_approach '.']);
end


% Check if listOfRequiredFiles is empty
if isempty(listOfRequiredFiles)
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

uniqueBlockInformation = strrep(strjoin(unique(blockInformation)), '.mat', ''); % Find unique block information
targetBlock = uniqueBlockInformation ;

% create variable, which will help to find the required file block for decoding
switch targetBlock
    case 'block_1'
        targetBlockUsed = 'block_1';
    case 'block_2'
        targetBlockUsed = 'block_2';
    case 'block_3'
        targetBlockUsed = 'block_3';
    case 'block_4'
        targetBlockUsed = 'block_4';
    case 'block_5'
        targetBlockUsed = 'block_5';
    case 'block_6'
        targetBlockUsed = 'block_6';
    otherwise
        blocks = strsplit(targetBlock, ' '); % Split the targetBlock string into individual blocks
        for i = 1:numel(blocks)
            blocks{i} = ['block_' strrep(blocks{i}, 'block_', '')]; % Add the 'Block_' prefix to each block
        end
        targetBlockUsed = strjoin(blocks, '_'); % Concatenate the blocks with underscores
end


all_targetBlock = {'block_1', 'block_2', 'block_3', 'block_4', 'block_5', 'block_6'};

switch targetBlock
    case 'block_1'
        targetBlockUsed_among_raster_data = 'block_1';
    case 'block_2'
        targetBlockUsed_among_raster_data = 'block_2';
    case 'block_3'
        targetBlockUsed_among_raster_data = 'block_3';
    case 'block_4'
        targetBlockUsed_among_raster_data = 'block_4';
    case 'block_5'
        targetBlockUsed_among_raster_data = 'block_5';
    case 'block_6'
        targetBlockUsed_among_raster_data = 'block_6';
    otherwise
        if (isfield(list_of_required_files, 'allBlocksFiles') && isequal(givenListOfRequiredFiles,'allBlocksFiles'))||...
                ((isfield(list_of_required_files, 'overlapBlocksFiles') && strcmp(dateOfRecording, 'merged_files_across_sessions') && isequal(givenListOfRequiredFiles, 'overlapBlocksFiles')) || ...
                (isfield(list_of_required_files, 'overlapBlocksFiles_AfterInjection') && isequal(givenListOfRequiredFiles, 'overlapBlocksFiles_AfterInjection')) || ... %  && strcmp(dateOfRecording, 'merged_files_across_sessions')
                (isfield(list_of_required_files, 'overlapBlocksFiles_AfterInjection_3_4') && isequal(givenListOfRequiredFiles, 'overlapBlocksFiles_AfterInjection_3_4')) || ...
                (isfield(list_of_required_files, 'allBlocksFiles_AfterInjection') && isequal(givenListOfRequiredFiles, 'allBlocksFiles_AfterInjection')))
            targetBlockUsed_among_raster_data = [];
        else
            targetBlockUsed_among_raster_data = targetBlockUsed;
        end
end



% create block_grouping_folder:
block_grouping_folder = '';

if isequal(dateOfRecording, 'merged_files_across_sessions')
    
    % Define block file names
    block_file_names = {'firstBlockFiles', 'secondBlockFiles', 'thirdBlockFiles', 'fourthBlockFiles', 'fifthBlockFiles', 'sixthBlockFiles'};
    
    if any(strcmp(givenListOfRequiredFiles, block_file_names))
        for i = 1:numel(block_file_names) % Loop through block file names
            if strcmp(given_approach, 'all_approach')
                approach_based_folder_name = 'all_FilesAcrossSessions_';
            elseif strcmp(given_approach, 'overlap_approach')
                approach_based_folder_name = 'overlap_FilesAcrossSessions_';
            else
                error('Unknown approach. Please use either ''all_approach'' or ''overlap_approach''.');
            end
            
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
    end
    
    % Check for 'allBlocksFiles'-group files
    if isempty(block_grouping_folder)
        if isequal(givenListOfRequiredFiles, 'allBlocksFiles') % && isequal(listOfRequiredFiles, list_of_required_files.allBlocksFiles)
            block_grouping_folder = 'allBlocksFilesAcrossSessions/';
        elseif isequal(givenListOfRequiredFiles, 'allBlocksFiles_AfterInjection')
            block_grouping_folder = 'allBlocksFilesAcrossSessions_AfterInjection/';
        elseif isequal(givenListOfRequiredFiles, 'allBlocksFiles_BeforeInjection')
            block_grouping_folder = 'allBlocksFilesAcrossSessions_BeforeInjection/';
            
            % Check for 'overlapBlocksFiles'
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
    
    
    %elseif ismember(current_date, allDateOfRecording) && isfield(list_of_required_files, 'overlapBlocksFiles_BeforeInjection') && isequal(listOfRequiredFiles, list_of_required_files.overlapBlocksFiles_BeforeInjection)
elseif ismember(dateOfRecording, allDateOfRecording) && isfield(list_of_required_files, 'overlapBlocksFiles_BeforeInjection') && isequal(givenListOfRequiredFiles, 'overlapBlocksFiles_BeforeInjection')
    block_grouping_folder = 'Overlap_blocks_BeforeInjection/';
    
    % elseif ismember(current_date, allDateOfRecording) && isfield(list_of_required_files, 'overlapBlocksFiles_AfterInjection') && isequal(listOfRequiredFiles, list_of_required_files.overlapBlocksFiles_AfterInjection)
elseif ismember(dateOfRecording, allDateOfRecording) && isfield(list_of_required_files, 'overlapBlocksFiles_AfterInjection') && isequal(givenListOfRequiredFiles, 'overlapBlocksFiles_AfterInjection')
    block_grouping_folder = 'Overlap_blocks_AfterInjection/';
    
    %elseif ismember(current_date, allDateOfRecording) && isfield(list_of_required_files, 'overlapBlocksFiles_BeforeInjection') && isequal(listOfRequiredFiles, list_of_required_files.overlapBlocksFiles_BeforeInjection)
elseif ismember(dateOfRecording, allDateOfRecording) && isfield(list_of_required_files, 'overlapBlocksFiles_BeforeInjection_3_4') && isequal(givenListOfRequiredFiles, 'overlapBlocksFiles_BeforeInjection_3_4')
    block_grouping_folder = 'Overlap_blocks_BeforeInjection_3_4/';
    
    % elseif ismember(current_date, allDateOfRecording) && isfield(list_of_required_files, 'overlapBlocksFiles_AfterInjection') && isequal(listOfRequiredFiles, list_of_required_files.overlapBlocksFiles_AfterInjection)
elseif ismember(dateOfRecording, allDateOfRecording) && isfield(list_of_required_files, 'overlapBlocksFiles_AfterInjection_3_4') && isequal(givenListOfRequiredFiles, 'overlapBlocksFiles_AfterInjection_3_4')
    block_grouping_folder = 'Overlap_blocks_AfterInjection_3_4/';
    
    % elseif ismember(current_date, allDateOfRecording) && isfield(list_of_required_files, 'allBlocksFiles_BeforeInjection') && isequal(listOfRequiredFiles, list_of_required_files.allBlocksFiles_BeforeInjection)
elseif ismember(dateOfRecording, allDateOfRecording) && isfield(list_of_required_files, 'allBlocksFiles_BeforeInjection') && isequal(givenListOfRequiredFiles, 'allBlocksFiles_BeforeInjection')
    block_grouping_folder = 'All_blocks_BeforeInjection/';
    
    % elseif ismember(current_date, allDateOfRecording) && isfield(list_of_required_files, 'allpBlocksFiles_AfterInjection') && isequal(listOfRequiredFiles, list_of_required_files.allBlocksFiles_AfterInjection)
elseif ismember(dateOfRecording, allDateOfRecording) && isfield(list_of_required_files, 'allBlocksFiles_AfterInjection') && isequal(givenListOfRequiredFiles, 'allBlocksFiles_AfterInjection')
    block_grouping_folder = 'All_blocks_AfterInjection/';
    
    
    
elseif ~isequal(dateOfRecording, allDateOfRecording)
    % Handle different date recordings
    if isfield(list_of_required_files, 'overlapBlocksFiles')&& isequal(givenListOfRequiredFiles, 'overlapBlocksFiles') && ...
            ~isequal(dateOfRecording, allDateOfRecording)
        block_grouping_folder = 'Overlap_blocks/';
    elseif isfield(list_of_required_files, 'allBlocksFiles')&& isequal(givenListOfRequiredFiles, 'allBlocksFiles') && ...
            ~isequal(dateOfRecording, allDateOfRecording)
        block_grouping_folder = 'All_blocks/';
        
    elseif isequal(given_approach, 'overlap_approach')
        block_grouping_folder = 'Overlap_By_block/';
    elseif isequal(given_approach, 'all_approach')
        block_grouping_folder = 'All_By_block/';
    end
end


% create prefix to save binned data
% (prefix will contain info about all blocks)
OUTPUT_PATH_binned_dateOfRecording = [OUTPUT_PATH_binned monkey_prefix dateOfRecording '/'];


% Create num_cv_splits_folder
num_cv_splits_folder = sprintf('num_cv_splits_%d(%d)', settings.num_cv_splits, settings.num_cv_splits * settings.num_times_to_repeat_each_label_per_cv_split);

num_cv_splits_approach = settings.num_cv_splits_approach_folder;

Binned_data_dir = [OUTPUT_PATH_binned_dateOfRecording block_grouping_folder num_cv_splits_approach num_cv_splits_folder '/'];
save_prefix_name = [Binned_data_dir 'Binned_Sim_LIP_dPul__NDT_data_for_' target_brain_structure '_' target_state_name '_' targetBlockUsed];

if ~exist(Binned_data_dir,'dir')
    mkdir(Binned_data_dir);
end


%% creating folders for sorting files when running across all sessions.
% Call the function for each category

if strcmp(dateOfRecording, 'merged_files_across_sessions')
    
    if isequal(givenListOfRequiredFiles, 'overlapBlocksFiles_BeforeInjection')|| ...
            isequal(givenListOfRequiredFiles, 'overlapBlocksFiles_AfterInjection')|| ...
            isequal(givenListOfRequiredFiles, 'overlapBlocksFiles_BeforeInjection_3_4')|| ...
            isequal(givenListOfRequiredFiles, 'overlapBlocksFiles_AfterInjection_3_4')|| ...
            isequal(givenListOfRequiredFiles, 'allBlocksFiles_BeforeInjection')|| ...
            isequal(givenListOfRequiredFiles, 'allBlocksFiles_AfterInjection')
        copyFilesForCategory(givenListOfRequiredFiles, [OUTPUT_PATH_raster monkey_prefix dateOfRecording '/' block_grouping_folder], listOfRequiredFiles, list_of_required_files);
        
    elseif isequal(givenListOfRequiredFiles, 'firstBlockFiles')|| ...
            isequal(givenListOfRequiredFiles, 'secondBlockFiles')|| ...
            isequal(givenListOfRequiredFiles, 'thirdBlockFiles')|| ...
            isequal(givenListOfRequiredFiles, 'fourthBlockFiles')|| ...
            isequal(givenListOfRequiredFiles, 'fifthBlockFiles')|| ...
            isequal(givenListOfRequiredFiles, 'sixthBlockFiles')
        copyFilesForCategory(givenListOfRequiredFiles_with_approach, [OUTPUT_PATH_raster monkey_prefix dateOfRecording '/' block_grouping_folder], listOfRequiredFiles, list_of_required_files);
    end
    
    
    
elseif ismember(dateOfRecording, allDateOfRecording)
    
    if isequal(givenListOfRequiredFiles, 'overlapBlocksFiles_AfterInjection') || ...
            isequal(givenListOfRequiredFiles, 'overlapBlocksFiles_BeforeInjection') || ...
            isequal(givenListOfRequiredFiles, 'overlapBlocksFiles_AfterInjection_3_4') || ...
            isequal(givenListOfRequiredFiles, 'overlapBlocksFiles_BeforeInjection_3_4') || ...
            isequal(givenListOfRequiredFiles, 'allBlocksFiles_AfterInjection') || ...
            isequal(givenListOfRequiredFiles, 'allBlocksFiles_BeforeInjection')
        copyFilesForCategory(givenListOfRequiredFiles, [OUTPUT_PATH_raster monkey_prefix dateOfRecording '/' block_grouping_folder], listOfRequiredFiles, list_of_required_files);
        
    elseif strcmp(given_approach, 'overlap_approach')
        isequal(givenListOfRequiredFiles, 'firstBlockFiles') || ...
            isequal(givenListOfRequiredFiles, 'secondBlockFiles') || ...
            isequal(givenListOfRequiredFiles, 'thirdBlockFiles') || ...
            isequal(givenListOfRequiredFiles, 'fourthBlockFiles') || ...
            isequal(givenListOfRequiredFiles, 'fifthBlockFiles') || ...
            isequal(givenListOfRequiredFiles, 'sixthBlockFiles')
        copyFilesForCategory(givenListOfRequiredFiles_with_approach, [OUTPUT_PATH_raster monkey_prefix dateOfRecording '/' block_grouping_folder], listOfRequiredFiles, list_of_required_files);
    end
    
end



%% Combining blocks, creating a metablock if 'overlapBlocksFiles'
% for both: for singal session and all sessions (control and injection)

% Create meta_block_folder if block_grouping_folder meets the conditions

meta_block_folder = '';  % Initialize meta_block_folder
if isequal(block_grouping_folder, 'overlapBlocksFilesAcrossSessions/') || ...
        isequal(block_grouping_folder, 'overlapBlocksFilesAcrossSessions_AfterInjection/')|| ...
        isequal(block_grouping_folder, 'overlapBlocksFilesAcrossSessions_AfterInjection_3_4/')
    
    % Construct paths
    OUTPUT_PATH_raster_dateOfRecording = [OUTPUT_PATH_raster monkey_prefix dateOfRecording '/'];
    OUTPUT_PATH_raster_dateOfRecording_Overlap_blocks = [OUTPUT_PATH_raster_dateOfRecording block_grouping_folder];
    
    % Modify "metaFiles" folder creation as needed
    meta_block_folder = [OUTPUT_PATH_raster_dateOfRecording_Overlap_blocks, 'metaFiles/'];
    if ~exist(meta_block_folder, 'dir')
        mkdir(meta_block_folder);
    end
    
elseif isequal(block_grouping_folder, 'Overlap_blocks_AfterInjection/')|| ...
        isequal(block_grouping_folder, 'Overlap_blocks_AfterInjection_3_4/')
    % Construct paths
    %         OUTPUT_PATH_raster_dateOfRecording = [OUTPUT_PATH_raster current_date '/'];
    OUTPUT_PATH_raster_dateOfRecording = [OUTPUT_PATH_raster monkey_prefix dateOfRecording '/'];
    OUTPUT_PATH_raster_dateOfRecording_Overlap_blocks = [OUTPUT_PATH_raster_dateOfRecording block_grouping_folder];
    
    % Modify "metaFiles" folder creation as needed
    meta_block_folder = [OUTPUT_PATH_raster_dateOfRecording_Overlap_blocks, 'metaFiles/'];
    if ~exist(meta_block_folder, 'dir')
        mkdir(meta_block_folder);
    end
else
    % Construct paths without creating meta_block_folder
    %         OUTPUT_PATH_raster_dateOfRecording = [OUTPUT_PATH_raster current_date '/'];
    OUTPUT_PATH_raster_dateOfRecording = [OUTPUT_PATH_raster monkey_prefix dateOfRecording '/'];
    OUTPUT_PATH_raster_dateOfRecording_Overlap_blocks = [OUTPUT_PATH_raster_dateOfRecording block_grouping_folder];
end




if (isfield(list_of_required_files, 'overlapBlocksFiles') && isequal(givenListOfRequiredFiles, 'overlapBlocksFiles')) || ...
        (isfield(list_of_required_files, 'overlapBlocksFiles_AfterInjection') && isequal(givenListOfRequiredFiles, 'overlapBlocksFiles_AfterInjection'))|| ...
        (isfield(list_of_required_files, 'overlapBlocksFiles_AfterInjection_3_4') && isequal(givenListOfRequiredFiles, 'overlapBlocksFiles_AfterInjection_3_4'))
    % add also for overlap-approach specific (with the better results) blocks after injection
    mergeFilesInBlockGroup(listOfRequiredFiles, target_state_name, search_target_brain_structure_among_raster_data, target_brain_structure, OUTPUT_PATH_raster_dateOfRecording_Overlap_blocks, meta_block_folder);
end

%%  Make Binned_data

if isempty(meta_block_folder)
    if strcmp(block_grouping_folder, 'All_By_block/')
        Raster_data_dir = [OUTPUT_PATH_raster, monkey_prefix, dateOfRecording '/'];
    else
        Raster_data_dir = [OUTPUT_PATH_raster, monkey_prefix, dateOfRecording '/' block_grouping_folder];
    end
else
    Raster_data_dir = meta_block_folder;
end


% If no files are found for either 'LIP_L' or 'LIP_R', return to the beginning
if ~any(contains(listOfRequiredFiles, search_target_brain_structure_among_raster_data))
    disp(['No files found for ' search_target_brain_structure_among_raster_data '. Returning to the beginning.']);
    return;
end


%Raster_data_dir = [OUTPUT_PATH_raster_dateOfRecording block_grouping_folder];
raster_data_directory_name =  [Raster_data_dir  '*' search_target_brain_structure_among_raster_data '_trial_state_' target_state_name '_' targetBlockUsed_among_raster_data '*'];
binned_data_file_name = create_binned_data_from_raster_data(raster_data_directory_name, save_prefix_name, settings.bin_width, settings.step_size);

load(binned_data_file_name);  % load the binned data
[~, filename_binned_data, ~] = fileparts(binned_data_file_name);

% smooth the data
binned_data = arrayfun(@(x) smoothdata(binned_data{x}, 2, settings.smoothing_method, settings.smoothing_window), 1:length(binned_data), 'UniformOutput', false);
save([Binned_data_dir filename_binned_data '_smoothed.mat'],'binned_data','binned_labels','binned_site_info');



%% Prepearing for decoding


switch given_labels_to_use
    case 'instr_R_instr_L'
        labels_to_use = {'instr_R', 'instr_L'};
    case 'choice_R_choice_L'
        labels_to_use = {'choice_R', 'choice_L'};
    case 'instr_R_choice_R'
        labels_to_use = {'instr_R', 'choice_R'};
    otherwise % 'instr_L_choice_L'
        labels_to_use = {'instr_L', 'choice_L'};
end


string_to_add_to_filename = '';
labels_to_use_string = strjoin(labels_to_use);

% Determining how many times each condition was repeated
for k = 1:250
    inds_of_sites_with_at_least_k_repeats = find_sites_with_k_label_repetitions(binned_labels.trial_type_side , k, labels_to_use);
    num_sites_with_k_repeats(k) = length(inds_of_sites_with_at_least_k_repeats);
    % number of columns - how many times the stimulus was presented (number of repetitions);
    % the value in each column - how many units has this number of repetitions
end


%% Create a file with information about the number of stimulus repetitions for N number of units
% Define the prefix for the file name
prefix_for_file_with_num_sites_with_k_repeats = ['num_sites_with_k_repeats_for_' target_brain_structure '_' target_state_name '_' targetBlockUsed '_' labels_to_use_string];

% Define the file name
file_name = fullfile(Binned_data_dir, [prefix_for_file_with_num_sites_with_k_repeats '.txt']);
fileID = fopen(file_name, 'w'); % Open the file for writing
lines = {}; % Initialize a cell array to store lines

% Iterate over each neuron group
for group = unique(num_sites_with_k_repeats)
    last_occurrence = find(num_sites_with_k_repeats == group, 1, 'last'); % Find the last occurrence of the current neuron group
    if ~isempty(last_occurrence) % Check if the last occurrence is not empty
        lines{end+1} = sprintf('%d units has %d repetitions of the stimuli', group, last_occurrence); % Add the line to the cell array
    end
end
lines = flip(lines); % Reverse the order of lines

% Write the lines to the file
for i = 1:numel(lines)
    fprintf(fileID, '%s\n', lines{i});
end
fclose(fileID); % Close the file



%% Detection of possible number of num_cv_splits

% Automatic detection of the maximum possible number of num_cv_splits
% Determine the maximum number of units and repetitions

if isequal(num_cv_splits_approach, 'max_num_cv_splits/') || ...
        (isequal(num_cv_splits_approach, 'same_num_cv_splits/') && ...
        (isequal(givenListOfRequiredFiles, 'overlapBlocksFiles_BeforeInjection') || isequal(givenListOfRequiredFiles, 'overlapBlocksFiles_BeforeInjection_3_4')))
  
    data_from_text_document = [];
    for i = 1:numel(lines)
        line_parts = split(lines{i}, {' units has ', ' repetitions of the stimuli'});
        data_from_text_document = [data_from_text_document; str2double(line_parts{1}), str2double(line_parts{2})];
    end
    
    % Extract the number of units and repetitions
    num_units = data_from_text_document(:, 1);
    num_repetitions = data_from_text_document(:, 2);
    
    % Filter out rows where the number of repetitions is less than 8
    valid_indices = num_repetitions >= 4*settings.num_times_to_repeat_each_label_per_cv_split;
    num_units = num_units(valid_indices);
    num_repetitions = num_repetitions(valid_indices);
    
    % Check if all units are zeros
    if all(num_units == 0)
        % If all units are zeros, return from the function
        return;
    end
    
    
    % Determine the maximum number of units
    max_units = max(num_units);
    
    % Find the corresponding number of repetitions for the maximum number of units
    max_repetitions_index = find(num_units == max_units, 1);
    max_repetitions = num_repetitions(max_repetitions_index);
    
    % Determine the maximum possible num_cv_splits based on the maximum number of units and repetitions
    max_cv_splits = max_repetitions / settings.num_times_to_repeat_each_label_per_cv_split;
    
    % % Set num_cv_splits to 16 if max_cv_splits is greater than 16
    % if max_cv_splits > 16
    %     num_cv_splits = 16;
    % else
    %     num_cv_splits = max_cv_splits;
    % end
    
    % Ensure num_cv_splits is an even number or less than 16
    num_cv_splits = min(floor(max_cv_splits), 16);  % Take the floor of max_cv_splits and cap it at 16
    
    % Make sure num_cv_splits is even
    if mod(num_cv_splits, 2) ~= 0  % If num_cv_splits is odd
        num_cv_splits = num_cv_splits - 1;  % Subtract 1 to make it even
    end
    
    % Check if num_cv_splits is less than 4
    if num_cv_splits < 4
        % If less than 4, return to the calling function sdndt_Sim_LIP_dPul_NDT_decoding
        return; % Exit the current function and return to the calling function
    end
    
    
    
    
elseif isequal(num_cv_splits_approach, 'same_num_cv_splits/') && ...
        isequal(givenListOfRequiredFiles, 'overlapBlocksFiles_AfterInjection') || isequal(givenListOfRequiredFiles, 'overlapBlocksFiles_AfterInjection_3_4')
  
     block_grouping_folder_Before = strrep(block_grouping_folder, 'After', 'Before'); % Replacing "After" with "Before"
    folder_where_search_CV_file = [OUTPUT_PATH_binned_dateOfRecording block_grouping_folder_Before num_cv_splits_approach ];
        
    [num_cv_splits] = find_num_cv_splits(folder_where_search_CV_file, target_brain_structure, target_state_name, labels_to_use_string, dateOfRecording);
    
    
end

% num_cv_splits = 6; % for Linus: Lin_20210709

%% moving binned files from the old folder to the new one if the num_cv_splits variable did not correspond to the specified settings.num_cv_splits
% Check if num_cv_splits is different from settings.num_cv_splits
if num_cv_splits ~= settings.num_cv_splits
   
    % Move files from unsuitable directory to new one to match new num_cv_splits_folder
    Binned_data_dir_old = [Binned_data_dir];
    old_dir = [Binned_data_dir_old];
    
    num_cv_splits_folder = sprintf('num_cv_splits_%d(%d)', num_cv_splits, num_cv_splits * settings.num_times_to_repeat_each_label_per_cv_split);
    Binned_data_dir = [OUTPUT_PATH_binned_dateOfRecording block_grouping_folder num_cv_splits_approach num_cv_splits_folder '/'];
    if ~exist(Binned_data_dir,'dir')
        mkdir(Binned_data_dir);
    end
    
    new_dir = fileparts(Binned_data_dir); % Get the parent directory of the new folder
    movefile([old_dir '/*'], new_dir);
    
    
    % Delete old unnecessary folder
    folder_name_to_delete = sprintf('num_cv_splits_%d(%d)', settings.num_cv_splits, settings.num_cv_splits * settings.num_times_to_repeat_each_label_per_cv_split);
    dir_to_delete = fullfile(OUTPUT_PATH_binned_dateOfRecording, block_grouping_folder, num_cv_splits_approach, folder_name_to_delete);
    if exist(dir_to_delete, 'dir') % Delete the directory
        rmdir(dir_to_delete, 's'); % 's' option deletes the directory and all its contents
    end
    
end



%%  Begin the decoding analysis
%  6.  Create a datasource object
specific_label_name_to_use = 'trial_type_side';
% num_cv_splits = settings.num_cv_splits; % 20 cross-validation runs


% If the data is run across sessions, the data was not recorded at the simultaneously
%(by default, the data is recorded at the simultaneously in the sdndt_Sim_LIP_dPul_NDT_settings.m:
% settings.create_simultaneously_recorded_populations = 1;)
if isequal(dateOfRecording, 'merged_files_across_sessions')%&& ...
    settings.create_simultaneously_recorded_populations = 0; % data are not recorded simultaneously
elseif isequal(typeOfDecoding, 'each_session_separately')&& ...
        isfield(list_of_required_files, 'allBlocksFiles_AfterInjection') && isequal(givenListOfRequiredFiles, 'allBlocksFiles_AfterInjection')
    settings.create_simultaneously_recorded_populations = 0;
end



% Create a datasource that takes our binned data, and specifies that we want to decode
ds = basic_DS([Binned_data_dir filename_binned_data '_smoothed.mat'], specific_label_name_to_use, num_cv_splits);

% can have multiple repetitions of each label in each cross-validation split (which is a faster way to run the code that uses most of the data)
ds.num_times_to_repeat_each_label_per_cv_split = settings.num_times_to_repeat_each_label_per_cv_split;

% optionally can specify particular sites to use
% Take only sites with enough repetitions of each condition:
% for example, if num_cv_splits=20 and ds.num_times_to_repeat_each_label_per_cv_split=2 (20*2 = 40), take only the units of neurons that had 40 presentations of the stimulus:
ds.sites_to_use = find_sites_with_k_label_repetitions(binned_labels.trial_type_side, num_cv_splits*ds.num_times_to_repeat_each_label_per_cv_split, labels_to_use); % shows how many units are taken for decoding (size, 2)


% flag, which specifies that the data was recorded at the simultaneously
% create_simultaneously_recorded_populations = 1; % data are recorded simultaneously
ds.create_simultaneously_recorded_populations = settings.create_simultaneously_recorded_populations;

% can do the decoding on a subset of labels
ds.label_names_to_use = labels_to_use; % {'instr_R', 'instr_L'} {'choice_R', 'choice_L'}

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




save_file_name = [Binned_data_dir filename_binned_data '_' labels_to_use_string string_to_add_to_filename '_DECODING_RESULTS.mat'];
save(save_file_name, 'DECODING_RESULTS');

% Save num_cv_splits to a .mat file
filename_binned_data_cv = regexp(filename_binned_data, '_for.*_sampled', 'match');
save_num_cv_splits_file = [Binned_data_dir 'num_cv_splits'  filename_binned_data_cv{1} '_' labels_to_use_string string_to_add_to_filename '.mat'];
save(save_num_cv_splits_file, 'num_cv_splits');




% Save unit_ID as a txt-file
% Define the prefix for the file name
prefix_for_file_with_units_IDs = ['units_IDs_for_' target_brain_structure '_' target_state_name '_' targetBlockUsed '_' labels_to_use_string];

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
sdndt_Sim_LIP_dPul_NDT_plot_decoding_results(monkey, injection, typeOfSessions, save_file_name);
%end

end



%% Supporting functions

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