function sdndt_Sim_LIP_dPul_NDT_make_list_of_required_files(monkey, injection, mode)
% If I plan to decode within one session:
% sdndt_Sim_LIP_dPul_NDT_make_list_of_required_files('Bacchus', '1', 'each_session_separately');

% If I plan to decode across all sessions:
% !(To do this action, you must first have filelists for each session individually)!
% sdndt_Sim_LIP_dPul_NDT_make_list_of_required_files('Bacchus', '0', 'merged_files_across_sessions');


% injection: '0' - control, '1' - injection (Inactivation experiment)
%            '2' - Functional interaction experiment (dPul and LIP)
% mode: 'each_session_separately' or 'merged_files_across_sessions'


%% Check if the injection parameter is valid
if ~ismember(injection, {'0', '1', '2'})
    error('Invalid value for the injection parameter. Use ''0'', ''1'' or ''2'' for control or injection.');
end

if ~ismember(mode, {'each_session_separately', 'merged_files_across_sessions'})
    error('Invalid value for the mode parameter. Use ''each_session_separately'' or ''merged_files_across_sessions''.');
end


%% Define the session types based on the injection value
if strcmp(injection, '1')
    if strcmp(monkey, 'Linus')
        typeOfSessions = {'left', 'right', 'all'}; % For control and injection experiments
    elseif strcmp(monkey, 'Bacchus')
        typeOfSessions = {'right'};
    end
elseif  strcmp(injection, '0') || strcmp(injection, '2')
    typeOfSessions = {''}; % For the functional interaction experiment
else
    error('Invalid injection value. Use ''0'', ''1'', or ''2''.');
end

% Initialize progress bar
h = waitbar(0, 'Processing Sessions...');
numTypesOfSessions = numel(typeOfSessions); % Get the total number of session types

% Initialize total session count
totalSessions = 0;

% Loop through each session type if injection is '1'
if strcmp(injection, '1')
    for k = 1:numTypesOfSessions
        currentType = typeOfSessions{k};
        % Call the function to generate lists of required files for the current session type
        dateOfRecording = filelist_of_days_from_Simultaneous_dPul_PPC_recordings(monkey, injection, currentType);
        
        % Increment total session count by the number of sessions for this type
        totalSessions = totalSessions + numel(dateOfRecording);
        
        % Call additional functions and process the data for each session type
        sdndt_Sim_LIP_dPul_NDT_make_list_of_required_files_inner(monkey, injection, mode, currentType, dateOfRecording);
        
        % Calculate progress
        %progress = k / numTypesOfSessions;
        progress = (k / numTypesOfSessions) * (totalSessions / length(dateOfRecording));
       
        waitbar(progress, h, sprintf('Processing... %.2f%%', progress * 100)); % Update progress bar
    end
else
    % Call the function to generate lists of required files
    dateOfRecording = filelist_of_days_from_Simultaneous_dPul_PPC_recordings(monkey, injection, typeOfSessions);
    
    % Increment total session count by the number of sessions for this type
    totalSessions = totalSessions + numel(dateOfRecording);
    
    % Call additional functions and process the data
    sdndt_Sim_LIP_dPul_NDT_make_list_of_required_files_inner(monkey, injection, mode, currentType, dateOfRecording); % !! check: (currentType) or ('') will work
    
    waitbar(1, h, 'Processing Completed.');   % Update progress bar
end

close(h); % Close progress bar
end   % function sdndt_Sim_LIP_dPul_NDT_make_list_of_required_files(injection, mode)





function sdndt_Sim_LIP_dPul_NDT_make_list_of_required_files_inner(monkey, injection, mode, currentType, dateOfRecording)
%% Call the additional functions
% Call the function to get the dates

% Call the settings function with the chosen set
[base_path, INPUT_PATH, OUTPUT_PATH_raster, OUTPUT_PATH_binned, monkey_prefix, settings] = sdndt_Sim_LIP_dPul_NDT_settings(monkey, injection, currentType);
%run('sdndt_Sim_LIP_dPul_NDT_settings');


%% Run getting lists of files depending on mods
if strcmp(mode, 'merged_files_across_sessions')
    
    % Initialize cell arrays for paths
    OUTPUT_PATH_raster_dateOfRecording = cell(1, numel(dateOfRecording));
    OUTPUT_PATH_list_of_required_files_per_day = cell(1, numel(dateOfRecording));
    
    % Create a cell array to store overlapBlocksFiles from different sessions
    all_first_BlocksFiles = {};
    all_second_BlocksFiles = {};
    all_third_BlocksFiles = {};
    all_fourth_BlocksFiles = {};
    all_fifth_BlocksFiles = {};
    all_sixth_BlocksFiles = {};
    allBlocksFiles = {};
    allBlocksFiles_AfterInjection = {};
    allBlocksFiles_BeforeInjection = {};
    OverlapBlocksFiles = {};
    OverlapBlocksFiles_1_3_4 = {};
    OverlapBlocksFiles_AfterInjection = {};
    OverlapBlocksFiles_BeforeInjection = {};
    OverlapBlocksFiles_AfterInjection_3_4 = {};
    OverlapBlocksFiles_BeforeInjection_3_4 = {};
    overlap_first_BlocksFiles = {};
    overlap_second_BlocksFiles = {};
    overlap_third_BlocksFiles = {};
    overlap_fourth_BlocksFiles = {};
    overlap_fifth_BlocksFiles = {};
    overlap_sixth_BlocksFiles = {};
    
    
    % Create the folder for the list of required files
    OUTPUT_PATH_list_of_required_files = [OUTPUT_PATH_raster monkey_prefix 'merged_files_across_sessions/List_of_required_files/'];
    if ~exist(OUTPUT_PATH_list_of_required_files, 'dir')
        mkdir(OUTPUT_PATH_list_of_required_files);
    end
    
    % Loop through the dates
    for fol = 1:numel(dateOfRecording)
        OUTPUT_PATH_raster_dateOfRecording{fol} = [OUTPUT_PATH_raster monkey_prefix dateOfRecording{fol} '/'];
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
                OverlapBlocksFiles = [OverlapBlocksFiles; loadedData.list_of_required_files.overlapBlocksFiles];
            end
              if isfield(loadedData.list_of_required_files, 'overlapBlocksFiles_1_3_4')
                % Append to the cell array
                OverlapBlocksFiles_1_3_4 = [OverlapBlocksFiles_1_3_4; loadedData.list_of_required_files.overlapBlocksFiles_1_3_4];
            end
            if isfield(loadedData.list_of_required_files, 'overlapBlocksFiles_AfterInjection')
                % Append to the cell array
                OverlapBlocksFiles_AfterInjection = [OverlapBlocksFiles_AfterInjection; loadedData.list_of_required_files.overlapBlocksFiles_AfterInjection];
            end
            if isfield(loadedData.list_of_required_files, 'overlapBlocksFiles_BeforeInjection')
                % Append to the cell array
                OverlapBlocksFiles_BeforeInjection = [OverlapBlocksFiles_BeforeInjection; loadedData.list_of_required_files.overlapBlocksFiles_BeforeInjection];
            end
            if isfield(loadedData.list_of_required_files, 'overlapBlocksFiles_AfterInjection_3_4')
                % Append to the cell array
                OverlapBlocksFiles_AfterInjection_3_4 = [OverlapBlocksFiles_AfterInjection_3_4; loadedData.list_of_required_files.overlapBlocksFiles_AfterInjection_3_4];
            end
            if isfield(loadedData.list_of_required_files, 'overlapBlocksFiles_BeforeInjection_3_4')
                % Append to the cell array
                OverlapBlocksFiles_BeforeInjection_3_4 = [OverlapBlocksFiles_BeforeInjection_3_4; loadedData.list_of_required_files.overlapBlocksFiles_BeforeInjection_3_4];
            end
            
            if isfield(loadedData.list_of_required_files, 'allBlocksFiles')
                allBlocksFiles = [allBlocksFiles; loadedData.list_of_required_files.allBlocksFiles];
            end
            
            if isfield(loadedData.list_of_required_files, 'allBlocksFiles_AfterInjection')
                % Append to the cell array
                allBlocksFiles_AfterInjection = [allBlocksFiles_AfterInjection; loadedData.list_of_required_files.allBlocksFiles_AfterInjection];
            end
            if isfield(loadedData.list_of_required_files, 'allBlocksFiles_BeforeInjection')
                % Append to the cell array
                allBlocksFiles_BeforeInjection = [allBlocksFiles_BeforeInjection; loadedData.list_of_required_files.allBlocksFiles_BeforeInjection];
            end
            
            
            if isfield(loadedData.list_of_required_files, 'all_firstBlockFiles')
                all_first_BlocksFiles = [all_first_BlocksFiles; loadedData.list_of_required_files.all_firstBlockFiles];
            end
            if isfield(loadedData.list_of_required_files, 'all_secondBlockFiles')
                all_second_BlocksFiles = [all_second_BlocksFiles; loadedData.list_of_required_files.all_secondBlockFiles];
            end
            if isfield(loadedData.list_of_required_files, 'all_thirdBlockFiles')
                all_third_BlocksFiles = [all_third_BlocksFiles; loadedData.list_of_required_files.all_thirdBlockFiles];
            end
            if isfield(loadedData.list_of_required_files, 'all_fourthBlockFiles')
                all_fourth_BlocksFiles = [all_fourth_BlocksFiles; loadedData.list_of_required_files.all_fourthBlockFiles];
            end
            if isfield(loadedData.list_of_required_files, 'all_fifthBlockFiles')
                all_fifth_BlocksFiles = [all_fifth_BlocksFiles; loadedData.list_of_required_files.all_fifthBlockFiles];
            end
            if isfield(loadedData.list_of_required_files, 'all_sixthBlockFiles')
                all_sixth_BlocksFiles = [all_sixth_BlocksFiles; loadedData.list_of_required_files.all_sixthBlockFiles];
            end
            
            if isfield(loadedData.list_of_required_files, 'overlap_firstBlockFiles')
                overlap_first_BlocksFiles = [overlap_first_BlocksFiles; loadedData.list_of_required_files.overlap_firstBlockFiles];
            end
            if isfield(loadedData.list_of_required_files, 'overlap_secondBlockFiles')
                overlap_second_BlocksFiles = [overlap_second_BlocksFiles; loadedData.list_of_required_files.overlap_secondBlockFiles];
            end
            if isfield(loadedData.list_of_required_files, 'overlap_thirdBlockFiles')
                overlap_third_BlocksFiles = [overlap_third_BlocksFiles; loadedData.list_of_required_files.overlap_thirdBlockFiles];
            end
            if isfield(loadedData.list_of_required_files, 'overlap_fourthBlockFiles')
                overlap_fourth_BlocksFiles = [overlap_fourth_BlocksFiles; loadedData.list_of_required_files.overlap_fourthBlockFiles];
            end
            if isfield(loadedData.list_of_required_files, 'overlap_fifthBlockFiles')
                overlap_fifth_BlocksFiles = [overlap_fifth_BlocksFiles; loadedData.list_of_required_files.overlap_fifthBlockFiles];
            end
            if isfield(loadedData.list_of_required_files, 'overlap_sixthBlockFiles')
                overlap_sixth_BlocksFiles = [overlap_sixth_BlocksFiles; loadedData.list_of_required_files.overlap_sixthBlockFiles];
            end
            
        end
    end
    
    % Create the variable list_of_required_files.overlapBlocksFilesAcrisSession
    list_of_required_files.all_firstBlockFiles = all_first_BlocksFiles;
    list_of_required_files.all_secondBlockFiles = all_second_BlocksFiles;
    list_of_required_files.all_thirdBlockFiles = all_third_BlocksFiles;
    list_of_required_files.all_fourthBlockFiles = all_fourth_BlocksFiles;
    list_of_required_files.all_fifthBlockFiles = all_fifth_BlocksFiles;
    list_of_required_files.all_sixthBlockFiles = all_sixth_BlocksFiles;
    
    list_of_required_files.overlap_firstBlockFiles = overlap_first_BlocksFiles;
    list_of_required_files.overlap_secondBlockFiles = overlap_second_BlocksFiles;
    list_of_required_files.overlap_thirdBlockFiles = overlap_third_BlocksFiles;
    list_of_required_files.overlap_fourthBlockFiles = overlap_fourth_BlocksFiles;
    list_of_required_files.overlap_fifthBlockFiles = overlap_fifth_BlocksFiles;
    list_of_required_files.overlap_sixthBlockFiles = overlap_sixth_BlocksFiles;
    
    list_of_required_files.overlapBlocksFiles = OverlapBlocksFiles;
    list_of_required_files.overlapBlocksFiles_1_3_4 = OverlapBlocksFiles_1_3_4;
    list_of_required_files.allBlocksFiles = allBlocksFiles;
    
    if strcmp(injection, '1')
        list_of_required_files.overlapBlocksFiles_AfterInjection = OverlapBlocksFiles_AfterInjection;
        list_of_required_files.overlapBlocksFiles_BeforeInjection = OverlapBlocksFiles_BeforeInjection;
        list_of_required_files.overlapBlocksFiles_AfterInjection_3_4 = OverlapBlocksFiles_AfterInjection_3_4;
        list_of_required_files.overlapBlocksFiles_BeforeInjection_3_4 = OverlapBlocksFiles_BeforeInjection_3_4;
        list_of_required_files.allBlocksFiles_AfterInjection = allBlocksFiles_AfterInjection;
        list_of_required_files.allBlocksFiles_BeforeInjection = allBlocksFiles_BeforeInjection;
    end
    
    % Save the structure to a .mat file in the specified folder
    nameOfFinalFile = ['sdndt_Sim_LIP_dPul_NDT_allSessionsBlocksFiles_list_of_required_files.mat'];
    save(fullfile(OUTPUT_PATH_list_of_required_files, nameOfFinalFile), 'list_of_required_files');
    
    
    
else % 'each_session_separately'
    % Use the provided date as a subfolder
    
    for day = 1:length(dateOfRecording)
        % Create the folder for the list of required files
        OUTPUT_PATH_raster_dateOfRecording = [OUTPUT_PATH_raster monkey_prefix dateOfRecording{day} '/'];
        OUTPUT_PATH_list_of_required_files = [OUTPUT_PATH_raster_dateOfRecording 'List_of_required_files/'];
        if ~exist(OUTPUT_PATH_list_of_required_files, 'dir')
            mkdir(OUTPUT_PATH_list_of_required_files);
        end
        
        
        % Get a list of all .mat files in the directory
        files = dir(fullfile(OUTPUT_PATH_raster_dateOfRecording, '*.mat'));
        
        
        % Initialize lists for each category
        list_of_required_files.all_firstBlockFiles = {};
        list_of_required_files.all_secondBlockFiles = {};
        list_of_required_files.all_thirdBlockFiles = {};
        list_of_required_files.all_fourthBlockFiles = {};
        list_of_required_files.all_fifthBlockFiles = {};
        list_of_required_files.all_sixthBlockFiles = {};
        list_of_required_files.allBlocksFiles = {};
        % list_of_required_files.allBlocksFiles_AfterInjection_3_4 = {};
        list_of_required_files.overlapBlocksFiles = {};
        list_of_required_files.overlapBlocksFiles_1_3_4 = {};
        
        
        % Initialize a struct to store the maximum block value and conventions for each session
        sessionBlockInfo = struct();
        
        % Call the function to get unique blocks for the day
        uniqueBlocks = countUniqueBlocksForDay(OUTPUT_PATH_raster_dateOfRecording);
        Blocks_1_2_3 = [1 3 4];
        
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
                    list_of_required_files.all_firstBlockFiles = [list_of_required_files.all_firstBlockFiles; fullfile(files(i).folder, files(i).name)];
                    
                    
                    % Check if it's the second block
                elseif contains(files(i).name, 'block_2') && all(cellfun(@(x) all(x == 2), data.raster_labels.block))
                    list_of_required_files.all_secondBlockFiles = [list_of_required_files.all_secondBlockFiles; fullfile(files(i).folder, files(i).name)];
                    
                    % Check if it's the third block
                elseif contains(files(i).name, 'block_3')&& all(cellfun(@(x) all(x == 3), data.raster_labels.block))
                    list_of_required_files.all_thirdBlockFiles = [list_of_required_files.all_thirdBlockFiles; fullfile(files(i).folder, files(i).name)];
                    
                    % Check if it's the fourth block
                elseif contains(files(i).name, 'block_4')&& all(cellfun(@(x) all(x == 4), data.raster_labels.block))
                    list_of_required_files.all_fourthBlockFiles = [list_of_required_files.all_fourthBlockFiles; fullfile(files(i).folder, files(i).name)];
                    
                    % Check if it's the fifth block
                elseif contains(files(i).name, 'block_5')&& all(cellfun(@(x) all(x == 5), data.raster_labels.block))
                    list_of_required_files.all_fifthBlockFiles = [list_of_required_files.all_fifthBlockFiles; fullfile(files(i).folder, files(i).name)];
                    
                    % Check if it's the sixth block
                elseif contains(files(i).name, 'block_6')&& all(cellfun(@(x) all(x == 6), data.raster_labels.block))
                    list_of_required_files.all_sixthBlockFiles = [list_of_required_files.all_sixthBlockFiles; fullfile(files(i).folder, files(i).name)];
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
                list_of_required_files.overlapBlocksFiles_1_3_4 = findBlocksFiles_1_3_4(OUTPUT_PATH_raster_dateOfRecording, list_of_required_files.allBlocksFiles,  Blocks_1_2_3); % find units that are present in blocks 1, 3, 4 (we are not interested in other blocks such as 5 and 6). 
                
                list_of_required_files.overlapBlocksFiles_BeforeInjection = processBeforeInjectionOverlapBlocksFiles(list_of_required_files.overlapBlocksFiles);
                list_of_required_files.overlapBlocksFiles_AfterInjection = processAfterInjectionOverlapBlocksFiles(list_of_required_files.overlapBlocksFiles); % select only files recorded after injection from overlapBlocksFiles
                
                list_of_required_files.overlapBlocksFiles_BeforeInjection_3_4 = processBeforeInjectionOverlapBlocksFiles(list_of_required_files.overlapBlocksFiles_1_3_4); % find units before inactivation (in block 1) that are also present in blocks 3 and 4. 
                list_of_required_files.overlapBlocksFiles_AfterInjection_3_4 = processAfterInjectionOverlapBlocksFiles(list_of_required_files.overlapBlocksFiles_1_3_4); % find units after inactivation (in block 3 and 4) that are also present in blocks 1.
                
                list_of_required_files.allBlocksFiles_BeforeInjection = list_of_required_files.all_firstBlockFiles;
                list_of_required_files.allBlocksFiles_AfterInjection = processAfterInjectionAllBlocksFiles(list_of_required_files.allBlocksFiles);
       
%                  % Add the file to the all_3_4_BlockFiles list
%                 if all(cellfun(@(x) any(x == [3 4]), data.raster_labels.block))
%                     list_of_required_files.allBlocksFiles_AfterInjection_3_4 = [list_of_required_files.all_3_4_BlockFiles; fullfile(files(i).folder, files(i).name)];
%                 end
        end
        
        list_of_required_files.overlap_firstBlockFiles = processSpecificOverlapBlocksFiles(list_of_required_files.overlapBlocksFiles,'block_1');
        list_of_required_files.overlap_secondBlockFiles = processSpecificOverlapBlocksFiles(list_of_required_files.overlapBlocksFiles,'block_2');
        list_of_required_files.overlap_thirdBlockFiles = processSpecificOverlapBlocksFiles(list_of_required_files.overlapBlocksFiles,'block_3');
        list_of_required_files.overlap_fourthBlockFiles = processSpecificOverlapBlocksFiles(list_of_required_files.overlapBlocksFiles, 'block_4');
        list_of_required_files.overlap_fifthBlockFiles = processSpecificOverlapBlocksFiles(list_of_required_files.overlapBlocksFiles,'block_5');
        list_of_required_files.overlap_sixthBlockFiles = processSpecificOverlapBlocksFiles(list_of_required_files.overlapBlocksFiles, 'block_6');
        
        % Save the structure to a .mat file in the specified folder
        nameOfFinalFile = ['sdndt_Sim_LIP_dPul_NDT_' dateOfRecording{day} '_list_of_required_files.mat'];
        save(fullfile(OUTPUT_PATH_list_of_required_files, nameOfFinalFile), 'list_of_required_files');
        
        % Display message indicating session is done
        fprintf('Session of %s is completed.\n', dateOfRecording{day});
        
    end % day = 1:length(dateOfRecording)
end % strcmp(mode, 'merged_files_across_sessions')
end   % function sdndt_Sim_LIP_dPul_NDT_make_list_of_required_files_inner(injection, mode)







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


function overlapBlocksFiles_1_3_4 = findBlocksFiles_1_3_4(OUTPUT_PATH_raster_dateOfRecording, allBlocksFiles, uniqueBlocks)
overlapBlocksFiles_1_3_4 = allBlocksFiles ;

% Loop through each file in overlapBlocksFiles
for i = numel(overlapBlocksFiles_1_3_4):-1:1
    if contains(overlapBlocksFiles_1_3_4{i}, 'block_5') || contains(overlapBlocksFiles_1_3_4{i}, 'block_6')
    overlapBlocksFiles_1_3_4(i) = [];  % Remove files containing 'block_5'
    end
end


% Extract prefixes from file names
for i = 1:numel(overlapBlocksFiles_1_3_4)
    [~, filename, ~] = fileparts(overlapBlocksFiles_1_3_4{i});
    parts = strsplit(filename, '_');
    prefix = strjoin(parts(1:end-1), '_'); % Extract the prefix
    prefixes{i} = prefix;
end

% Remove duplicates
uniquePrefixes = unique(prefixes);

% Initialize a cell array to store valid file names
validFileNames = {};

% Loop through each unique prefix
for prefixIdx = 1:numel(uniquePrefixes)
    prefix = uniquePrefixes{prefixIdx};
    
    % Extract file names from overlapBlocksFiles_1_3_4
    overlapFileNames = cellfun(@(x) split(x, filesep), overlapBlocksFiles_1_3_4, 'UniformOutput', false);
    overlapFileNames = cellfun(@(x) x{end}, overlapFileNames, 'UniformOutput', false);
    
    % Check if the file names start with the prefix
    files_with_prefix = overlapBlocksFiles_1_3_4(startsWith(overlapFileNames, [prefix, '_']));
    
    % Check if files with blocks 1, 3, and 4 exist for this prefix
    if any(contains(files_with_prefix, 'block_1')) && any(contains(files_with_prefix, 'block_3')) && any(contains(files_with_prefix, 'block_4'))
        % Add valid files to the list
        validFileNames = [validFileNames, files_with_prefix];
    end
end

overlapBlocksFiles_1_3_4 = validFileNames(:); % Assign valid file names to overlapBlocksFiles_1_3_4
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

function SpecificOverlapBlocksFiles = processSpecificOverlapBlocksFiles(overlapBlocksFiles, required_block)
    % Initialize the output variable
    SpecificOverlapBlocksFiles = {};

    % Loop through each file in overlapBlocksFiles
    for i = 1:numel(overlapBlocksFiles)
        % Check if the file name contains the required block
        if contains(overlapBlocksFiles{i}, required_block)
            % Load the file
            data = load(overlapBlocksFiles{i});
            
            % Define your new condition here
            % For example, check if any perturbation value is greater than 0
         %   if any(cellfun(@(x) x > 0, data.raster_labels.perturbation))
                % Add the file to SpecificOverlapBlocksFiles
                SpecificOverlapBlocksFiles = [SpecificOverlapBlocksFiles; overlapBlocksFiles{i}];
          %  end
        end
    end
end



function allBlocksFilesAfterInjection = processAfterInjectionAllBlocksFiles(allBlocksFiles)
% The function selects only files that were recorded after injection based on the already generated list of overlapBlocksFiles
% Initialize the output variable
allBlocksFilesAfterInjection = allBlocksFiles;

% Loop through each file in overlapBlocksFiles
for i = numel(allBlocksFilesAfterInjection):-1:1
    % Check if the file name contains 'block_1'
    if contains(allBlocksFilesAfterInjection{i}, 'block_1')
        allBlocksFilesAfterInjection(i) = []; % Remove files containing 'block_1'
    else
        % Load data and check if all perturbation values are 0
        data = load(allBlocksFilesAfterInjection{i}); % Assuming each file contains data.raster_labels.perturbation
        if all(cellfun(@(x) x == 0, data.raster_labels.perturbation))
            allBlocksFilesAfterInjection(i) = []; % Remove files with all perturbation values equal to 0
        end
    end
end
end

