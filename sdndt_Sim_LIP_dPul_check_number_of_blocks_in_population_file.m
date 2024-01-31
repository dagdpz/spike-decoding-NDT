function sdndt_Sim_LIP_dPul_check_number_of_blocks_in_population_file(injection, dateOfRecording)
% sdndt_Sim_LIP_dPul_check_number_of_blocks_in_population_file('1', '20210520');

%% call additional functions

% Call the function to get the dates
dateOfRecording = filelist_of_days_from_Simultaneous_dPul_PPC_recordings(injection);

% Call the settings function with the chosen set
[base_path, INPUT_PATH, OUTPUT_PATH_raster, OUTPUT_PATH_binned, settings] = sdndt_Sim_LIP_dPul_NDT_settings(injection);

% List of available dates for the specified injection
availableDates = filelist_of_days_from_Simultaneous_dPul_PPC_recordings(injection);

% Select the appropriate date if specified, otherwise use the first available date
if isempty(dateOfRecording)
    dateOfRecording = availableDates{1};
elseif ~ismember(dateOfRecording, availableDates)
    error('Specified date is not available for the selected injection.');
end

% Extract the date from the cell array
dateStr = dateOfRecording{1};
dateOfRecording = dateStr;

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



%% Ammount of particular blocks
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

maxUniqueUnits = max(cellfun(@length, uniqueUnitsCell)); % Find the maximum number of unique units across all populations
matrixUniqueBlocksForEachUnit = zeros(numPopulations, maxUniqueUnits); % Initialize a matrix to store unique units for each population

% Fill the matrix with unique units for each population
for n = 1:numPopulations
    uniqueUnitsForPopulation = uniqueUnitsCell{n};
    [~, colIndices] = ismember(uniqueUnitsForPopulation, uniqueUnitsForPopulation); % Assign column indices for each unique unit
    matrixUniqueBlocksForEachUnit(n, colIndices) = uniqueUnitsForPopulation; % Fill the matrix with unique units for the current population
end


ammount_of_blocks.block_1 = sum(matrixUniqueBlocksForEachUnit == 1, 'all'); % number of units that contain block 1
ammount_of_blocks.block_2 = sum(matrixUniqueBlocksForEachUnit == 2, 'all'); % number of units that contain block 2
ammount_of_blocks.block_3 = sum(matrixUniqueBlocksForEachUnit == 3, 'all'); % number of units that contain block 3
ammount_of_blocks.block_4 = sum(matrixUniqueBlocksForEachUnit == 4, 'all');
ammount_of_blocks.block_5 = sum(matrixUniqueBlocksForEachUnit == 5, 'all');
ammount_of_blocks.block_6 = sum(matrixUniqueBlocksForEachUnit == 6, 'all');


%% Number of Trials (for choice and instracted)
% Excluding sides: right and left
% can only be checked for the first trial for data recorded simultaneously (!)
% If the data are not recorded at the simultaneously, check for the other triels as well

idx_block_1 = find([population(1).trial.block]==1); % indices for trial 1, block 1
num_of_success_trials.block_1 = sum([population(1).trial(idx_block_1).success]); % including instr and choice
num_of_choice_trials.block_1 = sum([population(1).trial(idx_block_1).success] == 1 & [population(1).trial(idx_block_1).choice] == 1);
num_of_instr_trials.block_1 = sum([population(1).trial(idx_block_1).success] == 1 & [population(1).trial(idx_block_1).choice] == 0);

idx_block_2 = find([population(1).trial.block]==2); % indices for trial 1, block 2
num_of_success_trials.block_2 = sum([population(1).trial(idx_block_2).success]); % including instr and choice
num_of_choice_trials.block_2 = sum([population(1).trial(idx_block_2).success] == 1 & [population(1).trial(idx_block_2).choice] == 1);
num_of_instr_trials.block_2 = sum([population(1).trial(idx_block_2).success] == 1 & [population(1).trial(idx_block_2).choice] == 0);

idx_block_3 = find([population(1).trial.block]==3); % indices for trial 1, block 3
num_of_success_trials.block_3 = sum([population(1).trial(idx_block_3).success]); % including instr and choice
num_of_choice_trials.block_3 = sum([population(1).trial(idx_block_3).success] == 1 & [population(1).trial(idx_block_3).choice] == 1);
num_of_instr_trials.block_3 = sum([population(1).trial(idx_block_3).success] == 1 & [population(1).trial(idx_block_3).choice] == 0);

idx_block_4 = find([population(1).trial.block]==4); % indices for trial 1, block 4
num_of_success_trials.block_4 = sum([population(1).trial(idx_block_4).success]); % including instr and choice
num_of_choice_trials.block_4 = sum([population(1).trial(idx_block_4).success] == 1 & [population(1).trial(idx_block_4).choice] == 1);
num_of_instr_trials.block_4 = sum([population(1).trial(idx_block_4).success] == 1 & [population(1).trial(idx_block_4).choice] == 0);

idx_block_5 = find([population(1).trial.block]==5); % indices for trial 1, block 5
num_of_success_trials.block_5 = sum([population(1).trial(idx_block_5).success]); % including instr and choice
num_of_choice_trials.block_5 = sum([population(1).trial(idx_block_5).success] == 1 & [population(1).trial(idx_block_5).choice] == 1);
num_of_instr_trials.block_5 = sum([population(1).trial(idx_block_5).success] == 1 & [population(1).trial(idx_block_5).choice] == 0);

idx_block_6 = find([population(1).trial.block]==6); % indices for trial 1, block 6
num_of_success_trials.block_6 = sum([population(1).trial(idx_block_6).success]); % including instr and choice
num_of_choice_trials.block_6 = sum([population(1).trial(idx_block_6).success] == 1 & [population(1).trial(idx_block_6).choice] == 1);
num_of_instr_trials.block_6 = sum([population(1).trial(idx_block_6).success] == 1 & [population(1).trial(idx_block_6).choice] == 0);


parts = strsplit(population(1).unit_ID, '_');
nameOfSession = strcat(parts{1}, '_', parts{2});
disp('Amount of Blocks for Session:');
disp(nameOfSession);
disp(ammount_of_blocks);

disp('Number of Success Trials:');
disp(num_of_success_trials);

disp('Number of Choice Trials:');
disp(num_of_choice_trials);

disp('Number of Instructed Trials:');
disp(num_of_instr_trials);