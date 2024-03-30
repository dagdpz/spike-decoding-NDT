function sdndt_Sim_LIP_dPul_Num_of_Units_and_Trials_in_populat_file(injection) % , dateOfRecording
% sdndt_Sim_LIP_dPul_Num_of_Units_and_Trials_in_populat_file('1', '20210520');



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


datesForSessions = {}; % Initialize datesForSessions as an empty cell array
if strcmp(injection, '1')
    for type = 1:numel(typeOfSessions)
        % Get the dates for the corresponding injection and session types
        datesForSessions{end+1} = filelist_of_days_from_Simultaneous_dPul_PPC_recordings(injection, typeOfSessions{type});
    end
elseif  strcmp(injection, '0') || strcmp(injection, '2')
    datesForSessions = filelist_of_days_from_Simultaneous_dPul_PPC_recordings(injection, typeOfSessions);
end
%%
numTypesOfSessions = numel(typeOfSessions);


for j = 1:numTypesOfSessions
    current_type_of_session = typeOfSessions{j}
    current_set_of_date = datesForSessions{j}; % Get the corresponding set of dates !!!!!
    
    for numDays = 1:numel(current_set_of_date)
        current_date = current_set_of_date{numDays};
        sdndt_Sim_LIP_dPul_Num_of_Units_and_Trials_internal(injection, current_type_of_session, current_date)
    end

end
end 


function sdndt_Sim_LIP_dPul_Num_of_Units_and_Trials_internal(injection, typeOfSessions, dateOfRecording)
%% call additional functions

% Call the function to get the dates
allDateOfRecording = filelist_of_days_from_Simultaneous_dPul_PPC_recordings(injection, typeOfSessions);

% Call the settings function with the chosen set
[base_path, INPUT_PATH, OUTPUT_PATH_raster, OUTPUT_PATH_binned, settings] = sdndt_Sim_LIP_dPul_NDT_settings(injection, typeOfSessions);



% Check if dateOfRecording is in the list allDateOfRecording
if ~ismember(dateOfRecording, allDateOfRecording)
    error('Specified date is not available for the selected injection.');
end


% Construct the mat_file_name for the specified day
if strcmp(injection, '0') % '0' means 'control'
    mat_file_name = ['dPul_LIP_Lin_' dateOfRecording '/population_Linus_' dateOfRecording '.mat'];
elseif strcmp(injection, '1') % '1' means 'injection'
    mat_file_name = ['dPul_inj_LIP_Lin_10s/population_Linus_' dateOfRecording '.mat'];
else
    error('Invalid selection. Use ''0'' or ''1'' for injection.');
end

% Construct the full path to the population file
input_population_file = fullfile(INPUT_PATH, mat_file_name);

% Load the population file
load(input_population_file);



%% Number of Units and Trials
% checking that the number of units in the final picture after decoding is correctly counted for different targets (e.g. LIP_L and LIP_R)

numPopulations = length(population);% Calculate the total number of populations
uniqueUnitsCell = cell(numPopulations, 1); % Initialize a cell array to store unique units for each population

% Loop through each population and count unique units for each trial
for n = 1:numPopulations
    numTrials = length(population(n).trial);
    uniqueUnitsForPopulation = cell(1, numTrials); % Initialize a cell array to store unique units for the current population
    
    % Loop through each trial in the current population
    for t = 1:numTrials
        uniqueUnitsForPopulation{t} = unique(population(n).trial(t).block); % Store unique units for the current trial
    end
    
    % Combine unique units across all trials for the current population
    uniqueUnitsCell{n} = unique([uniqueUnitsForPopulation{:}]);
    
end



% Initialize variables for each unique block
uniqueBlocks = unique([uniqueUnitsCell{:}]);

% Loop through each block and count the number of units
for blockNum = uniqueBlocks
    blockStr = ['block_' num2str(blockNum)];
    
    % Initialize count for the current block
    blockCount = 0;
    
    % Loop through each population
    for n = 1:numPopulations
        % Count occurrences of the current block number in the current population
        blockCount = blockCount + sum(ismember(uniqueUnitsCell{n}, blockNum));
    end
    
    % Assign the count to the corresponding field in ammount_of_units
    ammount_of_units.(blockStr) = blockCount;
end




% Check if any cell contains more than one meaning
if any(cellfun(@(x) numel(unique(x)) > 1, uniqueUnitsCell))
    
    % Initialize variables to store the maximum number of blocks and the corresponding population index
    maxBlocks = 0;
    maxBlocksPopulationIndex = 0;
    
    % Loop through each population to find the one with the maximum number of blocks
    for n = 1:numPopulations
        % Calculate the unique blocks for the current population
        uniqueBlocksForPopulation = unique([population(n).trial.block]);
        
        % Check if the current population has the maximum number of blocks
        if numel(uniqueBlocksForPopulation) > maxBlocks
            maxBlocks = numel(uniqueBlocksForPopulation);
            maxBlocksPopulationIndex = n;
        end
    end
    
    % Check if a population with blocks exists
    if maxBlocksPopulationIndex == 0
        error('No population contains any blocks.');
    end
    
    % Use the population with the maximum number of blocks for counting trials
    selectedOneUnit = population(maxBlocksPopulationIndex);
    
    
    % Loop through each block and count the number of success, choice, and instructed trials
    for blockNum = uniqueBlocks
        blockStr = ['block_' num2str(blockNum)];
        
        % Initialize variables for ammount_of_units and success_trials
        num_of_success_trials.(blockStr) = 0;
        num_of_choice_trials.(blockStr) = 0;
        num_of_instr_trials.(blockStr) = 0;
        
        % Loop through each trial in the selected population
        for trial = selectedOneUnit.trial
            if trial.block == blockNum
                
                if trial.success
                    num_of_success_trials.(blockStr) = num_of_success_trials.(blockStr) + 1;
                    if trial.choice == 1
                        num_of_choice_trials.(blockStr) = num_of_choice_trials.(blockStr) + 1;
                    else
                        num_of_instr_trials.(blockStr) = num_of_instr_trials.(blockStr) + 1;
                    end
                end
            end
        end
    end
    
else
    % if the file (session) does not contain any overlap units:
    % If more than one block is recorded in a session, but no unit has been recorded in more than one block
    
    % Loop through each unique block number and find the first trial for each block
    for i = 1:numel(uniqueUnitsCell)
        blockNum = uniqueUnitsCell{i};
        
        % Initialize the selected trial index
        selectedTrialIndex = [];
        
        % Loop through each population to find the first trial for the current block
        for n = 1:numPopulations
            % Check if the block number matches the block number of the first trial
            if population(n).trial(1).block == blockNum
                % Store the index of the first trial for the current block
                selectedTrialIndex = n;
                break; % Exit the loop after finding the first trial
            end
        end
        
        % Check if a trial for the current block was found
        if isempty(selectedTrialIndex)
            error('No trial found for block %d.', blockNum);
        end
        
        % Get the selected trial for the current block
        selectedUnit{blockNum} = population(selectedTrialIndex).trial(:);
    end
    
    
    % Initialize variables for amount_of_units and success_trials
    num_of_success_trials = struct();
    num_of_choice_trials = struct();
    num_of_instr_trials = struct();
    
    % Loop through each block
    for blockNum = uniqueBlocks
        blockStr = ['block_' num2str(blockNum)];
        
        % Initialize counts for the current block
        num_of_success_trials.(blockStr) = 0;
        num_of_choice_trials.(blockStr) = 0;
        num_of_instr_trials.(blockStr) = 0;
        
        % Get the trials for the current block
        blockTrials = selectedUnit{blockNum};
        
        % Loop through each trial in the current block
        for trialIndex = 1:numel(blockTrials)
            trial = blockTrials(trialIndex);
            
            % Check if the trial is successful
            if trial.success
                num_of_success_trials.(blockStr) = num_of_success_trials.(blockStr) + 1;
                if trial.choice == 1
                    num_of_choice_trials.(blockStr) = num_of_choice_trials.(blockStr) + 1;
                else
                    num_of_instr_trials.(blockStr) = num_of_instr_trials.(blockStr) + 1;
                end
            end
        end
    end
end




%% Display
 uniqueTargets = unique({population.target}); % Extract unique targets from the entire population
 uniqueTargetsStr = ['(' strjoin(uniqueTargets, ', ') ')']; % Create a string of unique targets in round brackets
 parts = strsplit(population(1).unit_ID, '_');
 nameOfSession = strcat(parts{1}, '_', parts{2});
% disp(' '); % Display an empty line
% disp(['Number of Units for both targets ' uniqueTargetsStr ':']);
% disp(nameOfSession);
% disp(' '); % Display an empty line
% 
% % Display the number of units for each block
% for blockNum = uniqueBlocks
%     field = ['block_' num2str(blockNum)];
%     if isfield(ammount_of_units, field)
%         disp([num2str(ammount_of_units.(field)) ' units from ' num2str(numPopulations) ' contain ' field]);
%     end
% end
% 
% disp(' '); % Display an empty line
% disp('Number of Success Trials:');
% disp(num_of_success_trials);
% 
% disp('Number of Choice Trials:');
% disp(num_of_choice_trials);
% 
% disp('Number of Instructed Trials:');
% disp(num_of_instr_trials);

    
    
    
% Prepare data for writing to file
fileContent = sprintf('Number of Units for both targets %s:\n%s\n\n', uniqueTargetsStr, nameOfSession);

fileContent = [fileContent sprintf('A total of %d units were recorded\n\n', numPopulations)];

for blockNum = uniqueBlocks
    field = ['block_' num2str(blockNum)];
    if isfield(ammount_of_units, field)
        fileContent = [fileContent sprintf('    %s contain %d units\n', field, ammount_of_units.(field))];
    end
end


fileContent = [fileContent sprintf('\nNumber of Success Trials:\n')];
for blockNum = uniqueBlocks
    field = ['block_' num2str(blockNum)];
    if isfield(num_of_success_trials, field)
        fileContent = [fileContent sprintf('    %s: %d\n', field, num_of_success_trials.(field))];
    end
end

fileContent = [fileContent sprintf('\nNumber of Choice Trials:\n')];
for blockNum = uniqueBlocks
    field = ['block_' num2str(blockNum)];
    if isfield(num_of_choice_trials, field)
        fileContent = [fileContent sprintf('    %s: %d\n', field, num_of_choice_trials.(field))];
    end
end

fileContent = [fileContent sprintf('\nNumber of Instructed Trials:\n')];
for blockNum = uniqueBlocks
    field = ['block_' num2str(blockNum)];
    if isfield(num_of_instr_trials, field)
        fileContent = [fileContent sprintf('    %s: %d\n', field, num_of_instr_trials.(field))];
    end
end

% Define the folder and file name
folderNameForFile = 'Num_Units_Trials_based_on_Population_file/';
path_folderNameForFile = [OUTPUT_PATH_raster dateOfRecording '/' folderNameForFile]
if ~exist(path_folderNameForFile, 'dir')
    mkdir(path_folderNameForFile);
end
file_name = fullfile(path_folderNameForFile, ['num_of_units_and_trials_for_' dateOfRecording '.txt']);

% Write the content to the file
fileID = fopen(file_name, 'w'); % Open the file for writing
fprintf(fileID, fileContent);
fclose(fileID); % Close the file
end 