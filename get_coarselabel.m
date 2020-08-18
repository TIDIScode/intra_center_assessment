function [coarselabel] = get_coarselabel(label)

num_epoch = size(label,1);
coarselabel = zeros(num_epoch,1);

coarselabel(find(label==1)) = 1;
coarselabel(find(label==2)) = 2;
coarselabel(find(label==3)) = 2;
coarselabel(find(label==4)) = 3;
coarselabel(find(label==5)) = 3;

end
