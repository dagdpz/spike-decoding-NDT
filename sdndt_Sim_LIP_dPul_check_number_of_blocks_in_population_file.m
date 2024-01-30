% Assuming population is your data structure

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