function sdndt_Sim_LIP_dPul_NDT_plot_cross_decoding_results(monkey, injection, typeOfSessions, save_file_name, training_block, test_block)

% Call the settings function with the chosen set
[base_path, INPUT_PATH, OUTPUT_PATH_raster, OUTPUT_PATH_binned, monkey_prefix, settings] = sdndt_Sim_LIP_dPul_NDT_settings(monkey, injection, typeOfSessions);
%run('sdndt_Sim_LIP_dPul_NDT_settings');

load(save_file_name);

[filepath, filename, fileext] = fileparts(save_file_name); % Get the path and filename components
desired_part = fullfile(filepath, filename); % Concatenate the path and filename without the extension
binned_file_name = [desired_part '.mat']; % Add '.mat' to the desired part
% Specify substrings to remove
substrings_to_remove = {'_DECODING_RESULTS'}; % Add more patterns as needed
for substring = substrings_to_remove % Remove specified substrings using strrep
    binned_file_name = strrep(binned_file_name, substring{1}, '');
end
load(binned_file_name);



if isfield(DECODING_RESULTS.DS_PARAMETERS,'the_training_label_names')
    
    %     labels_to_use_string = [strjoin(vertcat(vertcat(DECODING_RESULTS.DS_PARAMETERS.the_training_label_names{:}))) ' as train ' ...
    %                             strjoin(vertcat(vertcat(DECODING_RESULTS.DS_PARAMETERS.the_test_label_names{:}))) ' as test'];
    
    % train_str = strjoin([DECODING_RESULTS.DS_PARAMETERS.the_training_label_names{:}], '_');
    % test_str = strjoin([DECODING_RESULTS.DS_PARAMETERS.the_test_label_names{:}], '_');
    % labels_to_use_string = sprintf('train: %s, test: %s', train_str, test_str);
    
    
   % Find unique blocks in the training and testing samples
    unique_train_blocks = unique([training_block{:}]);
    unique_test_blocks = unique([test_block{:}]);
    
   %Convert unique training blocks to ‘block_X’ format string
    train_str = sprintf('block_%d', unique_train_blocks(1)); %First value for the training block
    for i = 2:length(unique_train_blocks)
        train_str = [train_str, sprintf(', block_%d', unique_train_blocks(i))]; %Add the rest of the blocks
    end
    
    % Convert unique test blocks to ‘block_X’ format string
    test_str = sprintf('block_%d', unique_test_blocks(1)); % First value of the test block
    for i = 2:length(unique_test_blocks)
        test_str = [test_str, sprintf(', block_%d', unique_test_blocks(i))]; 
    end
    
    
    % Compose the final line
    blocks_to_use_string = sprintf('train: %s, test: %s', train_str, test_str);
    
    
else
    %labels_to_use_string = strjoin(DECODING_RESULTS.DS_PARAMETERS.label_names_to_use);
end

% Shift of time labels
% alignment_event_time = 501;  % Время события (по умолчанию середина шкалы)
% DECODING_RESULTS.DS_PARAMETERS.binned_site_info.binning_parameters.the_bin_start_times = ...
%     DECODING_RESULTS.DS_PARAMETERS.binned_site_info.binning_parameters.the_bin_start_times - alignment_event_time;

% DECODING_RESULTS.DS_PARAMETERS.binned_site_info.binning_parameters.alignment_event_time = 500; 
% DECODING_RESULTS.DS_PARAMETERS.binned_site_info.binning_parameters.alignment_type = 2; 
 

% Сдвигаем значения так, чтобы первый элемент стал -500
% DECODING_RESULTS.DS_PARAMETERS.binned_site_info.binning_parameters.the_bin_start_times = DECODING_RESULTS.DS_PARAMETERS.binned_site_info.binning_parameters.the_bin_start_times - 500;
% DECODING_RESULTS.DS_PARAMETERS.binned_site_info.binning_parameters.start_time = DECODING_RESULTS.DS_PARAMETERS.binned_site_info.binning_parameters.start_time - 500;
% DECODING_RESULTS.DS_PARAMETERS.binned_site_info.binning_parameters.end_time = DECODING_RESULTS.DS_PARAMETERS.binned_site_info.binning_parameters.end_time - 500;


% plot_obj.the_bin_start_times = DECODING_RESULTS.DS_PARAMETERS.binned_site_info.binning_parameters.the_bin_start_times - 500;
% plot_obj.start_time = DECODING_RESULTS.DS_PARAMETERS.binned_site_info.binning_parameters.start_time - 500;
% plot_obj.end_time = DECODING_RESULTS.DS_PARAMETERS.binned_site_info.binning_parameters.end_time - 500;



result_names{1} = save_file_name;
% create the plot results object
plot_obj = plot_standard_results_object(result_names);

% put a line at the time when the stimulus was shown 
% plot_obj.significant_event_times = setting.significant_event_times;
% the xline(500) function below is used for this purpose

plot_obj.errorbar_file_names = result_names;
plot_obj.errorbar_type_to_plot = settings.errorbar_type_to_plot;

% display the results
plot_obj.plot_results;


fig1 = figure(gcf);


% create a directory where the necessary raster files are located (Raster_data_dir) 
% Overlap_blocks = ''; % Initialize Overlap_blocks as an empty string
% for p = 1:numel(result_names) % Assuming result_names is a cell array of file paths (strings)
%     file_path = result_names{p};
%     if contains(file_path, '/Overlap_blocks/') % Check if the file path contains '/Overlap_blocks/'
%         Overlap_blocks = '/Overlap_blocks/';
%         break; % No need to continue checking once a match is found
%     end
% end
% path_parts = strsplit(file_path, '/'); % Split the file path using '/'
% if numel(path_parts) >= 6 % Access the sixth cell to get the date information
%     dateOfRecording = path_parts{6};
% else
%     dateOfRecording = 'Date information not available';
% end
% 
% Raster_data_dir = [OUTPUT_PATH_raster dateOfRecording '/' Overlap_blocks];



unique_targets = unique(DECODING_RESULTS.DS_PARAMETERS.binned_site_info.target); % Unique target values
target_info = sprintf(strjoin(unique_targets, ', ')); % Text under the title with information about the target

labels_info = create_labels_info(DECODING_RESULTS);



%% Number of units
% To honestly count the number of units that were used in decoding, it is best to use the sites_to_use variable,
% because only the size of this variable reflects the actual number of units used during decoding. 

% Example: on running decoding, we find out from variable num_sites_with_k_repeats that 
% 320 units had 9 stimulus repetitions,300 units had 12 stimulus repetitions, 268 units had 16 stimulus repetitions and etc. 
% If num_cv_splits = 4 (assuming ds.num_times_to_repeat_each_label_per_cv_split = 2 
% and num_cv_splits * ds.num_times_to_repeat_each_label_per_cv_split = 8), then only 320 units are used in decoding. 
% If num_cv_splits = 6 (6*2=12), then only 300 units are used in decoding. 
% If num_cv_splits = 8 (8*2=16), then only 268 units are used in decoding.

sites_to_use = DECODING_RESULTS.DS_PARAMETERS.sites_to_use;
numOfUnits = size(sites_to_use, 2); 
%numOfUnits = size(binned_site_info.unit_ID, 2);
% numOfUnits = size(DECODING_RESULTS.DS_PARAMETERS.sites_to_use, 2);

% need to use actual variable from DECODING_RESULTS


%% Number of trials

% Number of trials for training labels
trial_type_side = binned_labels.trial_type_side;  % Trial labels

% Call the function for the training labels
label_names_to_use_training = DECODING_RESULTS.DS_PARAMETERS.the_training_label_names;
numOfTrials_for_training_label = count_trials(sites_to_use, trial_type_side, label_names_to_use_training);

% Call the function for the test labels
label_names_to_use_test = DECODING_RESULTS.DS_PARAMETERS.the_test_label_names;
numOfTrials_for_test_label = count_trials(sites_to_use, trial_type_side, label_names_to_use_test);

% Now you have numOfTrials_for_training_label and numOfTrials_for_test_label





%% search target_brain_structure from the file name
path_parts = strsplit(save_file_name, '_'); % Split the file path
required_parts =  path_parts(24:end-9);
index_containing_O = find(cellfun(@(x) any(contains(x, 'O')), required_parts), 1); % Find a cell that contains an "O": 
if ~isempty(index_containing_O)
    cell_with_O = required_parts{index_containing_O};
else
    %disp('No cell contains an "O"');
end
% file_list = dir(fullfile(Raster_data_dir, '*.mat'));
% matching_files = {}; % Initialize a cell array to store matching files
% block_info_str = strjoin(block_info, '_');
% for i = 1:numel(file_list) % Iterate through the files
%     current_file = file_list(i).name;
%     
%     % Check if the current file contains any of the unique targets
%     contains_target = false;
%     for j = 1:numel(unique_targets)
%         if contains(current_file, unique_targets{j})
%             contains_target = true;
%             break;
%         end
%     end
%     
%     % Check the other conditions
%     if contains_target && contains(current_file, cell_with_O) && contains(current_file, block_info_str)
%         full_path = fullfile(Raster_data_dir, current_file); % Full path to the file
%         matching_files = [matching_files; full_path]; % Add the matching file to the cell array
%     end
% end
% load(matching_files{1});



%% Display
%numOfUnits_and_numOfTrials_info = ['Num of Units: ' numOfUnits, 'Num of Trials: ' numOfTrials];
numOfUnits_and_numOfTrials_info = sprintf('Num of Units: %s\nNum of Trials (train): %s\nNum of Trials (test): %s\n', num2str(numOfUnits), num2str(numOfTrials_for_training_label), num2str(numOfTrials_for_test_label));
% % Display the label counts information
% labelCountsInfo = '';
% for g = 1:length(label_names_to_use)
%     labelCountsInfo = [labelCountsInfo, sprintf('\nNum of %s: %d', label_names_to_use{g}, label_counts(g))];
% end

% % Display the complete information
% numOfUnits_and_numOfTrials_info_labelsAppears = [numOfUnits_and_numOfTrials_info, labelCountsInfo];

% change the size of the figure
set(gcf,'position',[450,400,730,580]) % [x0,y0,width,height]


% Set font size for axes
set(gca, 'FontSize', 11); % Here 11 is font size


% Add text using the annotation function
positionOfAnnotation = [0.76, 0.5, 0.26, 0.28]; % [x position, y position, size x, size y]
annotation('textbox', positionOfAnnotation, 'String', numOfUnits_and_numOfTrials_info, ...
    'FontSize', 10, 'HorizontalAlignment', 'left','FitBoxToText','on');
%set(gca, 'Position', [0.1, 0.13, 0.61, 0.72] ) % change the position of the axes to fit the annotation into the figure too.

% Ensure the figure is active before adding the text
% axes(fig1, 'Position',[0.0932277834525026 0.134420631630453 0.775 0.709626991319852]);
% addtionalTexAboutTrials = text('Units', 'Normalized', 'String', 'Position', [0.95, 0.85], numOfUnits_and_numOfTrials_info_labelsAppears, 'FontSize', 9, 'HorizontalAlignment', 'left');


target_and_block_info = [target_info '; ' labels_info '; ' cell_with_O]; 
%target_and_block_info_str = num2str(cell2mat(target_and_block_info));

[t,s] = title(blocks_to_use_string, target_and_block_info);
t.FontSize = 13;
s.FontSize = 12;


% Set the header and subheader offset upwards (e.g. 0.1 units higher)
t.Units = 'normalized'; % Normalised coordinates (0 to 1)
t.Position(2) = t.Position(2) + 0.05; % Y-axis upward displacement 5% higher from the current position

s.Units = 'normalized'; % Normalised coordinates
s.Position(2) = s.Position(2) + 0.04; % Shifting the subheading upwards on the Y-axis

% drawnow; % Ensure the title position is updated
% 
% % Change title position
% %Increase the vertical position of the combinedLabel_for_Title
% titlePos = get(t, 'Position');
% titlePos(2) = titlePos(2) + 18; % Increase the vertical position by 5
% set(t, 'Position', titlePos);
% 
% % Increase the vertical position of the target_info
% sPos = get(s, 'Position');
% sPos(2) = sPos(2) + 17; % Increase the vertical position by 5
% set(s, 'Position', sPos);


%% Setting of axes

xline(0); 
set(gca, 'Xlim', settings.time_lim, 'Ylim', settings.y_lim); % Установка пределов графика
xticks(-500:200:500); % Промежутки оси X каждые 200 мс
xticklabels(arrayfun(@num2str, -500:200:500, 'UniformOutput', false)); % Подписи для меток оси X


ax = gca;
ax.XAxis.FontSize = 12; % Font size for X-axis labels
ax.YAxis.FontSize = 12; % Font size for Y-axis labels


% Shift Y-axis number signatures to the left (in this case, a positive value moves them away from the axis)
ax.YAxis.TickLabelInterpreter = 'none'; % Remove TeX interpretation (if it interferes)
ax.YAxis.TickLength = [0.02, 0.02]; % Setting the length of ticks (divisions)

% Visual indentation for numbers (TickLabels) on the Y axis
ax.YRuler.TickLabelGapOffset = 8;  % Setting the indentation of numbers on the Y-axis from the axis itself

% Setting axis captions and axis dimensions
xlabel('Time (ms)', 'FontSize', 15);
ylabel('Classification Accuracy', 'FontSize', 16);

set(gca, 'Position', [0.11, 0.096, 0.62, 0.75] ) % change the position of the axes to fit the annotation into the figure too.


%% save

saveas(gcf, [save_file_name(1:end-4) '_DA_as_a_function_of_time.png']);

close(gcf);
end 



function numOfTrials = count_trials(sites_to_use, trial_type_side, label_names_to_use)

    % Initialize counters and a map to store unique sequences
    label_counts = zeros(size(label_names_to_use)); 
    unique_sequences = containers.Map('KeyType', 'char', 'ValueType', 'logical'); 

    % Loop through sites_to_use and count occurrences of labels_names_to_use in trial_type_side
    for x = 1:length(sites_to_use)
        site_index = sites_to_use(x);
        labels_at_site = trial_type_side{1, site_index}; % Access the labels at the specified site_index
        
        % Convert cell array to a string for easy comparison
        sequence_str = strjoin(labels_at_site, ',');
        
        % Check if the sequence is unique
        if ~isKey(unique_sequences, sequence_str)
            unique_sequences(sequence_str) = true; % Mark as seen
            for y = 1:length(label_names_to_use)
                % Count occurrences of unique_labels in labels_at_site
                label_counts(y) = label_counts(y) + sum(strcmp(labels_at_site, label_names_to_use{y}));
            end
        end
    end

    % Sum the label counts to get the total number of trials
    numOfTrials = sum(label_counts);
end


function labels_info = create_labels_info(DECODING_RESULTS)

    %Initialising an empty array to store label names
    label_names = {};

    % Passing through each label in the_test_label_names
    for i = 1:length(DECODING_RESULTS.DS_PARAMETERS.the_test_label_names)
        % Retrieving the current tag
        current_label = DECODING_RESULTS.DS_PARAMETERS.the_test_label_names{i}{1};
        
        % Remove the ‘_test’ suffix.
        cleaned_label = strrep(current_label, '_test', '');
        
        % Add the cleared label to the array
        label_names{end+1} = cleaned_label;
    end

    % Combine all labels into one line, separating them with commas
    labels_info = strjoin(label_names, ', ');

end

