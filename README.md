# spike-decoding-NDT
Decoding spiking activity with NDT 

Requires NDT: http://www.readout.info

# sdndt_Sim_LIP_dPul_NDT_settings.m
Сontains information about the base path (for the convenience of different users) and all other settings.

# sdndt_Sim_LIP_dPul_NDT_make_raster.m
Converts data from file type: "population_Linus_20211109.mat" to raster data.

Input:                                                                                                                                                                                                                          
mat-file: like population_Linus_20211109.mat, which contains variable population   

Output:                                                                                                                                                                                                                               
many mat-files: like Lin_20211109_01_raster_dPul_L_trial_state_cueON_block_1.mat, which contains variables raster_data, raster_labels, raster_site_info. 
for each unit, epoch around a certain trigger point (e.g. state_CueOn, state_GoSignal), and each block, separate mat-file

# sdndt_Sim_LIP_dPul_NDT_plot_raster.m
Plots spike rasters from each trial and peri-stimulus time histogram (PSTH) of the data.   

Input:                                                                                                                                                                                                                      
mat-file: like Lin_20211109_01_raster_dPul_L_trial_state_cueON_block_1.mat                                             

# sdndt_Sim_LIP_dPul_NDT_make_list_of_required_files.m
Groups files with raster data into groups: files containing only block 1, files containing only block 2, files containing only block 3, all files (from a particular session), and overlap blocks files (files that contain the same units in all blocks of a given session).    

Input:                                                                                                                                                                                                                       
many mat-files: like Lin_20211109_01_raster_dPul_L_trial_state_cueON_block_1.mat, which contains variables raster_data, raster_labels, raster_site_info. 

Output:                                                                                                                                                                                                       
mat-file:                                                                                                                                                                                                                             
like sdndt_Sim_LIP_dPul_NDT_20211109_list_of_required_files.mat (filelist for only one session), which contains variables list_of_required_files.firstBlockFiles, list_of_required_files.secondBlockFiles, list_of_required_files.thirdBlockFiles, list_of_required_files.allBlocksFiles, list_of_required_files.commonBlocksFiles   
like sdndt_Sim_LIP_dPul_NDT_allOverlapBlocksFiles_list_of_required_files.mat (filelist for all sessions), which contains variable list_of_required_files.overlapBlocksFilesAcrossSessions                                                              

# sdndt_Sim_LIP_dPul_NDT_decoding_per_block.m
Converts data from raster data into binned data (including merging binned data, if necessary), which it then uses for decoding.                                                                                                         

Input:                                                                                                                                                                                            
many mat-files: like Lin_20211109_01_raster_dPul_L_trial_state_cueON_block_1.mat,  which contains variables binned_data, binned_labels, binned_site_info   

Output:   
                                                                                                                                                                                                               
mat-files:                                                                                                                                                                                                                
like Binned_Sim_LIP_dPul__NDT_data_for_dPul_L_cueON_block_1_100ms_bins_25ms_sampled.mat, which contains variables binned_data, binned_labels, binned_site_info.
like Binned_Sim_LIP_dPul__NDT_data_for_dPul_L_cueON_block_1_100ms_bins_25ms_sampled_smoothed.mat, which contains smooth the binned data                                                    
like Binned_Sim_LIP_dPul__NDT_data_for_dPul_L_cueON_block_1_100ms_bins_25ms_sampled_instr_R instr_L_DECODING_RESULTS.mat which contains results of decoding                                             

picture:                                                                                                                                                                                                             
like Binned_Sim_LIP_dPul__NDT_data_for_dPul_L_cueON_block_1_100ms_bins_25ms_sampled_instr_R instr_L_DECODING_RESULTS_DA_as_a_function_of_time.png, which shows the decoding accuracy 

# sdndt_Sim_LIP_dPul_NDT_plot_decoding_results.m                   
The function contains additional settings for plotting decoding results.                    
