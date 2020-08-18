function [repredicted_REM_index,repredicted_N1_index] = svm_REM_N1(predicted_REM_index,predicted_N1_index,X,Y,response,subjectId,testingId,dim_X_EOG,dim_Y_EOG,dim_X_EMG,dim_Y_EMG,subject_age,Z)

store_featureL_EOG = [];
store_featureR_EOG = [];
store_featureL_EMG = [];
store_featureR_EMG = [];
store_feature_EMG = [];

store_label = [];

number_subject = numel(unique(cell2mat(subjectId)));


%% EOG EMG feature index
use_X = size(X,1);
use_Y = size(Y,1);
L_EOG_part = use_X - (dim_X_EOG+dim_Y_EOG)+1:use_X - dim_Y_EOG;
R_EOG_part = use_X - (dim_Y_EOG)+1:use_X;


L_EMG_part = use_Y- (dim_X_EMG+dim_Y_EMG)+1:use_Y - dim_Y_EMG;
R_EMG_part = use_Y - dim_Y_EMG+1: use_Y;


%% all training data
for i = 1:number_subject
    if (i~=testingId) && (subject_age(i)>=subject_age(testingId)-15)  && (subject_age(i)<=subject_age(testingId)+15)
    individual = cell2mat(subjectId) == i;
    training_featureL_EOG = X(L_EOG_part,:,individual);
    training_featureR_EOG = X(R_EOG_part,:,individual);
    
    training_featureL_EMG = Y(L_EMG_part,:,individual);
    training_featureR_EMG = Y(R_EMG_part,:,individual);
    training_feature_EMG = Z(:,:,individual);
    
    training_label = response(individual, :);
    
    store_featureL_EOG = cat(3,store_featureL_EOG, training_featureL_EOG);
    store_featureR_EOG = cat(3,store_featureR_EOG, training_featureR_EOG);
    
    store_featureL_EMG = cat(3,store_featureL_EMG, training_featureL_EMG);
    store_featureR_EMG = cat(3,store_featureR_EMG, training_featureR_EMG);
    store_feature_EMG = cat(3,store_feature_EMG, training_feature_EMG);
    
    store_label = [store_label; training_label];
    end
end



%% retesting data

    individual = cell2mat(subjectId) == testingId;
    testing_featureL_EOG = X(L_EOG_part,:,individual);
    testing_featureR_EOG = X(R_EOG_part,:,individual);
    testing_featureL_EMG = Y(L_EMG_part,:,individual);
    testing_featureR_EMG = Y(R_EMG_part,:,individual);
    testing_feature_EMG = Z(:,:,individual);
    %testing_label = response(individual, :); % forbidden use
    retesting_index = [predicted_REM_index; predicted_N1_index];
    
    retesting_featureL_EOG = testing_featureL_EOG(:,:,retesting_index);
    retesting_featureL_EOG = get_vec_feature(retesting_featureL_EOG);
    
    retesting_featureR_EOG = testing_featureR_EOG(:,:,retesting_index);
    retesting_featureR_EOG = get_vec_feature(retesting_featureR_EOG);

    retesting_featureL_EMG = testing_featureL_EMG(:,:,retesting_index);
    retesting_featureL_EMG = get_vec_feature(retesting_featureL_EMG);
    
    retesting_featureR_EMG = testing_featureR_EMG(:,:,retesting_index);
    retesting_featureR_EMG = get_vec_feature(retesting_featureR_EMG);
    
    retesting_feature_EMG = testing_feature_EMG(:,:,retesting_index);
    retesting_feature_EMG = get_vec_feature(retesting_feature_EMG);

%% training data REM 
REM_training_index = find(store_label==2);
REM_store_featureL_EOG = store_featureL_EOG(:,:,REM_training_index);
REM_store_featureL_EOG = get_vec_feature(REM_store_featureL_EOG);

REM_store_featureR_EOG = store_featureR_EOG(:,:,REM_training_index);
REM_store_featureR_EOG = get_vec_feature(REM_store_featureR_EOG);

REM_store_featureL_EMG = store_featureL_EMG(:,:,REM_training_index);
REM_store_featureL_EMG = get_vec_feature(REM_store_featureL_EMG);

REM_store_featureR_EMG = store_featureR_EMG(:,:,REM_training_index);
REM_store_featureR_EMG = get_vec_feature(REM_store_featureR_EMG);

REM_store_feature_EMG = store_feature_EMG(:,:,REM_training_index);
REM_store_feature_EMG = get_vec_feature(REM_store_feature_EMG);

REM_label = ones(numel(REM_training_index),1);

%% training data N1
N1_training_index = find(store_label==3);

N1_store_featureL_EOG = store_featureL_EOG(:,:,N1_training_index);
N1_store_featureL_EOG = get_vec_feature(N1_store_featureL_EOG);

N1_store_featureR_EOG = store_featureR_EOG(:,:,N1_training_index);
N1_store_featureR_EOG = get_vec_feature(N1_store_featureR_EOG);

N1_store_featureL_EMG = store_featureL_EMG(:,:,N1_training_index);
N1_store_featureL_EMG = get_vec_feature(N1_store_featureL_EMG);

N1_store_featureR_EMG = store_featureR_EMG(:,:,N1_training_index);
N1_store_featureR_EMG = get_vec_feature(N1_store_featureR_EMG);

N1_store_feature_EMG = store_feature_EMG(:,:,N1_training_index);
N1_store_feature_EMG = get_vec_feature(N1_store_feature_EMG);

N1_label = 2*ones(numel(N1_training_index),1);

%% SVM
template = templateSVM('KernelFunction', 'gaussian', ...
    'PolynomialOrder', [], 'KernelScale', 10, ...
    'BoxConstraint', 1, 'Standardize', true);
% EOG fusion
new_X = [REM_store_featureL_EOG; N1_store_featureL_EOG];
new_Y = [REM_store_featureR_EOG; N1_store_featureR_EOG];
new_testX = retesting_featureL_EOG;
new_testY = retesting_featureR_EOG;

safe_part = 1:size(new_X,1);
[trainingCOM_EOG,testingCOM_EOG,~] = unnormalized_ccaFuse(new_X, new_Y, new_testX, new_testY, new_testX, new_testY, 'concat', safe_part);

% EMG fusion
new_X = [REM_store_featureL_EMG; N1_store_featureL_EMG];
new_Y = [REM_store_featureR_EMG; N1_store_featureR_EMG];
new_testX = retesting_featureL_EMG;
new_testY = retesting_featureR_EMG;

safe_part = 1:size(new_X,1);
[trainingCOM_EMG,testingCOM_EMG,~] = unnormalized_ccaFuse(new_X, new_Y, new_testX, new_testY, new_testX, new_testY, 'concat', safe_part);

[trainingCOM_EOG,trainingCOM_EMG, testingCOM_EOG, testingCOM_EMG] = mycenter_pair(trainingCOM_EOG,trainingCOM_EMG, testingCOM_EOG, testingCOM_EMG);

AM_EMG_train = [REM_store_feature_EMG; N1_store_feature_EMG];
AM_EMG_test = [retesting_feature_EMG];

trainingCOM = [trainingCOM_EOG trainingCOM_EMG AM_EMG_train];% 
twoclass_training_label = [REM_label; N1_label];

testingCOM = [testingCOM_EOG  testingCOM_EMG AM_EMG_test]; % 

Mdl = fitcecoc(trainingCOM, twoclass_training_label, ...
        'Learners', template, ...
        'Coding', 'onevsall', ...
        'ClassNames', [1;2]);
    
[~, validationScores] = predict(Mdl, testingCOM);
[~,order_total] = sort(validationScores,2,'descend'); 



repredicted_REM_index = retesting_index(find(order_total(:,1)==1));
repredicted_N1_index = retesting_index(find(order_total(:,1)==2));

end
