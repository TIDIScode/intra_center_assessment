function [five_stage_score] = score_coarse_5(coarse_prediction_per_subject)

[N,m] = size(coarse_prediction_per_subject);

if (m~=3)
    error('error')
end

five_stage_score = zeros(N,5);
five_stage_score(:,1) = coarse_prediction_per_subject(:,1);
five_stage_score(:,2) = coarse_prediction_per_subject(:,2);
five_stage_score(:,4) = coarse_prediction_per_subject(:,3);

end
