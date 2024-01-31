function sdndt_Sim_LIP_dPul_check_number_of_Units_Trials_in_population_file(injection, dateOfRecording)
% sdndt_Sim_LIP_dPul_Num_of_Units_and_Trials_in_population_file('1', '20210520');

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

for blockNum = uniqueBlocks
    blockStr = ['block_' num2str(blockNum)];
    
    % Initialize variables for ammount_of_units and success_trials
    ammount_of_units.(blockStr) = 0;
    num_of_success_trials.(blockStr) = 0;
    num_of_choice_trials.(blockStr) = 0;
    num_of_instr_trials.(blockStr) = 0;
    
    for unitNum = 1:numPopulations
        % Check the trials within the current population for the specified block
        blockTrials = [population(unitNum).trial.block] == blockNum;
        
        % Increment variables based on the presence of blockNum in trials
        ammount_of_units.(blockStr) = ammount_of_units.(blockStr) + sum(ismember(uniqueUnitsCell{unitNum}, blockNum));

    end
    
        % ONLY IF DATA WAS RECORDED SIMULTENEOUSLY !
        % otherwise it's impossible to sum up only for the first trial 
        % Increment variables based on the presence of blockNum in trials for success, choice, and instructed
        num_of_success_trials.(blockStr) = sum([population(1).trial.block] == blockNum & [population(1).trial.success]);
        num_of_choice_trials.(blockStr) = sum([population(1).trial.block] == blockNum & [population(1).trial.success] == 1 & [population(1).trial.choice] == 1);
        num_of_instr_trials.(blockStr) = sum([population(1).trial.block] == blockNum & [population(1).trial.success] == 1 & [population(1).trial.choice] == 0);
  end

    
    
%% Display
uniqueTargets = unique({population.target}); % Extract unique targets from the entire population
uniqueTargetsStr = ['(' strjoin(uniqueTargets, ', ') ')']; % Create a string of unique targets in round brackets
parts = strsplit(population(1).unit_ID, '_');
nameOfSession = strcat(parts{1}, '_', parts{2});
disp(['Number of Units for both targets ' uniqueTargetsStr ':']);
disp(nameOfSession);
% Display the number of units for each block
for blockNum = uniqueBlocks
    field = ['block_' num2str(blockNum)];
    if isfield(ammount_of_units, field)
        disp([num2str(ammount_of_units.(field)) ' units from ' num2str(numPopulations) ' contain ' field]);
    end
end

disp('Number of Success Trials:');
disp(num_of_success_trials);

disp('Number of Choice Trials:');
disp(num_of_choice_trials);

disp('Number of Instructed Trials:');
disp(num_of_instr_trials);