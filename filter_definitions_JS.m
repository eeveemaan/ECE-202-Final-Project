% File: filter_definitions_JS.m

function [b_highpass, a_highpass, b_lowpass, a_lowpass] = filter_definitions_JS(Fs)
    % Apply high-pass filter
    fc_highpass = 200; % Change cutoff frequency to desired value
    [b_highpass, a_highpass] = butter(4, fc_highpass / (Fs / 2), 'high');

    % Apply low-pass filter
    fc_lowpass = 7000; % Change cutoff frequency to desired value
    [b_lowpass, a_lowpass] = butter(4, fc_lowpass / (Fs / 2), 'low');
end
