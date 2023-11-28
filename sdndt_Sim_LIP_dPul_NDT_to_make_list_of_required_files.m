function sdndt_Sim_LIP_dPul_NDT_to_make_list_of_required_files(OUTPUT_PATH_raster)
    % sdndt_Sim_LIP_dPul_NDT_to_make_list_of_required_files('C:\Projects\Sim_dPul_LIP\NDT\raster\');

    % Make a list of files
    run('sdndt_Sim_LIP_dPul_NDT_setting');

    % Get a list of all .mat files in the directory
    files = dir(fullfile(OUTPUT_PATH_raster, '*.mat'));

    % Initialize lists for each category
    list_of_required_files.firstBlockFiles = {};
    list_of_required_files.secondBlockFiles = {};
    list_of_required_files.thirdBlockFiles = {};
    list_of_required_files.allBlocksFiles = {};
    list_of_required_files.commonBlocksFiles = {};

    % Initialize a struct to store the maximum block value and conventions for each session
    sessionBlockInfo = struct();

    % Loop through each file
    for i = 1:length(files)

        % Extract session ID and unit ID from the file name
        [sessionID, unitID, ~] = extractFileInfo(files(i).name);
        unitID = ['Unit_', unitID]; 

        % Load the data from the file
        data = load(fullfile(OUTPUT_PATH_raster, files(i).name));

        % Check if the file contains information about the first block
        if isfield(data, 'raster_site_info') && isfield(data.raster_site_info, 'block_unit') && ...
                isfield(data, 'raster_labels') && isfield(data.raster_labels, 'block') && ...
                isfield(data.raster_site_info, 'unit_ID')

            % Get the maximum and minimum block value for the session
            if isfield(sessionBlockInfo, sessionID)
                sessionBlockInfo.(sessionID).maxBlock = max(sessionBlockInfo.(sessionID).maxBlock, max(data.raster_labels.block{1}));
                sessionBlockInfo.(sessionID).minBlock = min(sessionBlockInfo.(sessionID).minBlock, min(data.raster_labels.block{1}));
            else
                sessionBlockInfo.(sessionID).maxBlock = max(data.raster_labels.block{1});
                sessionBlockInfo.(sessionID).minBlock = min(data.raster_labels.block{1});
            end

            % Save the conventions for each unit
            sessionBlockInfo.(sessionID).unitConventions.(unitID) = strsplit(data.raster_site_info.block_unit, ' ');

            % Check if it's the first block
            if  contains(files(i).name, 'block_1') 
            list_of_required_files.firstBlockFiles = [list_of_required_files.firstBlockFiles; files(i).name];
        

                % Check if it's the second block
            elseif contains(files(i).name, 'block_2')
                list_of_required_files.secondBlockFiles = [list_of_required_files.secondBlockFiles; files(i).name];

                % Check if it's the third block
            elseif contains(files(i).name, 'block_3')
                list_of_required_files.thirdBlockFiles = [list_of_required_files.thirdBlockFiles; files(i).name];
            end

            % Check if it's all blocks
            % Add the file to the allBlocksFiles list
            list_of_required_files.allBlocksFiles = [list_of_required_files.allBlocksFiles; files(i).name];

        end

    end

    % Check if it has common blocks with the same unit designations
    % Loop through each session
    sessions = fieldnames(sessionBlockInfo);
    for s = 1:numel(sessions)
        sessionID = sessions{s};

        % Get units with the maximum number of blocks
        unitsWithMaxBlocks = getUnitsWithMaxBlocks(sessionBlockInfo.(sessionID).unitConventions, sessionBlockInfo.(sessionID).maxBlock);

        % Check if units with max blocks have the same conventions
        if areConventionsSame(sessionBlockInfo.(sessionID).unitConventions, unitsWithMaxBlocks, sessionBlockInfo.(sessionID).maxBlock)
            % Include files in commonBlocksFiles
            for unitID = unitsWithMaxBlocks
                commonFiles = getCommonFiles(sessionID, unitID, files, sessionBlockInfo);
                list_of_required_files.commonBlocksFiles = [list_of_required_files.commonBlocksFiles; commonFiles(:)];
            end
        end
    end

    % Save the structure to a .mat file in the specified folder
    save(fullfile(OUTPUT_PATH_list_of_required_files, 'sdndt_Sim_LIP_dPul_NDT_list_of_required_files.mat'), 'list_of_required_files');

end

% Helper function to extract session ID, unit ID, and block number from the file name
function [sessionID, unitID, blockNumber] = extractFileInfo(fileName)
    parts = strsplit(fileName, '_');
    sessionID = strcat(parts{1}, '_', parts{2});
    unitID = parts{3};
    blockNumber = parts{8};
end


% Helper function to get units with the maximum number of blocks
function unitsWithMaxBlocks = getUnitsWithMaxBlocks(unitConventions, maxBlock)
    unitsWithMaxBlocks = {};
    fieldNames = fieldnames(unitConventions);

    for idx = 1:numel(fieldNames)
        unitID = fieldNames{idx};

        % Check the size of the unitConventions data for the current unit
        unitData = unitConventions.(unitID);

        % Count the number of non-empty cells
        nonEmptyCount = sum(~cellfun('isempty', unitData));

        % Check if the count matches the maxBlock value
        if nonEmptyCount == maxBlock
            unitsWithMaxBlocks = [unitsWithMaxBlocks, unitID];
        end
    end
end


% Helper function to check if units with max blocks have the same conventions
% function sameConventions = areConventionsSame(unitConventions, unitsWithMaxBlocks, maxBlock)
%     sameConventions = true;
%     if numel(unitsWithMaxBlocks) > 1
%         for p = 1:numel(unitsWithMaxBlocks)
%             unitID = unitsWithMaxBlocks{p};
% 
%             % Extract the data from the cell array
%             unitData = unitConventions.(unitID);
% 
%             % Check if it's a cell array and has the expected number of elements
%             if iscell(unitData) && numel(unitData) >= maxBlock
%                 % Check that the letter designations within a unit are the same
%                 if ~isequal(unitData{1:maxBlock})
%                     sameConventions = false;
%                     break;
%                 end
%             else
%                 sameConventions = false;
%                 break;
%             end
%         end
%     end
% end


% Helper function to check if units with max blocks have the same conventions
% function sameConventions = areConventionsSame(unitConventions, unitsWithMaxBlocks, maxBlock)
%     sameConventions = true;
%     if numel(unitsWithMaxBlocks) > 1
%         for p = 1:numel(unitsWithMaxBlocks)
%             unitID = unitsWithMaxBlocks{p};
% 
%             % Extract the data from the cell array
%             unitData = unitConventions.(unitID);
% 
%             % Count the number of non-empty cells
%             nonEmptyCount = sum(~cellfun('isempty', unitData));
% 
%             % Check if the count matches the maxBlock value
%             if nonEmptyCount ~= maxBlock
%                 sameConventions = false;
%                 break;
%             end
%         end
%     end
% end


% Helper function to check if units with max blocks have the same conventions
function sameConventions = areConventionsSame(unitConventions, unitsWithMaxBlocks, maxBlock)
    sameConventions = true;
    if numel(unitsWithMaxBlocks) > 1
        for p = 1:numel(unitsWithMaxBlocks)
            unitID = unitsWithMaxBlocks{p};

            % Extract the data from the cell array
            unitData = unitConventions.(unitID);

            % Filter non-empty cells and extract the letter parts
            letterParts = cellfun(@(x) extractLetterPart(x), unitData(~cellfun('isempty', unitData)), 'UniformOutput', false);

            % Count the number of non-empty cells
            nonEmptyCount = numel(letterParts);

            % Check if the count matches the maxBlock value
            if nonEmptyCount ~= maxBlock
                sameConventions = false;
                break;
            end

            % Check that the letter designations within a unit are the same
            if ~isequal(letterParts{:})
                sameConventions = false;
                break;
            end
        end
    end
end

% Helper function to extract the letter part
function letterPart = extractLetterPart(str)
    % Extract only the letter part using regular expression
    letterPart = regexprep(str, '[^a-zA-Z]', '');
end



% Helper function to get common files for a session and unit
function commonFiles = getCommonFiles(sessionID, unitID, files, sessionBlockInfo)
    commonFiles = {};
    for w = 1:length(files)
        [fileSessionID, fileUnitID, fileBlockNumber] = extractFileInfo(files(w).name);

        % Check if the session and unit match
        if strcmp(sessionID, fileSessionID)

            % Extract the numeric part of unitID
            numericUnitID = extractNumericUnitID(unitID);

            % Check if the numeric part of unitID matches fileUnitID
            if strcmp(numericUnitID, fileUnitID) %&& fileBlockNumber <= sessionBlockInfo.(sessionID).maxBlock
                commonFiles = [commonFiles, files(w).name];
            end
        end
    end
end

% Helper function to extract the numeric part of unitID
function numericUnitID = extractNumericUnitID(unitID)
    % Extract numeric part using regular expression
    numericUnitID = regexprep(unitID, '\D', '');
end