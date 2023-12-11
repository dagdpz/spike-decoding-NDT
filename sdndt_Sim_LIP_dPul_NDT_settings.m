% sdndt_Sim_LIP_dPul_NDT_settings

base_path = 'C:/Projects/Sim_dPul_LIP/NDT/';

% for creating raster_data
INPUT_PATH = 'Y:/Projects/Simultaneous_dPul_PPC_recordings/ephys/';
OUTPUT_PATH_raster = [base_path 'raster/']; 
 
% for creating binned_data
OUTPUT_PATH_binned = [base_path 'binned/'];



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
settings.num_cv_splits = 17; % because size of curr_trial_to_use from baisic_DS function is 35x1 (num_cv_splits*num_times_to_repeat_each_label_per_cv_split = 34) 
settings.num_resample_runs = 50;
% additiobal
settings.num_times_to_repeat_each_label_per_cv_split = 2; % can have multiple repetitions of each label in each cross-validation split (which is a faster way to run the code that uses most of the data)
settings.create_simultaneously_recorded_populations = 1; % flag, which specifies that the data was recorded at the simultaneously (if not simultaneously - 0)

% plotting
settings.time_lim = [0 1000]; % s, relative to cue onset
settings.y_lim = [30 100];

% settings.significant_event_times = [0 500 1000]; % for plotting relevant trial events
% the xline(500) function in the sdndt_Sim_LIP_dPul_NDT_plot_decoding_results.m code is used for this purpose

settings.errorbar_type_to_plot = 1;


