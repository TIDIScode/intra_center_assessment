clear
clc
sec=30; 
current_position = cd;
filename = 'Normal_ShuangHo_20190603.xlsx';%'Normal_ShuangHo_mine.xlsx';
xlRange = 'A:A';
sheet = 1; %1: including mild apnea
[num,txt]  = xlsread(filename,sheet,xlRange)
ID = txt(2:end)


xlRange = 'E:E';
sheet = 1;
[num2,txt2]  = xlsread(filename,sheet,xlRange)
%ID = txt(2:end);
AGE = num2(1:end);

clear txt txt2

%ID = num;
number_subject = length(ID);

fname=mfilename('fullpath');
[pathstr,~,~]=fileparts(fname);
addpath([pathstr,'/EDF_read_code']) ;
%rmpath(name);
name = [current_position,'/database_zip'];
cd(name);
%dir *.zip 
databaseInfo = dir;
iszip = {databaseInfo.isdir};
zipname = {databaseInfo.name};
clear databaseInfo

iszip = cell2mat(iszip);
zipname = zipname(find(iszip==0));

if (length(zipname)~=number_subject)
     warning(['length(zipname) = ',num2str(length(zipname)),' ~ = number_subject = ',num2str(number_subject)]);
end

cd(current_position);

%%

Channels = cell(number_subject,2);
EMG_Channels = cell(number_subject,2);
EOG_Channels = cell(number_subject,2);
label = cell(number_subject, 1);
coarselabel = cell(number_subject, 1);


for i = 1:number_subject %[1 3 4 5 6 7 8 9 12 18 20 21 22 24 27:38] %number_subject
i
    name_unzip = [current_position,'/database_unzip'];
    cd(name_unzip);
    name = [current_position,'/database_unzip/',zipname(i)]
    NAME = char(zipname(i));
    NAME = NAME(1:end-4);
    exist_check = exist(NAME);
    cd(current_position)
    if (exist_check~=7)
       warning(['this file does not exist!']); 
    else
       name = [current_position,'/database_unzip/',NAME]; 
       addpath(name);
       %NAME = NAME(10:23);
       %new_Traces = [NAME,'.edf'];
       [hdr,record] = edfread('Traces.edf');
       
       hdr.label
       channel_name = hdr.label;
       channel_samplingrate = hdr.frequency;
       clear channel1_index channel2_index channel3_index channel4_index channel5_index
       for channel_index = 1:length(channel_name)
           if (strcmp(channel_name{channel_index},'C3M2')==1) || (strcmp(channel_name{channel_index},'C3A2')==1)  
               channel1_index = channel_index;
           end
           if (strcmp(channel_name{channel_index},'O2M1')==1) || (strcmp(channel_name{channel_index},'O2A1')==1) || (strcmp(channel_name{channel_index},'O22A1')==1)
               channel2_index = channel_index; 
           end
           
           % EOG
           if (strcmp(channel_name{channel_index},'E1')==1) || (strcmp(channel_name{channel_index},'LOCA2')==1) || (strcmp(channel_name{channel_index},'E1M2')==1) || (strcmp(channel_name{channel_index},'LOC')==1) || (strcmp(channel_name{channel_index},'LeftA2')==1)
               channel3_index = channel_index;
           end
           if (strcmp(channel_name{channel_index},'E2')==1) || (strcmp(channel_name{channel_index},'ROCA1')==1) || (strcmp(channel_name{channel_index},'E2M2')==1) || (strcmp(channel_name{channel_index},'ROC')==1) || (strcmp(channel_name{channel_index},'RightA1')==1)
               channel4_index = channel_index; 
           end
           
           % EMG
           if (strcmp(channel_name{channel_index},'LowerLeftUpper')==1) || (strcmp(channel_name{channel_index},'Chin')==1) || (strcmp(channel_name{channel_index},'EMG')==1) || ...
                   (strcmp(channel_name{channel_index},'chin1chin2')==1) || (strcmp(channel_name{channel_index},'EMG_R')==1)
               channel5_index = channel_index; 
           end
       end
       channel1_samplingrate = channel_samplingrate(channel1_index)
       channel2_samplingrate = channel_samplingrate(channel2_index);
       

       
       if (channel1_samplingrate~=200)
       input1 = resample(record(channel1_index,:),200,channel1_samplingrate); % C3M2
       warning(['Sampling rate has been changed to 200 Hz!']);
       else    
       input1 = record(channel1_index,:); % C3M2
       end
       
       if (channel2_samplingrate~=200)
       input2 = resample(record(channel2_index,:),200,channel2_samplingrate); % F4M1
       warning(['Sampling rate has been changed to 200 Hz!']);
       else    
       input2 = record(channel2_index,:); % F4M1
       end
       

       
       SampFreq = 200;
       SampFreq_EEG = SampFreq;
       SampFreq_EOG = SampFreq;
       
       
       [a1,a2,a3,a4,a5,a6,a7,a8,a9] = textread('Events.txt','%s%s%s%s%s%s%s%s%s','headerlines',27);
       %[a1,a2,a3,a4,a5,a6,a7,a8,a9] = textread(new_Events,'%s%s%s%s%s%s%s%s%s','headerlines',0);
       rmpath(name);
       if (strcmp(a3{1},'Position'))==1
       [label{i}] = get_STAGE(a1(2:end),a2(2:end),a3(2:end),a4(2:end),a5(2:end),a6(2:end),a7(2:end),a8(2:end),a9(2:end));
       elseif (strcmp(a3{1},'Time'))==1
       [label{i}] = get_STAGE(a1(2:end),a2(2:end),[],a3(2:end),a4(2:end),a5(2:end),a6(2:end),a7(2:end),a8(2:end));
       else
       error('error')    
       end
    end
    label_epoch = length(label{i})
   num_STAGE = label{i};

  
  num_STAGE = num_STAGE(:);
 
 signal1_number_epoch = floor(length(input1)/(SampFreq*30))
 signal2_number_epoch = floor(length(input2)/(SampFreq*30))

 GT_number_epoch = length(num_STAGE)
 

 revised_number_epoch = min([signal1_number_epoch,signal2_number_epoch, GT_number_epoch]);
 
 input1 = input1(1:(revised_number_epoch*SampFreq*30));
 input2 = input2(1:(revised_number_epoch*SampFreq*30));

 num_STAGE = num_STAGE(1:revised_number_epoch);
   
      if (length(input1)/SampFreq/sec~=length(num_STAGE)) || (length(input2)/SampFreq/sec~=length(num_STAGE))
      error('the lengths of the two-channel EEG data are not consistent! ');
      end

      
      Channels{i, 1} = (input1); % C3M2
      Channels{i, 2} = (input2); % F4M1
      

      label{i} = num_STAGE;
      
 
    label_epoch = length(label{i});  
   
   
    
    
    signal_epoch = floor(length(Channels{i,1})/SampFreq/sec);

    if (label_epoch<signal_epoch)
    Channels{i, 1} = Channels{i, 1}(1:label_epoch*sec*SampFreq); 
    Channels{i, 2} = Channels{i, 2}(1:label_epoch*sec*SampFreq);

    elseif (label_epoch>=signal_epoch)
    Channels{i, 1} = Channels{i, 1}(1:signal_epoch*sec*SampFreq); 
    Channels{i, 2} = Channels{i, 2}(1:signal_epoch*sec*SampFreq);  

    label{i} = label{i}(1:signal_epoch);
    end
end

w0 = 60*(2/SampFreq);
[b,a] = iirnotch(w0,w0/35); %w0/35

for i = 1:size(Channels, 1)

  Channels{i, 1} = filtfilt(b, a, Channels{i, 1});
  Channels{i, 2} = filtfilt(b, a, Channels{i, 2});     

end 
 



 
%%
Info.PID = [1:number_subject]'; 

      
len = sec*3;  % 5
Fs = SampFreq;
for i = 1:size(Channels, 1)
    
   
    
   Channels{i, 1} = mybuffer_past(Channels{i, 1},SampFreq_EEG); 
   Channels{i, 2} = mybuffer_past(Channels{i, 2},SampFreq_EEG); 
   

   
   % remove zeros
   label{i} = label{i}(3:end);  % (4:end-1)
   coarselabel{i} = get_coarselabel(label{i});

   % anomaly detection
   xx = Channels{i, 1};
   
   [anomaly_index1] = anomaly_detection(xx);
   
   if (length(anomaly_index1)~=size(xx,2))
       error('error')
   end
   
   xx = Channels{i, 2};
   [anomaly_index2] = anomaly_detection(xx);
   
   if (length(anomaly_index2)~=size(xx,2))
       error('error')
   end
   
   anomaly_index = anomaly_index1.*anomaly_index2;
   
   if (length(anomaly_index)~=size(xx,2))
       error('error')
   end
   
   clear anomaly_index1 anomaly_index2
   normal_part = find(anomaly_index==1);
   
   
   
   
   label{i} = label{i}(normal_part);  % (4:end-1)
   coarselabel{i} = coarselabel{i}(normal_part);
   Channels{i, 1} = Channels{i, 1}(:, normal_part);
   Channels{i, 2} = Channels{i, 2}(:, normal_part);

%%
   
   
   
    if (length(Channels{i, 1}(:))/SampFreq/30/(len / 30)~=length(label{i}))
        error('error');
    end
    if (length(Channels{i, 2}(:))/SampFreq/30/(len / 30)~=length(label{i}))
        error('error');
    end 
    
    if (length(Channels{i, 1}(:))/SampFreq/30/(len / 30)~=length(coarselabel{i}))
        error('error');
    end
    if (length(Channels{i, 2}(:))/SampFreq/30/(len / 30)~=length(coarselabel{i}))
        error('error');
    end 
    
end  
%%

for i = 1: size(Channels, 1)
    
    disp(num2str(i))
    [N3_feature] = my_N3_feature_overall(Channels{i, 1});
    [Channels{i, 1}] = myEEG_energy(Channels{i, 1},Fs,10,'lowEEG');
    Channels{i, 1} = [Channels{i, 1}; N3_feature];
    
    [N3_feature] = my_N3_feature_overall(Channels{i, 2});
    [Channels{i, 2}] = myEEG_energy(Channels{i, 2},Fs,10,'lowEEG');
    Channels{i, 2} = [Channels{i, 2}; N3_feature];
     
end



%% organization and indexing

t = cell(size(Channels, 1), 1);
multi_t = cell(size(Channels, 1), 1);

subjectId = cell(size(Info.PID));
for i = 1:size(Channels, 1)
    id = find(label{i} > 0);
    for j = 1:size(Channels, 2)
    Channels{i, j} = Channels{i, j}(:,:,id); %Channels{i, j} = Channels{i, j}(id, :);
    end
    t{i} = full(ind2vec(double(label{i}(id)'),5))';
    subjectId{i} = repelem(Info.PID(i), length(t{i}))';
end
clear label id




%%
[low_X,low_Y] = my_cell2mat(Channels);

clear Channels 
[dx,dy,dz] = size(low_X);

interior = 1:9;

 low_X = low_X(:,interior,:);
 low_Y = low_Y(:,interior,:);
 
 
if 1
for n = 1:size(low_X,1)%-dim_X_EOG-dim_Y_EOG
    scaled_X = low_X(n,:,:);
   
   if (sum(isinf(scaled_X(:)))>0)
       n
       error('error1')
   end
   
   if (min(scaled_X(:))>=0)
   
    scaled_X = scaled_X + median(scaled_X(:))*10^-8+1;
    scaled_X = log(scaled_X);

   if (sum(isinf(scaled_X(:)))>0)
       n
       error('error2')
   end
   low_X(n,:,:) = scaled_X;
   else
   low_X(n,:,:) = scaled_X;
   end
end

for n = 1:size(low_Y,1)
    scaled_Y = low_Y(n,:,:);
    if (sum(isinf(scaled_Y(:)))>0)
       n
       error('error')
   end
    
    if (min(scaled_Y(:))>=0)
    
    scaled_Y = scaled_Y + median(scaled_Y(:))*10^-8+1;
    scaled_Y = log(scaled_Y);

       if (sum(isinf(scaled_Y(:)))>0)
       error('error')
       end
    low_Y(n,:,:) = scaled_Y;
    else
    low_Y(n,:,:) = scaled_Y;
    end
        
end

end



save('low_X.mat','low_X')
save('low_Y.mat','low_Y')
