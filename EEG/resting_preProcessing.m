%This script is the resting state pre-processing for the flash fusion
%project. Data is filtered, downsampled, bad electrodes are removed and
%spherically interpolated and data is broken down to one second epochs for
%rejection. 

%% clean up
close all
clear
clc

%% paths
addpath(genpath('C:\Users\Administrator\Documents\MATLAB'));

% Open EEGLAB
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

% Setting EEGLAB calculations to double precision
eeg_options
if option_single ~= 0 % This value should be zero
    option_single =0;
end

%Path assuming you are in the correct folder
master_path = cd;
addpath(master_path);

raw_path= [master_path '..\..\Example_data\Raw_EEG_data\'];
resting_path= [raw_path 'resting_EEG_data\'];

%% load the raw data

rawDataFiles= dir([raw_path '*.cnt']);

% Open up a .csv file where to store the removed number of epochs
fid = fopen([master_path 'DyxProj_Rej_Final.csv'], 'a');
f = {['Subject'],['Rej.chans.'],['Sum rej.chans'],['Total Epochs'],['Rej.Epochs'],['Sum Rej.Comps_eye'],['Sum Rej.Comps_musc']};
fprintf(fid,'%s,%s,%s,%s,%s,%s,%s\n',f{1,:});

%Automatic rejection parameters
par.HFAnalysis.run = 1 ; %highnoise criterion
%par.deviationAnalysis.run = 1; %channel deviation criterion
par.HFAnalysis.channelRejection = 0; %nochannel removal

%List of stimuli needed for cropping procedure
stimuli_code= {'60','61'};

%% Loop through participants

for isub = 1:length(rawDataFiles)
    loadName = rawDataFiles(isub).name;
    fileName= loadName %think how to call it
    
    % Load
    [EEG com]= pop_loadeep_v4([raw_path '\' loadName],'triggerfile', 'on');
    EEG.setname=fileName;
    
    % Load chans location
    EEG=pop_chanedit(EEG, 'load',[],'lookup',[master_path 'standard-10-5-cap385.elp']);
    
    %Kill EOGs
    EEG = pop_select( EEG,'nochannel',{'HEOG', 'VEOG' , 'ECG2'});
    
%% Filtering
    unfiltEEG = EEG; %Keep the unfiltered EEG structure
    
    % High-pass filter 0.21(-6db at 0.05) + Low-Pass filter at 30 Hz
    EEG = pop_eegfiltnew(EEG, 0.2, [], [], 0);%high pass
    EEG = pop_eegfiltnew(EEG, [], 40, [], 0); %low pass
    
%% Downsample at 512 Hz (if needed - computational constrains)
    EEG = pop_resample(EEG, 512);
%% Clean/Remove Bad sensors
    %Remove bad channels (cleanrawdata way)
    EEG = clean_rawdata(EEG,5,[0.25 0.75],0.8,'off','off','off');
%% Interpolate missing channels
    chans=load([cd '/chanlocs.mat']);
    EEG = pop_interp(EEG, chans.chanlocs, 'spherical');
    
%% Re-reference the data to average
    % 0.1 Hz dataset
    EEG.nbchan = EEG.nbchan+1;
    EEG.data(end+1,:) = zeros(1, EEG.pnts); %continous case
    %EEG.data(end+1,:) = zeros(1, (EEG.pnts*EEG.trials)); %epoched
    EEG.chanlocs(1,EEG.nbchan).labels = 'initialReference';
    EEG = pop_reref(EEG, []);
    EEG = pop_select( EEG,'nochannel',{'initialReference'});
    
    [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);
    
    %% Epoch
    EEG = pop_epoch(EEG, {'60','61' [-1 0], 'newname',[fileName '_epoched'], 'epochinfo', 'yes'});
    tot_epochs = EEG.trials;
    
    
    [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);
   
    % Make sure data is in double precision
    EEG.data = double(EEG.data);
    %% find bad epochs
    par.HFAnalysis.run = 1 ;
    par.HFAnalysis.channelRejection = 0;
   [reject] = k1_detect_bad_epoch_channel(EEG, par); %automatic detection via highnoise 
%pop_saveset(EEG, [fileName '_epoched.set'] , epochs_path);

    % Reject epochs
    EEG = pop_select( EEG,'notrial',find(reject.epochRejectFinal));
    %% Save .set of cleaned epochs
    pop_saveset(EEG, [fileName '_clean.set'] , resting_path);
  
end
    