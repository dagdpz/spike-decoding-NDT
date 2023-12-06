function sdndt_Sim_LIP_dPul_NDT_plot_decoding_results(save_file_name)

run('sdndt_Sim_LIP_dPul_NDT_settings');

load(save_file_name);



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




% create a directory where the necessary raster files are located (Raster_data_dir) 
Overlap_blocks = ''; % Initialize Overlap_blocks as an empty string
for p = 1:numel(result_names) % Assuming result_names is a cell array of file paths (strings)
    file_path = result_names{p};
    if contains(file_path, '/Overlap_blocks/') % Check if the file path contains '/Overlap_blocks/'
        Overlap_blocks = '/Overlap_blocks/';
        break; % No need to continue checking once a match is found
    end
end
path_parts = strsplit(file_path, '/'); % Split the file path using '/'
if numel(path_parts) >= 6 % Access the sixth cell to get the date information
    dateOfRecording = path_parts{6};
else
    dateOfRecording = 'Date information not available';
end

Raster_data_dir = [OUTPUT_PATH_raster dateOfRecording '/' Overlap_blocks];



unique_targets = unique(DECODING_RESULTS.DS_PARAMETERS.binned_site_info.target); % Unique target values
target_info = sprintf(strjoin(unique_targets, ', ')); % Text under the title with information about the target

block_info = regexp(save_file_name, 'block_\d+', 'match');



numOfUnits = num2str(size(DECODING_RESULTS.DS_PARAMETERS.binned_site_info.unit_ID, 2)); % Number of units

% search Number of trials
path_parts = strsplit(save_file_name, '_'); % Split the file path
required_parts =  path_parts(10:end-9);
index_containing_O = find(cellfun(@(x) any(contains(x, 'O')), required_parts), 1); % Find a cell that contains an "O": 
if ~isempty(index_containing_O)
    cell_with_O = required_parts{index_containing_O};
else
    %disp('No cell contains an "O"');
end
file_list = dir(fullfile(Raster_data_dir, '*.mat'));
matching_files = {}; % Initialize a cell array to store matching files
block_info_str = strjoin(block_info, '_');
for i = 1:numel(file_list) % Iterate through the files
    current_file = file_list(i).name;
    
    % Check if the current file contains any of the unique targets
    contains_target = false;
    for j = 1:numel(unique_targets)
        if contains(current_file, unique_targets{j})
            contains_target = true;
            break;
        end
    end
    
    % Check the other conditions
    if contains_target && contains(current_file, cell_with_O) && contains(current_file, block_info_str)
        full_path = fullfile(Raster_data_dir, current_file); % Full path to the file
        matching_files = [matching_files; full_path]; % Add the matching file to the cell array
    end
end
load(matching_files{1});
numOfTrials = num2str(size(raster_data,1)); % Number of trials  

%numOfUnits_and_numOfTrials_info = ['Num of Units: ' numOfUnits, 'Num of Trials: ' numOfTrials];
numOfUnits_and_numOfTrials_info = sprintf('Num of Units: %s\nNum of Trials: %s', numOfUnits, numOfTrials);
figure(gcf); % Ensure the figure is active before adding the text
text('Units', 'Normalized', 'Position', [0.85, 0.95], 'String', numOfUnits_and_numOfTrials_info, 'FontSize', 9, 'HorizontalAlignment', 'left');




target_and_block_info = [target_info '; ' block_info '; ' cell_with_O]; 
target_and_block_info_str = num2str(cell2mat(target_and_block_info));

[t,s] = title(labels_to_use_string, target_and_block_info_str);
t.FontSize = 14;
s.FontSize = 10;




xline(500); 
set(gca,'Xlim',settings.time_lim, 'Ylim',settings.y_lim);

saveas(gcf, [save_file_name(1:end-4) '_DA_as_a_function_of_time.png']);

