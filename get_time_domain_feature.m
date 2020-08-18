function [ time_domain_feature ] = get_time_domain_feature(x)


[N,xcol] = size(x);

if (xcol~=1)
 error('X must be column vector');
end; 


framesize = N-1;


 fft_box_x = fft(x);
 a_fft_box_x = zeros(size(fft_box_x));
 a_fft_box_x(1,:) = fft_box_x(1,:);
 a_fft_box_x(2:(framesize/2),:) = 2*fft_box_x(2:(framesize/2),:);
 a_box_x = ifft(a_fft_box_x);

 Big_theta = angle(a_box_x);

 feature_mean_phase = mean(Big_theta);
 
 feature_var_phase = std(Big_theta);

 feature_mean_AM = mean(abs(a_box_x));

 feature_var_AM = std(abs(a_box_x));
 

 feature_kurtosis = kurtosis(x);
 feature_activity = sqrt(var(x));
 feature_mobility = sqrt(var(diff(x))./var(x));

time_domain_feature = [feature_mean_phase; feature_var_phase; feature_mean_AM;  feature_var_AM; feature_kurtosis; feature_activity; feature_mobility ]; %; feature_FAR; feature_STR   feature_mean_Dphase feature_activity; feature_mobility;feature_complexity

end
