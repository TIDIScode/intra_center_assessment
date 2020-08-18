function [repredicted_N2_index,repredicted_N3_index] = svm_N2_N3(predicted_N2_index,predicted_N3_index,X,Y,response,subjectId,testingId,dim_X_EOG,dim_Y_EOG,dim_X_EMG,dim_Y_EMG,subject_age)

template = templateSVM('KernelFunction', 'gaussian', ...
    'PolynomialOrder', [], 'KernelScale', 10, ...
    'BoxConstraint', 1, 'Standardize', true);

store_featureL_EEG = [];
store_featureR_EEG = [];

store_label = [];

number_subject = numel(unique(cell2mat(subjectId)));


%% EOG EMG feature index
use_X = size(X,1);
use_Y = size(Y,1);
L_EEG_part = 1: use_X -(dim_X_EOG+dim_Y_EOG);
R_EEG_part = 1: use_Y -(dim_X_EMG+dim_Y_EMG);
time_node = 1:9;

%% all training data
for i = 1:number_subject
    if (i~=testingId) && (subject_age(i)>=subject_age(testingId)-15)  && (subject_age(i)<=subject_age(testingId)+15)
    individual = cell2mat(subjectId) == i;
    
    training_featureL_EEG = X(L_EEG_part,time_node,individual);
    training_featureR_EEG = Y(R_EEG_part,time_node,individual);
    
    training_label = response(individual, :);
    
    store_featureL_EEG = cat(3,store_featureL_EEG, training_featureL_EEG);
    store_featureR_EEG = cat(3,store_featureR_EEG, training_featureR_EEG);
    
    store_label = [store_label; training_label];
    end
end



%% retesting data

    individual = cell2mat(subjectId) == testingId;
    testing_featureL_EEG = X(L_EEG_part,time_node,individual);
    testing_featureR_EEG = Y(R_EEG_part,time_node,individual);
    %testing_label = response(individual, :); % forbidden use
    retesting_index = [predicted_N2_index;predicted_N3_index];
    
    
    
    retesting_featureL_EEG = testing_featureL_EEG(:,:,retesting_index);
    retesting_featureL_EEG = get_vec_feature(retesting_featureL_EEG);
    
    retesting_featureR_EEG = testing_featureR_EEG(:,:,retesting_index);
    retesting_featureR_EEG = get_vec_feature(retesting_featureR_EEG);


%% training data N2 
N2_training_index = find(store_label==4);

N2_store_featureL_EEG = store_featureL_EEG(:,:,N2_training_index);


N2_store_featureR_EEG = store_featureR_EEG(:,:,N2_training_index);


N2_label = ones(numel(N2_training_index),1);

%% training data N3
N3_training_index = find(store_label==5);

N3_store_featureL_EEG = store_featureL_EEG(:,:,N3_training_index);
N3_store_featureR_EEG = store_featureR_EEG(:,:,N3_training_index);
N3_label = 2*ones(numel(N3_training_index),1);

if (numel(N3_label)>0)
ratio_all =(6^3-1);
[new_minorityX,new_minorityY, new_minority_label] = get_minority_sample_single_class(N3_store_featureL_EEG,N3_store_featureR_EEG,N3_label,ratio_all,[3 3 3]);

% filter 1
pseudo_old_training_label = [N2_label;N3_label];

pseudo_trainingCOM = [get_vec_feature(N2_store_featureL_EEG(:,7:9,:))  ;get_vec_feature(N3_store_featureL_EEG(:,7:9,:)) ];

Mdl = fitcecoc(pseudo_trainingCOM, pseudo_old_training_label, ...
        'Learners', template, ...
        'Coding', 'onevsall', ...
        'ClassNames', [1;2]);
    
[~, validationScores] = predict(Mdl, [get_vec_feature(new_minorityX(:,7:9,:))]);

[score_total1,order_total1] = sort(validationScores,2,'descend'); 
A = order_total1(:,1);

coincide_partA1 = find(A==new_minority_label);


% filter 2
pseudo_old_training_label = [N2_label;N3_label];

pseudo_trainingCOM = [ get_vec_feature(N2_store_featureR_EEG(:,7:9,:)) ; get_vec_feature(N3_store_featureR_EEG(:,7:9,:))];

Mdl = fitcecoc(pseudo_trainingCOM, pseudo_old_training_label, ...
        'Learners', template, ...
        'Coding', 'onevsall', ...
        'ClassNames', [1;2]);
    
[~, validationScores] = predict(Mdl, [get_vec_feature(new_minorityY(:,7:9,:))]);

[score_total2,order_total2] = sort(validationScores,2,'descend'); 
A = order_total2(:,1);

coincide_partA2 = find(A==new_minority_label);



% merge filter 1 2
coincide_partA = intersect(coincide_partA1,coincide_partA2);
coincide_score = score_total1(coincide_partA,1)+score_total2(coincide_partA,1);
[~,order_coincide_score] = sort(coincide_score,'ascend');

true_gap = numel(N2_label)-numel(N3_label);
order_coincide_score = order_coincide_score(1:min(length(order_coincide_score),true_gap));
selected_coincide_partA = coincide_partA(order_coincide_score);



new_minorityX = new_minorityX(:,:,selected_coincide_partA);
new_minorityY = new_minorityY(:,:,selected_coincide_partA);
new_minority_label = new_minority_label(selected_coincide_partA);



N3_store_featureL_EEG = cat(3,N3_store_featureL_EEG,new_minorityX);
N3_store_featureR_EEG = cat(3,N3_store_featureR_EEG,new_minorityY);
N3_label = [N3_label;new_minority_label];
end


%% vectorization
N2_store_featureL_EEG = get_vec_feature(N2_store_featureL_EEG);
N2_store_featureR_EEG = get_vec_feature(N2_store_featureR_EEG);


N3_store_featureL_EEG = get_vec_feature(N3_store_featureL_EEG);
N3_store_featureR_EEG = get_vec_feature(N3_store_featureR_EEG);


%% SVM

% EEG fusion
new_X = [N2_store_featureL_EEG; N3_store_featureL_EEG];
new_Y = [N2_store_featureR_EEG; N3_store_featureR_EEG];
new_testX = retesting_featureL_EEG;
new_testY = retesting_featureR_EEG;


 safe_part = 1:size(new_X,1);
 [trainingCOM,testingCOM,~] = unnormalized_ccaFuse(new_X, new_Y, new_testX, new_testY, new_testX, new_testY, 'concat', safe_part);


twoclass_training_label = [N2_label; N3_label];


Mdl = fitcecoc(trainingCOM, twoclass_training_label, ...
        'Learners', template, ...
        'Coding', 'onevsone', ...
        'ClassNames', [1;2]);
    
[~, validationScores] = predict(Mdl, testingCOM);
[~,order_total] = sort(validationScores,2,'descend'); 



repredicted_N2_index = retesting_index(find(order_total(:,1)==1));
repredicted_N3_index = retesting_index(find(order_total(:,1)==2));

end
