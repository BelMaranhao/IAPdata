% This script extracts the IAP from the pre-processed resting state
%(To be used after resting_preProcessing.m)



% channnel numbers we care: 30,31,32 then maybe 56,29,57
%% clean up
close all
clear
clc

%% paths
addpath(genpath('C:\Users\Administrator\Documents\MATLAB'));

% Open EEGLAB
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

%Open FOOF

% Setting EEGLAB calculations to double precision[
eeg_options
if option_single ~= 0 % This value should be zero
    option_single =0;
end

%Path assuming you are in the correct folder
master_path = 'EEG_data\';
addpath(master_path);

raw_path= [master_path 'raw\'];
resting_path= [master_path 'resting\'];
IAP_path=[master_path 'IAP\'];


%channels= [30, 31, 32, 56,29,57]

%% Load resting data
restingDataFiles= dir([resting_path '*.set']) 

%% Loop through participants 

for isub=1:length(restingDataFiles)
    loadName= restingDataFiles(isub).name
    fileName=loadName %call it something
    
    %Load
    [EEG com]=pop_loadset%([resting_path '\' loadName],'triggerfile', 'on');
    EEG.setname=fileName;

    %zeropad to stick epochs together 
    
    %calculate power spectrum with Welch's method on continuous data
    %(Barret's funstion)
    %[cpsd, freqs] = tsdata_to_cpsd(EEG.data, 512, [], [],[],[]);
    
    %Get the cpsd diagnal to obtain the psd
%    for i=1:64
%     psd(i)= diag(cpsd(i,:,:))
%    end 
    %[psd, freqs] = spectopo (EEG.data((32),:,:),0,512);
     Ch=32
    % Calculate power spectra with Welch's method
    %[psds, freqs] = spectopo (EEG.data((Ch),:,:),0,512);
    
     [psds, freqs] =spectopo (EEG.data((32),:,:),0,512);
   
%% Save Out Data

% Save the power spectra out to mat files
save('power_spectra', 'freqs', 'psds');


%     %transpose to make input row vectors 
%     freqs= freqs';
%     psd=psd';
%     
%     %fooof settings
%     settings= struct(); %default
%     f_range=[1, 30];
    
    %Run Fooof
    %fooof_results= fooof(freqs, psd, f_range, settings);

end 




