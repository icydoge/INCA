datasets = {};
datafiles = {'datatraining.txt'; 'datatest.txt'; 'datatest2.txt'};

for i = 1:size(datafiles, 1)
    file = fopen(datafiles{i});
    data = textscan(file, '%s%s%f%f%f%f%f%f', 'Delimiter', ',', 'HeaderLines', 1);
    date_times = strrep(data{2}, '"', '');
    time_stamps = datenum(date_times, 'yyyy-mm-dd HH:MM:SS');
    time_values = []; % No time
    %time_values = [time_stamps']; % Time Stamp
    %time_values = [cellfun(@str2num, strrep(data{1}, '"', ''))']; % Time Sequence
    if ~isempty(time_values)
        values = im2double(mat2gray(time_values));
    else
        values = time_values;
    end
    for j = 3:7
        values = [values; data{j}'];
    end
    results = [data{8}'];
    datasets{end+1} = {values, results};
    file = fclose(file);
end

training_set_in = datasets{1}{1};
training_set_out = datasets{1}{2};
testing_set_in = [datasets{2}{1} datasets{3}{1}];
testing_set_out = [datasets{2}{2} datasets{3}{2}];
%{
fprintf('============================================================\n');
fprintf('Pre-testing multilayer perceptron networks...\n');
trial_network_sizes = {[5 3 2], [6 4 2], [10 5 5], [20 10 10], [6 4]};
for n_size = 1:size(trial_network_sizes, 2)
    network_size = cell2mat(trial_network_sizes(n_size));
    
    test_lm = feedforwardnet(network_size, 'trainlm');
    [test_lm, test_lm_record] = train(test_lm, training_set_in, training_set_out);
    fprintf('%s LM Training MSE: %f.\n', mat2str(network_size), test_lm_record.best_perf);
    result = test_lm(testing_set_in);
    perf = perform(test_lm, testing_set_out, result);
    fprintf('%s LM Validation MSE: %f.\n', mat2str(network_size), perf);
    fprintf('%s LM Validation Actual Misclassification Rate: %f.\n', mat2str(network_size), get_misclassification(testing_set_out, result));
    
    test_gd = feedforwardnet([10 5 5], 'traingd');
    [test_gd, test_gd_record] = train(test_gd, training_set_in, training_set_out);
    fprintf('%s GD Training MSE: %f.\n', mat2str(network_size), test_gd_record.best_perf);
    result = test_gd(testing_set_in);
    perf = perform(test_gd, testing_set_out, result);
    fprintf('%s GD Validation MSE: %f.\n', mat2str(network_size), perf);
    fprintf('%s GD Validation Actual Misclassification Rate: %f.\n', mat2str(network_size), get_misclassification(testing_set_out, result));
    
    test_gdm = feedforwardnet([10 5 5], 'traingdm');
    [test_gdm, test_gdm_record] = train(test_gdm, training_set_in, training_set_out);
    fprintf('%s GDM Training MSE: %f.\n', mat2str(network_size), test_gdm_record.best_perf);
    result = test_gdm(testing_set_in);
    perf = perform(test_gdm, testing_set_out, result);
    fprintf('%s GDM Validation MSE: %f.\n', mat2str(network_size), perf);
    fprintf('%s GDM Validation Actual Misclassification Rate: %f.\n', mat2str(network_size), get_misclassification(testing_set_out, result));
end

fprintf('============================================================\n');
fprintf('Pre-testing RBF...\n');
rbf_goals = [0.1 0.05 0.01 0.001];
for rbf_g = 1:size(rbf_goals, 2)
    rbf_goal = rbf_goals(rbf_g);
    test_rb = newrb(training_set_in, training_set_out, rbf_goal, 1.0, size(training_set_in, 2), 25);
    fprintf('%f RBF Training MSE: %f.\n', rbf_goal, rbf_goal);
    rbf_out = test_rb(testing_set_in);
    result = immse(rbf_out, testing_set_out);
    fprintf('%f RBF Validation MSE: %f.\n', rbf_goal, result);
    fprintf('%f RBF Validation Actual Misclassification Rate: %f.\n', rbf_goal, get_misclassification(testing_set_out, rbf_out));
end

fprintf('============================================================\n');
fprintf('Pre-testing SOM...\n');
trial_som_sizes = {[2 1] [5 1] [10 1] [20 1] [30 1] [40 1] [50 1] [60 1] [70 1] [80 1] [90 1] [100 1]};
for som_s = 1:size(trial_som_sizes, 2)
    som_size = cell2mat(trial_som_sizes(som_s));
    test_som = selforgmap(som_size);
    test_som = train(test_som, training_set_in);
    fprintf('%s SOM Training MSE: %f.\n', mat2str(som_size), get_mse_som(test_som, training_set_in, training_set_out));
    fprintf('%s SOM Validation MSE: %f.\n', mat2str(som_size), get_mse_som(test_som, testing_set_in, testing_set_out));
    fprintf('%s SOM Validation Actual Misclassification Rate: %f.\n', mat2str(som_size), get_misclassification_som(test_som, testing_set_in, testing_set_out));
end
%}

proper_training_in = datasets{1}{1};
proper_training_out = datasets{1}{2};
door_closed_test_in = datasets{2}{1};
door_closed_test_out = datasets{2}{2};
door_open_test_in = datasets{3}{1};
door_open_test_out = datasets{3}{2};

%{
% Time check -- uncomment and comment lines at start of script
som_size = [20 1];
test_som = selforgmap(som_size);
test_som = train(test_som, proper_training_in);
fprintf('%s SOM Training MSE: %f.\n', mat2str(som_size), get_mse_som(test_som, proper_training_in, proper_training_out));
fprintf('%s SOM Validation 1 MSE: %f.\n', mat2str(som_size), get_mse_som(test_som, door_closed_test_in, door_closed_test_out));
fprintf('%s SOM Validation 1 Actual Misclassification Rate: %f.\n', mat2str(som_size), get_misclassification_som(test_som, door_closed_test_in, door_closed_test_out));
fprintf('%s SOM Validation 2 MSE: %f.\n', mat2str(som_size), get_mse_som(test_som, door_open_test_in, door_open_test_out));
fprintf('%s SOM Validation 2 Actual Misclassification Rate: %f.\n', mat2str(som_size), get_misclassification_som(test_som, door_open_test_in, door_open_test_out));

% Is equalized training data better? No.
occupied = [];
unoccupied = [];
for i = 1:size(proper_training_in, 2)
    column = [proper_training_in(:,i); proper_training_out(i)];
    if proper_training_out(i) == 1
        occupied = [occupied column];
    else
        unoccupied = [unoccupied column];
    end
end
occupied_count = size(occupied, 2);
unoccupied_sampled = datasample(unoccupied, occupied_count, 2, 'Replace', false);
test_train_in = [occupied(1:5,:) unoccupied_sampled(1:5,:)];
test_train_out = [occupied(6,:) unoccupied_sampled(6,:)];
full_sample = [proper_training_in; proper_training_out];
full_sampled = datasample(full_sample, occupied_count * 2, 2, 'Replace', false);
full_train_in = full_sampled(1:5,:);
full_train_out = full_sampled(6,:);
som_size = [20 1];
equalized_training_mses = [];
equalized_val1_mses = [];
equalized_val1_miss = [];
equalized_val2_mses = [];
equalized_val2_miss = [];
unequalized_training_mses = [];
unequalized_val1_mses = [];
unequalized_val1_miss = [];
unequalized_val2_mses = [];
unequalized_val2_miss = [];
for i = 1:10
    test_som = selforgmap(som_size);
    test_som = train(test_som, test_train_in);
    equalized_training_mses = [equalized_training_mses get_mse_som(test_som, test_train_in, test_train_out)];
    equalized_val1_mses = [equalized_val1_mses get_mse_som(test_som, door_closed_test_in, door_closed_test_out)];
    equalized_val1_miss = [equalized_val1_miss get_misclassification_som(test_som, door_closed_test_in, door_closed_test_out)];
    equalized_val2_mses = [equalized_val2_mses get_mse_som(test_som, door_open_test_in, door_open_test_out)];
    equalized_val2_miss = [equalized_val2_miss get_misclassification_som(test_som, door_open_test_in, door_open_test_out)];
end
for i = 1:10
    test_som = selforgmap(som_size);
    test_som = train(test_som, full_train_in);
    unequalized_training_mses = [unequalized_training_mses get_mse_som(test_som, full_train_in, full_train_out)];
    unequalized_val1_mses = [unequalized_val1_mses get_mse_som(test_som, door_closed_test_in, door_closed_test_out)];
    unequalized_val1_miss = [unequalized_val1_miss get_misclassification_som(test_som, door_closed_test_in, door_closed_test_out)];
    unequalized_val2_mses = [unequalized_val2_mses get_mse_som(test_som, door_open_test_in, door_open_test_out)];
    unequalized_val2_miss = [unequalized_val2_miss get_misclassification_som(test_som, door_open_test_in, door_open_test_out)];
end

datum = [equalized_training_mses; equalized_val1_mses; equalized_val1_miss; equalized_val2_mses; equalized_val2_miss; unequalized_training_mses; unequalized_val1_mses; unequalized_val1_miss; unequalized_val2_mses; unequalized_val2_miss];
for i = 1:size(datum, 1)
    fprintf('%d: mean %f, variance %f\n', i, mean(datum(i,:)), var(datum(i,:)));
end

% Should we normalize input? No.
cut_offs = [size(proper_training_in, 2) size(proper_training_in, 2) + size(door_closed_test_in, 2)];
full_in = [proper_training_in door_closed_test_in door_open_test_in];
full_in_normalized = normalize_rows(full_in);
training_data = full_in_normalized(:,1:cut_offs(1));
testing1_data = full_in_normalized(:,(cut_offs(1)+1):cut_offs(2));
testing2_data = full_in_normalized(:,(cut_offs(2)+1):end);
normalized_training_mses = [];
normalized_val1_mses = [];
normalized_val1_miss = [];
normalized_val2_mses = [];
normalized_val2_miss = [];
unnormalized_training_mses = [];
unnormalized_val1_mses = [];
unnormalized_val1_miss = [];
unnormalized_val2_mses = [];
unnormalized_val2_miss = [];
for i = 1:10
    som_size = [20 1];
    test_som = selforgmap(som_size);
    test_som = train(test_som, training_data);
    normalized_training_mses = [normalized_training_mses get_mse_som(test_som, training_data, proper_training_out)];
    normalized_val1_mses = [normalized_val1_mses get_mse_som(test_som, testing1_data, door_closed_test_out)];
    normalized_val1_miss = [normalized_val1_miss get_misclassification_som(test_som, testing1_data, door_closed_test_out)];
    normalized_val2_mses = [normalized_val2_mses get_mse_som(test_som, testing2_data, door_open_test_out)];
    normalized_val2_miss = [normalized_val2_miss get_misclassification_som(test_som, testing2_data, door_open_test_out)];
end
for i = 1:10
    som_size = [20 1];
    test_som = selforgmap(som_size);
    test_som = train(test_som, proper_training_in);
    unnormalized_training_mses = [unnormalized_training_mses get_mse_som(test_som, proper_training_in, proper_training_out)];
    unnormalized_val1_mses = [unnormalized_val1_mses get_mse_som(test_som, door_closed_test_in, door_closed_test_out)];
    unnormalized_val1_miss = [unnormalized_val1_miss get_misclassification_som(test_som, door_closed_test_in, door_closed_test_out)];
    unnormalized_val2_mses = [unnormalized_val2_mses get_mse_som(test_som, door_open_test_in, door_open_test_out)];
    unnormalized_val2_miss = [unnormalized_val2_miss get_misclassification_som(test_som, door_open_test_in, door_open_test_out)];
end
datum = [normalized_training_mses; normalized_val1_mses; normalized_val1_miss; normalized_val2_mses; normalized_val2_miss];
datum = [datum; unnormalized_training_mses; unnormalized_val1_mses; unnormalized_val1_miss; unnormalized_val2_mses; unnormalized_val2_miss];
for i = 1:size(datum, 1)
    fprintf('%d: mean %f, variance %f\n', i, mean(datum(i,:)), var(datum(i,:)));
end

% Should we PCA the data? No.
cut_offs = [size(proper_training_in, 2) size(proper_training_in, 2) + size(door_closed_test_in, 2)];
full_in = [proper_training_in door_closed_test_in door_open_test_in];
[xn, xs1] = mapstd(full_in);
[xtrans,xs2] = processpca(xn, 0.02);
training_data = xtrans(:,1:cut_offs(1));
testing1_data = xtrans(:,(cut_offs(1)+1):cut_offs(2));
testing2_data = xtrans(:,(cut_offs(2)+1):end);
pcad_training_mses = [];
pcad_val1_mses = [];
pcad_val1_miss = [];
pcad_val2_mses = [];
pcad_val2_miss = [];
unpcad_training_mses = [];
unpcad_val1_mses = [];
unpcad_val1_miss = [];
unpcad_val2_mses = [];
unpcad_val2_miss = [];
for i = 1:10
    som_size = [20 1];
    test_som = selforgmap(som_size);
    test_som = train(test_som, training_data);
    pcad_training_mses = [pcad_training_mses get_mse_som(test_som, training_data, proper_training_out)];
    pcad_val1_mses = [pcad_val1_mses get_mse_som(test_som, testing1_data, door_closed_test_out)];
    pcad_val1_miss = [pcad_val1_miss get_misclassification_som(test_som, testing1_data, door_closed_test_out)];
    pcad_val2_mses = [pcad_val2_mses get_mse_som(test_som, testing2_data, door_open_test_out)];
    pcad_val2_miss = [pcad_val2_miss get_misclassification_som(test_som, testing2_data, door_open_test_out)];
end
for i = 1:10
    som_size = [20 1];
    test_som = selforgmap(som_size);
    test_som = train(test_som, proper_training_in);
    unpcad_training_mses = [unpcad_training_mses get_mse_som(test_som, proper_training_in, proper_training_out)];
    unpcad_val1_mses = [unpcad_val1_mses get_mse_som(test_som, door_closed_test_in, door_closed_test_out)];
    unpcad_val1_miss = [unpcad_val1_miss get_misclassification_som(test_som, door_closed_test_in, door_closed_test_out)];
    unpcad_val2_mses = [unpcad_val2_mses get_mse_som(test_som, door_open_test_in, door_open_test_out)];
    unpcad_val2_miss = [unpcad_val2_miss get_misclassification_som(test_som, door_open_test_in, door_open_test_out)];
end
datum = [pcad_training_mses; pcad_val1_mses; pcad_val1_miss; pcad_val2_mses; pcad_val2_miss];
datum = [datum; unpcad_training_mses; unpcad_val1_mses; unpcad_val1_miss; unpcad_val2_mses; unpcad_val2_miss];
for i = 1:size(datum, 1)
    fprintf('%d: mean %f, variance %f\n', i, mean(datum(i,:)), var(datum(i,:)));
end

% Influence of the steps : 500.
som_steps = [100 250 500 750 1000 2000];
mean1_miss = [];
mean2_miss = [];
for s = 1:size(som_steps, 2)
    training_mses = [];
    val1_mses = [];
    val1_miss = [];
    val2_mses = [];
    val2_miss = [];
    for i = 1:10
        som_size = [20 1];
        test_som = selforgmap(som_size, som_steps(s));
        test_som = train(test_som, proper_training_in);
        training_mses = [training_mses get_mse_som(test_som, proper_training_in, proper_training_out)];
        val1_mses = [val1_mses get_mse_som(test_som, door_closed_test_in, door_closed_test_out)];
        val1_miss = [val1_miss get_misclassification_som(test_som, door_closed_test_in, door_closed_test_out)];
        val2_mses = [val2_mses get_mse_som(test_som, door_open_test_in, door_open_test_out)];
        val2_miss = [val2_miss get_misclassification_som(test_som, door_open_test_in, door_open_test_out)];
    end
    fprintf('%d steps: Mean T MSE %f, V1 MSE %f, V1 MIS %f, V2 MSE %f, V2 MIS %f.\n', som_steps(s), mean(training_mses), mean(val1_mses), mean(val1_miss), mean(val2_mses), mean(val2_miss));
    fprintf('%d steps: Vari T MSE %f, V1 MSE %f, V1 MIS %f, V2 MSE %f, V2 MIS %f.\n\n', som_steps(s), var(training_mses), var(val1_mses), var(val1_miss), var(val2_mses), var(val2_miss));
    mean1_miss = [mean1_miss 100 - mean(val1_miss)];
    mean2_miss = [mean2_miss 100 - mean(val2_miss)];
end
figure;
plot(som_steps, mean1_miss, '-rx'); hold on;
plot(som_steps, mean2_miss, '-gx');
axis([100,2000,80,100]);
legend(['Validation Set 1 (2665 inputs)'; 'Validation Set 2 (9752 inputs)']);
title('Performance of SOM on Unseen Data (Varying Training Steps)');
xlabel('Number of Training Steps');
ylabel('Mean Correct Classification Rate');

% Influence of the neighbourhood size: 3.
neighbourhood_sizes = [2 3 5 10 15 20];
mean1_miss = [];
mean2_miss = [];
for s = 1:size(neighbourhood_sizes, 2)
    training_mses = [];
    val1_mses = [];
    val1_miss = [];
    val2_mses = [];
    val2_miss = [];
    for i = 1:10
        som_size = [20 1];
        test_som = selforgmap(som_size, 500, neighbourhood_sizes(s));
        test_som = train(test_som, proper_training_in);
        training_mses = [training_mses get_mse_som(test_som, proper_training_in, proper_training_out)];
        val1_mses = [val1_mses get_mse_som(test_som, door_closed_test_in, door_closed_test_out)];
        val1_miss = [val1_miss get_misclassification_som(test_som, door_closed_test_in, door_closed_test_out)];
        val2_mses = [val2_mses get_mse_som(test_som, door_open_test_in, door_open_test_out)];
        val2_miss = [val2_miss get_misclassification_som(test_som, door_open_test_in, door_open_test_out)];
    end
    fprintf('%d steps: Mean T MSE %f, V1 MSE %f, V1 MIS %f, V2 MSE %f, V2 MIS %f.\n', neighbourhood_sizes(s), mean(training_mses), mean(val1_mses), mean(val1_miss), mean(val2_mses), mean(val2_miss));
    fprintf('%d steps: Vari T MSE %f, V1 MSE %f, V1 MIS %f, V2 MSE %f, V2 MIS %f.\n\n', neighbourhood_sizes(s), var(training_mses), var(val1_mses), var(val1_miss), var(val2_mses), var(val2_miss));
    mean1_miss = [mean1_miss 100 - mean(val1_miss)];
    mean2_miss = [mean2_miss 100 - mean(val2_miss)];
end
figure;
plot(neighbourhood_sizes, mean1_miss, '-rx'); hold on;
plot(neighbourhood_sizes, mean2_miss, '-gx');
axis([2,20,80,100]);
legend(['Validation Set 1 (2665 inputs)'; 'Validation Set 2 (9752 inputs)']);
title('Performance of SOM on Unseen Data (Varying Neighbourhood Sizes)');
xlabel('Initial Neighbourhood Size');
ylabel('Mean Correct Classification Rate');

% Influence of the network size: 40.
trial_som_sizes = {[2 1] [10 1] [20 1] [30 1] [40 1] [50 1]};
network_sizes = [];
mean1_miss = [];
mean2_miss = [];
for som_s = 1:size(trial_som_sizes, 2)
    som_size = cell2mat(trial_som_sizes(som_s));
    network_sizes = [network_sizes som_size(1)];
    training_mses = [];
    val1_mses = [];
    val1_miss = [];
    val2_mses = [];
    val2_miss = [];
    learning_rate1 = learning_rates(s);
    learning_rate2 = learning_rate1 / 45;
    for i = 1:10
        test_som = selforgmap(som_size, 500);
        test_som = train(test_som, proper_training_in);
        training_mses = [training_mses get_mse_som(test_som, proper_training_in, proper_training_out)];
        val1_mses = [val1_mses get_mse_som(test_som, door_closed_test_in, door_closed_test_out)];
        val1_miss = [val1_miss get_misclassification_som(test_som, door_closed_test_in, door_closed_test_out)];
        val2_mses = [val2_mses get_mse_som(test_som, door_open_test_in, door_open_test_out)];
        val2_miss = [val2_miss get_misclassification_som(test_som, door_open_test_in, door_open_test_out)];
    end
    fprintf('%d steps: Mean T MSE %f, V1 MSE %f, V1 MIS %f, V2 MSE %f, V2 MIS %f.\n', som_size(1), mean(training_mses), mean(val1_mses), mean(val1_miss), mean(val2_mses), mean(val2_miss));
    fprintf('%d steps: Vari T MSE %f, V1 MSE %f, V1 MIS %f, V2 MSE %f, V2 MIS %f.\n\n', som_size(1), var(training_mses), var(val1_mses), var(val1_miss), var(val2_mses), var(val2_miss));
    mean1_miss = [mean1_miss 100 - mean(val1_miss)];
    mean2_miss = [mean2_miss 100 - mean(val2_miss)];
end

figure;
plot(network_sizes, mean1_miss, '-rx'); hold on;
plot(network_sizes, mean2_miss, '-gx');
axis([2,50,70,100]);
legend(['Validation Set 1 (2665 inputs)'; 'Validation Set 2 (9752 inputs)']);
title('Performance of SOM on Unseen Data (Varying Network Size)');
xlabel('Number of Neurons in 1-D SOM');
ylabel('Mean Correct Classification Rate');
%}