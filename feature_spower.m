%% Load file and snip recording
Tsnip = 0.2;          %MAKE SURE TO SET SNIPPET LENGTH CORRECTLY!
after = 1;
snip_recording;

%% Initializing left feature list
SigPower_l = zeros(lcount,2);

% Iterating over left samples
for ii=1:lcount
    % Extract feature here
    for jj=1:2        
        SigPower_l(ii,jj)=sum(snippets_l(ii,:,jj).^2);
    end
end

%% Initializing right feature list
SigPower_r = zeros(rcount,2);

% Iterating over right samples
for ii=1:rcount
    % Extract feature here
    for jj=1:2
        % One channel at a time
        SigPower_r(ii,jj)=sum(snippets_r(ii,:,jj).^2);
    end
end

%% Initializing silent feature list
SigPower_s = zeros(scount,2);

% Iterating over right samples
for ii=1:scount
    % Extract feature here
    for jj=1:2
        % One channel at a time
        SigPower_s(ii,jj)=sum(snippets_s(ii,:,jj).^2)/Tsnip;
    end
end

%% Compute Correlation
events=[1*ones(lcount,1); 1*ones(rcount,1); 0*ones(scount,1)];
features=[SigPower_l; SigPower_r; SigPower_s];

A = [events features];
R = corrcoef(A);

% Do y'all think using numerical labels for events is valid? Should we be
% using ANOVA or something along those lines?

scatter(events,features(:,1)); ylim([0 1e6]);

% Need to agree on a way to save this data!
% Also need to figure out how to handle 2D features!

%% ANOVA
for jj=1:2
    %data_anova=NaN(max([lcount rcount scount]),3);
    data_anova=NaN(max([lcount scount]),2);
    data_anova(1:lcount,1)=SigPower_l(:,jj);data_anova(1:scount,2)=SigPower_s(:,jj);
    fprintf("Channel %d\n",jj);
    aov=anova(data_anova);
    disp(aov);
end