%% Load file and snip recording
Tsnip = 0.1;          %MAKE SURE TO SET SNIPPET LENGTH CORRECTLY!
after = 0.99;
snip_recording;
%MAKE SURE TO SET SNIPPET LENGTH CORRECTLY!

%% Initializing left feature list
fval1_l = zeros(lcount,2);

% Iterating over left samples
for ii=1:lcount
    % Extract feature here
    for jj=1:2
        % One channel at a time
        fval1_l(ii,jj)=randn(1);
    end
end

%% Initializing right feature list
fval1_r = zeros(rcount,2);

% Iterating over right samples
for ii=1:rcount
    % Extract feature here
    for jj=1:2
        % One channel at a time
        fval1_r(ii,jj)=randn(1);
    end
end

%% Initializing silent feature list
fval1_s = zeros(scount,2);

% Iterating over right samples
for ii=1:scount
    % Extract feature here
    for jj=1:2
        % One channel at a time
        fval1_s(ii,jj)=randn(1);
    end
end

%% Compute Correlation
events=[-1*ones(lcount,1); 1*ones(rcount,1); 0*ones(scount,1)];
features=[fval1_l; fval1_r; fval1_s];

A = [events features];
R = corrcoef(A);

% Do y'all think using numerical labels for events is valid? Should we be
% using ANOVA or something along those lines?

figure;
scatter(events,features(:,1))

% Need to agree on a way to save this data!
% Also need to figure out how to handle 2D features!

