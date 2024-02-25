clear;
close all;

%% Read the recorded file and plot impedances

% Select file to read
read_Intan_RHD2000_file;

% Plot the impedances of all the channels, find the working channels
figure;
for i = 1:32
    plot(i-1,amplifier_channels(i).electrode_impedance_magnitude/1000,'o')
    hold on
end
set(gca,'XTick',0:1:32)

%% Choose channel(s) to process and apply filter(s)

% Select channel number(s) with useful signal
% [channel#]+1 because of matlab indexing
mapping = [14] + 1;

% Load and apply filters (Create your own filters and apply here)
load lowpass.mat
useful_Amp_Data = amplifier_data(mapping,:); 
dataFiltered = useful_Amp_Data;
% dataFiltered = zeros(length(mapping),size(useful_Amp_Data,2));
% for i = 1:length(mapping)
%     dataFiltered(i,:) = filtfilt(Num_50_10k,1,useful_Amp_Data(i,:));
% end
%% Plot waveforms

% Plot raw data and filtered data
figure;
for i = 1:length(mapping)
    subplot(1,length(mapping),i);
    plot(t_amplifier,amplifier_data(mapping(i),:));
    hold on
    plot(t_amplifier,dataFiltered(i,:));
    hold off
    xlabel('Time/min')
    ylabel('Voltage/{\mu}V')
end

% Plot filtered data
figure;
for i = 1:length(mapping)
    subplot(1,length(mapping),i);
    plot(t_amplifier,dataFiltered(i,:));
%     ylim([-100,100]);
%     xlim([1,119]);
    xlabel('Time/min')
    ylabel('Voltage/{\mu}V')
end

%% Plot Welch’s power spectral density estimate

figure; 
for i = 1:length(mapping)
    pwelch(dataFiltered(i,:),10000,50,200,1e4)
end

%% Compute and plot spectrogram

dataDownSample = dataFiltered(:,1:100:end); 
figure; 
for i = 1:length(mapping)
    subplot(1,length(mapping),i);
    [~,~,~,ps] = spectrogram(dataDownSample(i,:),100,50,200,100); 
    spectrogram(dataDownSample(i,:),100,50,200,100); 
    view(90,-90); colormap('jet'); caxis([-5 25]);
    c=colorbar; ylabel(c,'Power/frequency (dB/Hz)')
end