%function sdndt_Sim_LIP_dPul_decode_data(OUTPUT_PATH_raster)
% sdndt_Sim_LIP_dPul_decode_data('C:\Projects\Sim_dPul_LIP\NDT\...');

% Add the path to the NDT so add_ndt_paths_and_init_rand_generator can be called
toolbox_basedir_name = 'Y:\Sources\ndt.1.0.4';
addpath(toolbox_basedir_name);
% Add the NDT paths using add_ndt_paths_and_init_rand_generator
add_ndt_paths_and_init_rand_generator;

run('sdndt_Sim_LIP_dPul_NDT_settings');


pattern = 'Lin_\d{8}_\d{2}_trial_state_cueON\.mat'; % Define the pattern using regular expressions
fileList = dir(fullfile(OUTPUT_PATH_raster, '*.mat'));% Use the dir function to get a list of files in the folder
matchingFiles = {}; % Initialize an empty cell array to store matching file names
for i = 1:length(fileList) % Iterate through the list of files and check if the name matches the pattern
    fileName = fileList(i).name;
    if ~isempty(regexp(fileName, pattern, 'once'))
        matchingFiles{end+1} = fullfile(OUTPUT_PATH_raster, fileName);
    end
end
%load(OUTPUT_PATH_raster);

dir(OUTPUT_PATH_binned);
bin_width = 150;
step_size = 50;
save_prefix_name = 'Binned_Sim_LIP_dPul__NDT_data'; 

if ~exist(OUTPUT_PATH_binned,'dir')
    mkdir(OUTPUT_PATH_binned);
end
create_binned_data_from_raster_data(OUTPUT_PATH_binned, save_prefix_name, bin_width, step_size);
