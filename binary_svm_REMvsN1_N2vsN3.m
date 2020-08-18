clear all
load('my_coarse_prediction.mat','my_coarse_prediction')
load('subjectId.mat','subjectId')
load('response.mat','response')
load('t.mat','t')
load('subject_age.mat','subject_age')



only_use_low_EEG = 1;


dim_X_EOG = 16;
dim_Y_EOG = 16;
dim_X_EMG = 2;
dim_Y_EMG = 4;
load('X.mat','X')
load('Y.mat','Y')
load('X_EMG.mat','X_EMG')


dim_X_EOG_low = 0;
dim_Y_EOG_low = 0;
dim_X_EMG_low = 0;
dim_Y_EMG_low = 0;  

low_X = [X(1:27,:,:)];
low_Y = [Y(1:27,:,:)];


number_subject = numel(unique(cell2mat(subjectId)));
    
cm = cell(number_subject,1);
my_new_prediction = cell(number_subject,1);
parfor i = 1:number_subject
    
    
    
    [total_score] = score_coarse_5(my_coarse_prediction{i});
    [~,A] = max(total_score, [], 2);
    predicted_N2_index = find(A==4);
    predicted_N3_index = find(A==5);
    
    predicted_REM_index = find(A==2);
    predicted_N1_index = find(A==3);
    
    % N2 N3
    [repredicted_N2_index,repredicted_N3_index] = svm_N2_N3(predicted_N2_index,...
    predicted_N3_index,low_X,low_Y,response,subjectId,i,dim_X_EOG_low,dim_Y_EOG_low,dim_X_EMG_low,dim_Y_EMG_low,subject_age);

    total_score(repredicted_N2_index,:) = repmat([0 0 0 1 0], numel(repredicted_N2_index),1);
    total_score(repredicted_N3_index,:) = repmat([0 0 0 0 1], numel(repredicted_N3_index),1);
    
    % REM N1
    [repredicted_REM_index,repredicted_N1_index] = svm_REM_N1_v2(predicted_REM_index,...
    predicted_N1_index,X,Y,response,subjectId,i,dim_X_EOG,dim_Y_EOG,dim_X_EMG,dim_Y_EMG,subject_age,X_EMG);

    total_score(repredicted_REM_index,:) = repmat([0 1 0 0 0], numel(repredicted_REM_index),1);
    total_score(repredicted_N1_index,:) = repmat([0 0 1 0 0], numel(repredicted_N1_index),1);
    

    
    [~, cm{i}, ~, ~] = confusion(t{i}', total_downsampling_score');
    my_new_prediction{i} = total_downsampling_score;
    warning(['the accuracy of ',num2str(i),'th subject is ',num2str(sum(diag(cm{i}))/sum(sum(cm{i})))]);

end

ACC_subject = zeros(size(cm,1),1);
for i = 1:size(cm,1)
    ACC_subject(i) = sum(diag(cm{i}))/sum(sum(cm{i}));
end

Median_ACC = median(ACC_subject)


ConfMat = zeros(5);
for i = 1:size(cm,1)
    ConfMat = ConfMat + cm{i};
end
acc = sum(diag(ConfMat)) / sum(ConfMat(:));

disp(['Accuracy = ' num2str(acc)])



%% metrics

SUM=sum(ConfMat,2);
nonzero_idx=find(SUM~=0);
normalizer=zeros(5,1);
normalizer(nonzero_idx)=SUM(nonzero_idx).^(-1);
matHMM=diag(normalizer)*ConfMat;
normalized_confusion_matrix = matHMM;

SUM=sum(ConfMat,1);
nonzero_idx=find(SUM~=0);
normalizer=zeros(5,1);
normalizer(nonzero_idx)=SUM(nonzero_idx).^(-1);
normalized_sensitivity_matrix=ConfMat*diag(normalizer);

recall = diag(normalized_confusion_matrix);
precision = diag(normalized_sensitivity_matrix);

F1_score = 2*(recall.*precision)./(recall+precision);
Macro_F1 = mean(F1_score);

TOTAL_EPOCH = sum(sum(ConfMat));
ACC = sum(diag(ConfMat))/TOTAL_EPOCH;
EA = sum(sum(ConfMat,1).*sum(transpose(ConfMat),1))/TOTAL_EPOCH^2;
kappa = (ACC-EA)/(1-EA);

output = cell(8, 9);
output(1, 2:end) = {'Predict-W', 'Predict-REM', 'Predict-N1', 'Predict-N2', 'Predict-N3', 'PR', 'RE', 'F1'};
output(2:6, 1) = {'Target-W', 'Target-REM', 'Target-N1', 'Target-N2', 'Target-N3'};
output(2:6, 2:6) = num2cell(ConfMat);
output(2:6, 7) = num2cell(precision);
output(2:6, 8) = num2cell(recall);
output(2:6, 9) = num2cell(F1_score);
output(8, 1:3) = {['Accuracy: ' num2str(ACC)], ['Macro F1: ' num2str(Macro_F1)], ['Kappa: ' num2str(kappa)]};
time = clock;

%%
    ratio = sum(ConfMat,2)/sum(sum(ConfMat));
    matHMM=normalized_confusion_matrix;

figure;
imagesc(matHMM);            %# Create a colored plot of the matrix values
colormap(flipud(gray));  %# Change the colormap to gray (so higher values are
                         %#   black and lower values are white)

textStrings = num2str(matHMM(:),'%0.2f');  %# Create strings from the matrix values
textStrings = strtrim(cellstr(textStrings));  %# Remove any space padding
[x,y] = meshgrid(1:5);   %# Create x and y coordinates for the strings
hStrings = text(x(:),y(:),textStrings(:),...      %# Plot the strings
                'HorizontalAlignment','center');
midValue = mean(get(gca,'CLim'));  %# Get the middle value of the color range
textColors = repmat(matHMM(:) > midValue,1,3);  %# Choose white or black for the
                                             %#   text color of the strings so
                                             %#   they can be easily seen over
                                             %#   the background color
set(hStrings,{'Color'},num2cell(textColors,2));  %# Change the text colors


%ratio=[numel(find(testing_GT==1)) numel(find(testing_GT==2)) numel(find(testing_GT==3)) numel(find(testing_GT==4)) numel(find(testing_GT==5))]'/length(testing_GT);

ratio=cellstr(num2str(ratio*100,'%5.0f%%'));

delta=0.2;
specialaxis=[1 1+delta 2 2+delta 3 3+delta 4 4+delta 5 5+delta];
set(gca,'XTick',1:5,...                         %# Change the axes tick marks
        'XTickLabel',{'Awake','REM','N1','N2','N3'},...  %#   and tick labels
        'YTick',specialaxis,...
        'YTickLabel',{'Awake',ratio{1},'REM',ratio{2},'N1',ratio{3},'N2',ratio{4},'N3',ratio{5}},...
        'TickLength',[0 0]);
set(gca,'XAxisLocation','top');
%ylabel('Ground Truth');
%xlabel('normalized confusion matrix (Taichung TzuChi LOOCV)', 'fontweight','bold');   
%xlabel('normalized confusion matrix (SVM)', 'fontweight','bold');   


SUM_col=sum(ConfMat,1);
precision = ConfMat*diag(1./SUM_col)*100
