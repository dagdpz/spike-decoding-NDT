function [raster_data, raster_labels, raster_site_info] = sdndt_Sim_LIP_dPul_NDT_plot_raster(mat_filename)
% sdndt_Sim_LIP_dPul_NDT_plot_raster('C:\Projects\Sim_dPul_LIP\NDT\raster\Lin_20211109_01_raster_trial_state_cueON.mat');
% sdndt_Sim_LIP_dPul_NDT_plot_raster('C:\Projects\Sim_dPul_LIP\NDT\raster\Lin_20211109_01_raster_trial_state_GOsignal.mat');



% Replace 'your_file_name.mat' with the actual file name you want to process
load(mat_filename);

run('sdndt_Sim_LIP_dPul_NDT_settings');


% Extract information states from the file name
[~, filename, ~] = fileparts(mat_filename);
parts = strsplit(filename, '_');
state_info = parts{end}; % Extract the stage information from the file name


switch state_info
    case 'GOsignal'
        target_state_name = state_info;
    case 'cueON'
        target_state_name = state_info;
        % Add more cases for other possible stage_info values
        % case 'AnotherStage'
        %     target_state_name = state_info;
    otherwise
        error('Unrecognized stage information in the file name'); % Handle the case when the stage information is not recognized
end



% Get unique trial types
trial_types = unique(raster_labels.trial_type_side);

%presentation_times = size(raster_data, 2);

hFig = figure;
set(hFig, 'WindowState', 'maximized'); % Maximize the figure

% Create subplots for each trial type
for i = 1:length(trial_types)
    trial_type = trial_types(i);
    
    % Filter data for the current trial type
    trial_data = raster_data(:, strcmp(raster_labels.trial_type_side, trial_type));
    %sorted_trial_data = zeros(size(raster_data));
    subplot(2, 4, i); % Adjust the subplot arrangement as needed
    
    % Find the indices of trials for the current trial type
    trial_indices = find(strcmp(raster_labels.trial_type_side, trial_type));
	sorted_trial_data = zeros(size(raster_data, 1), size(raster_data, 2));
    sorted_trial_data(trial_indices, :) = raster_data(trial_indices, :);
    
    % Plot raster for the current trial type
    imagesc(~sorted_trial_data(trial_indices, :)); %imagesc(~trial_data(:, trial_indices(sorted_indices))); %  imagesc(~trial_data);
    colormap gray;
    %axis([0 1000 0 160]);
    line([500 500], get(gca, 'YLim'), 'color', [1 0 0]);
    ylabel('Trials');
    xlabel('Time (ms)');
    %set(gca, 'Position', get(gca, 'Position') + [0, 0, 0, -0.05]);
    
    % Set title only for subplot(2, 4, i)
    if i == 1
        main_title_rasters = ['RASTER'];
        setting_main_title_rasters = text('String', main_title_rasters, 'Position', [2.5, 1.14], ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
            'FontSize', 12, 'FontWeight', 'bold', 'Units', 'normalized');
        subtitle_str_rasters_per_group = [char(strrep(raster_site_info.unit_ID, '_', ' ')) ', ' char(strrep(raster_site_info.target, '_', ' ')) ', ' target_state_name];
        setting_subtitle_rasters_per_group = text('String', subtitle_str_rasters_per_group, 'Position', [2.5, 1.07], ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
            'FontSize', 11, 'FontWeight', 'normal', 'Units', 'normalized');
    end
    
    subtitle_str_rasters_per_pic = [trial_type];
    setting_subtitle_rasters_per_pic = text('String', subtitle_str_rasters_per_pic, 'Position', [0.5, 1.03], ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
        'FontSize', 10, 'FontWeight', 'normal', 'Units', 'normalized');
   
    
    
    hold on
 
    
    %Plot PSTH for the current trial type
    subplot(2, 4, length(trial_types) + i);
    
    end_time = length(raster_data);
    if (length(settings.bin_width) == 1) && (length(settings.step_size) == 1); % if a single bin width and step size have been specified, then create binned data that averaged data over bin_width sized bins, sampled at sampling_interval intervals
        bin_start_time = settings.start_time : settings.step_size : (end_time - settings.bin_width  + 1);
        bin_widths = settings.bin_width .* ones(size(bin_start_time));
    end
    sorted_data = sorted_trial_data(trial_indices, :);
    
    % Initialize bins with zeros (preallocation)
    bins = zeros(size(sorted_data, 1), length(bin_start_time));
    for b = 1:length(bin_start_time)
        bins(:, b) = mean(sorted_data(:, bin_start_time(b):(bin_start_time(b) + bin_widths(b) -1)), 2);
    end
    
    bar(sum(bins, 1));
    %bar(sum(sorted_trial_data(trial_indices, :), 1)); % bar(sum(trial_data));
    
    time_point_500ms_bin = find(bin_start_time <= 500, 1, 'last'); % Find the bin corresponding to 500 ms in the binned data
    line([time_point_500ms_bin time_point_500ms_bin], get(gca, 'YLim'), 'color', [1 0 0]); % % Plot the vertical line at the corresponding bin in the binned data
    %line([500 500], get(gca, 'YLim'), 'color', [1 0 0]);
    ylabel('Number of spikes');
    xlabel('Number of bins');
    %xlabel('Time (ms)');
    set(gca, 'Position', get(gca, 'Position') + [0, 0, 0, -0.05]);
    
    % Set title only for subplot(2, 4, length(trial_types) + i)
    if i == 1
        main_title_PSTH = ['PSTH'];
        setting_main_title_PSTH = text('String', main_title_PSTH, 'Position', [2.5, 1.14], ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
            'FontSize', 12, 'FontWeight', 'bold', 'Units', 'normalized');
        subtitle_str_PSTH_per_group = [char(strrep(raster_site_info.unit_ID, '_', ' ')) ', ' char(strrep(raster_site_info.target, '_', ' ')) ', ' target_state_name];
        setting_subtitle_PSTH_per_group = text('String', subtitle_str_rasters_per_group, 'Position', [2.5, 1.07], ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
            'FontSize', 11, 'FontWeight', 'normal', 'Units', 'normalized');
    end
    
    subtitle_str_PSTH_per_pic = [trial_type];
    setting_subtitle_PSTH_per_pic = text('String', subtitle_str_PSTH_per_pic, 'Position', [0.5, 1.03], ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
        'FontSize', 10, 'FontWeight', 'normal', 'Units', 'normalized');
    


end

