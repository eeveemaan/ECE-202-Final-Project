% Jean's Sine Design
fs = 44100; % Sampling frequency (changed to 44100 Hz)
duration_per_wave = 1.75; % Duration of each frequency wave in seconds
interval_duration = 3; % Duration of the interval between waves in seconds
attack_duration = 0.5; % Duration of the attack in seconds
fade_duration = 0.5; % Duration of the fade in and fade out in seconds
release_duration = 0.5; % Duration of the release in seconds
freq_range = 80:(80:10:130):10000; % Frequency range

% Define the desired differences between frequencies
desired_differences = [8, 9, 10, 11, 12, 13];

% Define base frequency range
base_freq_range = freq_range;

% Define overtones frequency range
overtone_freq_range = 8:13; % Overtone frequency range

% Initialize output variables for stereo audio
total_duration = 60; % Total duration of 60 seconds
num_intervals = floor(total_duration / (duration_per_wave + interval_duration));
stereo_audio = zeros(2, total_duration * fs); % Stereo audio with 2 channels
current_idx = 1;

% Generate and save audio for each frequency wave
t = linspace(0, duration_per_wave, duration_per_wave * fs);
modulation = sin(2 * pi * 10 * t); % Modulation frequency set to 10 Hz

for i = 1:num_intervals
    % Generate random base frequency for this interval
    base_freq = randi([min(base_freq_range), max(base_freq_range)]);
    
    % Generate audio signal for the base frequency
    base_signal = sin(2 * pi * base_freq * t);
    
    % Add overtones
    overtone_signal = zeros(size(base_signal));
    for overtone_freq = overtone_freq_range
        overtone_signal = overtone_signal + sin(2 * pi * overtone_freq * t);
    end
    
    % Apply low-pass filter at 100 Hz to base signal
    low_pass_filter_base = designfilt('lowpassfir', 'PassbandFrequency', 80, 'StopbandFrequency', 8000, ...
        'PassbandRipple', 0.5, 'StopbandAttenuation', 60, 'DesignMethod', 'kaiserwin', 'SampleRate', fs);
    base_signal = filter(low_pass_filter_base, base_signal);
    
    % Apply low-pass filter at 50 Hz to overtone signal
    low_pass_filter_overtone = designfilt('lowpassfir', 'PassbandFrequency', 40, 'StopbandFrequency', 8000, ...
        'PassbandRipple', 0.5, 'StopbandAttenuation', 60, 'DesignMethod', 'kaiserwin', 'SampleRate', fs);
    overtone_signal = filter(low_pass_filter_overtone, overtone_signal);
    
    % Apply subtle modulation to the base signal
    modulated_signal = base_signal .* (1 + 0.1 * modulation); % Modulation depth set to 0.1
    
    % Apply envelope
    envelope = hann(length(modulated_signal))';
    modulated_signal = modulated_signal .* envelope;
    
    % Apply arbitrary panning (100% left or right)
    panning = randi([0, 1]); % Randomly choose between 0 (left) or 1 (right)
    stereo_signal = zeros(2, length(modulated_signal));
    stereo_signal(1 + panning, :) = modulated_signal;
    
    % Insert the stereo signal into the output variable
    start_idx = current_idx;
    end_idx = start_idx + length(modulated_signal) - 1;
    stereo_audio(:, start_idx:end_idx) = stereo_audio(:, start_idx:end_idx) + stereo_signal;
    
    % Update the current index for the next iteration
    current_idx = end_idx + round(interval_duration * fs);
end

% Normalize the final audio to ensure the loudest peak is at -3 dBFS
max_val = max(abs(stereo_audio(:)));
target_peak = 10^(-3/20); % -3 dBFS
scaling_factor = target_peak / max_val;
stereo_audio = stereo_audio * scaling_factor;

% Save the audio as WAV file
audiowrite('Group_Sine.wav', stereo_audio', fs); % Transpose stereo_audio for proper orientation