function sdndt_Sim_LIP_dPul_NDT_plot_decoding_results(injection, typeOfSessions, save_file_name)

% Call the settings function with the chosen set
[base_path, INPUT_PATH, OUTPUT_PATH_raster, OUTPUT_PATH_binned, settings] = sdndt_Sim_LIP_dPul_NDT_settings(injection, typeOfSessions);
%run('sdndt_Sim_LIP_dPul_NDT_settings');

load(save_file_name);

[filepath, filename, fileext] = fileparts(save_file_name); % Get the path and filename components
desired_part = fullfile(filepath, filename); % Concatenate the path and filename without the extension
binned_file_name = [desired_part '.mat']; % Add '.mat' to the desired part
% Specify substrings to remove
substrings_to_remove = {'_instr_R instr_L_DECODING_RESULTS', '_choice_R choice_L_DECODING_RESULTS', '_instr_R choice_R_DECODING_RESULTS', '_instr_L choice_L_DECODING_RESULTS'}; % Add more patterns as needed
for substring = substrings_to_remove % Remove specified substrings using strrep
    binned_file_name = strrep(binned_file_name, substring{1}, '');
end
load(binned_file_name);



if isfield(DECODING_RESULTS.DS_PARAMETERS,'the_training_label_names')
    
    labels_to_use_string = [strjoin(vertcat(vertcat(DECODING_RESULTS.DS_PARAMETERS.the_training_label_names{:}))) ' as train ' ...
                            strjoin(vertcat(vertcat(DECODING_RESULTS.DS_PARAMETERS.the_test_label_names{:}))) ' as test'];

else
    labels_to_use_string = strjoin(DECODING_RESULTS.DS_PARAMETERS.label_names_to_use); 
end


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

block_info = regexp(save_file_name, 'block_\d+', 'match');



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
trial_type_side = binned_labels.trial_type_side;
label_names_to_use = DECODING_RESULTS.DS_PARAMETERS.label_names_to_use;

label_counts = zeros(size(label_names_to_use)); % Initialize counters
unique_sequences = containers.Map('KeyType', 'char', 'ValueType', 'logical'); % Map to store unique sequences

for x = 1:length(sites_to_use) % Loop through sites_to_use and count occurrences of labels_names_to_use in trial_type_side
    site_index = sites_to_use(x);
    labels_at_site = trial_type_side{1, site_index}; % Access the_labels at the specified site_index
    
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

% label_counts = zeros(size(label_names_to_use)); % Initialize counters
% 
% for x = 1:length(sites_to_use) % Loop through sites_to_use and count occurrences of labels_names_to_use in trial_type_side
%     site_index = sites_to_use(x);    
%     labels_at_site = trial_type_side{1, site_index}; % Access the_labels at the specified site_index
%     for y = 1:length(label_names_to_use) % Count occurrences of unique_labels in labels_at_site
%         label_counts(y) = label_counts(y) + sum(strcmp(labels_at_site, label_names_to_use{y}));
%     end
% end
% for k = 1:length(label_names_to_use) % Display the results
%     fprintf('Label %s appears %d times.\n', label_names_to_use{k}, label_counts(k));
% end
numOfTrials = sum(label_counts);




%% search target_brain_structure from the file name
path_parts = strsplit(save_file_name, '_'); % Split the file path
required_parts =  path_parts(10:end-9);
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
numOfUnits_and_numOfTrials_info = sprintf('Num of Units: %s\nNum of Trials: %s\n', num2str(numOfUnits), num2str(numOfTrials));
% Display the label counts information
labelCountsInfo = '';
for g = 1:length(label_names_to_use)
    labelCountsInfo = [labelCountsInfo, sprintf('\nNum of %s: %d', label_names_to_use{g}, label_counts(g))];
end

% Display the complete information
numOfUnits_and_numOfTrials_info_labelsAppears = [numOfUnits_and_numOfTrials_info, labelCountsInfo];

% change the size of the figure
set(gcf,'position',[450,400,700,500]) % [x0,y0,width,height]

% Add text using the annotation function
positionOfAnnotation = [0.76, 0.5, 0.26, 0.26]; % [x position, y position, size x, size y]
annotation('textbox', positionOfAnnotation, 'String', numOfUnits_and_numOfTrials_info_labelsAppears, ...
    'FontSize', 10, 'HorizontalAlignment', 'left','FitBoxToText','on');
set(gca, 'Position', [0.1, 0.13, 0.65, 0.72] ) % change the position of the axes to fit the annotation into the figure too.

% Ensure the figure is active before adding the text
% axes(fig1, 'Position',[0.0932277834525026 0.134420631630453 0.775 0.709626991319852]);
% addtionalTexAboutTrials = text('Units', 'Normalized', 'String', 'Position', [0.95, 0.85], numOfUnits_and_numOfTrials_info_labelsAppears, 'FontSize', 9, 'HorizontalAlignment', 'left');


target_and_block_info = [target_info '; ' block_info '; ' cell_with_O]; 
target_and_block_info_str = num2str(cell2mat(target_and_block_info));

[t,s] = title(labels_to_use_string, target_and_block_info_str);
t.FontSize = 15;
s.FontSize = 12;


xline(500); 
set(gca,'Xlim',settings.time_lim, 'Ylim',settings.y_lim);



saveas(gcf, [save_file_name(1:end-4) '_DA_as_a_function_of_time.png']);

close(gcf);

