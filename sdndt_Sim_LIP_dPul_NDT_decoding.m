function sdndt_Sim_LIP_dPul_NDT_decoding(dateOfRecording, target_brain_structure, target_state, labels_to_use, listOfRequiredFiles)
% This code loads one population**.mat file and converts it to a raster_data, array 0 and 1.
% The code converts the received raster data into binned data and then performs decoding.

% HOW TO CALL THE FUNCTION?
% If we decode within a session:
% sdndt_Sim_LIP_dPul_NDT_decoding('20211109', 'dPul_L', 4, 'instr_R_instr_L', 'firstBlockFiles');
% sdndt_Sim_LIP_dPul_NDT_decoding('20211110', 'LIP_L', 6, 'instr_R_instr_L', 'overlapBlocksFiles');

% If we decode across sessions:
% sdndt_Sim_LIP_dPul_NDT_decoding('merged_files_across_sessions', 'dPul_L', 4, 'instr_R_instr_L', 'overlapBlocksFilesAcrossSessions');

% ADDITIONAL SETTINGS
% dateOfRecording - folder name
% target_brain_structure = 'dPul_L', 'LIP_L', if both 'LIP_L_dPul_L'
% target_state: 6 - cue on , 4 - target acquisition
% labels_to_use: 'instr_R_instr_L'            
%                'choice_R_choice_L' 
%                'instr_R_choice_R'
%                'instr_L_choice_L'
% listOfRequiredFiles - variable name, which contains the list of necessary files for decoding:
%                       'firstBlockFiles', 'secondBlockFiles', 'thirdBlockFiles',
%                       'allBlocksFiles', 'overlapBlocksFiles',
%                       'overlapBlocksFilesAcrossSessions'



run('sdndt_Sim_LIP_dPul_NDT_settings');
%run('sdndt_Sim_LIP_dPul_NDT_make_raster');

if isequal(listOfRequiredFiles, 'overlapBlocksFilesAcrossSessions')
    partOfName = 'allOverlapBlocksFiles';
    dateOfRecording = 'merged_files_across_sessions';  % Set a default value for the dateOfRecording in this case
else
    partOfName = dateOfRecording;
end

OUTPUT_PATH_list_of_required_files = [OUTPUT_PATH_raster dateOfRecording '/List_of_required_files/sdndt_Sim_LIP_dPul_NDT_' partOfName '_list_of_required_files.mat'];

load(OUTPUT_PATH_list_of_required_files);




%% Prepearing for Binned_data
% Add the path to the NDT so add_ndt_paths_and_init_rand_generator can be called
toolbox_basedir_name = 'Y:\Sources\ndt.1.0.4';
addpath(toolbox_basedir_name);
% Add the NDT paths using add_ndt_paths_and_init_rand_generator
add_ndt_paths_and_init_rand_generator;


% target_brain_structure = all_brain_structures; % all structures from which neurons were recorded can be found in the variable brain_structures_present

switch listOfRequiredFiles
    case 'firstBlockFiles'
        listOfRequiredFiles = list_of_required_files.firstBlockFiles;
    case 'secondBlockFiles'
        listOfRequiredFiles = list_of_required_files.secondBlockFiles;
    case 'thirdBlockFiles'
        listOfRequiredFiles = list_of_required_files.thirdBlockFiles;
    case 'allBlocksFiles'
        listOfRequiredFiles = list_of_required_files.allBlocksFiles;
    case 'overlapBlocksFiles'
        listOfRequiredFiles = list_of_required_files.overlapBlocksFiles;
    otherwise % 'overlapBlocksFilesAcrossSessions'
        listOfRequiredFiles = list_of_required_files.overlapBlocksFilesAcrossSessions;
end

switch target_state
    case 6
        target_state_name = 'cueON';
    case 4
        target_state_name = 'GOsignal';
    otherwise
        %fprintf('Invalid target_state value: %d\n', target_state);
        % You might want to handle the case when target_state is neither 6 nor 4
end

switch target_brain_structure
    case 'dPul_L'
        target_brain_structure = 'dPul_L';
    case 'LIP_L'
        target_brain_structure = 'LIP_L';
    otherwise
        target_brain_structure = 'LIP_L_dPul_L';
end


%     % Upload the necessary files: only cueON or only GOsignal
%     file_list = dir(fullfile(OUTPUT_PATH_raster, ['*' target_state_name '*.mat'])); %  Use dir to list all files in the directory
%     for f = 1:numel(file_list) % Loop through the files and load them
%         file_path = fullfile(OUTPUT_PATH_raster, file_list(f).name);
%         load(file_path);
%     end

all_target_brain_structure = {'dPul_L', 'LIP_L'};

switch target_brain_structure
    case 'dPul_L'
        search_target_brain_structure_among_raster_data = 'dPul_L';
    case 'LIP_L'
        search_target_brain_structure_among_raster_data = 'LIP_L';
    otherwise
        % Check if target_brain_structure is in all_brain_structures
        if any(strcmp(target_brain_structure, all_target_brain_structure))
            search_target_brain_structure_among_raster_data = target_brain_structure;
        else
            search_target_brain_structure_among_raster_data = [];
        end
end



for h = 1:numel(listOfRequiredFiles)
    parts = strsplit(listOfRequiredFiles{h}, '_'); % Split the file name into parts using underscores
    blockIndex = find(contains(parts, 'block'), 1, 'last'); % Find the index of the part containing 'block'
    if ~isempty(blockIndex) % Extract the block information
        blockInfo = strjoin(parts(blockIndex:end), '_');
        blockInformation{h} = blockInfo;
    else
        blockInformation{h} = 'No block information found';
    end
end

uniqueBlockInformation = strrep(strjoin(unique(blockInformation)), '.mat', ''); % Find unique block information
targetBlock = uniqueBlockInformation ;

switch targetBlock
    case 'block_1'
        targetBlockUsed = 'block_1';
    case 'block_2'
        targetBlockUsed = 'block_2';
    case 'block_3'
        targetBlockUsed = 'block_3';
    otherwise
        blocks = strsplit(targetBlock, ' '); % Split the targetBlock string into individual blocks
        for i = 1:numel(blocks)
            blocks{i} = ['block_' strrep(blocks{i}, 'block_', '')]; % Add the 'Block_' prefix to each block
        end
        targetBlockUsed = strjoin(blocks, '_'); % Concatenate the blocks with underscores
end


all_targetBlock = {'block_1', 'block_2', 'block_3'};

switch targetBlock
    case 'block_1'
        targetBlockUsed_among_raster_data = 'block_1';
    case 'block_2'
        targetBlockUsed_among_raster_data = 'block_2';
    case 'block_3'
        targetBlockUsed_among_raster_data = 'block_3';
    otherwise
        if isfield(list_of_required_files, 'overlapBlocksFilesAcrossSessions') && isequal(listOfRequiredFiles, list_of_required_files.overlapBlocksFilesAcrossSessions)
            targetBlockUsed_among_raster_data = [];
        else
            targetBlockUsed_among_raster_data = targetBlockUsed;
        end
end


if isfield(list_of_required_files, 'overlapBlocksFiles') && isequal(listOfRequiredFiles, list_of_required_files.overlapBlocksFiles)
    Overlap_blocks = 'Overlap_blocks/';
elseif isfield(list_of_required_files, 'overlapBlocksFilesAcrossSessions') && isequal(listOfRequiredFiles, list_of_required_files.overlapBlocksFilesAcrossSessions)
    Overlap_blocks = 'overlapBlocksFilesAcrossSessions/';
else
    Overlap_blocks = '';
end


OUTPUT_PATH_binned_dateOfRecording = [OUTPUT_PATH_binned dateOfRecording '/'];
Binned_data_dir = [OUTPUT_PATH_binned_dateOfRecording Overlap_blocks];
save_prefix_name = [Binned_data_dir 'Binned_Sim_LIP_dPul__NDT_data_for_' target_brain_structure '_' target_state_name '_' targetBlockUsed];

if ~exist(Binned_data_dir,'dir')
    mkdir(Binned_data_dir);
end



%% Combining blocks, creating a metablock if 'commonBlocksFiles'

% Assuming you have a cell array of groups of files
% for h = 1:numel(listOfRequiredFiles)
%     parts{h} = strsplit(listOfRequiredFiles{h}, '\');
%     requiredParts{h} = fullfile(parts{h}{1:6});
%     uniqueRequiredRasterFolder = unique(requiredParts);
% end

% If we are interested in overlapBlocksFilesAcrossSessions, we create a folder where we will put all the files from this category
if isfield(list_of_required_files, 'overlapBlocksFilesAcrossSessions') && isequal(listOfRequiredFiles, list_of_required_files.overlapBlocksFilesAcrossSessions)
    folderForCopyingFilesAcrossSessions = [OUTPUT_PATH_raster dateOfRecording '/overlapBlocksFilesAcrossSessions/'];
    % Create the destination folder if it doesn't exist
    if ~exist(folderForCopyingFilesAcrossSessions, 'dir')
        mkdir(folderForCopyingFilesAcrossSessions);
    end
    
    for h = 1:numel(listOfRequiredFiles)
        currentFilePath = listOfRequiredFiles{h}; % Get the current file path
        [~, currentFileName, currentFileExt] = fileparts(currentFilePath); % Generate the destination path by replacing the initial part of the path
        destinationPath = fullfile(folderForCopyingFilesAcrossSessions, [currentFileName currentFileExt]);
        copyfile(currentFilePath, destinationPath); % Copy the file to the destination folder
    end
end


OUTPUT_PATH_raster_dateOfRecording = [OUTPUT_PATH_raster dateOfRecording '/'];

OUTPUT_PATH_raster_dateOfRecording_Overlap_blocks = [OUTPUT_PATH_raster_dateOfRecording Overlap_blocks];
if ~exist(OUTPUT_PATH_raster_dateOfRecording_Overlap_blocks,'dir')
    mkdir(OUTPUT_PATH_raster_dateOfRecording_Overlap_blocks);
end






% Assuming list_of_required_files.commonBlocksFiles is already defined

% Extract unique prefixes from the filenames
if isfield(list_of_required_files, 'overlapBlocksFiles') && isequal(listOfRequiredFiles, list_of_required_files.overlapBlocksFiles)   % if isequal(listOfRequiredFiles, list_of_required_files.overlapBlocksFiles)
    
    unique_prefixes = {};
    for idx = 1:length(list_of_required_files.overlapBlocksFiles)
        current_file_parts = strsplit(list_of_required_files.overlapBlocksFiles{idx}, '_');
        current_prefix = strjoin(current_file_parts(1:9), '_');
        
        % Check if the current_prefix is not already in unique_prefixes
        if ~any(strcmp(unique_prefixes, current_prefix))
            unique_prefixes{end+1} = current_prefix;
        end
    end
    
    %     for prefix_idx = 1:length(unique_prefixes)
    %         current_prefix = unique_prefixes{prefix_idx};
    
    % Extract unique prefixes from the filenames based on your criteria
    %unique_prefixes = unique(cellfun(@(file) strjoin(strsplit(file, '_'), '_'), list_of_required_files.overlapBlocksFiles, 'UniformOutput', false), 'stable');
    
    
    for prefix_idx = 1:length(unique_prefixes)
        current_prefix = unique_prefixes{prefix_idx};
        
        
        % Filter files based on the target_brain_structure
        %         current_group_files = list_of_required_files.overlapBlocksFiles(startsWith(list_of_required_files.overlapBlocksFiles, current_prefix) ...
        %             & contains(list_of_required_files.overlapBlocksFiles, search_target_brain_structure_among_raster_data)...
        %             & contains(list_of_required_files.overlapBlocksFiles, target_state_name));
        
        % Filter files based on the target_brain_structure, target_state, and listOfRequiredFiles
        current_group_files = list_of_required_files.overlapBlocksFiles(startsWith(list_of_required_files.overlapBlocksFiles, current_prefix) ...
            & contains(list_of_required_files.overlapBlocksFiles, target_state_name));
        
        
        % Check if the search term is not empty before using it in contains
        %                 if ~isempty(search_target_brain_structure_among_raster_data)
        %                    current_group_files = current_group_files & contains(list_of_required_files.overlapBlocksFiles, search_target_brain_structure_among_raster_data);
        %                 end
        %         if ~isempty(search_target_brain_structure_among_raster_data)
        %             % Filter files based on the target_brain_structure, target_state, and listOfRequiredFiles
        %             current_group_files = list_of_required_files.overlapBlocksFiles(contains(list_of_required_files.overlapBlocksFiles, search_target_brain_structure_among_raster_data) & contains(list_of_required_files.overlapBlocksFiles, target_state_name));
        %         else
        %             % Filter files based on the target_state only
        %             current_group_files = list_of_required_files.overlapBlocksFiles(contains(list_of_required_files.overlapBlocksFiles, target_state_name));
        %         end
        if ~isempty(search_target_brain_structure_among_raster_data)
            % Filter files based on the target_brain_structure
            current_group_files = current_group_files(contains(current_group_files, search_target_brain_structure_among_raster_data));
        end
        
        % Ensure that only files with the correct target_brain_structure are included
        current_group_files = current_group_files(contains(current_group_files, ['_' target_brain_structure '_']));
        
        
        
        
        
        % Check if any files are present in the current group before proceeding
        if  ~isempty(current_group_files) %   any(current_group_files)
            
            
            % Initialize cell arrays to store data from each file
            extracted_raster_data = cell(length(current_group_files), 1);
            extracted_raster_labels = cell(length(current_group_files), 1);
            extracted_raster_site_info = cell(length(current_group_files), 1);
            
            
            
            % Loop through each file in the list
            for c = 1:length(current_group_files)
                % Get the current file from the list
                current_file = current_group_files{c};
                
                % Load the data from the current file
                data = load([current_file]);
                
                % Extract variables from the loaded data
                extracted_raster_data{c} = data.raster_data;
                extracted_raster_labels{c} = data.raster_labels;
                extracted_raster_site_info{c} = data.raster_site_info;
            end
            
            % Check if files can be merged based on relevant parts of the filenames
            can_be_merged = true(length(current_group_files), 1);
            reference_parts = strsplit(current_group_files{1}, '_');
            
            for p = 2:length(current_group_files)
                current_parts = strsplit(current_group_files{p}, '_');
                can_be_merged(p) = isequal(reference_parts(1:9), current_parts(1:9));
            end
            
            
            
            % Filter out files that cannot be merged
            extracted_raster_data = extracted_raster_data(can_be_merged);
            extracted_raster_labels = extracted_raster_labels(can_be_merged);
            extracted_raster_site_info = extracted_raster_site_info(can_be_merged);
            
            
            %  Proceed with merging only if there are files that can be merged
            if any(can_be_merged)
                % Concatenate raster_data using vertcat
                raster_data = vertcat(extracted_raster_data{:});
                
                % Concatenate raster_labels fields separately
                raster_labels = struct(); % Initialize an empty struct for raster_labels
                
                fields_to_concatenate = {'trial_type', 'sideSelected', 'trial_type_side', 'stimulus_position_X_coordinate', 'stimulus_position_Y_coordinate', 'perturbation', 'block', 'run'};
                
                for field = fields_to_concatenate
                    field_name = char(field);
                    % Extract the values for the current field from each cell in the cell array
                    field_values = cellfun(@(x) x.(field_name), extracted_raster_labels, 'UniformOutput', false);
                    
                    % Concatenate the values into a single array and assign to the struct
                    raster_labels.(field_name) = [field_values{:}];
                end
                
                % Use the raster_site_info from the first file since they are assumed to be the same
                raster_site_info = extracted_raster_site_info{1};
                
                % Create a new filename for the merged file (using the first file's name)
                [~, base_name, ~] = fileparts(current_group_files{1});
                merged_filename = [OUTPUT_PATH_raster_dateOfRecording_Overlap_blocks erase(base_name, '_block_1') '_' targetBlockUsed '.mat'];
                
                % Save the merged data to a new file
                save(merged_filename, 'raster_data', 'raster_labels', 'raster_site_info');
            end
        end
    end
else
    % disp('The cell arrays are not equal.');
end


%%  Make Binned_data

Raster_data_dir = [OUTPUT_PATH_raster_dateOfRecording Overlap_blocks];
raster_data_directory_name =  [Raster_data_dir  '*' search_target_brain_structure_among_raster_data '_trial_state_' target_state_name '_' targetBlockUsed_among_raster_data '*'];
binned_data_file_name = create_binned_data_from_raster_data(raster_data_directory_name, save_prefix_name, settings.bin_width, settings.step_size);

load(binned_data_file_name);  % load the binned data
[~, filename_binned_data, ~] = fileparts(binned_data_file_name);

% smooth the data
binned_data = arrayfun(@(x) smoothdata(binned_data{x}, 2, settings.smoothing_method, settings.smoothing_window), 1:length(binned_data), 'UniformOutput', false);
save([Binned_data_dir filename_binned_data '_smoothed.mat'],'binned_data','binned_labels','binned_site_info');

%% Prepearing for decoding

%labels_to_use = {'instr_R', 'instr_L'};
% labels_to_use = {'choice_R', 'choice_L'};
% labels_to_use = {'instr_R', 'choice_R'};
% labels_to_use = {'instr_L', 'choice_L'};

switch labels_to_use
    case 'instr_R_instr_L'
        labels_to_use = {'instr_R', 'instr_L'};
    case 'choice_R_choice_L'
        labels_to_use = {'choice_R', 'choice_L'};
    case 'instr_R_choice_R'
        labels_to_use = {'instr_R', 'choice_R'};
    otherwise % 'instr_L_choice_L'
        labels_to_use = {'instr_L', 'choice_L'};
end


string_to_add_to_filename = '';
labels_to_use_string = strjoin(labels_to_use);

% Determining how many times each condition was repeated
for k = 1:150
    inds_of_sites_with_at_least_k_repeats = find_sites_with_k_label_repetitions(binned_labels.trial_type_side , k, labels_to_use);
    num_sites_with_k_repeats(k) = length(inds_of_sites_with_at_least_k_repeats);
end

%%  Begin the decoding analysis
%  6.  Create a datasource object
specific_label_name_to_use = 'trial_type_side';
num_cv_splits = settings.num_cv_splits; % 20 cross-validation runs

if isfield(list_of_required_files, 'overlapBlocksFilesAcrossSessions') && isequal(listOfRequiredFiles, list_of_required_files.overlapBlocksFilesAcrossSessions)
    settings.create_simultaneously_recorded_populations = 0;
end


% Create a datasource that takes our binned data, and specifies that we want to decode
ds = basic_DS([Binned_data_dir filename_binned_data '_smoothed.mat'], specific_label_name_to_use, num_cv_splits);

% can have multiple repetitions of each label in each cross-validation split (which is a faster way to run the code that uses most of the data)
ds.num_times_to_repeat_each_label_per_cv_split = settings.num_times_to_repeat_each_label_per_cv_split;

% optionally can specify particular sites to use
ds.sites_to_use = find_sites_with_k_label_repetitions(binned_labels.trial_type_side, num_cv_splits, labels_to_use);

% flag, which specifies that the data was recorded at the simultaneously

ds.create_simultaneously_recorded_populations = settings.create_simultaneously_recorded_populations;

% can do the decoding on a subset of labels
ds.label_names_to_use = labels_to_use; % {'instr_R', 'instr_L'} {'choice_R', 'choice_L'}

% Creating a feature-preprocessor (FP) object
% create a feature preprocessor that z-score normalizes each neuron
% note that the FP objects are stored in a cell array, which allows multiple FP objects to be used in one analysis
the_feature_preprocessors{1} = zscore_normalize_FP;

% other useful options:

% can include a feature-selection features preprocessor to only use the top k most selective neurons
% fp = select_or_exclude_top_k_features_FP;
% fp.num_features_to_use = 50;   % use only the 25 most selective neurons as determined by a univariate one-way ANOVA
% the_feature_preprocessors{2} = fp;
% string_to_add_to_filename = ['_top_ num2str(fp.num_features_to_use) '_units_'];



% Creating a classifier (CL) object
% create the CL object
the_classifier = max_correlation_coefficient_CL;
% the_classifier = libsvm_CL;
% the_classifier.multiclass_classificaion_scheme = 'one_vs_all';

% Creating a cross-validator (CV) object
% create the CV object
the_cross_validator = standard_resample_CV(ds, the_classifier, the_feature_preprocessors);

% Set how many times the outer 'resample' loop is run
the_cross_validator.num_resample_runs = settings.num_resample_runs;

% other useful options:

% can greatly speed up the run-time of the analysis by not creating a full TCT matrix (i.e., only trainging and testing the classifier on the same time bin)
the_cross_validator.test_only_at_training_times = 1;



% Running the decoding analysis and saving the results
DECODING_RESULTS = the_cross_validator.run_cv_decoding;


save_file_name = [Binned_data_dir filename_binned_data '_' labels_to_use_string string_to_add_to_filename '_DECODING_RESULTS.mat'];
save(save_file_name, 'DECODING_RESULTS');


% Plot decoding
sdndt_Sim_LIP_dPul_NDT_plot_decoding_results(save_file_name);
