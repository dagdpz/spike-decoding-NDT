function [raster_data, raster_labels, raster_site_info] = sdndt_Sim_LIP_dPul_NDT_plot_raster(mat_filename)
% sdndt_Sim_LIP_dPul_NDT_plot_raster('C:\Projects\Sim_dPul_LIP\NDT\raster\Lin_20211109_01_raster_trial_state_cueON.mat');
% sdndt_Sim_LIP_dPul_NDT_plot_raster('C:\Projects\Sim_dPul_LIP\NDT\raster\Lin_20211109_01_raster_trial_state_GOsignal.mat');



% Replace 'your_file_name.mat' with the actual file name you want to process
load(mat_filename);

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

%
% % view the rasters from one neuron
% subplot(1, 2, 1)
% imagesc(~raster_data); colormap gray
% line([500 500], get(gca, 'YLim'), 'color', [1 0 0]);
% ylabel('Trials')
% xlabel('Time (ms)')
% %title('rasters')
% set(gca, 'Position', get(gca, 'Position') + [0, 0, 0, -0.05]); % Adjust the subplot to make room for the subtitle
%
% main_title_rasters = title('rasters');
% %title_pos_rasters = get(main_title_rasters, 'Position'); set(main_title_rasters, 'Position', title_pos_rasters + [0, -13, 0]);
% set(main_title_rasters, 'Position', get(main_title_rasters, 'Position') + [0, -18, 0]); % Adjust the main title position
%
% subtitle_str_rasters = [char(strrep(raster_site_info.unit_ID, '_', ' ')) ', ' char(strrep(raster_site_info.target, '_', ' ')) ', ' target_state_name];
% subtitle_rasters = text('String', subtitle_str_rasters, 'Position', [0.5, 1.03], ...
%     'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
%     'FontSize', 10, 'FontWeight', 'normal', 'Units', 'normalized');
% %current_position_r = get(main_title_rasters, 'Position'); new_position_r = current_position_r + [0, 3, 0]; set(main_title_rasters, 'Position', new_position_r);


% Get unique trial types
trial_types = unique(raster_labels.trial_type_side);

%presentation_times = size(raster_data, 2);

 figure;
% Create subplots for each trial type
for i = 1:length(trial_types)
    trial_type = trial_types(i);
    
    % Filter data for the current trial type
    trial_data = raster_data(:, strcmp(raster_labels.trial_type_side, trial_type));
    %sorted_trial_data = zeros(size(raster_data));
    subplot(2, 4, i); % Adjust the subplot arrangement as needed
    
    % Find the indices of trials for the current trial type
    trial_indices = find(strcmp(raster_labels.trial_type_side, trial_type));
    % Get the corresponding presentation times for the current trial type
    %presentation_times_trial_type = raster_labels.presentation_times(trial_indices);
    % Sort the trials based on presentation times
    [~, sorted_indices] = ismember(trial_indices, 1:length(raster_labels.trial_type_side)); %[~, sorted_indices] = sort(raster_labels.trial_type_side == trial_type);

    
    % Plot raster for the current trial type
    imagesc(~trial_data(:, trial_indices(sorted_indices))); %  imagesc(~trial_data);
    colormap gray;
    axis([0 1000 0 400]);
    line([500 500], get(gca, 'YLim'), 'color', [1 0 0]);
    ylabel('Trials');
    xlabel('Time (ms)');
    %set(gca, 'Position', get(gca, 'Position') + [0, 0, 0, -0.05]);
    
    % Adjust titles and subtitles
    main_title_rasters = title('rasters');  % title(['Rasters for ' char(strrep(raster_site_info.unit_ID, '_', ' '))]);
    subtitle_str_rasters = [char(strrep(raster_site_info.unit_ID, '_', ' ')) ', ' char(strrep(raster_site_info.target, '_', ' ')) ', ' target_state_name ', ' trial_type];
    subtitle_rasters = text('String', subtitle_str_rasters, 'Position', [0.5, 1.03], ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
        'FontSize', 10, 'FontWeight', 'normal', 'Units', 'normalized');
    
    hold on
    
%     % view the PSTH for one neuron
%     subplot(2, 4, i)
%     bar(sum(raster_data));
%     line([500 500], get(gca, 'YLim'), 'color', [1 0 0]);
%     ylabel('Number of spikes')
%     xlabel('Time (ms)')
%     set(gca, 'Position', get(gca, 'Position') + [0, 0, 0, -0.05]); % Adjust the subplot to make room for the subtitle
%     
%     main_title_PSTH = title('PSTH');
%     %title_pos_PSTH = get(main_title_rasters, 'Position'); set(main_title_PSTH, 'Position', title_pos_PSTH + [0, 36, 0]);
%     set(main_title_PSTH, 'Position', get(main_title_PSTH, 'Position') + [0, 1, 0]); % Adjust the main title position if needed
%     
%     subtitle_str_PSTH = [char(strrep(raster_site_info.unit_ID, '_', ' ')) ', ' char(strrep(raster_site_info.target, '_', ' ')) ', ' target_state_name];
%     subtitle_PSTH = text('String', subtitle_str_PSTH, 'Position', [0.5, 1.03], ...
%         'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
%         'FontSize', 10, 'FontWeight', 'normal', 'Units', 'normalized');
    
    
    %Plot PSTH for the current trial type
    subplot(2, 4, length(trial_types) + i);
    bar(sum(trial_data));
    line([500 500], get(gca, 'YLim'), 'color', [1 0 0]);
    ylabel('Number of spikes');
    xlabel('Time (ms)');
    set(gca, 'Position', get(gca, 'Position') + [0, 0, 0, -0.05]);
    
    % Adjust titles and subtitles
    main_title = title(['PSTH for ' char(strrep(raster_site_info.unit_ID, '_', ' '))]);
    subtitle_str = [char(strrep(raster_site_info.target, '_', ' ')) ', ' target_state_name ', Trial Type: ' trial_type];
    subtitle = text('String', subtitle_str, 'Position', [0.5, 1.03], ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
        'FontSize', 10, 'FontWeight', 'normal', 'Units', 'normalized');
    


end
main_title.Position = main_title.Position + [0, 1, 0];

set(gcf, 'Position',[180 280 1300 720])
