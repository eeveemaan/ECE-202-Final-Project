
load('HomoAnti_closed.mat')
Fs = 5000;


alphaBand = [8 12]; % Alpha band

% Preallocate 
numSeconds = floor(length(savedata) / Fs);
alphaPower = zeros(numSeconds, 2); %two channels
savedata = savedata.';

for i = 1:numSeconds
    %one-second snippets for each channel
    idxStart = (i-1)*Fs + 1;
    idxEnd = i*Fs;
    snippet1 = bandpass(savedata(idxStart:idxEnd, 1), alphaBand, Fs);
    snippet2 = bandpass(savedata(idxStart:idxEnd, 2), alphaBand, Fs);
    
    % Calculate alpha power for each channel
    alphaPower(i, 1) = bandpower(snippet1, Fs, alphaBand);
    alphaPower(i, 2) = bandpower(snippet2, Fs, alphaBand);
end


% Initialize 
eventLabels = zeros(numSeconds, 1); % One label /second

% Loop over the savesound array to mark the start of each event
for i = 1:length(savesound)
    if savesound(i) == 1 || savesound(i) == 2
        % Find the corresponding second for the event start
        secondIdx = floor((i-1) / Fs) + 1;
        if secondIdx <= numSeconds
            eventLabels(secondIdx) = 1; % Mark event 1 or 2 as '1'
        end
    elseif savesound(i) == 3
        % Find the corresponding second for the event start
        secondIdx = floor((i-1) / Fs) + 1;
        if secondIdx <= numSeconds
            eventLabels(secondIdx) = 0; % Mark event 3 as '0'
        end
    end
    % This approach marks the second in which an event starts.
    % If events last exactly 1 second, this mapping is accurate.
    % Adjust if your event duration differs.
end



% Average alpha power of the two channels
averageAlphaPower = mean(alphaPower, 2);

X = averageAlphaPower; % For using the average alpha power
% X = alphaPower; % Uncomment if using both channels separately
y = eventLabels;

% split the data w cvpartition
cv = cvpartition(length(y), 'HoldOut', 0.2); % 80-20 split
idxTrain = cv.training;
idxTest = cv.test;

XTrain = X(idxTrain, :);
yTrain = y(idxTrain);
XTest = X(idxTest, :);
yTest = y(idxTest);

% Fit logistic regression model
B = mnrfit(XTrain, yTrain + 1); % Adding 1 because MATLAB indexing

% Make predictions on the test set
prob = mnrval(B, XTest);
[~, predictions] = max(prob, [], 2);
predictions = predictions - 1; % Adjusting back to 0-based indexing

% Calculate accuracy or other performance metrics
accuracy = sum(predictions == yTest) / length(yTest);
fprintf('Model accuracy: %.2f%%\n', accuracy * 100);

