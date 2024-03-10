% Constants
Fsound = 44100;
T = 1;
t = (0:1/Fsound:T-1/Fsound)';
pad = 0;

% Parameters
ITD = 4e-4;
delta = round(ITD * Fsound);
ILD = 1;
f = 500;

% Define band-pass filter parameters
Fc_low = 200;  % Low cutoff frequency
Fc_high = 2000; % High cutoff frequency
order = 4;      % Filter order

% Design band-pass filters
[b_bandpass_low, a_bandpass_low] = butter(order, Fc_low / (Fsound / 2), 'low');
[b_bandpass_high, a_bandpass_high] = butter(order, Fc_high / (Fsound / 2), 'high');

% Initialize arrays
y_bfs = zeros(length(t) + pad, 2);
y_bfw = zeros(length(t) + pad, 2);
y_w = zeros(length(t) + pad, 2);
y_homo = zeros(length(t) + pad, 2);
y_anti = zeros(length(t) + pad, 2);

% Generate signals
So = (1 * sin(2 * pi * f * t)) .* blackman(length(t));
Spi = -So;

y_bfs(:, 1) = 0.1 * So .* blackman(length(t));
y_bfs(delta+1:end, 2) = y_bfs(1:end-delta, 1);

y_bfw(:, 1) = 0.1 * randn(length(t), 1) .* blackman(length(t));
y_bfw(delta+1:end, 2) = y_bfw(1:end-delta, 1);

% Generate y_w with band-pass filter
y_w = zeros(length(t) + pad, 2);

% Pre-padding with zeros to compensate for delay
y_w_pad = [zeros(round(length(t)/2), 1); zeros(length(t), 1)];

% Apply band-pass filter to the padded signal
filtered_low = filter(b_bandpass_low, a_bandpass_low, y_w_pad);
filtered_low = filtered_low(1:length(y_w));  % Truncate or pad to match the length
y_w(:, 1) = filtered_low;

% Apply high-pass filter to the filtered low-pass signal
filtered_high = filter(b_bandpass_high, a_bandpass_high, y_w(:, 1));
filtered_high = filtered_high(1:length(y_w));  % Truncate or pad to match the length
y_w(:, 1) = filtered_high;

% Add random noise
y_w(:, 1) = y_w(:, 1) + 0.1 * randn(length(y_w), 1) .* blackman(length(y_w));

% Duplicate to right channel
y_w(:, 2) = y_w(:, 1);

% Reverse y_w
y_w = flipud(y_w);

% Homophasic and antiphasic signals
y_homo(:, 1) = So; % Assign So to the first column
y_homo(:, 2) = So; % Assign So to the second column

y_anti(:, 1) = So; % Assign So to the first column
y_anti(:, 2) = Spi; % Assign Spi to the second column

% Apply LPF and HPF to all signals
Fc_lpf = 7000; % LPF cutoff frequency
Fc_hpf = 80;   % HPF cutoff frequency
[b_lpf, a_lpf] = butter(4, Fc_lpf / (Fsound / 2), 'low'); % LPF
[b_hpf, a_hpf] = butter(4, Fc_hpf / (Fsound / 2), 'high'); % HPF

signals = {y_bfs, y_bfw, y_w, y_homo, y_anti};

for i = 1:numel(signals)
    for j = 1:2
        signals{i}(:, j) = filtfilt(b_lpf, a_lpf, signals{i}(:, j));
        signals{i}(:, j) = filtfilt(b_hpf, a_hpf, signals{i}(:, j));
    end
    
    % Check for clipping and implement attack/release if necessary
    max_amplitude = max(abs(signals{i}(:)));
    if max_amplitude >= 1
        % Implement attack/release
        attack_release_time = 0.01; % Adjust as needed
        attack_release_samples = round(attack_release_time * Fsound);
        for j = 1:2 % Iterate over channels
            [env_up, env_down] = envelope(signals{i}(:, j), attack_release_samples, 'peak');
            signals{i}(:, j) = signals{i}(:, j) ./ max(env_up, env_down);
        end
    end
end

% Normalize each signal individually
for i = 1:numel(signals)
    max_amplitude_channel1 = max(abs(signals{i}(:, 1)));
    max_amplitude_channel2 = max(abs(signals{i}(:, 2)));
    max_amplitude_signal = max(max_amplitude_channel1, max_amplitude_channel2);
    norm_factor = 10^(-6/20) / max_amplitude_signal;
    signals{i} = signals{i} * norm_factor;
end

% % Export signals as WAV files
% folder = 'Sounds/';
% if ~exist(folder, 'dir')
%     mkdir(folder);
% end
% 
% file_names = {'1y_bfs.wav', '1y_bfw.wav', '1y_w.wav', '1y_homo.wav', '1y_anti.wav'};
% for i = 1:numel(signals)
%     file_path = fullfile(folder, file_names{i});
%     audiowrite(file_path, signals{i}, Fsound);
%     disp([file_names{i} ' exported to: ' file_path]);
% end
