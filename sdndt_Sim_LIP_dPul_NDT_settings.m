function [base_path, INPUT_PATH, OUTPUT_PATH_raster, OUTPUT_PATH_binned, monkey_prefix, settings] = sdndt_Sim_LIP_dPul_NDT_settings(monkey, injection, typeOfSessions)
% This code contains the variables needed to run all the basic codes (raster data creation, file list, decoding)
% Will automatically run when the main codes are run


%% Determine the base_path based on the selected set

% Experiment: Functional interactions between the dorsal pulvinar and LIP during spatial target selection and oculomotor planning
if strcmp(injection, '2') 
    base_path = 'Y:\Personal\Masha/Sim_dPul_LIP/NDT/Functional_interaction_experiment_dPul_LIP/';
    
% Experiment: The effect of unilateral dorsal pulvinar inactivation on bi-hemispheric LIP activity
elseif strcmp(injection, '1')
    base_path = 'Y:\Personal\Masha/Sim_dPul_LIP/NDT/Inactivation_experiment/inactivation_sessions/';
elseif strcmp(injection, '0')
    base_path = 'Y:\Personal\Masha/Sim_dPul_LIP/NDT/Inactivation_experiment/control_sessions/';
    
else
    error('Invalid selection. Use ''control'' or ''injection'' for selectedSet.');
end



%% for creating raster_data and binned_data output path
INPUT_PATH = 'Y:/Projects/Simultaneous_dPul_PPC_recordings/ephys/';
 
if strcmp(injection, '1') % For injection sessions
    if strcmp(typeOfSessions, 'left')
        typeOfSessions_folder = 'left_dPul_injection/';
    elseif strcmp(typeOfSessions, 'right')
        typeOfSessions_folder = 'right_dPul_injection/';
    elseif strcmp(typeOfSessions, 'all')
        typeOfSessions_folder = 'both_R_and_L_dPul_injection/';
    else
        error('Invalid typeOfSessions. Use ''left'', ''right'', or ''all''.');
    end
    OUTPUT_PATH_raster = [base_path 'raster/' typeOfSessions_folder];
    OUTPUT_PATH_binned = [base_path 'binned/' typeOfSessions_folder];
else % For control sessions (Inactivation experiment) and Functional interaction experiment (dPul and LIP)
    OUTPUT_PATH_raster = [base_path 'raster/'];
    OUTPUT_PATH_binned = [base_path 'binned/'];
end


 % Create the folder for the list of required files
    if strcmp(monkey, 'Linus')
        monkey_prefix = 'Lin_';
    elseif strcmp(monkey, 'Bacchus')
        monkey_prefix = 'Bac_';
    else
        error('Invalid monkey name. Use ''Linus'' or ''Bacchus''.');
    end


%% settings
settings.windowAroundEvent = 0.5; % s:  epoch to take around the trigger event

% data preparation to create binned_data
settings.start_time = 1; % ms
settings.bin_width = 100; % ms
settings.step_size = 25; % ms

% data preparation
settings.bin_dur = 50; % ms
settings.smoothing_window = 3; % number of bins to smooth over
settings.smoothing_method = 'gaussian'; % movmean / gaussian, see smoothdata




% Decoding
settings.num_cv_splits = 4; % because size of curr_trial_to_use from baisic_DS function is 35x1 (num_cv_splits*num_times_to_repeat_each_label_per_cv_split = 34)

%settings.num_cv_splits_approach_folder = ['max_num_cv_splits/'];
settings.num_cv_splits_approach_folder = ['same_num_cv_splits/'];

settings.num_resample_runs = 50;

% additiobal
settings.num_times_to_repeat_each_label_per_cv_split = 2; % can have multiple repetitions of each label in each cross-validation split (which is a faster way to run the code that uses most of the data)
settings.create_simultaneously_recorded_populations = 1; % flag, which specifies that the data was recorded at the simultaneously (if not simultaneously - 0)

% plotting
settings.time_lim = [0 1000]; % s, relative to cue onset
settings.y_lim = [20 100];

% settings.significant_event_times = [0 500 1000]; % for plotting relevant trial events
% the xline(500) function in the sdndt_Sim_LIP_dPul_NDT_plot_decoding_results.m code is used for this purpose

settings.errorbar_type_to_plot = 1; % 1 -If this is set to 1, then the standard deviations over resample runs (i.e., stdev.over_resamples) is used. 
