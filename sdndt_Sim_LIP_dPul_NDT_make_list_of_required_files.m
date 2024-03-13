function sdndt_Sim_LIP_dPul_NDT_make_list_of_required_files(injection, mode)
% If I plan to decode within one session:
% sdndt_Sim_LIP_dPul_NDT_make_list_of_required_files('1', 'each_session_separately');

% If I plan to decode across all sessions:
% !(To do this action, you must first have filelists for each session individually)!
% sdndt_Sim_LIP_dPul_NDT_make_list_of_required_files('0', 'merged_files_across_sessions');


% injection: '0' - control, '1' - injection
% mode: 'each_session_separately' or 'merged_files_across_sessions'


% Check if the injection parameter is valid
if ~ismember(injection, {'0', '1'})
    error('Invalid value for the injection parameter. Use ''0'' or ''1'' for control or injection.');
end

if ~ismember(mode, {'each_session_separately', 'merged_files_across_sessions'})
    error('Invalid value for the mode parameter. Use ''each_session_separately'' or ''merged_files_across_sessions''.');
end


% Call the function to get the dates
dateOfRecording = filelist_of_days_from_Simultaneous_dPul_PPC_recordings(injection);

% Call the settings function with the chosen set
[base_path, INPUT_PATH, OUTPUT_PATH_raster, OUTPUT_PATH_binned, settings] = sdndt_Sim_LIP_dPul_NDT_settings(injection);
%run('sdndt_Sim_LIP_dPul_NDT_settings');


if strcmp(mode, 'merged_files_across_sessions')
    
    % Initialize cell arrays for paths
    OUTPUT_PATH_raster_dateOfRecording = cell(1, numel(dateOfRecording));
    OUTPUT_PATH_list_of_required_files_per_day = cell(1, numel(dateOfRecording));
    
    % Create a cell array to store overlapBlocksFiles from different sessions
    first_BlocksFiles = {};
    second_BlocksFiles = {};
    third_BlocksFiles = {};
    fourth_BlocksFiles = {};
    fifth_BlocksFiles = {};
    sixth_BlocksFiles = {};
    allallBlocksFiles = {};
    allOverlapBlocksFiles = {};
    allOverlapBlocksFiles_AfterInjection = {}; 
    allOverlapBlocksFiles_BeforeInjection = {}; 
    
    
    % Create the folder for the list of required files
    OUTPUT_PATH_list_of_required_files = [OUTPUT_PATH_raster 'merged_files_across_sessions/List_of_required_files/'];
    if ~exist(OUTPUT_PATH_list_of_required_files, 'dir')
        mkdir(OUTPUT_PATH_list_of_required_files);
    end
    
    % Loop through the dates
    for fol = 1:numel(dateOfRecording)
        OUTPUT_PATH_raster_dateOfRecording{fol} = [OUTPUT_PATH_raster dateOfRecording{fol} '/'];
        OUTPUT_PATH_list_of_required_files_per_day{fol} = [OUTPUT_PATH_raster_dateOfRecording{fol} 'List_of_required_files/'];
        
        % Loop through the dates and create subfolders (optional, remove if not needed)
        %         for fol = 1:numel(dateOfRecording)
        %             dateFolder = [OUTPUT_PATH_list_of_required_files dateOfRecording{fol} '/'];
        %             if ~exist(dateFolder, 'dir')
        %                 mkdir(dateFolder);
        %             end
        %         end
        
        
        
        % Loop through the dates and load overlapBlocksFiles from each session
        
        currentSessionPath = OUTPUT_PATH_list_of_required_files_per_day{fol};
        nameOfRequiredFile = ['sdndt_Sim_LIP_dPul_NDT_' dateOfRecording{fol} '_list_of_required_files.mat'];
        currentFilePath = fullfile(currentSessionPath, nameOfRequiredFile);
        
        % Check if the file exists
        if exist(currentFilePath, 'file')
            % Load the file
            loadedData = load(currentFilePath);
            
            % Check if the variable overlapBlocksFiles exists
            if isfield(loadedData.list_of_required_files, 'overlapBlocksFiles')
                % Append to the cell array
                allOverlapBlocksFiles = [allOverlapBlocksFiles; loadedData.list_of_required_files.overlapBlocksFiles];
            end
            if isfield(loadedData.list_of_required_files, 'overlapBlocksFiles_AfterInjection')
                % Append to the cell array
                allOverlapBlocksFiles_AfterInjection = [allOverlapBlocksFiles_AfterInjection; loadedData.list_of_required_files.overlapBlocksFiles_AfterInjection];
            end
            if isfield(loadedData.list_of_required_files, 'overlapBlocksFiles_BeforeInjection')
                % Append to the cell array
                allOverlapBlocksFiles_BeforeInjection = [allOverlapBlocksFiles_BeforeInjection; loadedData.list_of_required_files.overlapBlocksFiles_BeforeInjection];
            end
            
            if isfield(loadedData.list_of_required_files, 'allBlocksFiles')
                allallBlocksFiles = [allallBlocksFiles; loadedData.list_of_required_files.allBlocksFiles];
            end
            
            if isfield(loadedData.list_of_required_files, 'firstBlockFiles')
                first_BlocksFiles = [first_BlocksFiles; loadedData.list_of_required_files.firstBlockFiles];
            end
            if isfield(loadedData.list_of_required_files, 'secondBlockFiles')
                second_BlocksFiles = [second_BlocksFiles; loadedData.list_of_required_files.secondBlockFiles];
            end
            if isfield(loadedData.list_of_required_files, 'thirdBlockFiles')
                third_BlocksFiles = [third_BlocksFiles; loadedData.list_of_required_files.thirdBlockFiles];
            end
            if isfield(loadedData.list_of_required_files, 'fourthBlockFiles')
                fourth_BlocksFiles = [fourth_BlocksFiles; loadedData.list_of_required_files.fourthBlockFiles];
            end
            if isfield(loadedData.list_of_required_files, 'fifthBlockFiles')
                fifth_BlocksFiles = [fifth_BlocksFiles; loadedData.list_of_required_files.fifthBlockFiles];
            end
            if isfield(loadedData.list_of_required_files, 'sixthBlockFiles')
                sixth_BlocksFiles = [sixth_BlocksFiles; loadedData.list_of_required_files.sixthBlockFiles];
            end
            
        end
    end
    
    % Create the variable list_of_required_files.overlapBlocksFilesAcrisSession
    list_of_required_files.firstBlockFiles = first_BlocksFiles;
    list_of_required_files.secondBlockFiles = second_BlocksFiles;
    list_of_required_files.thirdBlockFiles = third_BlocksFiles;
    list_of_required_files.fourthBlockFiles = fourth_BlocksFiles;
    list_of_required_files.fifthBlockFiles = fifth_BlocksFiles;
    list_of_required_files.sixthBlockFiles = sixth_BlocksFiles;
    list_of_required_files.overlapBlocksFiles = allOverlapBlocksFiles;
    list_of_required_files.allBlocksFiles = allallBlocksFiles;
    
    if strcmp(injection, '1')
        list_of_required_files.overlapBlocksFiles_AfterInjection = allOverlapBlocksFiles_AfterInjection;
        list_of_required_files.overlapBlocksFiles_BeforeInjection = allOverlapBlocksFiles_BeforeInjection;
    end
    
    % Save the structure to a .mat file in the specified folder
    nameOfFinalFile = ['sdndt_Sim_LIP_dPul_NDT_allSessionsBlocksFiles_list_of_required_files.mat'];
    save(fullfile(OUTPUT_PATH_list_of_required_files, nameOfFinalFile), 'list_of_required_files');
    
    
    
else % 'each_session_separately'
    % Use the provided date as a subfolder
    
    for day = 1:length(dateOfRecording)
        % Create the folder for the list of required files
        OUTPUT_PATH_raster_dateOfRecording = [OUTPUT_PATH_raster dateOfRecording{day} '/'];
        OUTPUT_PATH_list_of_required_files = [OUTPUT_PATH_raster_dateOfRecording 'List_of_required_files/'];
        if ~exist(OUTPUT_PATH_list_of_required_files, 'dir')
            mkdir(OUTPUT_PATH_list_of_required_files);
        end
        
        
        % Get a list of all .mat files in the directory
        files = dir(fullfile(OUTPUT_PATH_raster_dateOfRecording, '*.mat'));
        
        
        % Initialize lists for each category
        list_of_required_files.firstBlockFiles = {};
        list_of_required_files.secondBlockFiles = {};
        list_of_required_files.thirdBlockFiles = {};
        list_of_required_files.fourthBlockFiles = {};
        list_of_required_files.fifthBlockFiles = {};
        list_of_required_files.sixthBlockFiles = {};
        list_of_required_files.allBlocksFiles = {};
        list_of_required_files.overlapBlocksFiles = {};
        
        
        % Initialize a struct to store the maximum block value and conventions for each session
        sessionBlockInfo = struct();
        
        % Call the function to get unique blocks for the day
        uniqueBlocks = countUniqueBlocksForDay(OUTPUT_PATH_raster_dateOfRecording);
        
        
        % Loop through each file
        for i = 1:length(files)
            
            
            % Extract session ID and unit ID from the file name
            [sessionID, unitID, ~] = extractFileInfo(files(i).name);
            unitID = ['Unit_', unitID];
            
            % Load the data from the file
            data = load(fullfile(OUTPUT_PATH_raster_dateOfRecording, files(i).name));
            
            % Check if the file contains information about the first block
            if isfield(data, 'raster_site_info') && isfield(data.raster_site_info, 'block_unit') && ...
                    isfield(data, 'raster_labels') && isfield(data.raster_labels, 'block') && ...
                    isfield(data.raster_site_info, 'unit_ID')
                
                
                % Get the maximum and minimum block value, the unique block numbers for the session
                if isfield(sessionBlockInfo, sessionID)
                    sessionBlockInfo.(sessionID).maxBlock = max(sessionBlockInfo.(sessionID).maxBlock, max(data.raster_labels.block{1}));
                    sessionBlockInfo.(sessionID).minBlock = min(sessionBlockInfo.(sessionID).minBlock, min(data.raster_labels.block{1}));
                    sessionBlockInfo.(sessionID).uniqueBlocks = unique([sessionBlockInfo.(sessionID).uniqueBlocks, data.raster_labels.block{1}]);
                else
                    sessionBlockInfo.(sessionID).maxBlock = max(data.raster_labels.block{1});
                    sessionBlockInfo.(sessionID).minBlock = min(data.raster_labels.block{1});
                    sessionBlockInfo.(sessionID).uniqueBlocks = unique(data.raster_labels.block{1});
                end
                
                
                
                
                
                % Check if it's the first block
                if contains(files(i).name, 'block_1') &&  all(cellfun(@(x) all(x == 1), data.raster_labels.block))
                    list_of_required_files.firstBlockFiles = [list_of_required_files.firstBlockFiles; fullfile(files(i).folder, files(i).name)];
                    
                    
                    % Check if it's the second block
                elseif contains(files(i).name, 'block_2') && all(cellfun(@(x) all(x == 2), data.raster_labels.block))
                    list_of_required_files.secondBlockFiles = [list_of_required_files.secondBlockFiles; fullfile(files(i).folder, files(i).name)];
                    
                    % Check if it's the third block
                elseif contains(files(i).name, 'block_3')&& all(cellfun(@(x) all(x == 3), data.raster_labels.block))
                    list_of_required_files.thirdBlockFiles = [list_of_required_files.thirdBlockFiles; fullfile(files(i).folder, files(i).name)];
                    
                    % Check if it's the fourth block
                elseif contains(files(i).name, 'block_4')&& all(cellfun(@(x) all(x == 4), data.raster_labels.block))
                    list_of_required_files.fourthBlockFiles = [list_of_required_files.fourthBlockFiles; fullfile(files(i).folder, files(i).name)];
                    
                    % Check if it's the fifth block
                elseif contains(files(i).name, 'block_5')&& all(cellfun(@(x) all(x == 5), data.raster_labels.block))
                    list_of_required_files.fifthBlockFiles = [list_of_required_files.fifthBlockFiles; fullfile(files(i).folder, files(i).name)];
                    
                    % Check if it's the sixth block
                elseif contains(files(i).name, 'block_6')&& all(cellfun(@(x) all(x == 6), data.raster_labels.block))
                    list_of_required_files.sixthBlockFiles = [list_of_required_files.sixthBlockFiles; fullfile(files(i).folder, files(i).name)];
                end
                
                % Check if it's all blocks
                % Add the file to the allBlocksFiles list
                list_of_required_files.allBlocksFiles = [list_of_required_files.allBlocksFiles; fullfile(files(i).folder, files(i).name)];
                
            end % isfield(data, 'raster_site_info')
        end % i = 1:length(files)
        
       
        switch injection
            case '0'
                % Process the overlapBlocksFiles for the day
                list_of_required_files.overlapBlocksFiles = processOverlapBlocksFiles(OUTPUT_PATH_raster_dateOfRecording, OUTPUT_PATH_list_of_required_files, uniqueBlocks);
                
            case '1'
                list_of_required_files.overlapBlocksFiles = processOverlapBlocksFiles(OUTPUT_PATH_raster_dateOfRecording, OUTPUT_PATH_list_of_required_files, uniqueBlocks);
                list_of_required_files.overlapBlocksFiles_AfterInjection = processAfterInjectionOverlapBlocksFiles(list_of_required_files.overlapBlocksFiles); % select only files recorded after injection from overlapBlocksFiles
                list_of_required_files.overlapBlocksFiles_BeforeInjection = processBeforeInjectionOverlapBlocksFiles(list_of_required_files.overlapBlocksFiles);
        end
        
        % Save the structure to a .mat file in the specified folder
        nameOfFinalFile = ['sdndt_Sim_LIP_dPul_NDT_' dateOfRecording{day} '_list_of_required_files.mat'];
        save(fullfile(OUTPUT_PATH_list_of_required_files, nameOfFinalFile), 'list_of_required_files');
        
        % Display message indicating session is done
        fprintf('Session of %s is completed.\n', dateOfRecording{day});
        
    end % day = 1:length(dateOfRecording)
end % strcmp(mode, 'merged_files_across_sessions')
end   % function sdndt_Sim_LIP_dPul_NDT_make_list_of_required_files(injection, mode)







% Helper function to extract session ID, unit ID, and block number from the file name
function [sessionID, unitID, targetOfBrain, targetState, blockNumber] = extractFileInfo(fileName)
parts = strsplit(fileName, '_');
sessionID = strcat(parts{1}, '_', parts{2});
unitID = parts{3};
targetOfBrain = strcat(parts{5}, '_', parts{6});
targetState = parts{9};
blockNumber = str2double(parts{11}(1:end-4));
end

function uniqueFileGroups = groupFilesByPrefix(files)
uniqueFileGroups = struct('uniquePrefix', {}, 'files', {}, 'blocks', {});

% Loop through each file
for i = 1:length(files)
    % Extract session ID, unit ID, targetOfBrain, targetState from the file name
    [sessionID, unitID, targetOfBrain, targetState, blockNumber] = extractFileInfo(files(i).name);
    prefix = strcat(sessionID, '_', unitID, '_', targetOfBrain, '_', targetState);
    
    % Check if the prefix already exists in uniqueFileGroups
    groupIndex = find(strcmp({uniqueFileGroups.uniquePrefix}, prefix));
    
    % If the prefix is already in the list, add the file to the group
    if ~isempty(groupIndex)
        uniqueFileGroups(groupIndex).files = [uniqueFileGroups(groupIndex).files; [files(i).folder '\' files(i).name]];
        uniqueFileGroups(groupIndex).blocks = [uniqueFileGroups(groupIndex).blocks; blockNumber];
    else
        % If the prefix is not in the list, create a new entry
        uniqueFileGroups(end + 1).uniquePrefix = prefix;
        uniqueFileGroups(end).files = {[files(i).folder '\' files(i).name]};
        uniqueFileGroups(end).blocks = {blockNumber};
    end
end
end


function uniqueBlocks = countUniqueBlocksForDay(OUTPUT_PATH_raster_dateOfRecording)
% Get a list of all .mat files in the directory
files = dir(fullfile(OUTPUT_PATH_raster_dateOfRecording, '*.mat'));

uniqueBlocks = []; % Initialize a variable to store unique blocks
maxIterations = length(files);  % Set a maximum number of iterations

% Loop through each file
for i = 1:length(files)
    
    % Load the data from the file
    data = load(fullfile(OUTPUT_PATH_raster_dateOfRecording, files(i).name));
    
    % Check if the file contains information about the first block
    if isfield(data, 'raster_site_info') && isfield(data.raster_site_info, 'block_unit') && ...
            isfield(data, 'raster_labels') && isfield(data.raster_labels, 'block') && ...
            isfield(data.raster_site_info, 'unit_ID')
        
        % Update the uniqueBlocks variable
        uniqueBlocks = unique([uniqueBlocks, data.raster_labels.block{1}]);
    else
        % Handle the case where fields are missing (e.g., display a warning)
        warning('Fields missing in file: %s', files(i).name);
    end
    % Break the loop if the maximum number of iterations is reached
    if i >= maxIterations
        warning('Maximum iterations reached. Exiting the loop.');
        break;
    end
end
end

function isValid = isGroupValidBlocks(fileGroup, uniqueBlocks)
% Check if the group contains all unique block numbers
isValid = length(fileGroup.files) == length(uniqueBlocks) && ...
    all(cellfun(@(x) ismember(x, uniqueBlocks), fileGroup.blocks));
end



function overlapFiles  = processOverlapBlocksFiles(OUTPUT_PATH_raster_dateOfRecording, OUTPUT_PATH_list_of_required_files, uniqueBlocks)
% Get a list of all .mat files in the directory
files = dir(fullfile(OUTPUT_PATH_raster_dateOfRecording, '*.mat'));

% Initialize lists for each category
list_of_required_files.overlapBlocksFiles = {};

% Group files based on common prefixes
uniqueFileGroups = groupFilesByPrefix(files);

%     % Call the function to get unique blocks for the day
%     uniqueBlocks = countUniqueBlocksForDay(OUTPUT_PATH_raster_dateOfRecording);

% Filter file groups based on valid block numbers
validGroups = arrayfun(@(group) isGroupValidBlocks(group, uniqueBlocks), uniqueFileGroups);

% Extract files from valid groups
overlapFiles  = vertcat(uniqueFileGroups(validGroups).files);
end





function overlapBlocksFilesAfterInjection = processAfterInjectionOverlapBlocksFiles(overlapBlocksFiles)
% The function selects only files that were recorded after injection based on the already generated list of overlapBlocksFiles
% Initialize the output variable
overlapBlocksFilesAfterInjection = overlapBlocksFiles;

% Loop through each file in overlapBlocksFiles
for i = numel(overlapBlocksFilesAfterInjection):-1:1
    % Check if the file name contains 'block_1'
    if contains(overlapBlocksFilesAfterInjection{i}, 'block_1')
        overlapBlocksFilesAfterInjection(i) = []; % Remove files containing 'block_1'
    else
        % Load data and check if all perturbation values are 0
        data = load(overlapBlocksFilesAfterInjection{i}); % Assuming each file contains data.raster_labels.perturbation
        if all(cellfun(@(x) x == 0, data.raster_labels.perturbation))
            overlapBlocksFilesAfterInjection(i) = []; % Remove files with all perturbation values equal to 0
        end
    end
end
end

function overlapBlocksFilesBeforeInjection = processBeforeInjectionOverlapBlocksFiles(overlapBlocksFiles)
% The function selects only files that were recorded before injection based on the already generated list of overlapBlocksFiles
% Initialize the output variable
overlapBlocksFilesBeforeInjection = {};

% Loop through each file in overlapBlocksFiles
for i = 1:numel(overlapBlocksFiles)
    % Check if the file name contains 'block_1'
    if contains(overlapBlocksFiles{i}, 'block_1')
        % Load the file
        data = load(overlapBlocksFiles{i});
        % Check if all perturbation values are 0
        if all(cellfun(@(x) x == 0, data.raster_labels.perturbation))
            % Add the file to overlapBlocksFilesBeforeInjection
  overlapBlocksFilesBeforeInjection = [overlapBlocksFilesBeforeInjection; overlapBlocksFiles{i}];
        end
    end
end
end



% function specificOverlapFiles = processSpecificOverlapBlocksFiles(OUTPUT_PATH_raster_dateOfRecording, OUTPUT_PATH_list_of_required_files)
%     % Get a list of all .mat files in the directory
%     files = dir(fullfile(OUTPUT_PATH_raster_dateOfRecording, '*.mat'));
%
%     % Initialize lists for each category
%     specificOverlapFiles = {};
%
%     % Group files based on common prefixes
%     uniqueFileGroups = groupFilesByPrefix(files);
%
%     % Filter file groups based on valid block numbers (3, 4, 5, 6)
%     validGroups = arrayfun(@(group) isSpecificBlockValid(group, [3, 4, 5, 6]), uniqueFileGroups);
%
%     % Extract files from valid groups
%     specificOverlapFiles = vertcat(uniqueFileGroups(validGroups).files);
% end

% function isValid = isSpecificBlockValid(fileGroup, validBlocks)
%     % Check if the group contains all valid block numbers
%     isValid = length(fileGroup.files) == length(validBlocks) && ...
%         all(cellfun(@(x) ismember(x, validBlocks), fileGroup.blocks));
% end





% % Helper function to get units with the maximum number of blocks
% function unitsWithMaxBlocks = getUnitsWithMaxBlocks(sessionID, sessionBlockInfo) % before: uniqueBlocksLength = maxBlock
% unitsWithMaxBlocks = {};
% % Check if the sessionID is present in sessionBlockInfo
% if isfield(sessionBlockInfo, sessionID)
%     uniqueBlocks = sessionBlockInfo.(sessionID).uniqueBlocks;
%
%
%     % fieldNames = fieldnames(uniqueBlocks);
%
%     for idx = 1:numel(uniqueBlocks)
%         unitID = uniqueBlocks{idx};
%
%         % Check the size of the unitConventions data for the current unit
%         unitData = uniqueBlocks.(unitID);
%
%         %     % Count the number of non-empty cells
%         %     nonEmptyCount = sum(~cellfun('isempty', unitData));
%
%         %     % Check if the count matches the maxBlock value
%         %     if nonEmptyCount == maxBlock
%         %         unitsWithMaxBlocks = [unitsWithMaxBlocks, unitID];
%         %     end
%
%         %     % Check if the unit contains all the units specified in uniqueBlocksLength
%         %     if numel(unitData) == uniqueBlocksLength && all(ismember(unitData, num2cell(1:uniqueBlocksLength)))
%         %         unitsWithMaxBlocks = [unitsWithMaxBlocks, unitID];
%         %     end
%         % Check if the unit contains all the units specified in uniqueBlocksLength
%         % Check if the units have the same conventions
%         if areConventionsSame(sessionID, unitID, sessionBlockInfo)
%             unitsWithMaxBlocks = [unitsWithMaxBlocks, unitID];
%         end
%     end
% end
% end
%
%
% % Helper function to check if units with max blocks have the same conventions
% % function sameConventions = areConventionsSame(unitConventions, unitsWithMaxBlocks, maxBlock)
% %     sameConventions = true;
% %     if numel(unitsWithMaxBlocks) > 1
% %         for p = 1:numel(unitsWithMaxBlocks)
% %             unitID = unitsWithMaxBlocks{p};
% %
% %             % Extract the data from the cell array
% %             unitData = unitConventions.(unitID);
% %
% %             % Check if it's a cell array and has the expected number of elements
% %             if iscell(unitData) && numel(unitData) >= maxBlock
% %                 % Check that the letter designations within a unit are the same
% %                 if ~isequal(unitData{1:maxBlock})
% %                     sameConventions = false;
% %                     break;
% %                 end
% %             else
% %                 sameConventions = false;
% %                 break;
% %             end
% %         end
% %     end
% % end
%
%
% % Helper function to check if units with max blocks have the same conventions
% % function sameConventions = areConventionsSame(unitConventions, unitsWithMaxBlocks, maxBlock)
% %     sameConventions = true;
% %     if numel(unitsWithMaxBlocks) > 1
% %         for p = 1:numel(unitsWithMaxBlocks)
% %             unitID = unitsWithMaxBlocks{p};
% %
% %             % Extract the data from the cell array
% %             unitData = unitConventions.(unitID);
% %
% %             % Count the number of non-empty cells
% %             nonEmptyCount = sum(~cellfun('isempty', unitData));
% %
% %             % Check if the count matches the maxBlock value
% %             if nonEmptyCount ~= maxBlock
% %                 sameConventions = false;
% %                 break;
% %             end
% %         end
% %     end
% % end
%
%
% % Helper function to check if units with max blocks have the same conventions
% function sameConventions = areConventionsSame(unitConventions, unitsWithMaxBlocks, maxBlock)
% sameConventions = true;
%
% disp(['Number of units with max blocks: ' num2str(numel(unitsWithMaxBlocks))]);
% % Debug statement to check the content of unitsWithMaxBlocks
% disp('Contents of unitsWithMaxBlocks:');
% disp(unitsWithMaxBlocks);
%
% if numel(unitsWithMaxBlocks) > 1
%     % Initialize the flag variable
%     continueLoop = true; %new
%
%     for p = 1:numel(unitsWithMaxBlocks)
%         unitID = unitsWithMaxBlocks{p};
%
%
%         % Extract the data from the cell array
%         unitData = unitConventions.(unitID);
%
%         % Debug statement to print unitData for each unit
%     % Debug statement to print unitData for each unit
%     disp(['Unit data for ' unitID ':']);
%     disp(unitData);
%
%         % Filter non-empty cells and extract the letter parts
%         letterParts = cellfun(@(x) extractLetterPart(x), unitData(~cellfun('isempty', unitData)), 'UniformOutput', false);
%
%   % Debug statement to print letterParts for each unit
%     disp(['Letter parts for ' unitID ':']);
%     disp(letterParts);
%
%         % Count the number of non-empty cells
%         nonEmptyCount = numel(letterParts);
%
%         % Debug statement to check the value of nonEmptyCount
%     disp(['Non-empty count for unitID ' unitID ': ' num2str(nonEmptyCount)]);
%
%
%         % Check if the count matches the maxBlock value
%         if nonEmptyCount ~= maxBlock
%             sameConventions = false;
%             continueLoop = false;  % break;
%         end
%
%         % Check that the letter designations within a unit are the same
%         if ~isequal(letterParts{:})
%             sameConventions = false;
%             continueLoop = false; % break;
%         end
%
%         % Check the flag variable to decide whether to continue the loop
%         if ~continueLoop
%             break;
%         end
%
%         % Debugging output for letterParts
%         disp(['Inside loop - Iteration p = ' num2str(p)]);
%         disp(['unitID = ' unitID]);
%         disp(['letterParts = ']);
%         disp(letterParts);
%
%
%     end % p = 1:numel(unitsWithMaxBlocks)
% end % if numel(unitsWithMaxBlocks) > 1
% end
%
% % Helper function to extract the letter part
% function letterPart = extractLetterPart(str)
% % Extract only the letter part using regular expression
% disp(['Input to extractLetterPart: ' str]);
% letterPart = regexprep(str, '[^a-zA-Z]', '');
% disp(['Output from extractLetterPart: ' letterPart]);
%
% % Handle the case where the result is empty (e.g., if the input is numeric)
% if isempty(letterPart)
%     letterPart = '';  % Set it to an empty string or handle it according to your needs
% end
% end
%
%
%
% % Helper function to get common files for a session and unit
% function overlapFiles = getOverlapFiles(sessionID, unitID, files, sessionBlockInfo)
% overlapFiles = {};
% for w = 1:length(files)
%     [fileSessionID, fileUnitID, fileBlockNumber] = extractFileInfo(files(w).name);
%
%     % Check if the session and unit match
%     if strcmp(sessionID, fileSessionID)
%
%         % Extract the numeric part of unitID
%         numericUnitID = extractNumericUnitID(unitID);
%
%         % Check if the numeric part of unitID matches fileUnitID
%          if strcmp(numericUnitID, fileUnitID) % && fileBlockNumber <= sessionBlockInfo.(sessionID).maxBlock
%             overlapFiles = [overlapFiles;  fullfile(files(w).folder, files(w).name)];
%         end
%     end
% end
% end
%
% % Helper function to extract the numeric part of unitID
% function numericUnitID = extractNumericUnitID(unitID)
% % Extract numeric part using regular expression
% numericUnitID = regexprep(unitID, '\D', '');
%
% end