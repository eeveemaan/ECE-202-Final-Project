%% Load file and snip recording
snip_recording;

%MAKE SURE TO SET SNIPPET LENGTH CORRECTLY!

%% Initializing left feature list
fval1_l = zeros(lcount,2);

% Iterating over left samples
for ii=1:lcount
    % Extract feature here
    for jj=1:2
        % One channel at a time
        fval1_l(ii,jj)=0;
    end
end

%% Initializing right feature list
fval1_r = zeros(rcount,2);

% Iterating over right samples
for ii=1:rcount
    % Extract feature here
    for jj=1:2
        % One channel at a time
        fval1_r(ii,jj)=0;
    end
end

%% Initializing silent feature list
fval1_s = zeros(scount,2);

% Iterating over right samples
for ii=1:scount
    % Extract feature here
    for jj=1:2
        % One channel at a time
        fval1_s(ii,jj)=0;
    end
end

%% Compute Correlation
events=[1*ones(lcount,1); 2*ones(rcount,1); 3*ones(scount,1)];
features=[fval1_l; fval1_r; fval1_s];

A = [events features];
R = corrcoef(A);

% Need to agree on a way to save this data!