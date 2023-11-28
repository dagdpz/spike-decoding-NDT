function [binned_data, binned_labels, binned_site_info] = sdndt_Sim_LIP_dPul_NDT_decoding_per_block(mat_filename, target_brain_structure, target_state, listOfRequiredFiles)
% This code loads one population**.mat file and converts it to a raster_data, array 0 and 1.
% The code converts the received raster data into binned data and then performs decoding. 

% TEST MODE. 
% To check how the code works, we load only one file as input (one session = one day of recording). For example:
% sdndt_Sim_LIP_dPul_NDT_decoding_per_block('C:\Projects\Sim_dPul_LIP\NDT\raster\List_of_required_files\sdndt_Sim_LIP_dPul_NDT_list_of_required_files.mat', 'dPul_L', 4, 'firstBlockFiles');

% DECODING MODE. 
% sdndt_Sim_LIP_dPul_NDT_decoding(mat_filename, target_state, target_brain_structure);
% mat_filename - list of files that are required for decoding 
% target_state - 6 - cue on , 4 - target acquisition
% target_brain_structure = 'dPul_L', 'LIP_L', if both 'LIP_L_dPul_L'



load(mat_filename);
%load('C:\Projects\Sim_dPul_LIP\NDT\raster\List_of_required_files\sdndt_Sim_LIP_dPul_NDT_list_of_required_files.mat'); % once debug is complete, comment this line and enable the line above

run('sdndt_Sim_LIP_dPul_NDT_setting');
%run('sdndt_Sim_LIP_dPul_NDT_make_raster');




%% Make Binned_data
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
    otherwise 'commonBlocksFiles'
        listOfRequiredFiles = list_of_required_files.commonBlocksFiles  ;
end

switch target_state
    case 6
        target_state_name = 'cueON';
    case 4
        target_state_name = 'GOsignal';
    otherwise
        fprintf('Invalid target_state value: %d\n', target_state);
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
    
    all_target_brain_structure = {'dPul_L', 'LIP_L', 'other_structure'}; % Example value, replace it with your actual variable
    
    switch target_brain_structure
        case 'dPul_L'
            search_target_brain_structure_among_raster_data = 'dPul_L';
        case 'LIP_L'
            search_target_brain_structure_among_raster_data = 'LIP_L';
        otherwise
            % Check if target_structure_of_brain is in all_brain_structures
            if any(strcmp(target_brain_structure, all_target_brain_structure))
                search_target_brain_structure_among_raster_data = target_structure_of_brain;
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
        % Check for the presence of 'block_1', 'block_2', and 'block_3'
        if contains(targetBlock, 'block_1')
            targetBlockUsed = 'block_1';
        elseif contains(targetBlock, 'block_2')
            targetBlockUsed = 'block_2';
        elseif contains(targetBlock, 'block_3')
            targetBlockUsed = 'block_3';
        else
            % Handle the case when none of the blocks is specified
            error('Invalid targetBlock value: %s', targetBlock);
        end
end
   
     save_prefix_name = [OUTPUT_PATH_binned 'Binned_Sim_LIP_dPul__NDT_data_for_' target_brain_structure '_' target_state_name '_' targetBlockUsed];
    if ~exist(OUTPUT_PATH_binned,'dir')
        mkdir(OUTPUT_PATH_binned);
    end
    
    raster_data_directory_name =  [OUTPUT_PATH_raster '*' search_target_brain_structure_among_raster_data '_trial_state_' target_state_name '_' targetBlockUsed '*'];
    binned_data_file_name = create_binned_data_from_raster_data(raster_data_directory_name, save_prefix_name, settings.bin_width, settings.step_size);
    
    load(binned_data_file_name);  % load the binned data
    [~, filename_binned_data, ~] = fileparts(binned_data_file_name);
    
    % smooth the data 
binned_data = arrayfun(@(x) smoothdata(binned_data{x}, 2, settings.smoothing_method, settings.smoothing_window), 1:length(binned_data), 'UniformOutput', false);
save([OUTPUT_PATH_binned filename_binned_data '_smoothed.mat'],'binned_data','binned_labels','binned_site_info'); 


 labels_to_use = {'instr_R', 'instr_L'};
% labels_to_use = {'choice_R', 'choice_L'};
% labels_to_use = {'instr_R', 'choice_R'};
% labels_to_use = {'instr_L', 'choice_L'};

string_to_add_to_filename = '';
labels_to_use_string = strjoin(labels_to_use);

% Determining how many times each condition was repeated
for k = 1:91
    inds_of_sites_with_at_least_k_repeats = find_sites_with_k_label_repetitions(binned_labels.trial_type_side , k, labels_to_use);
    num_sites_with_k_repeats(k) = length(inds_of_sites_with_at_least_k_repeats);
end

%%  Begin the decoding analysis
%  6.  Create a datasource object
specific_label_name_to_use = 'trial_type_side'; 
num_cv_splits = settings.num_cv_splits; % 20 cross-validation runs

% Create a datasource that takes our binned data, and specifies that we want to decode
ds = basic_DS([OUTPUT_PATH_binned filename_binned_data '_smoothed.mat'], specific_label_name_to_use, num_cv_splits);

% can have multiple repetitions of each label in each cross-validation split (which is a faster way to run the code that uses most of the data)
% ds.num_times_to_repeat_each_label_per_cv_split = 2;

% optionally can specify particular sites to use
ds.sites_to_use = find_sites_with_k_label_repetitions(binned_labels.trial_type_side, num_cv_splits, labels_to_use);  

% flag, which specifies that the data was recorded at the simultaneously  
ds.create_simultaneously_recorded_populations =1;

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


save_file_name = [OUTPUT_PATH_binned filename_binned_data '_' labels_to_use_string string_to_add_to_filename '_DECODING_RESULTS.mat'];
save(save_file_name, 'DECODING_RESULTS');

% Plot decoding
sdndt_Sim_LIP_dPul_NDT_plot_decoding_results(save_file_name);


