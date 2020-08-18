function [new_minorityX,new_minorityY, new_minority_label,new_minority_multilabel] = get_minority_sampleXY1225(original_featureX,original_featureY,original_label,ratio_all,epoch_dims,original_multilabel)


minority_set = [1 2];

if (size(original_label,1)~=size(original_featureX,3))
    error('error')
end

if (size(original_label,1)~=size(original_featureY,3))
    error('error')
end



%minority_label = cell(number_recording,1);
permutation_list = perms(1:epoch_dims(1));%perms(1:3);% perms(1:size(original_feature,2));

[local_permutation] = get_local_permutation(size(epoch_dims,2),size(original_featureX,2));

    minorities_number = 0;
    for minority_class = minority_set
        minorities_number = minorities_number + ratio_all(minority_class)*numel(find(original_label == minority_class));
    end
    new_minorityX = zeros(size(original_featureX,1),size(original_featureX,2),minorities_number);  
    new_minorityY = zeros(size(original_featureY,1),size(original_featureY,2),minorities_number);
    new_minority_label = zeros(minorities_number,1);
    if (nargout==4)
    new_minority_multilabel = zeros(minorities_number,1); 
    end
    count = 0;
    
for minority_class = minority_set
    minority_featureX = original_featureX(:,:,original_label == minority_class);
    minority_featureY = original_featureY(:,:,original_label == minority_class);
    if (nargout==4)
    minority_multilabel = original_multilabel(original_label == minority_class);
    end
    J = numel(find(original_label == minority_class));
    
    for j = 1:J
        
        rand_k = randperm(size(local_permutation,1));
        
        for k = 1:ratio_all(minority_class)


            count = count + 1;
            if (size(epoch_dims,2)==3)
            new_minorityX(:,:,count) = minority_featureX(:,[permutation_list(local_permutation(rand_k(k),1) ,:), epoch_dims(1)+permutation_list(local_permutation(rand_k(k),2) ,:),2*epoch_dims(1)+permutation_list(local_permutation(rand_k(k),3) ,:)],j);
            new_minorityY(:,:,count) = minority_featureY(:,[permutation_list(local_permutation(rand_k(k),1) ,:), epoch_dims(1)+permutation_list(local_permutation(rand_k(k),2) ,:),2*epoch_dims(1)+permutation_list(local_permutation(rand_k(k),3) ,:)],j);
          
            elseif (size(epoch_dims,2)==2)
             new_minorityX(:,:,count) = minority_featureX(:,[permutation_list(local_permutation(rand_k(k),1) ,:), epoch_dims(1)+permutation_list(local_permutation(rand_k(k),2) ,:)],j);
             new_minorityY(:,:,count) = minority_featureY(:,[permutation_list(local_permutation(rand_k(k),1) ,:), epoch_dims(1)+permutation_list(local_permutation(rand_k(k),2) ,:)],j);
             
            elseif (size(epoch_dims,2)==1)
            new_minorityX(:,:,count) = minority_featureX(:,permutation_list(local_permutation(rand_k(k),1) ,:),j);
            new_minorityY(:,:,count) = minority_featureY(:,permutation_list(local_permutation(rand_k(k),1) ,:),j);
                
            else
                error('error')
            end
                

            new_minority_label(count,1) = minority_class;
            if (nargout==4)
            new_minority_multilabel(count,1) = minority_multilabel(j);
            end
        end
    end
end

                
if (count ~=minorities_number)
    error('error')
end            


end


 

