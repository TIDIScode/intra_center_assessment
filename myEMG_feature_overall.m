function [total_feature] = myEMG_feature_overall(EMG)


number_epoch = size(EMG,2);

size_node = 9;

total_feature = zeros(1,size_node,number_epoch);

parfor t = 1:number_epoch
temp_X = EMG(:,t);

[D,~] = envelope(abs(temp_X));
D = D(:);

band_width = floor(length(D)/size_node);

output = zeros(1,size_node);

for k = 1:size_node
    if (k<size_node)
    range = (k-1)*band_width+1:k*band_width;
    temp = D(range);
    output(1,k) = quantile(temp,0.95); %sum(temp,2);
    else
    range = length(D)-band_width+1:length(D);    
    temp = D(range);
    output(1,k) = quantile(temp,0.95);%sum(temp,2);
    end
end

total_feature(:,:,t) = output;

end
