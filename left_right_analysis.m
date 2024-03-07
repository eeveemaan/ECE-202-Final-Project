data = 'PlainWhite_open.mat';
load(data)
Fs= 10000;
epochs = directionEEG(savedata,savesound,0,1,Fs);

[avgL, avgR, avgS] = plotAverageEpochs(epochs,0,Fs);

plotFrequencySpectrum(avgL, avgR, avgS, Fs);

function [avgLeft, avgRight, avgSilence] = plotAverageEpochs(epochs, timeBefore, samplingRate)
    % Calculate the time axis for plotting
    nSamplesBefore = round(timeBefore * samplingRate);
    nSamplesTotal = size(epochs.left, 2); % Assuming all have the same size
    timeAxis = linspace(-timeBefore, (nSamplesTotal - nSamplesBefore - 1)/samplingRate, nSamplesTotal);
    
    % Calculate averages
    avgLeft = mean(epochs.left, 3);
    avgRight = mean(epochs.right, 3);
    avgSilence = mean(epochs.silence, 3);
    
    % Plotting
    figure; hold on; % Opens a new figure and holds it for multiple plots
    plot(timeAxis, mean(avgLeft, 1), 'LineWidth', 2, 'DisplayName', 'Left');
    plot(timeAxis, mean(avgRight, 1), 'LineWidth', 2, 'DisplayName', 'Right');
    plot(timeAxis, mean(avgSilence, 1), 'LineWidth', 2, 'DisplayName', 'Silence');
    
    legend('show'); % Show legend
    xlabel('Time (s)');
    ylabel('Amplitude (\muV)'); % Assuming microvolts, adjust as necessary
    title('Average EEG Response');
    grid on;
end


function epochs = directionEEG(savedata, savesound, timeBefore, timeAfter, samplingRate)
    % Convert timeBefore and timeAfter to samples
    samplesBefore = round(timeBefore * samplingRate);
    samplesAfter = round(timeAfter * samplingRate);
    
    % Initialize the epoch structure
    epochs.left = [];
    epochs.right = [];
    epochs.silence = [];
    
    % Loop through each point in savesound
    for i = 1:length(savesound)
        if savesound(i) ~= 0 % Check if there's a stimulus
            % Determine epoch start and end points
            startIdx = max(i - samplesBefore, 1); % Ensure not before start
            endIdx = min(i + samplesAfter, length(savesound)); % Ensure not after end
            
            % Extract the epoch from savedata
            epochData = savedata(:, startIdx:endIdx);
            
            % Append to the appropriate field based on stimulus type
            switch savesound(i)
                case 1 % Left
                    epochs.left = cat(3, epochs.left, epochData);
                case 2 % Right
                    epochs.right = cat(3, epochs.right, epochData);
                case 3 % Silence
                    epochs.silence = cat(3, epochs.silence, epochData);
            end
        end
    end
end

function plotFrequencySpectrum(avgLeft, avgRight, avgSilence, samplingRate)


    % Left condition
    nL = length(avgLeft); % Number of points in avgLeft
    fL = (0:nL-1)*(samplingRate/nL); % Frequency vector for Left
    fftLeft = fft(avgLeft); % FFT of avgLeft
    magLeft = abs(fftLeft/nL); % Magnitude of FFT for Left

    % Right condition
    nR = length(avgRight); % Number of points in avgRight
    fR = (0:nR-1)*(samplingRate/nR); % Frequency vector for Right
    fftRight = fft(avgRight); % FFT of avgRight
    magRight = abs(fftRight/nR); % Magnitude of FFT for Right

    % Silence condition
    nS = length(avgSilence); % Number of points in avgSilence
    fS = (0:nS-1)*(samplingRate/nS); % Frequency vector for Silence
    fftSilence = fft(avgSilence); % FFT of avgSilence
    magSilence = abs(fftSilence/nS); % Magnitude of FFT for Silence
    
    % Plot the frequency spectrum in separate subplots
    figure;
    
    % Left
    subplot(1,3,1);
    plot(fL(1:floor(nL/2)), magLeft(1:floor(nL/2)), 'LineWidth', 2);
    title('Left');
    xlabel('Frequency (Hz)');
    ylabel('Magnitude');
    xlim([0, 30]); % Limit x-axis to Nyquist frequency
    
    % Right
    subplot(1,3,2);
    plot(fR(1:floor(nR/2)), magRight(1:floor(nR/2)), 'LineWidth', 2);
    title('Right');
    xlabel('Frequency (Hz)');
    xlim([0, 30]);
    
    % Silence
    subplot(1,3,3);
    plot(fS(1:floor(nS/2)), magSilence(1:floor(nS/2)), 'LineWidth', 2);
    title('Silence');
    xlabel('Frequency (Hz)');
    xlim([0, 30]);
    
    sgtitle('Frequency Spectrum of EEG Averages'); % Super title for all subplots
end

