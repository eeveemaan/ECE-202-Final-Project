%% Extract features from EEG data 
% to be added to the feature_template.m file loop

% Time-domain features
% Mean amplitude
feature1 = mean(window_data(:, jj));

% Standard deviation of amplitude
feature2 = std(window_data(:, jj));

% Variance
feature3 = var(window_data(:, jj));

% Root mean square (RMS)
feature4 = rms(window_data(:, jj));

% Skewness
feature5 = skewness(window_data(:, jj));

% Kurtosis
feature6 = kurtosis(window_data(:, jj));

% Maximum amplitude
feature7 = max(window_data(:, jj));

% Minimum amplitude
feature8 = min(window_data(:, jj));

% Frequency-domain features
% Apply Fast Fourier Transform (FFT) to windowed EEG data
fft_data = abs(fft(window_data(:, jj)));

% Peak frequency (frequency with maximum amplitude)
feature9 = fs * find(fft_data == max(fft_data)) / length(fft_data);

% Mean frequency
feature10 = sum((1:length(fft_data)) * fft_data) / sum(fft_data);

% Median frequency
cumulative_fft = cumsum(fft_data);
feature11 = fs * find(cumulative_fft >= sum(fft_data) / 2, 1) / length(fft_data);

% Total power in specific frequency bands (e.g., delta, theta, alpha, beta)
delta_band = [1, 4]; % Define delta band (1-4 Hz)
theta_band = [4, 8]; % Define theta band (4-8 Hz)
alpha_band = [8, 12]; % Define alpha band (8-12 Hz)
beta_band = [12, 30]; % Define beta band (12-30 Hz)

delta_power = sum(fft_data(delta_band(1):delta_band(2)));
theta_power = sum(fft_data(theta_band(1):theta_band(2)));
alpha_power = sum(fft_data(alpha_band(1):alpha_band(2)));
beta_power = sum(fft_data(beta_band(1):beta_band(2)));

feature12 = delta_power;
feature13 = theta_power;
feature14 = alpha_power;
feature15 = beta_power;

% Store features
fval1(ii, :) = [feature1, feature2, feature3, feature4, feature5, feature6, feature7, feature8, feature9, feature10, feature11, feature12, feature13, feature14, feature15];
