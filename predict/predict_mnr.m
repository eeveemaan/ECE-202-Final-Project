%% Loads the following files, merges them and trains a model
files = string(ls);
files = files(3:end);
%files = files.name
Fs = 5000; % Sampling frequency

allFeatures = [];
allLabels = [];
Tsnip = 1;
after= 1;
for i = 1:length(files)
    [sl, sr, ss] = snipEEG(files{i},Tsnip,after);
    featl = featEEGsnip(sl);
    featr = featEEGsnip(sr);
    feats = featEEGsnip(ss);
    allFeatures = [allFeatures; featl ;featr ;feats];
    for n = 1:size(sl,1)
        allLabels = [allLabels 1];
    end

    for n = 1:size(sr,1)
        allLabels = [allLabels 2];
    end

    for n = 1:size(ss, 1)
        allLabels = [allLabels 3];
    end
end
allFeatures = allFeatures;
%% Splits the data into training and test sets
cv = cvpartition(length(allLabels), 'HoldOut', 0.2);
idxTrain = training(cv);
idxTest = test(cv);

XTrain = allFeatures(idxTrain,:);
yTrain = allLabels(idxTrain);
XTest = allFeatures(idxTest,:);
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
function features = featEEGsnip(snips)
    Fs = 5000;
    seconds = size(snips,1);
    alphaBand = [8 12]; 
    betaBand = [13 20];
    alphaPower = zeros(seconds, 2); %two channels
    betaPower = zeros(seconds, 2);
    diffAlpha = zeros(seconds, 2);
    diffBeta = zeros(seconds, 2);
    for i = 1:seconds
        % Calculate alpha power for each channel
        alphaPower(i, 1) = bandpower(snips(i,:,1), Fs, alphaBand);
        alphaPower(i, 2) = bandpower(snips(i,:,2), Fs, alphaBand);
        betaPower(i, 1) = bandpower(snips(i,:,1), Fs, betaBand);
        betaPower(i, 2) = bandpower(snips(i,:,2), Fs, betaBand);
    end
    for i = 2:seconds
        diffAlpha(i, 1) = alphaPower(i, 1) - alphaPower(i-1,1);
        diffAlpha(i, 2) = alphaPower(i, 2) - alphaPower(i-1,2);
        diffBeta(i, 1) = betaPower(i, 1) - betaPower(i-1,1);
        diffBeta(i, 2) = betaPower(i, 2) - betaPower(i-1,2);
    end
        
    

    features = [alphaPower, betaPower];

end
    
   

