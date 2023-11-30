% sdndt_Sim_LIP_dPul_NDT_settings

base_path = 'C:/Projects/Sim_dPul_LIP/NDT/';



% for creating raster_data
INPUT_PATH = 'Y:/Projects/Simultaneous_dPul_PPC_recordings/ephys/dPul_LIP_Lin_20211109/';
OUTPUT_PATH_raster = [base_path 'raster/']; 

% Specify the directory to save the lists
OUTPUT_PATH_list_of_required_files = [OUTPUT_PATH_raster 'List_of_required_files/']; 
 
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
settings.num_cv_splits = 20;
settings.num_resample_runs = 50;

% plotting
settings.time_lim = [0 1000]; % s, relative to cue onset
settings.y_lim = [30 100];

% settings.significant_event_times = [0 500 1000]; % for plotting relevant trial events
% the xline(500) function in the sdndt_Sim_LIP_dPul_NDT_plot_decoding_results.m code is used for this purpose

settings.errorbar_type_to_plot = 1;


