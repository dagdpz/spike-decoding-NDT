% Determination of parameters
num_cells_main = 150; % Total number of cells
num_labels_per_cell = 358; % Number of labels in each sub-cell

% Define training and test marks
training_labels = {'instr_L_training', 'instr_R_training', 'choice_L_training', 'choice_R_training'};
test_labels = {'instr_L_test', 'instr_R_test', 'choice_L_test', 'choice_R_test'};

% Initialisation of the structure
training_and_test_binned_labels = struct();
training_and_test_binned_labels.trial_type_side = cell(1, num_cells_main);

% Generation mode: ‘random’ for random distribution or ‘split’ for clear division
mode = 'split'; % Replace with ‘random’ for random distribution

switch mode
    case 'random'
        % Random distribution mode
        all_labels = [training_labels, test_labels]; % All tags
        
        for i = 1:num_cells_main
            % Generate random labels by selecting from all possible labels
            trial_labels = all_labels(randi(numel(all_labels), 1, num_labels_per_cell));
            training_and_test_binned_labels.trial_type_side{i} = trial_labels;
        end
        
    case 'split'
        % Clear-cut mode
        for i = 1:80
            % Filling the first 80 cells with training marks only
            trial_labels = training_labels(randi(numel(training_labels), 1, num_labels_per_cell));
            training_and_test_binned_labels.trial_type_side{i} = trial_labels;
        end
        
        for i = 81:num_cells_main
            % Filling the remaining 70 cells with test marks only
            trial_labels = test_labels(randi(numel(test_labels), 1, num_labels_per_cell));
            training_and_test_binned_labels.trial_type_side{i} = trial_labels;
        end
end

labels_to_use_training = {'instr_R_training', 'instr_L_training'};
labels_to_use_test = {'instr_R_test', 'instr_L_test'};


for k = 1:250
%     inds_of_sites_with_at_least_k_repeats = find_sites_with_k_label_repetitions(test_binned_data.binned_labels.trial_type_side , k, labels_to_use_k);
%     num_sites_with_k_repeats(k) = length(inds_of_sites_with_at_least_k_repeats);
    inds_of_sites_with_at_least_k_repeats_training = find_sites_with_k_label_repetitions(training_and_test_binned_labels.trial_type_side , k, labels_to_use_training);
    num_sites_with_k_repeats_training(k) = length(inds_of_sites_with_at_least_k_repeats_training);
   
    % number of columns - how many times the stimulus was presented (number of repetitions);
    % the value in each column - how many units has this number of repetitions
end

for k = 1:250
%     inds_of_sites_with_at_least_k_repeats = find_sites_with_k_label_repetitions(test_binned_data.binned_labels.trial_type_side , k, labels_to_use_k);
%     num_sites_with_k_repeats(k) = length(inds_of_sites_with_at_least_k_repeats);
    inds_of_sites_with_at_least_k_repeats_test = find_sites_with_k_label_repetitions(training_and_test_binned_labels.trial_type_side , k, labels_to_use_test);
    num_sites_with_k_repeats_test(k) = length(inds_of_sites_with_at_least_k_repeats_test);
   
    % number of columns - how many times the stimulus was presented (number of repetitions);
    % the value in each column - how many units has this number of repetitions
end