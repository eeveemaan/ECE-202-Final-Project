%% Loads the following files, merges them and trains a model
files = string(ls);
files = files(3:end);
%files = files.name
Fs = 5000; % Sampling frequency

allFeatures = [];
allLabels = [];
%B_ALL = [1.359966733506670;2.722059206731870e-04];
for i = 1:length(files)
    [features, labels] = processEEGFile(files{i}, Fs);
    allFeatures = [allFeatures; features];
    allLabels = [allLabels; labels];
end

%% Splits the data into training and test sets
cv = cvpartition(length(allLabels), 'HoldOut', 0.2);
idxTrain = training(cv);
idxTest = test(cv);

XTrain = allFeatures(idxTrain, :);
yTrain = allLabels(idxTrain);
XTest = allFeatures(idxTest, :);
yTest = allLabels(idxTest);

%% Fit logistic regression model
[Ball,dev,stat] = mnrfit(XTrain, yTrain + 1); % MATLAB indexing

%% Test the model and calculate accuracy
prob = mnrval(Ball, XTest);          % Compute the probabilities given test set features
[~, predictions] = max(prob, [], 2); % 
predictions = predictions - 1;

accuracy = sum(predictions == yTest) / length(yTest);
fprintf('Model accuracy: %.2f%%\n', accuracy * 100);


%% Function definitions:
function [features, labels] = processEEGFile(fileName, Fs)
    
    data = load(fileName);
    savedata = data.savedata; 
    savesound = data.savesound;
    
    
    savedata = savedata.'; 


    alphaBand = [8 12]; 
    betaBand = [13 20];
    % Preallocate 
    numSeconds = floor(length(savedata) / Fs);
    alphaPower = zeros(numSeconds, 2); %two channels
    betaPower = zeros(numSeconds, 2);
    savedata = savedata;

    for i = 1:numSeconds
        %one-second snippets for each channel
        idxStart = (i-1)*Fs + 1;
        idxEnd = i*Fs;
        snippet1 = bandpass(savedata(idxStart:idxEnd, 1), alphaBand, Fs);
        snippet2 = bandpass(savedata(idxStart:idxEnd, 2), alphaBand, Fs);
        snippet3 = bandpass(savedata(idxStart:idxEnd, 1), betaBand, Fs);
        snippet4 = bandpass(savedata(idxStart:idxEnd, 2), betaBand, Fs);
        
        % Calculate alpha power for each channel
        alphaPower(i, 1) = bandpower(snippet1, Fs, alphaBand);
        alphaPower(i, 2) = bandpower(snippet2, Fs, alphaBand);
        betaPower(i, 1) = bandpower(snippet1, Fs, betaBand);
        betaPower(i, 2) = bandpower(snippet2, Fs, betaBand);
    end
    
    
    % Initialize the eventLabels array with zeros
    eventLabels = zeros(numSeconds, 1); % One label per second
    
    % Loop over the savesound array to mark the start of each event
    for i = 1:length(savesound)
        if savesound(i) == 1 
            % Find the corresponding second for the event start
            secondIdx = floor((i-1) / Fs) + 1;
            if secondIdx <= numSeconds
                eventLabels(secondIdx) = 1; % Mark event 1 as '1'
            end
        elseif savesound(i) == 3
            % Find the corresponding second for the event start
            secondIdx = floor((i-1) / Fs) + 1;
            if secondIdx <= numSeconds
                eventLabels(secondIdx) = 0; % Mark event 3 as '0'
            end
         elseif savesound(i) == 2
            % Find the corresponding second for the event start
            secondIdx = floor((i-1) / Fs) + 1;
            if secondIdx <= numSeconds
                eventLabels(secondIdx) = 2; % Mark event 2 as '2'
            end
        end

    end

    
    % Calculate average alpha power or use both channels
    %averageAlphaPower = mean(alphaPower, 2); % average alpha power
    %averageBetaPower = mean(betaPower, 2);
    features = [alphaPower, betaPower];
    labels = eventLabels;
end
