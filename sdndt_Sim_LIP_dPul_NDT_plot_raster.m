function [raster_data, raster_labels, raster_site_info] = sdndt_Sim_LIP_dPul_NDT_plot_raster(monkey, injection)
% sdndt_Sim_LIP_dPul_NDT_plot_raster('Bacchus', '1');




%%
% Start timing the execution
startTime = tic;

%% Define the list of required files
listOfRequiredFiles = {%'firstBlockFiles', 'secondBlockFiles', ...
    %     'thirdBlockFiles', 'fourthBlockFiles', ...
    %     'fifthBlockFiles', 'sixthBlockFiles', ...
     'overlapBlocksFiles_BeforeInjection',          'overlapBlocksFiles_AfterInjection' %, ...
    %'overlapBlocksFiles_BeforeInjection_3_4',  'overlapBlocksFiles_AfterInjection_3_4'%, ...
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

% if strcmp(typeOfDecoding, 'each_session_separately')
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
% else % strcmp(typeOfDecoding, 'merged_files_across_sessions')
%     datesForSessions = {''};
%     totalIterations = 1; % For merged_files_across_sessions, only one iteration per combination
% end


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
                            
                            
                            %    if strcmp(typeOfDecoding, 'each_session_separately') % typeOfDecoding
                            
                            current_set_of_date = datesForSessions{j}; % Get the corresponding set of dates !!!!!
                            % totalIterations = totalIterations + numel(current_set_of_date) * numLabels * numApproach * numFieldNames;
                            
                            
                            for numDays = 1:numel(current_set_of_date)
                                current_date = current_set_of_date{numDays};
                                
                                % Call the internal decoding function for each day
                                sdndt_Sim_LIP_dPul_NDT_plot_raster_internal(monkey, current_injection, current_type_of_session, current_date, current_target_brain_structure, target_state, current_label, current_approach, current_file); % typeOfSessions{j}
                                
                                % Update progress for each iteration
                                overallProgress = overallProgress + 1;
                                waitbar(overallProgress / totalIterations, h, sprintf('Processing... %.2f%%', overallProgress / totalIterations * 100));
                                
                            end
                            
                            
                            %                             else % strcmp(typeOfDecoding, 'merged_files_across_sessions')
                            %                                 current_date = [];
                            %                                 % Call the internal decoding function only once
                            %                                 sdndt_Sim_LIP_dPul_NDT_plot_raster_internal(monkey, current_injection, current_type_of_session, current_date, typeOfDecoding, current_target_brain_structure, target_state, current_label, current_approach, current_file);
                            %
                            %                                 % Update progress for each iteration
                            %                                 overallProgress = overallProgress + 1;
                            %                                 waitbar(overallProgress / totalIterations, h, sprintf('Processing... %.2f%%', overallProgress / totalIterations * 100));
                            %
                            
                            % end % if strcmp(typeOfDecoding, 'each_session_separately')
                            
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







function sdndt_Sim_LIP_dPul_NDT_plot_raster_internal(monkey, injection, typeOfSessions, dateOfRecording, target_brain_structure, target_state, given_labels_to_use, given_approach, givenListOfRequiredFiles)



% Call the function to get the dates
allDateOfRecording = filelist_of_days_from_Simultaneous_dPul_PPC_recordings(monkey, injection, typeOfSessions);


% Call the settings function with the chosen set
[base_path, INPUT_PATH, OUTPUT_PATH_raster, OUTPUT_PATH_binned, monkey_prefix, settings] = sdndt_Sim_LIP_dPul_NDT_settings(monkey, injection, typeOfSessions);
% run('sdndt_Sim_LIP_dPul_NDT_settings');


% Load required files for each session or merged files
OUTPUT_PATH_list_of_required_files = [OUTPUT_PATH_raster monkey_prefix dateOfRecording '/List_of_required_files/sdndt_Sim_LIP_dPul_NDT_' dateOfRecording '_list_of_required_files.mat'];
load(OUTPUT_PATH_list_of_required_files);

% Initialize an array of structures to store the results
grouping_folder = struct('block_grouping_folder', {}, 'num_block_suffix', {});

num_block = {};  % Initialize as an empty cell array

for s = 1:size(givenListOfRequiredFiles, 1)
    
    currentFile = strtrim(givenListOfRequiredFiles(s, :));  % Extract and trim the current row
    
    
    % Extract the block number suffix from givenListOfRequiredFiles
    if strcmp(currentFile, 'firstBlockFiles')
        num_block_suffix = '1';
        block_grouping_folder = sprintf('%sBy_block', block_grouping_folder_prefix);
    elseif strcmp(currentFile, 'secondBlockFiles')
        num_block_suffix = '2';
        block_grouping_folder = sprintf('%sBy_block', block_grouping_folder_prefix);
    elseif strcmp(currentFile, 'thirdBlockFiles')
        num_block_suffix = '3';
        block_grouping_folder = sprintf('%sBy_block', block_grouping_folder_prefix);
    elseif strcmp(currentFile, 'fourthBlockFiles')
        num_block_suffix = '4';
        block_grouping_folder = sprintf('%sBy_block', block_grouping_folder_prefix);
    elseif strcmp(currentFile, 'fifthBlockFiles')
        num_block_suffix = '5';
        block_grouping_folder = sprintf('%sBy_block', block_grouping_folder_prefix);
    elseif strcmp(currentFile, 'sixthBlockFiles')
        num_block_suffix = '6';
        block_grouping_folder = sprintf('%sBy_block', block_grouping_folder_prefix);
    elseif strcmp(currentFile, 'overlapBlocksFiles_BeforeInjection')
        % For overlap blocks before injection
        block_grouping_folder = 'Overlap_blocks_BeforeInjection/';
        num_block_suffix = '';
    elseif strcmp(currentFile, 'overlapBlocksFiles_AfterInjection')
        % For overlap blocks after injection
        block_grouping_folder = 'Overlap_blocks_AfterInjection/';
        num_block_suffix = '';
    elseif strcmp(currentFile, 'overlapBlocksFiles_BeforeInjection_3_4')
        % For overlap blocks before injection
        block_grouping_folder = 'Overlap_blocks_BeforeInjection_3_4/';
        num_block_suffix = '';
    elseif strcmp(currentFile, 'overlapBlocksFiles_AfterInjection_3_4')
        % For overlap blocks after injection
        block_grouping_folder = 'Overlap_blocks_AfterInjection_3_4/';
        num_block_suffix = '';
    elseif strcmp(currentFile, 'allBlocksFiles_BeforeInjection')
        % For all blocks before injection
        block_grouping_folder = 'All_blocks_BeforeInjection/';
        num_block_suffix = '';
    elseif strcmp(currentFile, 'allBlocksFiles_AfterInjection')
        % For all blocks after injection
        block_grouping_folder = 'All_blocks_AfterInjection/';
        num_block_suffix = '';
    else
        error('Unknown value for givenListOfRequiredFiles.');
    end
    
    % Save the results in the structure array
    grouping_folder(s).block_grouping_folder = block_grouping_folder;
    grouping_folder(s).num_block_suffix = num_block_suffix;
    
    % Construct num_block
    if isempty(grouping_folder(s).num_block_suffix)
        num_block{s} = '';  % Use curly braces for cell array assignment
    else
        % For specific block files, construct num_block
        num_block{s} = sprintf('block_%s', num_block_suffix);
    end
    
    
end


files_to_process = list_of_required_files.(givenListOfRequiredFiles);


for f = 1:numel(files_to_process)
    currentFilePath = files_to_process{f};
    
    load(currentFilePath);
    
    
    % Extract information states from the file name
    
    [~, filename, ~] = fileparts(currentFilePath);
    parts = strsplit(filename, '_');
    state_info = parts{9}; % Extract the stage information from the file name
    
    
    switch state_info
        case 'GOsignal'
            target_state_name = state_info;
        case 'cueON'
            target_state_name = state_info;
            % Add more cases for other possible stage_info values
            % case 'AnotherStage'
            %     target_state_name = state_info;
        otherwise
            error('Unrecognized stage information in the file name'); % Handle the case when the stage information is not recognized
    end
    
    
    
    % Get unique trial types
    trial_types = unique(raster_labels.trial_type_side);
    
    %presentation_times = size(raster_data, 2);
    
    hFig = figure;
    set(hFig, 'WindowState', 'maximized'); % Maximize the figure
    
    
    % Initialisation for minimum and maximum Y values for RASTER and PSTH
    y_min_raster = inf;
    y_max_raster = -inf;
    
    
    % Инициализация переменных для данных PSTH
    all_bins = cell(1, length(trial_types));
    bin_start_times = [];
    end_time = length(raster_data);
    
    
    % Create subplots for each trial type
    for i = 1:length(trial_types)
        trial_type = trial_types(i);
        
        %% RASTER
        % Filter data for the current trial type
        trial_data = raster_data(:, strcmp(raster_labels.trial_type_side, trial_type));
        %sorted_trial_data = zeros(size(raster_data));
        subplot(2, 4, i); % Adjust the subplot arrangement as needed
        
        % Find the indices of trials for the current trial type
        trial_indices = find(strcmp(raster_labels.trial_type_side, trial_type));
        sorted_trial_data = zeros(size(raster_data, 1), size(raster_data, 2));
        sorted_trial_data(trial_indices, :) = raster_data(trial_indices, :);
        
        % Plot raster for the current trial type
        imagesc(~sorted_trial_data(trial_indices, :)); %imagesc(~trial_data(:, trial_indices(sorted_indices))); %  imagesc(~trial_data);
        colormap gray;
        %axis([0 1000 0 160]);
        %line([500 500], get(gca, 'YLim'), 'color', [1 0 0]);
        
        ylabel('Trials');
        xlabel('Time (ms)');
        %set(gca, 'Position', get(gca, 'Position') + [0, 0, 0, -0.05]);
        
        % Determining the minimum and maximum Y values for RASTER
        y_min_raster = min(y_min_raster, min(ylim));
        y_max_raster = max(y_max_raster, max(ylim));
        
        
        
        % Set title only for subplot(2, 4, i)
        if i == 1
            main_title_rasters = ['RASTER'];
            setting_main_title_rasters = text('String', main_title_rasters, 'Position', [2.5, 1.14], ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
                'FontSize', 12, 'FontWeight', 'bold', 'Units', 'normalized');
            subtitle_str_rasters_per_group = [char(strrep(raster_site_info.unit_ID, '_', ' ')) ', ' char(strrep(raster_site_info.target, '_', ' ')) ', ' target_state_name];
            setting_subtitle_rasters_per_group = text('String', subtitle_str_rasters_per_group, 'Position', [2.5, 1.07], ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
                'FontSize', 11, 'FontWeight', 'normal', 'Units', 'normalized');
        end
        
        subtitle_str_rasters_per_pic = [trial_type];
        setting_subtitle_rasters_per_pic = text('String', subtitle_str_rasters_per_pic, 'Position', [0.5, 1.03], ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
            'FontSize', 10, 'FontWeight', 'normal', 'Units', 'normalized');
        
        
        hold on
        
        
        
        
        
        %% PSTH
        % Initialisation of bins and data accumulation for PSTH
        % subplot(2, 4, length(trial_types) + i);
        
        end_time = length(raster_data);
        if (length(settings.bin_width) == 1) && (length(settings.step_size) == 1); % if a single bin width and step size have been specified, then create binned data that averaged data over bin_width sized bins, sampled at sampling_interval intervals
            bin_start_time = settings.start_time : settings.step_size : (end_time - settings.bin_width  + 1);
            bin_widths = settings.bin_width .* ones(size(bin_start_time));
        end
        sorted_data = sorted_trial_data(trial_indices, :);
        
        % Initialize bins with zeros (preallocation)
        bins = zeros(size(sorted_data, 1), length(bin_start_time));
        for b = 1:length(bin_start_time)
            bins(:, b) = mean(sorted_data(:, bin_start_time(b):(bin_start_time(b) + bin_widths(b) -1)), 2);
        end
        
        all_bins{i} = sum(bins, 1);
        bin_start_times = bin_start_time;
        
        % Creating an empty graph for PSTH
        subplot(2, 4, length(trial_types) + i);
        hold on;
        xlim([0, length(all_bins{i}) + 1]);
        set(gca, 'Position', get(gca, 'Position') + [0, 0, 0, -0.05]);
        
        
        
        
    end
    
    
    
    
    % Defining axis limits for PSTH based on collected data
    y_min_psth = min(cellfun(@(x) min(x), all_bins));
    y_max_psth = max(cellfun(@(x) max(x), all_bins));
    
    
    
    % Updating data and axis scales after all graphs have been created
    for i = 1:length(trial_types)
        
        % Apply Y-limits to RASTER subplots
        subplot(2, 4, i);
        ylim([y_min_raster, y_max_raster]);
        line([500 500], [0 y_max_raster], 'color', [1 0 0]);
        
        
        
        
        % Making PSTH graphs
        subplot(2, 4, length(trial_types) + i);
        
        bar(all_bins{i});
        time_point_500ms_bin = find(bin_start_times <= 500, 1, 'last');
        
        hold on;
        ylabel('Number of spikes');
        xlabel('Number of bins');
        
        % Updating axis limits
        ylim([y_min_psth, y_max_psth]);
        xlim([0, length(all_bins{i}) + 1]); % Ensure X limits are set
        line([time_point_500ms_bin time_point_500ms_bin], [y_min_psth y_max_psth], 'color', [1 0 0]);
        
        
        
        trial_type = trial_types(i);
        
        if i == 1
            main_title_PSTH = ['PSTH'];
            setting_main_title_PSTH = text('String', main_title_PSTH, 'Position', [2.5, 1.14], ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
                'FontSize', 12, 'FontWeight', 'bold', 'Units', 'normalized');
            subtitle_str_PSTH_per_group = [char(strrep(raster_site_info.unit_ID, '_', ' ')) ', ' char(strrep(raster_site_info.target, '_', ' ')) ', ' target_state_name];
            setting_subtitle_PSTH_per_group = text('String', subtitle_str_rasters_per_group, 'Position', [2.5, 1.07], ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
                'FontSize', 11, 'FontWeight', 'normal', 'Units', 'normalized');
        end
        
        subtitle_str_PSTH_per_pic = [trial_type];
        setting_subtitle_PSTH_per_pic = text('String', subtitle_str_PSTH_per_pic, 'Position', [0.5, 1.03], ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
            'FontSize', 10, 'FontWeight', 'normal', 'Units', 'normalized');
        
        
        drawnow; %  Graph update
        
        
    end
    
    
    
    
    % save picture
    name_to_save = ['Raster_Sim_LIP_dPul_rasters_from_each_trial_and_PSTH_for_' parts{1} '_' parts{2} '_' parts{3} '_' parts{5} '_' parts{6} '_' state_info '_' parts{10} '_' parts{11}  '.png'];
    path_to_save = [OUTPUT_PATH_raster monkey_prefix dateOfRecording '/' block_grouping_folder 'Graphs/'];
    if ~exist(path_to_save, 'dir')
        mkdir(path_to_save);
    end
    path_name_to_save = [path_to_save name_to_save];
    saveas(gcf, path_name_to_save);
    
    close(gcf);
end % f = 1:numel(files_to_process)
end

