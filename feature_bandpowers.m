%% Load file and snip recording
Tsnip = 1;          %MAKE SURE TO SET SNIPPET LENGTH CORRECTLY!
after = 1;
snip_recording;
%MAKE SURE TO SET SNIPPET LENGTH CORRECTLY!

close all;

%close all; 
delta_band = [1, 4]; % Define delta band (1-4 Hz)
theta_band = [4, 8]; % Define theta band (4-8 Hz)
alpha_band = [8, 12]; % Define alpha band (8-12 Hz)
beta_band = [12, 30]; % Define beta band (12-30 Hz)

%% Initializing left feature list
delta_power_l = zeros(lcount,2);
theta_power_l = zeros(lcount,2);
alpha_power_l = zeros(lcount,2);
beta_power_l  = zeros(lcount,2);

% Iterating over left samples
for ii=1:lcount   
    for jj=1:2        
        % Total power in specific frequency bands (e.g., delta, theta, alpha, beta)    
        delta_power_l(ii,jj) = bandpower(snippets_l(ii,:,jj),5000,delta_band);
        theta_power_l(ii,jj) = bandpower(snippets_l(ii,:,jj),5000,theta_band);
        alpha_power_l(ii,jj) = bandpower(snippets_l(ii,:,jj),5000,alpha_band);
        beta_power_l (ii,jj) = bandpower(snippets_l(ii,:,jj),5000,beta_band);
    end
end

%% Initializing right feature list
delta_power_r = zeros(rcount,2);
theta_power_r = zeros(rcount,2);
alpha_power_r = zeros(rcount,2);
beta_power_r  = zeros(rcount,2);

% Iterating over right samples
for ii=1:rcount
    % Extract feature here
    for jj=1:2
        % One channel at a time
        delta_power_r(ii,jj) = bandpower(snippets_r(ii,:,jj),5000,delta_band);
        theta_power_r(ii,jj) = bandpower(snippets_r(ii,:,jj),5000,theta_band);
        alpha_power_r(ii,jj) = bandpower(snippets_r(ii,:,jj),5000,alpha_band);
        beta_power_r (ii,jj) = bandpower(snippets_r(ii,:,jj),5000,beta_band);
    end
end

%% Initializing silent feature list
delta_power_s = zeros(scount,2);
theta_power_s = zeros(scount,2);
alpha_power_s = zeros(scount,2);
beta_power_s  = zeros(scount,2);

% Iterating over right samples
for ii=1:scount
    % Extract feature here
    for jj=1:2
        % One channel at a time
        delta_power_s(ii,jj) = bandpower(snippets_s(ii,:,jj),5000,delta_band);
        theta_power_s(ii,jj) = bandpower(snippets_s(ii,:,jj),5000,theta_band);
        alpha_power_s(ii,jj) = bandpower(snippets_s(ii,:,jj),5000,alpha_band);
        beta_power_s (ii,jj) = bandpower(snippets_s(ii,:,jj),5000,beta_band);
    end
end

%% Compute Correlation
events=[-1*ones(lcount,1); 1*ones(rcount,1); 0*ones(scount,1)];

% alpha
features=[alpha_power_l; alpha_power_r; alpha_power_s];

levels = [mean(alpha_power_l); mean(alpha_power_s); mean(alpha_power_r)];
disp(levels);

%beta
% features=[beta_power_l; beta_power_r; beta_power_s];
% levels = [mean(beta_power_l); mean(beta_power_s); mean(beta_power_r)];
% disp(levels);

% %delta
% features=[delta_power_l; delta_power_r; delta_power_s];
% 
% levels = [mean(delta_power_l); mean(delta_power_s); mean(delta_power_r)];
% disp(levels);

% %theta
% features=[theta_power_l; theta_power_r; theta_power_s];
% 
% levels = [mean(theta_power_l); mean(theta_power_s); mean(theta_power_r)];
% disp(levels);

A = [events features];
R = corrcoef(A);

% Do y'all think using numerical labels for events is valid? Should we be
% using ANOVA or something along those lines?

figure;
scatter(events,features(:,1))

% Need to agree on a way to save this data!
% Also need to figure out how to handle 2D features!


% %% ANOVA
% for jj=1:2
%     data_anova=NaN(max([lcount rcount scount]),3);
%     data_anova(1:lcount,1)=fval1_l(:,jj);data_anova(1:rcount,2)=fval1_r(:,jj);data_anova(1:scount,3)=fval1_s(:,jj);
%     fprintf("Channel %d\n",jj);
%     aov=anova(data_anova);
%     disp(aov);
% end    