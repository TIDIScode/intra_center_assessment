function [final_feature] = myEMG_energy(old_raw_data_cell,SampFreq,sec,channel_name)




raw_data_cell = old_raw_data_cell(:,:);  


number_epoch = size(raw_data_cell,2);
feature_cell = cell(number_epoch,[]);

parfor t = 1:number_epoch
    triple_epoch_feature = [];
    clean = raw_data_cell(:,t);
    [featureA] = SST_frameversion(clean,SampFreq,sec,channel_name);
    
    feature_cell{t,1} = featureA;
end

[Nx,Ny] = size(feature_cell{1,1});
final_feature = zeros(Nx,Ny,number_epoch);
parfor t = 1:number_epoch
final_feature(:,:,t) = feature_cell{t,1};
end




end
    
