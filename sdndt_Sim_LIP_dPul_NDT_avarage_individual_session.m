function sdndt_Sim_LIP_dPul_NDT_avarage_individual_session(injection, typeOfDecoding)

% For across session analysis, you just need to average individual session
% sdndt_Sim_LIP_dPul_NDT_avarage_individual_session('1', 'merged_files_across_sessions')


%%
% Start timing the execution
startTime = tic;


%% Define the list of required files
listOfRequiredFiles = {%'firstBlockFiles', 'secondBlockFiles', 'thirdBlockFiles', ...
    %'fourthBlockFiles', 'fifthBlockFiles', 'sixthBlockFiles'%, ...
    %     'allBlocksFiles', 'overlapBlocksFiles', ...
    %      'overlapBlocksFiles_BeforeInjection', 'overlapBlocksFiles_AfterInjection', ...
    'allBlocksFiles_BeforeInjection' %, 'allBlocksFiles_AfterInjection'
    };


%% Define typeOfSessions
% Calculate typeOfSessions based on the injection parameter
if strcmp(injection, '1')
    typeOfSessions = {'left', 'right', 'all'}; % For control and injection experiments
    %    typeOfSessions = { 'right'};
elseif strcmp(injection, '0') || strcmp(injection, '2')
    typeOfSessions = {''}; % For the functional interaction experiment
else
    error('Invalid injection value. Use ''0'', ''1'', or ''2''.');
end


%% Define target_state parameters
targetParams = struct();

% Define target_state parameters
targetParams.cueON = 'cueON';
targetParams.GOSignal = 'GOsignal';


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
numFiles = numel(listOfRequiredFiles); % Add this line to get the number of files

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
            
            % Loop through each label in labels_to_use
            for label_index = 1:numLabels
                current_label = labels_to_use{label_index};
                
                % Check if decoding should be performed for each session separately
                % if strcmp(typeOfDecoding, 'each_session_separately')
                datesForSessions = {}; % Initialize datesForSessions as an empty cell array
                if strcmp(injection, '1')
                    for type = 1:numel(typeOfSessions)
                        % Get the dates for the corresponding injection and session types
                        datesForSessions{end+1} = filelist_of_days_from_Simultaneous_dPul_PPC_recordings(injection, typeOfSessions{type});
                    end
                elseif  strcmp(injection, '0') || strcmp(injection, '2')
                    datesForSessions = filelist_of_days_from_Simultaneous_dPul_PPC_recordings(injection, typeOfSessions);
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
                                sdndt_Sim_LIP_dPul_NDT_avarage_internal(current_injection, current_type_of_session, typeOfDecoding, current_date, current_target_brain_structure, target_state, current_label, current_file); % typeOfSessions{j}
                                
                                % Update progress bar
                                progress = ((file_index - 1) * numCombinations * numLabels * numFieldNames * numTypesOfSessions * numel(current_set_of_date) + ...
                                    (comb_index - 1) * numLabels * numFieldNames * numTypesOfSessions * numel(current_set_of_date) + ...
                                    (label_index - 1) * numFieldNames * numTypesOfSessions * numel(current_set_of_date) + ...
                                    (i - 1) * numTypesOfSessions * numel(current_set_of_date) + ...
                                    (j - 1) * numel(current_set_of_date) + numDays) / ...
                                    (numFiles * numCombinations * numLabels * numFieldNames * numTypesOfSessions * numel(current_set_of_date));
                                waitbar(progress, h, sprintf('Processing... %.2f%%', progress * 100));
                                
                            end
                            
                            
                        else % strcmp(typeOfDecoding, 'merged_files_across_sessions')
                            current_date = [];
                            % Call the internal decoding function only once
                            sdndt_Sim_LIP_dPul_NDT_avarage_internal(current_injection, current_type_of_session, typeOfDecoding, current_set_of_date, current_target_brain_structure, target_state, current_label, current_file);
                            
                            %                             % Update progress bar for merged files scenario
                            %                             progress = ((file_index - 1) * numCombinations + (comb_index - 1)) / (numFiles * numCombinations);
                            %                             waitbar(progress, h, sprintf('Processing... %.2f%%', progress * 100));
                            
                            % Update progress for each combination
                            overallProgress = ((file_index - 1) * numCombinations * numLabels * numFieldNames * numTypesOfSessions + ...
                                (comb_index - 1) * numLabels * numFieldNames * numTypesOfSessions + ...
                                (label_index - 1) * numFieldNames * numTypesOfSessions + ...
                                (i - 1) * numTypesOfSessions + ...
                                (j - 1)) / ...
                                (numFiles * numCombinations * numLabels * numFieldNames * numTypesOfSessions);
                            
                            % Update progress bar
                            waitbar(overallProgress, h, sprintf('Processing... %.2f%%', overallProgress * 100));
                            
                            
                        end % if strcmp(typeOfDecoding, 'each_session_separately')
                        
                    end % for j = 1:numTypesOfSessions
                end % for i = 1:numFieldNames
            end % for label_index = 1:numLabels
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





function sdndt_Sim_LIP_dPul_NDT_avarage_internal(injection, typeOfSessions, typeOfDecoding, dateOfRecording, target_brain_structure, target_state, given_labels_to_use, givenListOfRequiredFiles)




%% Path
% Call the function to get the dates
allDateOfRecording = filelist_of_days_from_Simultaneous_dPul_PPC_recordings(injection, typeOfSessions);


% Call the settings function with the chosen set
[base_path, INPUT_PATH, OUTPUT_PATH_raster, OUTPUT_PATH_binned, settings] = sdndt_Sim_LIP_dPul_NDT_settings(injection, typeOfSessions);

%% find grouping_folder
if isequal(givenListOfRequiredFiles, 'overlapBlocksFiles_BeforeInjection')
    block_grouping_folder = 'Overlap_blocks_BeforeInjection/';
    
    % elseif ismember(current_date, allDateOfRecording) && isfield(list_of_required_files, 'overlapBlocksFiles_AfterInjection') && isequal(listOfRequiredFiles, list_of_required_files.overlapBlocksFiles_AfterInjection)
elseif isequal(givenListOfRequiredFiles, 'overlapBlocksFiles_AfterInjection')
    block_grouping_folder = 'Overlap_blocks_AfterInjection/';
    
    % elseif ismember(current_date, allDateOfRecording) && isfield(list_of_required_files, 'allBlocksFiles_BeforeInjection') && isequal(listOfRequiredFiles, list_of_required_files.allBlocksFiles_BeforeInjection)
elseif isequal(givenListOfRequiredFiles, 'allBlocksFiles_BeforeInjection')
    block_grouping_folder = 'All_blocks_BeforeInjection/';
    
    % elseif ismember(current_date, allDateOfRecording) && isfield(list_of_required_files, 'allpBlocksFiles_AfterInjection') && isequal(listOfRequiredFiles, list_of_required_files.allBlocksFiles_AfterInjection)
elseif isequal(givenListOfRequiredFiles, 'allBlocksFiles_AfterInjection')
    block_grouping_folder = 'All_blocks_AfterInjection/';
    
    % elseif ~isequal(dateOfRecording, allDateOfRecording)
    %     % Handle different date recordings
    %     if isfield(list_of_required_files, 'overlapBlocksFiles')&& isequal(givenListOfRequiredFiles, 'overlapBlocksFiles') && ...
    %             ~isequal(dateOfRecording, allDateOfRecording)
    %         block_grouping_folder = 'Overlap_blocks/';
    %     elseif isfield(list_of_required_files, 'allBlocksFiles')&& isequal(givenListOfRequiredFiles, 'allBlocksFiles') && ...
    %             ~isequal(dateOfRecording, allDateOfRecording)
    %         block_grouping_folder = 'All_blocks/';
    %     end
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
       
    % Initialize cell array to store mean decoding results
    all_mean_decoding_results = {};
    
    for numOfData = 1:numel(dateOfRecording)
        current_dateOfRecording = dateOfRecording{numOfData}
        OUTPUT_PATH_binned_data = fullfile(OUTPUT_PATH_binned, current_dateOfRecording, block_grouping_folder);
        
        % List the contents of the All_blocks_BeforeInjection folder
        cvSplitsFolders = dir(OUTPUT_PATH_binned_data);
        
        % Filter out current directory '.' and parent directory '..'
        cvSplitsFolders = cvSplitsFolders(~ismember({cvSplitsFolders.name}, {'.', '..'}));
        
        
        % Check, that we will chose required file from the folder with
        % the haighest number of num_cv_splits
        for cvIndex = 1:numel(cvSplitsFolders)
            cvSplitFolderName = cvSplitsFolders(cvIndex).name;
            
            % Check if the folder name starts with 'num_cv_splits_'
            if startsWith(cvSplitFolderName, 'num_cv_splits_')
                % Extract the value within parentheses
                parenthesesIdx = strfind(cvSplitFolderName, '(');
                parenthesesValue = str2double(cvSplitFolderName(parenthesesIdx+1:end-1));
                
                % Update highest value and folder if necessary
                if parenthesesValue > highestValue
                    highestValue = parenthesesValue;
                    highestFolder = cvSplitFolderName;
                end
            end
        end
        
        % If the highest value folder is found, proceed to check files inside it
        if ~isempty(highestFolder)
            cvSplitFolderPath = fullfile(OUTPUT_PATH_binned_data, highestFolder);
            
            % List the contents of the current highest value CV splits folder
            decodingResultsFiles = dir(fullfile(cvSplitFolderPath, '*_DECODING_RESULTS.mat'));
            
            % Check if the required file exists in the highest value folder
            for fileIndex = 1:numel(decodingResultsFiles)
                decodingResultsFilename = decodingResultsFiles(fileIndex).name;
                
                % Check if the file name contains the desired target structure, state, and label
                if contains(decodingResultsFilename, target_brain_structure) && ...
                        contains(decodingResultsFilename, target_state) && ...
                        contains(decodingResultsFilename, combinedLabel)
                    % Construct the full path to the DECODING_RESULTS.mat file
                    decodingResultsFilePath = fullfile(cvSplitFolderPath, decodingResultsFilename);
                    
                    % Now you have the path to the suitable DECODING_RESULTS.mat file
                    % You can process or load this file as needed
                    break; % Exit the loop once the file is found
                end
            end
            
            if ~isempty(decodingResultsFilePath)
                % Load the file
                loadedData = load(decodingResultsFilePath);
                
                % Now you can access the data from the loaded file using the appropriate fields or variables
                % For example, if there is a variable named 'results' in the loaded file, you can access it as follows:
                mean_decoding_results = loadedData.DECODING_RESULTS.NORMALIZED_RANK_RESULTS.mean_decoding_results;
                
                % Append mean decoding results to the cell array
                all_mean_decoding_results{end+1} = mean_decoding_results;
                
                % Process the loaded data as needed
            else
                % Handle the case when the file was not found
                disp('ERROR: The decoding results file was not found.');
            end
            
        end
        
        
        
    end
        % Concatenate mean decoding results from all days into one variable
    mean_decoding_results = horzcat(all_mean_decoding_results{:});
    mean_decoding_results_100 = mean_decoding_results*100
     plot(mean_decoding_results_100) 
  
     
    % Calculate the total number of time points
numTimePoints = size(mean_decoding_results_100, 1);

% Calculate the bin duration in milliseconds
binDuration = 25; % milliseconds

% Calculate the total duration of the time window
totalDuration = numTimePoints * binDuration; % milliseconds

% Generate the time values for each bin starting from 25 ms
timeValues = linspace(25, totalDuration + 25, numTimePoints);

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
% Join the combined segments with a space
combinedLabel = strjoin(combinedSegments, ' ');
end