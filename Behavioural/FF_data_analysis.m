% clear all
% close all

participant = 1;
plot_it = 1;

data=[];
for block = 1:6
    clear block_data
    %block_data= load(['.\behavioural_data\raw\IS_0' num2str(participant) '_' num2str(block) '.mat']);   
    block_data=load(['..\..\Example_data\raw_bahav\IS_0' num2str(participant) '_' num2str(block) '.mat']);    
    data=[data;block_data.Results_matrix];   
    
end

data(:,5) = data(:,2) ~= data(:,4);

one_flash=data(data(:,2)==1,:);
two_flash=data(data(:,2)==0,:);

levels = unique(data(:,1));

for i = 1:numel(levels)
    
    prop_1(i) = mean(one_flash(one_flash(:,1)==levels(i),4));
    prop_2(i) = mean(two_flash(two_flash(:,1)==levels(i),4));
    prop_all(i) = mean(data(data(:,1)==levels(i),4));
    
    corr_1(i) = mean(one_flash(one_flash(:,1)==levels(i),5));
    corr_2(i) = mean(two_flash(two_flash(:,1)==levels(i),5));
    corr_all(i) = mean(data(data(:,1)==levels(i),5));
    
    prop_2_sum(i) = sum(two_flash(two_flash(:,1)==levels(i),4));
    num_trials_prop_2(i) = size((two_flash(two_flash(:,1)==levels(i),5)),1);
    
    corr_sum_all(i) = sum(data(data(:,1)==levels(i),5));
    num_trials_prop_corr(i) = size((data(data(:,1)==levels(i),5)),1);
    
end

if plot_it == 1
subplot(1,2,1);
hold on
plot(levels, prop_1,'r*--');
plot(levels, prop_2,'go');
plot(levels, prop_all,'k+--');
hold off
ylabel('Proportion report "2 Flashes"');
xlabel('ISI (s)');
ylim([0,1])

subplot(1,2,2);
hold on
plot(levels, corr_1,'r*--');
plot(levels, corr_2,'go--');
plot(levels, corr_all,'k+');
hold off
ylabel('Proportion Correct');
xlabel('ISI (s)');
ylim([0,1])
end

%fit psychometric function
PF = @PAL_Logistic; % specify psychometric function shape
 
% %structure defining grid to search for initial values
searchGrid.alpha = [.02:.01:04]; % range of values to check around for threshold value
searchGrid.beta = [1:2:200]; % range of values to check around for the spread of the PF
searchGrid.gamma = [0.5]; % range of values to check around for the guess rate
searchGrid.lambda = [0]; % range of values to check around for the lapse rate
paramsFree = [1 1 0 0];%0 fixes

% fit PF function with maximum likelihood method
paramsValues_prop_corr = PAL_PFML_Fit(levels', corr_sum_all, num_trials_prop_corr, ...
    searchGrid, paramsFree, PF);

% number of bootstraps to perform below
B = 500;

% bootstrap estimate of deviance of fit
[Dev, pDev_corr, DevSim, converged] = PAL_PFML_GoodnessOfFit(levels', corr_sum_all, ...
    num_trials_prop_corr, paramsValues_prop_corr, paramsFree, B, PF, 'searchGrid', searchGrid);

% % bootstrap estimate of standard errors on parameters fit
% [SD, paramsSim, LLSim, converged2] = PAL_PFML_BootstrapParametric(StimLevels', OutOfNum', ...
%     paramsValues, paramsFree, B, PF, 'searchGrid', searchGrid);

searchGrid.gamma = [0]; % range of values to check around for the guess rate
% fit PF function with maximum likelihood method
paramsValues_prop_2 = PAL_PFML_Fit(levels', prop_2_sum, num_trials_prop_2, ...
    searchGrid, paramsFree, PF);

% % % bootstrap estimate of deviance of fit
[Dev2, pDev_PSE, DevSim2, converged2] = PAL_PFML_GoodnessOfFit(levels', prop_2_sum, ...
    num_trials_prop_2, paramsValues_prop_2, paramsFree, B, PF, 'searchGrid', searchGrid);

if plot_it == 1        
% analyse fitted function parameters across range of stimulus values
t = (min(levels)-.001:.001:max(levels)+.001)';
y = PAL_Logistic(paramsValues_prop_corr, t);
hold on
plot(t,y,'k');
% ylim([0.5,1])
xlim([min(t),max(t)])
hold off

subplot(1,2,1)
hold on
y2 = PAL_Logistic(paramsValues_prop_2, t);
hold on
plot(t,y2,'g');
% ylim([0.5,1])
xlim([min(t),max(t)])
hold off

end

disp(['      PSE     Slope     Guess Rate Lapse Rate pDev']);
disp([paramsValues_prop_2 pDev_PSE]);

if pDev_PSE < 0.05
    disp('Poor data fit for proportion "2 flashes" - visually check fit and search grid to see if there is a problem, or the fit might just be no good');    
end

disp(['  Threshold   Slope   Guess Rate  Lapse Rate pDev']);
disp([paramsValues_prop_corr pDev_corr]);

if pDev_corr < 0.05
    disp('Poor data fit for proportion correct - visually check fit and search grid to see if there is a problem, or the fit might just be no good');    
end



