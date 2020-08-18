function [total_feature] = myEOG_feature_time_domain(EOG_array,Hz)

sec = 10;

[N,number_epoch] = size(EOG_array);

size_node = 9;

total_feature = zeros(7,size_node,number_epoch);

ratio = 1.8;

index = cell(9,1);

index{1} = 1:(sec*Hz*ratio)+1;
index{2} = median(index{1}):median(index{1})+(sec*Hz*ratio);
index{3} = median(index{2}):median(index{2})+(sec*Hz*ratio);
index{4} = median(index{3}):median(index{3})+(sec*Hz*ratio);
index{5} = median(index{4}):median(index{4})+(sec*Hz*ratio);
index{6} = median(index{5}):median(index{5})+(sec*Hz*ratio);
index{7} = median(index{6}):median(index{6})+(sec*Hz*ratio);
index{8} = median(index{7}):median(index{7})+(sec*Hz*ratio);
index{9} = median(index{8})-1:min(median(index{8})+(sec*Hz*ratio)-1,N);


parfor t = 1:number_epoch
   time_domain_feature = zeros(7,size_node);
   for node_index = 1:size_node 
    
    temp_x = EOG_array(index{node_index},t);


    time_domain_feature(:,node_index)  = get_time_domain_feature(temp_x);

   end

total_feature(:,:,t) = [time_domain_feature];

end

end
