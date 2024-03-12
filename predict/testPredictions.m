
load("Left_Closed_HomoAnti_03-07_112828.mat")
Fs = 5000;


[eegSnippets, eventLabels] = splitDataIntoSnippets(savedata.', savesound.', Fs);

predictionsNow = predictEvents(eegSnippets,Fs);

% Calculate accuracy
correctPredictions = sum(predictionsNow == eventLabels);
totalPredictions = length(eventLabels);
accuracy = correctPredictions / totalPredictions;

fprintf('Prediction accuracy: %.2f%%\n', accuracy * 100);


function [eegSnippets, eventLabels] = splitDataIntoSnippets(eegData, soundData, Fs)

    samplesPerSecond = Fs;
    
   
    totalSeconds = floor(size(eegData, 1) / samplesPerSecond);
    
    % Preallocate 
    eegSnippets = cell(totalSeconds, 1);
    eventLabels = zeros(totalSeconds, 1);
    
    % Loop through each second of data
    for i = 1:totalSeconds
        % Calculate start and end indices for the current second
        idxStart = (i - 1) * samplesPerSecond + 1;
        idxEnd = i * samplesPerSecond;
        
        % Extract the EEG snippet and corresponding sound label
        eegSnippets{i} = eegData(idxStart:idxEnd, :);
        

        if soundData(idxStart) == 1 || soundData(idxStart) == 2
            eventLabels(i) = 1; % Events 1 and 2 correspond to 1
        elseif soundData(idxStart) == 3
            eventLabels(i) = 0; % Event 3 corresponds to 0
        end
    end
end

function predictions = predictEvents(eegSnippets, Fs)
    % Initialize predictions
    numSnippets = length(eegSnippets);
    predictions = zeros(numSnippets, 1);
    
    %coefficients for logistic regression
    B = [1.9216, -0.0021]; 
    %B = [1.359966733506670;2.722059206731870e-04];
    
    for i = 1:numSnippets
      
        snippet = eegSnippets{i};
        
      
        alphaBand = [8 12];
        alphaData = bandpass(snippet, alphaBand, Fs);
        alphaPower = mean(sum(alphaData.^2, 1)); 
        
        prob = exp(B(1) + B(2) * alphaPower) / (1 + exp(B(1) + B(2) * alphaPower));
        predictions(i) = prob > 0.5; % Determine class based on probability
    end
end

