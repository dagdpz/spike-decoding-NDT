function [raster_data, raster_labels, raster_site_info] = sdndt_Sim_LIP_dPul_NDT_decoding(mat_filename)
% [raster_data, raster_labels, raster_site_info] = sdndt_Sim_LIP_dPul_NDT_decoding('Y:\Projects\Simultaneous_dPul_PPC_recordings\ephys\dPul_LIP_Lin_20211109\population_Linus_20211109.mat');

% This code loads one population**.mat file and converts it to a raster_data, array 0 and 1.

load(mat_filename);
%load('Y:\Projects\Simultaneous_dPul_PPC_recordings\ephys\dPul_LIP_Lin_20211109\population_Linus_20211109.mat'); % once debug is complete, comment this line and enable the line above

run('sdndt_Sim_LIP_dPul_NDT_settings');


%%Make raster_data 

if ~exist(OUTPUT_PATH_raster,'dir')
    mkdir(OUTPUT_PATH_raster);
end

target_state = 6; % 6 - cue on , 4 - target acquisition

switch target_state
    case 6
        target_state_name = 'cueON';
    case 4
        target_state_name = 'GOsignal';
    otherwise
        fprintf('Invalid target_state value: %d\n', target_state);
        % You might want to handle the case when target_state is neither 6 nor 4
end

units_skipped = 0; % Initialize the counter for skipped units
columnsNumberBasedOnWindow = settings.windowAroundEvent*2*1000; % windowAroundEvent in ms

num_units = size(population, 2);

for u = 1:num_units
    num_trial = size (population(u).trial, 2 );
    
    % Initialize cell arrays
    raster_labels.trial_type = cell(1, num_trial);
    raster_labels.sideSelected = cell(1, num_trial);
    raster_labels.trial_type_side = cell(1, num_trial);
    raster_labels.stimulus_position_X_coordinate = cell(1, num_trial);
    raster_labels.stimulus_position_X_coordinate = cell(1, num_trial);
    raster_labels.perturbation = cell(1, num_trial);
    raster_labels.block = cell(1, num_trial);
    raster_labels.run = cell(1, num_trial);
    
    % Initialize numeric array for raster_data
    raster_data = NaN(num_trial, columnsNumberBasedOnWindow);
    
    blocks_present = []; % Track the blocks present in the trials
    
    
    for t = 1:num_trial
        
        if population(u).trial(t).success == 0 ;% Check if the trial should be excluded based on success value
            fprintf('Trial %d in unit %d excluded from analysis (success = 0).\n', t, u);
            continue;  % Skip the rest of the loop and move to the next trial
        end
        % choiceVariable = [population(45).trial(:).success]; valueToCount = true; howManySuccessTrials = sum(choiceVariable == valueToCount);
        
        blocks_present = unique([blocks_present, population(u).trial(t).block]); % Add the block information to the blocks_present array
        
        
        
        %%% raster_data
        state_index = find(population(u).trial(t).states == target_state); % Find the index of the target state in the 'states' array
        if isempty(state_index)
            fprintf('State %d not found. Excluding from analysis.\n', target_state);
        else
            onsetTimeOfRequiredStage (t) = population(u).trial(t).states_onset(state_index); % Use the index to retrieve the corresponding value from 'states_onset'
            raster_data(t, :) = histcounts(population(u).trial(t).arrival_times, (onsetTimeOfRequiredStage(t) - settings.windowAroundEvent):0.001:(onsetTimeOfRequiredStage(t) + settings.windowAroundEvent));
        end
        
        
        %%% raster_labels
        if population(u).trial(t).choice
            raster_labels.trial_type{1, t} =  'choice';
        else
            raster_labels.trial_type{1, t} =  'instr';
        end
        
        if real(population(u).trial(t).tar_pos) > 0 % Convert positive values to 'R' and negative values to 'L'
            raster_labels.sideSelected{1, t} = 'R';
        else
            raster_labels.sideSelected{1, t} = 'L';
        end
        
        raster_labels.trial_type_side {1, t} = append(raster_labels.trial_type{1, t},'_',raster_labels.sideSelected{1, t});
        
        X_coordinate = real(population(u).trial(t).tar_pos);
        Y_coordinate = imag(population(u).trial(t).tar_pos);
        raster_labels.stimulus_position_X_coordinate{1, t} = X_coordinate;
        raster_labels.stimulus_position_Y_coordinate{1, t} = Y_coordinate;
        
        raster_labels.perturbation{1, t} = population(u).trial(t).perturbation;
        raster_labels.block{1, t} = population(u).trial(t).block;
        raster_labels.run{1, t} = population(u).trial(t).run;
        
    end
    
   
    %%% raster_site_info
    raster_site_info.recording_channel = population(u).channel;
    raster_site_info.session_ID = population(u).unit_ID(1:12);
    raster_site_info.unit_ID = population(u).unit_ID;
    raster_site_info.block_unit = [population(u).block_unit{:}];
    raster_site_info.perturbation_site = population(u).perturbation_site;
    raster_site_info.SNR_rating = population(u).SNR_rating;
    raster_site_info.Single_rating = population(u).Single_rating;
    raster_site_info.stability_rating = population(u).stability_rating;
    raster_site_info.site_ID = population(u).site_ID;
    raster_site_info.target = population(u).target;
    raster_site_info.grid_x = population(u).grid_x;
    raster_site_info.grid_y = population(u).grid_y;
    raster_site_info.electrode_depth = population(u).electrode_depth;
    
        
    
    raster_data = raster_data(~isnan(raster_data(:, 1)), :); % Remove NaN rows (trials with success == 0) from raster_data
    raster_labels.trial_type = raster_labels.trial_type(~cellfun('isempty', raster_labels.trial_type)); % Remove empty cells (trials with success == 0) from raster_data
    raster_labels.sideSelected = raster_labels.sideSelected(~cellfun('isempty', raster_labels.sideSelected));
    raster_labels.trial_type_side = raster_labels.trial_type_side(~cellfun('isempty', raster_labels.trial_type_side));
    raster_labels.stimulus_position_X_coordinate = raster_labels.stimulus_position_X_coordinate(~cellfun('isempty', raster_labels.stimulus_position_X_coordinate));
    raster_labels.stimulus_position_Y_coordinate = raster_labels.stimulus_position_Y_coordinate(~cellfun('isempty', raster_labels.stimulus_position_Y_coordinate));
    raster_labels.perturbation = raster_labels.perturbation(~cellfun('isempty', raster_labels.perturbation));
    raster_labels.block = raster_labels.block(~cellfun('isempty', raster_labels.block));
    raster_labels.run = raster_labels.run(~cellfun('isempty', raster_labels.run));
    
    
    % Check if both blocks 1 and 2 are present in the trials
    if ismember(1, blocks_present) && ismember(2, blocks_present)
        % Save data only if both blocks 1 and 2 are present
        filename = [OUTPUT_PATH_raster population(u).unit_ID '_raster_trial_state_' target_state_name '.mat'];
        save(filename, 'raster_data', 'raster_labels', 'raster_site_info');
    else
        fprintf('Skipping unit %d because it does not have both blocks 1 and 2.\n', u);
        units_skipped = units_skipped + 1;
    end
    
    %     filename = [OUTPUT_PATH_raster population(u).unit_ID '_raster_trial_state_' target_state_name '.mat'];
    %     save(filename,'raster_data', 'raster_labels', 'raster_site_info')
end

fprintf('%d units out of %d for the file %s not taken in the analysis.\n', units_skipped, num_units, mat_filename);
    
    
    %% Make Binned_data
    % Add the path to the NDT so add_ndt_paths_and_init_rand_generator can be called
    toolbox_basedir_name = 'Y:\Sources\ndt.1.0.4';
    addpath(toolbox_basedir_name);
    % Add the NDT paths using add_ndt_paths_and_init_rand_generator
    add_ndt_paths_and_init_rand_generator;
    
    save_prefix_name = [OUTPUT_PATH_binned 'Binned_Sim_LIP_dPul__NDT_data_' target_state_name];
    if ~exist(OUTPUT_PATH_binned,'dir')
        mkdir(OUTPUT_PATH_binned);
    end
    
    
%     % Upload the necessary files: only cueON or only GOsignal
%     file_list = dir(fullfile(OUTPUT_PATH_raster, ['*' target_state_name '*.mat'])); %  Use dir to list all files in the directory
%     for f = 1:numel(file_list) % Loop through the files and load them
%         file_path = fullfile(OUTPUT_PATH_raster, file_list(f).name);
%         load(file_path);
%     end
    
    raster_data_directory_name = [OUTPUT_PATH_raster '*' target_state_name '*']
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


