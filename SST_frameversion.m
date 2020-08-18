function [feature] = SST_frameversion(x,Hz,sec,channel_name)
% Computes the SST (Ts)  of the signal x.
% The frequency of an EMG signal is between 0 to 500 Hz. However, the usable energy of EMG signal is dominant between 50-150 Hz
% ONLINE EMG SIGNAL ANALYSIS FOR DIAGNOSIS OF NEUROMUSCULAR DISEASES BY USING PCA AND PNN 


totoal_sample=1;
M=1;
[N,xcol] = size(x);
use_SST=0;
if (xcol~=1)
 error('X must be column vector');
end; 
framesize=Hz*sec;


RR=rem(N,Hz*sec);
num_feature = (N-RR)/(Hz*sec);
hlength = floor(framesize*1); % 10

num_partition = Hz*sec/framesize;


hlength = hlength+1-rem(hlength,2);

if (strcmp(channel_name,'EEG')==1)
N1 = hlength*8;    
upper_bound_freq_index = floor((Hz/2)*N1/Hz);
end


if (strcmp(channel_name,'lowEEG')==1)
N1 = hlength*50;    
upper_bound_freq_index = floor(17*N1/Hz);
end

if (strcmp(channel_name,'EMG')==1)
N1 = hlength*8;    
upper_bound_freq_index = floor((Hz/2)*N1/Hz);
end

if (strcmp(channel_name,'EOG')==1)
N1 = hlength*1000;       
upper_bound_freq_index = floor(2*N1/Hz);
end


Lh=(hlength-1)/2;
ft = 1:upper_bound_freq_index;
va=N1/hlength;




sst = zeros (upper_bound_freq_index,num_feature,num_partition) ;
average_sst = zeros (upper_bound_freq_index,num_feature) ;



for m=1:totoal_sample

    h = hann(hlength);  
    
    
    parfor feature_index = 1:num_feature  %%%%%%%%%%
    if (use_SST==1)
    tfr0= zeros(N1,num_partition) ; 
    tfr1= zeros(N1,num_partition) ; 
    count=0;
       for icol = (feature_index-1)*num_partition+1 : feature_index*num_partition
       count=count+1;
       %ti = slot_center(icol);
       ti = icol*framesize-(framesize/2);
       tau = -min([round(N1/2)-1,Lh,ti-1]):min([round(N1/2)-1,Lh,N-ti]);
       indices= rem(N1+tau,N1)+1;
       norm_h=norm(h(Lh+1+tau));
       
       tfr0(indices,count) = x(ti+tau).*conj( h(Lh+1+tau)) /norm_h;
       tfr1(indices,count) = x(ti+tau).*conj(dh(Lh+1+tau)) /norm_h;
       end
    
    tfr0 = fft(tfr0) ; 
    tfr0 = tfr0(1:upper_bound_freq_index,:) ;
    tfr1 = fft(tfr1) ; 
    tfr1 = tfr1(1:upper_bound_freq_index,:) ;
    
    elseif (use_SST==0)
    tfr0= zeros(N1,num_partition) ; 
    count=0;
       for icol = (feature_index-1)*num_partition+1 : feature_index*num_partition
       count=count+1;
       %ti = slot_center(icol);
       ti = icol*framesize-(framesize/2);
       %tau = -min([round(N1/2)-1,Lh,ti-1]):min([round(N1/2)-1,Lh,N-ti]);
       LL = -min([round(N1/2)-1,Lh,ti-1])-max(min(Lh,round(N1/2)-1)-(N-ti),0);
       RR = min([round(N1/2)-1,Lh,N-ti])+max(min(Lh,round(N1/2)-1)-(ti-1),0);
       tau = LL:RR;
       indices= rem(N1+tau,N1)+1;
       
       norm_h=norm(h(:));
       
       tfr0(indices,count) = x(ti+tau).*conj( h(:)) /norm_h;
       %tfr1(indices,count) = x(ti+tau).*conj(dh(Lh+1+tau)) /norm_h;
       end
    
    tfr0 = fft(tfr0) ; 
    tfr0 = tfr0(1:upper_bound_freq_index,:) ;
     
        
    end
    
    

    Threshold_matrix = sqrt(mean(abs(tfr0).^2,1))*10^(-9);
    
    

		% get the first order omega
	  omega = zeros(upper_bound_freq_index,num_partition) ;
    sub_sst = zeros (upper_bound_freq_index,num_partition) ;
        if (use_SST==1)
            for tt = 1:num_partition
            avoid_warn = find(abs(tfr0(1:upper_bound_freq_index,tt))>Threshold_matrix(tt));
            omega(avoid_warn,tt) = round(imag(va*tfr1(avoid_warn,tt)./tfr0(avoid_warn,tt)/(2.0*pi)));
            omega(:,tt)=(ft-1)'-omega(:,tt);
            end
        end
 
    if (use_SST==1)
     for tt = 1:num_partition
        for ff = 1: upper_bound_freq_index
            if (abs(tfr0(ff,tt)) >Threshold_matrix(tt))
            kk = omega(ff,tt);
                if (kk <= upper_bound_freq_index) && (kk >= 1) % && (abs(kk-ff)<5*N1/Hz)
				 
                 sub_sst(kk,tt) = sub_sst(kk,tt) + abs(tfr0(ff,tt)).^2 ;

                end
        
            end
       end
     end
      

     
    sst(:,feature_index,:) = sub_sst;
    %sst(:,feature_index,m) = sst(:,feature_index)+ mean(sub_sst,2);
    else
    sst(:,feature_index,:) = abs(tfr0).^2; 
    end
    
    
    end
    
    average_sst = average_sst + mean(abs(sst),3);
   
end

average_sst=average_sst/totoal_sample;

df = Hz/N1;


if (strcmp(channel_name,'lowEEG')==1)
featureA=sum(average_sst(max(floor(0.3/df)+1,1):floor(4/df)-1,:)); 
featureA=(featureA)/(numel(max(floor(0.3/df)+1,1):floor(4/df)-1));

featureB=sum(average_sst(max(floor(4/df)+1,1):floor(7/df)-1,:)); 
featureB=(featureB)/(numel(max(floor(4/df)+1,1):floor(7/df)-1));

featureC=sum(average_sst(max(floor(8/df)+1,1):floor(15/df)-1,:)); 
featureC=(featureC)/(numel(max(floor(8/df)+1,1):floor(15/df)-1));

featureD=sum(average_sst(max(floor(7.5/df)+1,1):floor(12.5/df)-1,:)); 
featureD=(featureD)/(numel(max(floor(7.5/df)+1,1):floor(12.5/df)-1));

featureE=sum(average_sst(max(floor(12.5/df)+1,1):floor(12.5/df)-1,:)); 
featureE=(featureE)/(numel(max(floor(12.5/df)+1,1):floor(15.5/df)-1));

feature = [featureA; featureB;  featureC; featureD; featureE];
end


if (strcmp(channel_name,'EEG')==1)
featureA=sum(average_sst(max(floor(35/df)+1,1):floor(60/df)-1,:));  
featureA=(featureA)/(numel(max(floor(35/df)+1,1):floor(60/df)-1));

featureB=sum(average_sst(max(floor(60/df)+1,1):floor(95/df)-1,:)); 
featureB=(featureB)/(numel(max(floor(60/df)+1,1):floor(95/df)-1));


feature = [featureA; featureB]; 

end





if (strcmp(channel_name,'EMG')==1)
featureA=sum(average_sst(max(floor(35/df)+1,1):floor(80/df)-1,:));  
featureA=(featureA)/(numel(max(floor(35/df)+1,1):floor(80/df)-1));



featureC=sum(average_sst(max(floor(80/df)+1,1):floor((Hz/2)/df)-1,:)); % 150-250
featureC=(featureC)/(numel(max(floor(80/df)+1,1):floor((Hz/2)/df)-1));


feature = [featureA; featureC]; % featureB; featureC

end


if (strcmp(channel_name,'EOG')==1)
featureA=sum(average_sst(max(floor(0.1/df)+1,1):floor(0.3/df)-1,:));  
featureA=(featureA)/(numel(max(floor(0.1/df)+1,1):floor(0.3/df)-1));


featureB=sum(average_sst(max(floor(0.3/df)+1,1):floor(0.45/df)-1,:)); 
featureB=(featureB)/(numel(max(floor(0.3/df)+1,1):floor(0.45/df)-1));


featureC=sum(average_sst(max(floor(0.45/df)+1,1):floor((1)/df)-1,:)); 
featureC=(featureC)/(numel(max(floor(0.45/df)+1,1):floor((1)/df)-1));


feature = [featureA; featureB; featureC]; % featureB; featureC

end


end
