% This script reads 'time.dat' and any present amplifier '.dat' files,
% plotting those named in the UI.

% This script works with both previously saved data and data that's being
% acquired in real-time, and is intended to run from the same directory as
% the acquired data. By default, Intan RHX software creates a new directory
% at the time of recording for each session, but this can be disabled in
% the 'File Format' dialog of the RHX, by deselecting 'Create new save
% directory with timestamp for each recording'. Note that disabling this
% allows for previously acquired data to be overwritten when a new
% recording session begins, so use this option with care.

% Set up main UI
create_main_ui();

% When 'start' is clicked - begin realtime reading and plotting
function start(button_group)

% Global handles object used to share variables among functions
global hs

% Initialize plotted sample counter
hs.plotted_samples = 0;

% Determine how many channels should be plotted
num_channels = length(hs.d_filenames);

% Set up plotting window (maximize so the multiple waveforms are large
% enough to see)
f = figure;
set(f, 'WindowState', 'maximized');

% While 'start' remains selected ('stop' not selected), 
while get(button_group.Children(2), 'Value')
    
    % Determine how many samples should be plotted based on UI state
    N_samples_per_plot = hs.samples_per_plot_spinner.Value;
    
    % Total # of samples available in these files (use the minimum of both
    % t and data in case they're not written at exactly the same time)
    available_samples = min(dir(hs.t_filename).bytes/4, dir(hs.d_filenames(1)).bytes/2);
    
    % If enough samples are available, continue with plotting
    if available_samples - hs.plotted_samples >= N_samples_per_plot
        
        % read timestamp and data from files
        t = read_timestamp;
        d = read_data;
        
        % plot channels
        plot_channels(num_channels, t, d);
        hs.plotted_samples = hs.plotted_samples + N_samples_per_plot;
        
        % deliver status update to UI
        accumulated_samples = available_samples - hs.plotted_samples;
        status_str = ['Accumulated unplotted samples: ' int2str(accumulated_samples)];
        status_color = get_suitable_color(accumulated_samples, N_samples_per_plot);
        update_ui_status(status_str, status_color);
        
    % If there aren't enough samples, wait for a short while
    else
        pause(0.01);
    end
end

end

% When 'stop' is clicked - stop realtime reading and plotting
function stop()
update_ui_status('Stopped', 'black');
end

% Update status_text on the UI with the given message
function update_ui_status(status_message, color)
global hs
set(hs.status_text, 'Text', status_message);
set(hs.status_text, 'FontColor', color);
drawnow;
end

% Start button change callback function
function button_changed(source, event)
if strcmp(event.NewValue.Text, 'Start')
    start(source);
else
    stop;
end
end

% Read info button clicked callback function
function read_info_clicked(~,~)

global hs

% Peek into info file for sample rate
[success, info_fid] = open_file(['info' hs.rhd_or_rhs_group.SelectedObject.Text]);
if ~success, return; end
fread(info_fid, 8, 'int8'); % Skip first 8 bytes
hs.sample_rate = fread(info_fid, 1, 'single'); % Get sample rate
fclose(info_fid);

% Update UI to indicate that info file has been read
set(hs.start_button, 'Enable', 1);
set(hs.stop_button, 'Enable', 1);
update_ui_status('Click start to begin looking for data to read.', 'black');

% Initialize timestamp and data file IDs
hs.t_filename = 'time.dat';
hs.d_filenames = string(strsplit(hs.filenames_edit.Value, ';'));

% Open timestamp and data files to read later
[success, hs.t_fid] = open_file(hs.t_filename);
if ~success, return; end
[success, hs.d_fid] = open_files(hs.d_filenames);
if ~success, return; end

end

% Open file and give a UI status warning in case of failure
function [success, fid] = open_file(filename)
[fid, errmsg] = fopen(filename, 'r');
if ~strcmp(errmsg, '')
    status_str = append('Failed to read ', filename, '. Is it in this directory?');
    update_ui_status(status_str, 'red');
    success = false;
    return;
else
    success = true;
end
return;
end

% Open multiple files
function [success, fids] = open_files(filenames)
fids = [];
for i = 1:length(filenames)
    [success, fids(end+1)] = open_file(filenames(i));
    if ~success, return; end
end
end

% Create the main UI window that contains control buttons
function create_main_ui()
global hs
% Make figure visible after adding components
hs = add_ui_components();
hs.fig.Visible = 'on';
end

% Populate the UI with the components it needs
function hs = add_ui_components()
% Add components, save handles in a struct
hs.main_ui = uifigure('Name', 'RHX Realtime Read GUI, for One File Per Channel',...
    'Position', [10, 50, 500, 304]);
hs.rhd_or_rhs_group = uibuttongroup(hs.main_ui,...
    'Position', [10, 250, 80, 50]);
hs.rhd_button = uiradiobutton(hs.rhd_or_rhs_group,...
    'Text', '.rhd',...
    'Position', [10, 25, 100, 22],...
    'Value', 1);
hs.rhs_button = uiradiobutton(hs.rhd_or_rhs_group,...
    'Text', '.rhs',...
    'Position', [10, 5, 100, 22],...
    'Value', 0);
hs.read_info_button = uibutton(hs.main_ui,...
    'Text', 'Read info file',...
    'Position', [100, 270, 100, 20]);
hs.filenames_label = uilabel(hs.main_ui,...
    'Text', 'Filenames to read data from (semicolon-separated):',...
    'Position', [10, 230, 400, 20]);
hs.filenames_edit = uieditfield(hs.main_ui,...
    'Position', [10, 210, 400, 20],...
    'Value', 'amp-A-000.dat;amp-A-001.dat;amp-A-002.dat;amp-A-003.dat;amp-A-004.dat;amp-A-005.dat;amp-A-006.dat;amp-A-007.dat;amp-A-008.dat;amp-A-009.dat;amp-A-010.dat;amp-A-011.dat;amp-A-012.dat;amp-A-013.dat;amp-A-014.dat;amp-A-015.dat');
hs.button_group = uibuttongroup(hs.main_ui,...
    'Position', [10, 123, 120, 82]);
hs.start_button = uitogglebutton(hs.button_group,...
    'Text', 'Start',...
    'Position', [10, 50, 100, 22],...
    'Value', 0,...
    'Enable', 0);
hs.stop_button = uitogglebutton(hs.button_group,...
    'Text', 'Stop',...
    'Position', [10, 10, 100, 22],...
    'Value', 1,...
    'Enable', 0);
hs.spacing_label = uilabel(hs.main_ui,...
    'Text', 'Spacing offset between waveforms (uV)',...
    'Position', [10, 90, 220, 20]);
hs.spacing_spinner = uispinner(hs.main_ui,...
    'Limits', [10, 9999],...
    'Value', 1000,...
    'Step', 100,...
    'Position', [230, 90, 60, 20]);
hs.samples_per_plot_label = uilabel(hs.main_ui,...
    'Text', 'Samples per plot',...
    'Position', [10, 65, 100, 20]);
hs.samples_per_plot_spinner = uispinner(hs.main_ui,...
    'Limits', [10, 99999],...
    'Value', 30000,...
    'Step', 1000,...
    'ValueDisplayFormat', '%u',...
    'RoundFractionalValues', 'on',...
    'Position', [110, 65, 70, 20]);
hs.status_text = uilabel(hs.main_ui,...
    'Text', 'Read info file before reading can begin.',...
    'Position', [10, 5, 450, 30]);
set(hs.read_info_button, 'ButtonPushedFcn', @read_info_clicked);
set(hs.button_group, 'SelectionChangedFcn', @button_changed);
end

% Get color for the UI status text depending on amount of backed-up data
function color = get_suitable_color(accumulated_samples, N_samples_per_plot)
if accumulated_samples < N_samples_per_plot % black for no data back-up
    color = 'black';
elseif accumulated_samples > N_samples_per_plot * 10 % red for serious data back-up
    color = 'red';
else
    color = '#EDB120'; % orange for slight data back-up
end
end

% Read and scale timestamps from the timestamp file
function t = read_timestamp()
global hs
t = fread(hs.t_fid, hs.samples_per_plot_spinner.Value, 'int32') / hs.sample_rate;
end

% Read and scale (assuming amplifier scaling) data from the data file
function d = read_data()
global hs

% For each data file, read that file and put it in its own row of d

% Note: Use of 'arrayfun' improves performance, but is less readable.
% The following commented-out code is a more readable version that
% accomplishes the same goal, but slightly less efficiently.
%for i = 1:length(hs.d_filenames)
    %d(i,:) = fread(hs.d_fid(i), hs.samples_per_plot_spinner.Value, 'int16');
%end
%d = d * 0.195;

d = cell2mat(arrayfun(@(x) fread(x, hs.samples_per_plot_spinner.Value, 'int16'), hs.d_fid, 'UniformOutput', false))' * 0.195;
end

% Plot all channels 
function plot_channels(num_channels, t, d)
global hs
% Create an array the same size as 'd' containing offsets to add to each
% sample so that plotted waveforms have a uniform spacing between them.
offset_vector = (0:hs.spacing_spinner.Value:(num_channels-1)*hs.spacing_spinner.Value);
offset_array = repmat(offset_vector', 1, hs.samples_per_plot_spinner.Value);

% Apply the offset array to data
d = offset_array + d;

% Plot each channel's data, only clearing the plot for the first channel,
% allowing for overlaying multiple channels on the same plot
for i = 1:num_channels
    if i > 1, hold on; end
    plot(t, d(i,:));
end
hold off

% Explicitly constrain the x-axes to the domain of the t-vector to
% eliminate auto-scaling
B = axis;
axis([min(t) max(t) B(3) B(4)]);

% Write a tick on the y-axis for each filename
set(gca, 'YTick', offset_vector, 'YTickLabel', cellstr(hs.d_filenames));
end