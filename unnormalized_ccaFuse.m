function [trainZ,testZ,testZ2] = unnormalized_ccaFuse(trainX, trainY, testX, testY, testX2, testY2, mode, safe_part)

% Reference:   
%   
%   M. Haghighat, M. Abdel-Mottaleb, W. Alhalabi, "Fully Automatic Face 
%   Normalization and Single Sample Face Recognition in Unconstrained 
%   Environments," Expert Systems With Applications, vol. 47, pp. 23-34, 
%   April 2016.
%   http://dx.doi.org/10.1016/j.eswa.2015.10.047

[n,p] = size(trainX);
if size(trainY,1) ~= n
    error('trainX and trainY must have the same number of samples.');
elseif n == 1
    error('trainX and trainY must have more than one sample.');
end
q = size(trainY,2);


if size(testX,2) ~= p
    error('trainX and testX must have the same dimensions.');
end

if size(testY,2) ~= q
    error('trainY and testY must have the same dimensions.');
end

if size(testX,1) ~= size(testY,1)
    error('testX and testY must have the same number of samples.');
end

if ~exist('mode', 'var')
    mode = 'sum';	% Default fusion mode
end


%% Center the variables

meanX = mean(trainX(safe_part,:));
meanY = mean(trainY(safe_part,:));
trainX = bsxfun(@minus, trainX, meanX);
testX  = bsxfun(@minus, testX,  meanX);
trainY = bsxfun(@minus, trainY, meanY);
testY  = bsxfun(@minus, testY,  meanY);

testX2  = bsxfun(@minus, testX2,  meanX);
testY2  = bsxfun(@minus, testY2,  meanY);

%% Dimensionality reduction using PCA for the first data X

% Calculate the covariance matrix
if n >= p
    C = trainX(safe_part,:)' * trainX(safe_part,:);	% pxp
else
    C = trainX(safe_part,:)  * trainX(safe_part,:)';	% nxn
end

% Perform eigenvalue decomposition
[eigVecs, eigVals] = eig(C);
eigVals = abs(diag(eigVals));

% Ignore zero eigenvalues
maxEigVal = max(eigVals);
zeroEigIdx = find((eigVals/maxEigVal)<1e-4); %-4
eigVals(zeroEigIdx) = [];
eigVecs(:,zeroEigIdx) = [];

% Sort in descending order
[~,index] = sort(eigVals,'descend');
eigVals = eigVals(index);
eigVecs = eigVecs(:,index);

% Obtain the projection matrix
if n >= p
    Wxpca = eigVecs;
else
    Wxpca = trainX' * eigVecs * diag(1 ./ sqrt(eigVals));
end
clear C eigVecs eigVals maxEigVal zeroEigIndex

% Update the first train and test data
trainX = trainX * Wxpca;
testX = testX * Wxpca;

testX2 = testX2 * Wxpca;
%% Dimensionality reduction using PCA for the second data Y

% Calculate the covariance matrix
if n >= q
    C = trainY(safe_part,:)' * trainY(safe_part,:);	% qxq
else
    C = trainY(safe_part,:)  * trainY(safe_part,:)';	% nxn
end

% Perform eigenvalue decomposition
[eigVecs, eigVals] = eig(C);
eigVals = abs(diag(eigVals));

% Ignore zero eigenvalues
maxEigVal = max(eigVals);
zeroEigIndex = find((eigVals/maxEigVal)<1e-4); %-4
eigVals(zeroEigIndex) = [];
eigVecs(:,zeroEigIndex) = [];

% Sort in descending order
[~,index] = sort(eigVals,'descend');
eigVals = eigVals(index);
eigVecs = eigVecs(:,index);

% Obtain the projection matrix
if n >= q
    Wypca = eigVecs;
else
    Wypca = trainY' * eigVecs * diag(1 ./ sqrt(eigVals));
end
clear C eigVecs eigVals maxEigVal zeroEigIndex

% Update the second train and test data
trainY = trainY * Wypca;
testY = testY * Wypca;

testY2 = testY2 * Wypca;


%
meanX = mean(trainX(safe_part,:));
meanY = mean(trainY(safe_part,:));
trainX = bsxfun(@minus, trainX, meanX);
testX  = bsxfun(@minus, testX,  meanX);
trainY = bsxfun(@minus, trainY, meanY);
testY  = bsxfun(@minus, testY,  meanY);

testX2  = bsxfun(@minus, testX2,  meanX);
testY2  = bsxfun(@minus, testY2,  meanY);

%% Fusion using Canonical Correlation Analysis (CCA)
cca = 1;
if (cca==0)
  trainZ = [trainX, trainY];
  testZ  = [testX, testY];
  testZ2  = [testX2, testY2];  
 
elseif (cca==1)
%[U, LAMBDA, V] = svds((trainX')*trainY, 120);
[U, LAMBDA, V] = svd((trainX')*trainY);
[sorted_lambda,I] = sort(diag(LAMBDA),'descend');
significant_cor = numel(find(sorted_lambda>sorted_lambda(1)*0.01)); %0.001

I = I(1:significant_cor);
LAMBDA = LAMBDA(I,I);
U = U(:,I);
V = V(:,I);


trainingXU = trainX * real(U);
trainingYV = trainY * real(V);
trainZ = [trainingXU, trainingYV];    

testing_featureX = testX * real(U);
testing_featureY = testY * real(V);
testZ = [testing_featureX, testing_featureY];

testX2 = testX2 * real(U);
testY2 = testY2 * real(V);
testZ2  = [testX2, testY2]; 


pp = median([trainZ; testZ]);
trainZ = trainZ-repmat(pp,size(trainZ,1),1);
testZ = testZ-repmat(pp,size(testZ,1),1);
testZ2 = testZ2-repmat(pp,size(testZ2,1),1);


qq = [trainZ; testZ];
qq = mad(qq);
qq = 1./qq;

trainZ = trainZ.*repmat(qq,size(trainZ,1),1);
testZ = testZ.*repmat(qq,size(testZ,1),1);
testZ2 = testZ2.*repmat(qq,size(testZ2,1),1);


end

end
