% This script reads 'time.dat' and 'amplifier.dat', plotting the channels
% named in the UI.

% This script works with both previously saved data and data that's being
% acquired in real-time. By default, Intan RHX software creates a new directory
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

% Set up plotting window (maximize so the multiple waveforms are large
% enough to see)
f = figure;
set(f, 'WindowState', 'maximized');

% While 'start' remains selected ('stop' not selected),
while get(button_group.Children(2), 'Value')
    
    % Determine how many samples should be plotted based on UI state
    N_samples_per_plot = hs.samples_per_plot_spinner.Value;
    
    % Total # of samples available in these files (use the minimum of both
    % t and data in case they're not written at exactly the same time).
    
    % Note that this calculation assumes 'amplifier.dat' only contains
    % wideband amplifier samples and should be more sophisticated if other
    % filter bands or non-amplifier channels are to be considered.
    
    % 4 bytes per timestamp, 2 bytes per amplifier sample.
    available_samples = min(dir(hs.t_filename).bytes/4, dir(hs.d_filename).bytes/(hs.num_amp_channels * 2));
    
    % If enough samples are available, continue with plotting
    if available_samples - hs.plotted_samples >= N_samples_per_plot
        
        % read timestamp and data from files
        t = read_timestamp;
        d = read_data;
        
        % plot channels
        plot_channels(t, d);
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

% Initialize timestamp and data file IDs
hs.t_filename = 'time.dat';
hs.d_filename = 'amplifier.dat';
hs.channel_names = string(strsplit(hs.channels_edit.Value, ';'));

% Peek into info file for sample rate
[success, info_fid] = open_file(['info' hs.rhd_or_rhs_group.SelectedObject.Text]);
if ~success, return; end
fread(info_fid, 4, 'int8'); % Skip first 4 bytes

% Read RHD info file
if strcmp(hs.rhd_or_rhs_group.SelectedObject.Text, '.rhd')
    % Read version number.
    data_file_main_version_number = fread(info_fid, 1, 'int16');
    data_file_secondary_version_number = fread(info_fid, 1, 'int16');

    hs.sample_rate = fread(info_fid, 1, 'single'); % Get sample rate

    % Keep look further to get # of amplifier channels (assuming only wideband)
    fread(info_fid, 36, 'int8'); % Skip next 36 bytes

    fread_QString(info_fid); % Skip next 3 QStrings
    fread_QString(info_fid);
    fread_QString(info_fid);

    % If data file is from GUI v1.1 or later, skip temperature sensor saved
    % flag (2 bytes)
    if ((data_file_main_version_number == 1 && data_file_secondary_version_number >= 1) ...
            || (data_file_main_version_number > 1))
        fread(info_fid, 2, 'int8');
    end

    % If data file is from GUI v1.3 or later, skip eval board mode (2 bytes)
    if ((data_file_main_version_number == 1 && data_file_secondary_version_number >= 3) ...
            || (data_file_main_version_number > 1))
        fread(info_fid, 2, 'int8');
    end

    % If data file is from v2.0 or later (Intan Recording Controller), skip
    % name of digital reference channel.
    if data_file_main_version_number > 1
        fread_QString(info_fid);
    end

    number_of_signal_groups = fread(info_fid, 1, 'int16');
    amp_channel_idx = 0;
    channels_to_plot = zeros(length(hs.channel_names), 1);

    % Determine which channels should be plotted
    for signal_group = 1:number_of_signal_groups
        signal_group_name = fread_QString(info_fid);
        signal_group_prefix = fread_QString(info_fid);
        signal_group_enabled = fread(info_fid, 1, 'int16');
        signal_group_num_channels = fread(info_fid, 1, 'int16');
        signal_group_num_amp_channels = fread(info_fid, 1, 'int16');

        if (signal_group_num_channels > 0 && signal_group_enabled > 0)
            for signal_channel = 1:signal_group_num_channels
                native_channel_name = fread_QString(info_fid);
                fread_QString(info_fid); % Skip custom channel name
                fread(info_fid, 4, 'int8'); % Skip next 4 bytes
                signal_type = fread(info_fid, 1, 'int16');
                channel_enabled = fread(info_fid, 1, 'int16');

                % If this is an enabled amp channel, add its index to
                % channels_to_plot
                if signal_type == 0 && channel_enabled == 1
                    amp_channel_idx = amp_channel_idx + 1;
                    for i = 1:length(hs.channel_names)
                        if strcmp(native_channel_name, hs.channel_names(i))
                            channels_to_plot(i) = amp_channel_idx;
                        end
                    end
                end

                fread(info_fid, 20, 'int8'); % Skip next 20 bytes
            end
        end
    end
    
% Read RHS info file
else
    % Read version number.
    data_file_main_version_number = fread(info_fid, 1, 'int16');
    data_file_secondary_version_number = fread(info_fid, 1, 'int16');

    hs.sample_rate = fread(info_fid, 1, 'single'); % Get sample rate
    fprintf(1, 'Here... sample rate: %f\n', hs.sample_rate);

    % Keep look further to get # of amplifier channels (assuming only wideband)
    fread(info_fid, 64, 'int8'); % Skip next 64 bytes

    fread_QString(info_fid); % Skip next 3 QStrings
    fread_QString(info_fid);
    fread_QString(info_fid);
    
    fread(info_fid, 4, 'int8'); % Skip next 4 bytes
    
    fread_QString(info_fid); % Skip next QString

    number_of_signal_groups = fread(info_fid, 1, 'int16');
    fprintf(1, 'Here... number of signal groups: %d\n', number_of_signal_groups);
    amp_channel_idx = 0;
    channels_to_plot = zeros(length(hs.channel_names), 1);

    % Determine which channels should be plotted
    for signal_group = 1:number_of_signal_groups
        signal_group_name = fread_QString(info_fid);
        signal_group_prefix = fread_QString(info_fid);
        signal_group_enabled = fread(info_fid, 1, 'int16');
        signal_group_num_channels = fread(info_fid, 1, 'int16');
        signal_group_num_amp_channels = fread(info_fid, 1, 'int16');

        if (signal_group_num_channels > 0 && signal_group_enabled > 0)
            for signal_channel = 1:signal_group_num_channels
                native_channel_name = fread_QString(info_fid);
                fread_QString(info_fid); % Skip custom channel name
                fread(info_fid, 4, 'int8'); % Skip next 4 bytes
                signal_type = fread(info_fid, 1, 'int16');
                channel_enabled = fread(info_fid, 1, 'int16');

                % If this is an enabled amp channel, add its index to
                % channels_to_plot
                if signal_type == 0 && channel_enabled == 1
                    amp_channel_idx = amp_channel_idx + 1;
                    for i = 1:length(hs.channel_names)
                        if strcmp(native_channel_name, hs.channel_names(i))
                            channels_to_plot(i) = amp_channel_idx;
                        end
                    end
                end

                fread(info_fid, 20, 'int8'); % Skip next 20 bytes
            end
        end
    end
    
end

hs.num_amp_channels = amp_channel_idx;
hs.channels_to_plot = channels_to_plot;

fclose(info_fid);

% Update UI to indicate that info file has been read
set(hs.start_button, 'Enable', 1);
set(hs.stop_button, 'Enable', 1);
update_ui_status('Click start to begin looking for data to read.', 'black');

% Open timestamp and data files to read later
[success, hs.t_fid] = open_file(hs.t_filename);
if ~success, return; end
[success, hs.d_fid] = open_file(hs.d_filename);
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
hs.main_ui = uifigure('Name', 'RHX Realtime Read GUI, for One File Per Signal Type',...
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
hs.channels_label = uilabel(hs.main_ui,...
    'Text', 'Channels to read data from (semicolon-separated):',...
    'Position', [10, 230, 400, 20]);
hs.channels_edit = uieditfield(hs.main_ui,...
    'Position', [10, 210, 400, 20],...
    'Value', 'A-000;A-001;A-002;A-003');
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

% Read MxN samples from 'amplifier.dat', where M is number of saved amp
% channels and N is number of samples per plotting period (controlled by
% editable numeric field in UI). Because there may be present channels in
% the .dat file that aren't plotted, it's likely that much of this data won't
% be plotted
d = fread(hs.d_fid, [hs.num_amp_channels, hs.samples_per_plot_spinner.Value], 'int16') * 0.195;

end

% Plot all channels
function plot_channels(t, d)
global hs

d_to_plot = d(hs.channels_to_plot,:);

% Create an array the same size as 'd' containing offsets to add to each
% sample so that plotted waveforms have a uniform spacing between them.
offset_vector = 0:hs.spacing_spinner.Value:(length(hs.channel_names)-1)*hs.spacing_spinner.Value;
offset_array = repmat(offset_vector', 1, hs.samples_per_plot_spinner.Value);

% Apply the offset array to data
d_to_plot = offset_array + d_to_plot;

% Plot each channel's data, only clearing the plot for the first channel,
% allowing for overlaying multiple channels on the same plot
for i = 1:length(hs.channel_names)
    if i > 1, hold on; end
    plot(t, d_to_plot(i,:));
end
hold off

% Explicitly constrain the x-axes to the domain of the t-vector to
% eliminate auto-scaling
B = axis;
axis([min(t) max(t) B(3) B(4)]);

% Write a tick on the y-axis for each filename
set(gca, 'YTick', offset_vector, 'YTickLabel', cellstr(hs.channel_names));
end

function a = fread_QString(fid)

% a = read_QString(fid)
%
% Read Qt style QString.  The first 32-bit unsigned number indicates
% the length of the string (in bytes).  If this number equals 0xFFFFFFFF,
% the string is null.

a = '';
length = fread(fid, 1, 'uint32');
if length == hex2num('ffffffff')
    return;
end
% convert length from bytes to 16-bit Unicode words
length = length / 2;

for i=1:length
    a(i) = fread(fid, 1, 'uint16');
end

return
end