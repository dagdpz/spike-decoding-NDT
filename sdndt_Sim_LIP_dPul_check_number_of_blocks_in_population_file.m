% To run the code, it is necessary to load the population file

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
uniqueUnitsMatrix = zeros(numPopulations, maxUniqueUnits); % Initialize a matrix to store unique units for each population

% Fill the matrix with unique units for each population
for n = 1:numPopulations
    uniqueUnitsForPopulation = uniqueUnitsCell{n};
    [~, colIndices] = ismember(uniqueUnitsForPopulation, uniqueUnitsForPopulation); % Assign column indices for each unique unit
    uniqueUnitsMatrix(n, colIndices) = uniqueUnitsForPopulation; % Fill the matrix with unique units for the current population
end


ammount_of_block_1 = sum(uniqueUnitsMatrix == 1, 'all'); % Count the number of block_1 in the uniqueUnitsMatrix
ammount_of_block_2 = sum(uniqueUnitsMatrix == 2, 'all');
ammount_of_block_3 = sum(uniqueUnitsMatrix == 3, 'all');
ammount_of_block_4 = sum(uniqueUnitsMatrix == 4, 'all');
ammount_of_block_5 = sum(uniqueUnitsMatrix == 5, 'all');
ammount_of_block_6 = sum(uniqueUnitsMatrix == 6, 'all');


%% Number of Trials (for choice and instracted) 
idx_block_1 = find([population(1).trial.block]==1); % indices for trial 1, block 3
num_of_success_trials_block_1 = sum([population(1).trial(idx_block_1).success])
num_of_choice_trials_block_1 = sum([population(1).trial(idx_block_1).success] == 1 & [population(1).trial(idx_block_1).choice] == 1)
num_of_instr_trials_block_1 = sum([population(1).trial(idx_block_1).success] == 1 & [population(1).trial(idx_block_1).choice] == 0)

idx_block_3 = find([population(1).trial.block]==3); % indices for trial 1, block 3
num_of_success_trials_block_3 = sum([population(1).trial(idx_block_3).success])
num_of_choice_trials_block_3 = sum([population(1).trial(idx_block_3).success] == 1 & [population(1).trial(idx_block_3).choice] == 1)
num_of_instr_trials_block_3 = sum([population(1).trial(idx_block_3).success] == 1 & [population(1).trial(idx_block_3).choice] == 0)

idx_block_4 = find([population(1).trial.block]==4); % indices for trial 1, block 4
num_of_success_trials_block_4 = sum([population(1).trial(idx_block_4).success])
num_of_choice_trials_block_4 = sum([population(1).trial(idx_block_4).success] == 1 & [population(1).trial(idx_block_4).choice] == 1)
num_of_instr_trials_block_4 = sum([population(1).trial(idx_block_4).success] == 1 & [population(1).trial(idx_block_4).choice] == 0)
