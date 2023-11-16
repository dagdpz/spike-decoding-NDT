# spike-decoding-NDT
Decoding spiking activity with NDT 

Requires NDT: http://www.readout.info

# sdndt_Sim_LIP_dPul_NDT_settings.m
Сontains information about the base path. This code is invented for the convenience of different users.

# sdndt_Sim_LIP_dPul_NDT_decoding.m
Converts data from file type: "population_Linus_20211109.mat" to raster data and binned data, which it then uses for decoding. 
Input:                                                                                                                                                                                                                           
mat-file: like population_Linus_20211109.mat, which contains variable population
Output:                                                                                                                                                                                                                                                     
mat-file: like Binned_Sim_LIP_dPul__NDT_data_cueON_150ms_bins_50ms_sampled.mat, which contains variables binned_data, binned_labels, binned_site_info.

# sdndt_Sim_LIP_dPul_NDT_plot_raster.m
Plots spike rasters from each trial and peri-stimulus time histogram (PSTH) of the data.
Input:                                                                                                                                                                                                                      
mat-file: like Lin_20211109_01_raster_trial_state_GOsignal.mat

# sdndt_Sim_LIP_dPul_NDT_make_raster.m
Converts data from file type: "population_Linus_20211109.mat" to raster data. 
Input:                                                                                                                                                                                                                          
mat-file: like population_Linus_20211109.mat, which contains variable population
Output:                                                                                                                                                                                                                               
mat-file: like Lin_20211109_02_raster_trial_state_cueON.mat, which contains variables raster_data, raster_labels, raster_site_info. 


