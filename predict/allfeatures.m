files = {'HomoAnti_closed.mat', 'HomoAnti_closed2.mat', 'PlainWhite_closed2.mat', 'HomoAnti_open.mat', 'PlainWhite_open.mat' }; % Add your file names
Fs = 5000; % Sampling frequency

allFeatures = [];
allLabels = [];

for i = 1:length(files)
    [features, labels] = processEEGFile(files{i}, Fs);
    allFeatures = [allFeatures; features];
    allLabels = [allLabels; labels];
end

% Proceed with data splitting, model training, and testing as before
cv = cvpartition(length(allLabels), 'HoldOut', 0.2);
idxTrain = training(cv);
idxTest = test(cv);

XTrain = allFeatures(idxTrain, :);
yTrain = allLabels(idxTrain);
XTest = allFeatures(idxTest, :);
yTest = allLabels(idxTest);

% Fit logistic regression model
Ball = mnrfit(XTrain, yTrain + 1); % MATLAB indexing

% Test the model and calculate accuracy
prob = mnrval(Ball, XTest);
[~, predictions] = max(prob, [], 2);
predictions = predictions - 1;

accuracy = sum(predictions == yTest) / length(yTest);
fprintf('Model accuracy: %.2f%%\n', accuracy * 100);


function [features, labels] = processEEGFile(fileName, Fs)
    % Load .mat file
    data = load(fileName);
    savedata = data.savedata; % Adjust variable names as needed
    savesound = data.savesound;
    
    % Transpose savedata if necessary
    savedata = savedata.'; % Ensure savedata is [time x channels]

    % Compute alpha power and prepare labels (as in your provided code)
    alphaBand = [8 12]; 
    % Preallocate 
    numSeconds = floor(length(savedata) / Fs);
    alphaPower = zeros(numSeconds, 2); %two channels
    savedata = savedata;

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
    
    
    % Initialize the eventLabels array with zeros
    eventLabels = zeros(numSeconds, 1); % One label per second
    
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




    
    % Calculate average alpha power or use both channels
    averageAlphaPower = mean(alphaPower, 2); % Example: using average alpha power
    features = averageAlphaPower;
    labels = eventLabels;
end
