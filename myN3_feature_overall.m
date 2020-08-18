function [total_feature] = myN3_feature_overall(EEG1)

Hz = 200;

number_epoch = size(EEG1,2);

size_node = 9;

total_feature = zeros(1,size_node,number_epoch);

parfor t = 1:number_epoch
temp_L = EEG1(:,t);

    H1 = temp_L>37.5;
    H2 = temp_L<-37.5;
    D = H1+H2;

D = D(:);

band_width = floor(length(D)/size_node);

output = zeros(1,size_node);

for k = 1:size_node
    if (k<size_node)
    range = (k-1)*band_width+1:k*band_width;
    temp = D(range);
    output(1,k) = mean(temp); 
    else
    range = length(D)-band_width+1:length(D);    
    temp = D(range);
    output(1,k) = mean(temp);
    end
end



total_feature(:,:,t) = output;


end

total_feature(1,:,:) = total_feature/10/Hz;

end
