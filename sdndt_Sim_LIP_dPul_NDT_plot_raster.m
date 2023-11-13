function [raster_data, raster_labels, raster_site_info] = sdndt_Sim_LIP_dPul_NDT_plot_raster(mat_filename)
%sdndt_Sim_LIP_dPul_NDT_plot_raster('C:\Projects\Sim_dPul_LIP\NDT\Lin_20211109_01_trial_state_cueON.mat');

load(mat_filename);

% view the rasters from one neuron
subplot(1, 2, 1)
imagesc(~raster_data); colormap gray
line([500 500], get(gca, 'YLim'), 'color', [1 0 0]);
ylabel('Trials')
xlabel('Time (ms)')
title('rasters')
 
% view the PSTH for one neuron
subplot(1, 2, 2)
bar(sum(raster_data));
line([500 500], get(gca, 'YLim'), 'color', [1 0 0]);
ylabel('Number of spikes')
xlabel('Time (ms)')
title('PSTH')