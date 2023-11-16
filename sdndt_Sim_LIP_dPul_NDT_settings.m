% sdndt_Sim_LIP_dPul_NDT_settings

% for creating raster_data
INPUT_PATH = 'Y:/Projects/Simultaneous_dPul_PPC_recordings/ephys/dPul_LIP_Lin_20211109/';
OUTPUT_PATH_raster = 'C:/Projects/Sim_dPul_LIP/NDT/raster/';

% for creating binned_data
OUTPUT_PATH_binned = 'C:/Projects/Sim_dPul_LIP/NDT/binned/';


settings.windowAroundEvent = 0.5; % s:  epoch to take around the trigger event

% data preparation to create binned_data
settings.bin_width = 150;
settings.step_size = 50;

% data preparation
settings.bin_dur = 50; % ms
settings.smoothing_window = 3; % number of bins to smooth over
settings.smoothing_method = 'gaussian'; % movmean / gaussian, see smoothdata


% Decoding
settings.num_cv_splits = 20;
settings.num_resample_runs = 50;

% plotting
settings.time_lim = [-1000 5000]; % s, relative to cue onset
settings.y_lim = [30 100];

settings.significant_event_times = [0 200 1200]; % for plotting relevant trial events

settings.errorbar_type_to_plot = 1;
