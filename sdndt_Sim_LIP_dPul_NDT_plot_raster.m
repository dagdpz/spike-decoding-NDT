function [raster_data, raster_labels, raster_site_info] = sdndt_Sim_LIP_dPul_NDT_plot_raster(mat_filename)
% sdndt_Sim_LIP_dPul_NDT_plot_raster('C:\Projects\Sim_dPul_LIP\NDT\raster\Lin_20211109_01_raster_trial_state_cueON.mat');
% sdndt_Sim_LIP_dPul_NDT_plot_raster('C:\Projects\Sim_dPul_LIP\NDT\raster\Lin_20211109_01_raster_trial_state_GOsignal.mat');

load(mat_filename);

% view the rasters from one neuron
subplot(1, 2, 1)
imagesc(~raster_data); colormap gray
line([500 500], get(gca, 'YLim'), 'color', [1 0 0]);
ylabel('Trials')
xlabel('Time (ms)')
%title('rasters')
set(gca, 'Position', get(gca, 'Position') + [0, 0, 0, -0.05]); % Adjust the subplot to make room for the subtitle

main_title_rasters = title('rasters');
%title_pos_rasters = get(main_title_rasters, 'Position'); set(main_title_rasters, 'Position', title_pos_rasters + [0, -13, 0]);
set(main_title_rasters, 'Position', get(main_title_rasters, 'Position') + [0, -18, 0]); % Adjust the main title position 

subtitle_str_rasters = [char(strrep(raster_site_info.unit_ID, '_', ' ')) ', ' char(strrep(raster_site_info.target, '_', ' '))]; 
subtitle_rasters = text('String', subtitle_str_rasters, 'Position', [0.5, 1.03], ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
    'FontSize', 10, 'FontWeight', 'normal', 'Units', 'normalized');
%current_position_r = get(main_title_rasters, 'Position'); new_position_r = current_position_r + [0, 3, 0]; set(main_title_rasters, 'Position', new_position_r);


 
% view the PSTH for one neuron
subplot(1, 2, 2)
bar(sum(raster_data));
line([500 500], get(gca, 'YLim'), 'color', [1 0 0]);
ylabel('Number of spikes')
xlabel('Time (ms)')
set(gca, 'Position', get(gca, 'Position') + [0, 0, 0, -0.05]); % Adjust the subplot to make room for the subtitle

main_title_PSTH = title('PSTH');
%title_pos_PSTH = get(main_title_rasters, 'Position'); set(main_title_PSTH, 'Position', title_pos_PSTH + [0, 36, 0]);
set(main_title_PSTH, 'Position', get(main_title_PSTH, 'Position') + [0, 1, 0]); % Adjust the main title position if needed

subtitle_str_PSTH = [char(strrep(raster_site_info.unit_ID, '_', ' ')) ', ' char(strrep(raster_site_info.target, '_', ' '))]; 
subtitle_PSTH = text('String', subtitle_str_PSTH, 'Position', [0.5, 1.03], ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
    'FontSize', 10, 'FontWeight', 'normal', 'Units', 'normalized');


set(gcf, 'Position',[180 280 1300 720])
