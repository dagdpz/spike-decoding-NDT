function sdndt_Sim_LIP_dPul_NDT_plot_decoding_results(save_file_name)

run('sdndt_Sim_LIP_dPul_NDT_setting');

load(save_file_name);

if isfield(DECODING_RESULTS.DS_PARAMETERS,'the_training_label_names')
    
    labels_to_use_string = [strjoin(vertcat(vertcat(DECODING_RESULTS.DS_PARAMETERS.the_training_label_names{:}))) ' as train ' ...
                            strjoin(vertcat(vertcat(DECODING_RESULTS.DS_PARAMETERS.the_test_label_names{:}))) ' as test'];

else
    labels_to_use_string = strjoin(DECODING_RESULTS.DS_PARAMETERS.label_names_to_use); 
end


result_names{1} = save_file_name;
% create the plot results object
plot_obj = plot_standard_results_object(result_names);

% put a line at the time when the stimulus was shown 
% plot_obj.significant_event_times = setting.significant_event_times;
% the xline(500) function below is used for this purpose

plot_obj.errorbar_file_names = result_names;
plot_obj.errorbar_type_to_plot = settings.errorbar_type_to_plot;

% display the results
plot_obj.plot_results;

title(labels_to_use_string);

xline(500); 
set(gca,'Xlim',settings.time_lim, 'Ylim',settings.y_lim);

saveas(gcf, [save_file_name(1:end-4) '_DA_as_a_function_of_time.png']);

