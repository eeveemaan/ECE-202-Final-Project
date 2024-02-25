% This script reads 'time.dat' and 'spikes.dat' in the current directory,
% plotting all spike rasters. Also, if spike snapshots were saved, the
% channel with the name specified in the UI will have its snapshots
% plotted.

% This script works with both previously saved data and data that's being
% acquired in real-time. By default, Intan RHX software creates a new directory
% at the time of recording for each session, but this can be disabled in
% the 'File Format' dialog of the RHX, by deselecting 'Create new save
% directory with timestamp for each recording'. Note that disabling this
% allows for previously acquired data to be overwritten when a new
% recording session begins, so use this option with care.

% Note that this script reads both 'time.dat' and 'spikes.dat', because
% 'time.dat' is a consistent timestamps file that is used for reading all
% signal types from all channels, and synchronizing 'time.dat' with
% 'spikes.dat' is important for applications that read waveforms and spikes
% simultaneously. Because 'time.dat' and 'spikes.dat' are
% written simultaneously but aren't necessarily synchronized, this script
% has to synchronize reading 'time.dat' and 'spikes.dat'. For user
% applications that don't have any use for 'time.dat', a simpler approach
% would be to only read 'spikes.dat'. Each spike in 'spikes.dat' contains
% its own timestamp

% Set up main UI
create_main_ui();

% When 'start' is clicked - begin realtime reading and plotting
function start(button_group)

% Global handles object used to share variables among functions
global hs

% Open timestamp and spike files
[success, hs.t_fid] = open_file('time.dat');
if ~success, return; end
[success, hs.spike_fid] = open_file('spike.dat');
if ~success, return; end

% Read and discard unused fields in spike file
fread(hs.spike_fid, 1, 'uint32'); % magic number
fread(hs.spike_fid, 1, 'uint16'); % version number
readNullTerminatedString(hs.spike_fid); % base filename

% Read all amp native names as comma-separated list (null-terminated)
raw_native_list = readNullTerminatedString(hs.spike_fid);
% Store amp native names in native_list
hs.native_list = split(raw_native_list, ',');
% Determine number of channels in this spike file
hs.num_channels = length(hs.native_list);

% Read all amp custom names as comma-separated list (null-terminated)
raw_custom_list = readNullTerminatedString(hs.spike_fid);
% Store amp custom names in custom_list
custom_list = split(raw_custom_list, ',');

% Read sample rate
hs.sample_rate = fread(hs.spike_fid, 1, 'single');

% Read information related to spike snapshots
% # samples saved before detection
hs.samples_pre_detect = fread(hs.spike_fid, 1, 'uint32');
% # samples saved after detection
hs.samples_post_detect = fread(hs.spike_fid, 1, 'uint32');

% Calculate total # of samples in each snapshot
hs.samples_per_snapshot = hs.samples_pre_detect + hs.samples_post_detect;

% Create array to contain snapshots
hs.snapshots = zeros(hs.num_channels, hs.samples_per_snapshot);

% Initialize default snapshot display
hs.snapshot_name = 'A-000';
hs.snapshot_idx = 1;

% Create snapshot_t vector with values in seconds of each timestamp
% with reference to the spike event at t = 0
snapshot_step_ms = (1 / hs.sample_rate) * 1000;
snapshot_start_ms = snapshot_step_ms * hs.samples_pre_detect * -1;
snapshot_end_ms = snapshot_step_ms * (hs.samples_post_detect - 1);
hs.snapshot_t = snapshot_start_ms : snapshot_step_ms : snapshot_end_ms;

% Array indicating if each channel recently had a snapshot added
hs.snapshot_added = zeros(1, hs.num_channels);

% History of recent snapshots from the currently displayed channel
hs.snapshot_history = [];

% Set up raster plotting window (maximize so the many channels are large
% enough to see)
hs.raster_figure = figure('Name', 'Spike Rasters for All Channels',...
    'NumberTitle', 'off');
set(hs.raster_figure, 'WindowState', 'maximized');

% If snapshots are saved, set up snapshot plotting window
if hs.samples_per_snapshot > 0
    hs.snapshot_figure = figure('NumberTitle', 'off');
end

% Track the first iteration of the coming while loop
hs.first_time = true;

% Track when on-deck timestamps should be moved to current timestamps
advance_t_range = true;

% Track when next timestamps should be read
read_next_timestamps = true;

% Track file position of last read timestamp
last_read_timestamp_pos = 0;

% Track last timestamp of current range
last_current_timestamp = 0;

% Track last timestamp of on-deck range
last_on_deck_timestamp = 0;

% Track when timestamps are ready to plot
timestamps_ready_to_plot = false;

% Track when spikes are ready to plot
spikes_ready_to_plot = true;

% Track when the last timestamp read occurred
last_timestamp_read_time = tic;

% Track when the last spike read occurred
last_spike_read_time = tic;

% Track when while loop should break after the last plot of remaining data
% is displayed
break_after_plot = false;

% Track how many samples should be displayed in each plot, updated from UI
samples_per_plot = hs.samples_per_plot_spinner.Value;

% Initialize spike events in the current timestamp range to be zeros
current_spikes = zeros(hs.num_channels, hs.samples_per_plot_spinner.Value);

% While 'start' remains selected ('stop' not selected),
while get(button_group.Children(2), 'Value')
    
    % For the first read, load first chunk of timestamp data into on-deck
    if hs.first_time
        
        % Wait for the timestamp file to have enough data before reading
        while dir('time.dat').bytes/4 < samples_per_plot
            pause(0.01);
        end
        
        % Read timestamp data into on_deck_t
        on_deck_t = fread(hs.t_fid, samples_per_plot, 'int32');
        last_on_deck_timestamp = on_deck_t(end);
    end
    
    % If advance_t_range, move on-deck timestamps to current timestamps,
    % toggle on read_next_timestamps, and toggle off advance_t_range
    if advance_t_range
        current_t = on_deck_t;
        last_current_timestamp = last_on_deck_timestamp;
        read_next_timestamps = true;
        advance_t_range = false;
    end
    
    % Determine if enough timestamp data is present to read for next plot
    timestamp_data_available = dir('time.dat').bytes >= last_read_timestamp_pos + 4 * samples_per_plot;
    
    % If read_next_timestamps and timestamp_data_available, read next
    % chunk of timestamp data directly into on-deck, and toggle off
    % read_next_timestamps
    if read_next_timestamps && timestamp_data_available
        on_deck_t = fread(hs.t_fid, samples_per_plot, 'int32');
        last_timestamp_read_time = tic;
        last_on_deck_timestamp = on_deck_t(end);
        last_read_timestamp_pos = ftell(hs.t_fid);
        read_next_timestamps = false;
        timestamps_ready_to_plot = true;
        
        
    % If read_next_timestamps and more than 3 plotting periods of time have
    % passed, assume that no more data is being written so read the
    % remaining data and report that the end has been reached
    timestamp_delay_time = 3 * samples_per_plot / hs.sample_rate;
    elseif read_next_timestamps && (toc(last_timestamp_read_time) > timestamp_delay_time)
        remaining_timestamps = (dir('time.dat').bytes - last_read_timestamp_pos) / 4;
        if remaining_timestamps > 0
            
            % Read all remaining timestamps into current_t
            current_t = fread(hs.t_fid, remaining_timestamps, 'int32');
            
            % Read all remaining (on-deck and current) spikes into
            % current_spikes
            current_spikes = read_remaining_spikes(current_t);
            timestamps_ready_to_plot = true;
            spikes_ready_to_plot = true;
            break_after_plot = true;
        end
    end
    
    % Determine if any new spike data is available
    spike_data_available = dir('spike.dat').bytes > ftell(hs.spike_fid);
    
    % If break_after_plot hasn't been flagged (signaling the coming end of
    % the while loop), continue reading spike data
    if ~break_after_plot
        
        % If new spike data is available, read it into current_spikes
        if spike_data_available
            [current_spikes, filled_up_current] = read_spikes(current_spikes, last_current_timestamp, size(current_t, 1));
            
            % If the end of the current_spikes timestamp range has been
            % reached, signal that this range is read to plot
            if filled_up_current
                spikes_ready_to_plot = true;
            end
            last_spike_read_time = tic;

        % If spike activity stops (no new spike.dat data has been written) for
        % more than the time of 1 full plot, assuming spiking activity has
        % stopped, so just treat as if a read has happened but keeping spikes
        % array full of zeros
        elseif toc(last_spike_read_time) > (1 / hs.sample_rate)
            spikes_ready_to_plot = true;
            last_spike_read_time = tic;
        end
    end
    
    % Plot current_spikes vs current_timestamps, toggle on advance_t_range
    if timestamps_ready_to_plot && spikes_ready_to_plot
        
        % Scale timestamps to seconds
        scaled_t = current_t ./ hs.sample_rate;
        
        % Plot spike data vs. timestamp data
        plot_channels(scaled_t, current_spikes);
        
        % Reset state-tracking variables
        timestamps_ready_to_plot = false;
        spikes_ready_to_plot = false;
        advance_t_range = true;
        current_spikes = zeros(hs.num_channels, samples_per_plot);
        samples_per_plot = hs.samples_per_plot_spinner.Value;
        
        % Deliver status update to UI
        unplotted_timestamps = (dir('time.dat').bytes - ftell(hs.t_fid)) / 4;
        status_str = ['Accumulated unplotted timestamps: ' int2str(unplotted_timestamps)];
        status_color = get_suitable_color(unplotted_timestamps, samples_per_plot);
        if get(button_group.Children(2), 'Value')
            update_ui_status(status_str, status_color);
        end

        % For the first plot, if snapshots are included, set snapshots as
        % current figure
        if hs.first_time
            if hs.samples_per_snapshot > 0
                set(0, 'CurrentFigure', hs.snapshot_figure);
            end
            hs.first_time = false;
        end
        
        % If the while loop is about to be broken, update UI status
        if break_after_plot
            status_str = sprintf('No new data detected for %.2f seconds, implying the end of the session.', timestamp_delay_time);
            update_ui_status(status_str, 'black');
            break;
        end
        
    else
        pause(0.01);
    end
    
end

% Bring UI to its 'finished' state
hs.start_button.Enable = 'off';
hs.stop_button.Enable = 'off';

end

% Read all remaining spikes in the timestamp range of t
function remaining_spikes = read_remaining_spikes(t)
global hs
total_spike_bytes = dir('spike.dat').bytes;

% While spike data remains, read them
remaining_spikes = zeros(hs.num_channels, size(t, 1));
while ftell(hs.spike_fid) < total_spike_bytes
    
    % Read this spike
    channel_name = readChars(hs.spike_fid, 5);
    timestamp = fread(hs.spike_fid, 1, 'int32');
    spike_id = fread(hs.spike_fid, 1, 'uint8'); % Currently unused
    channel_idx = find(contains(hs.native_list, channel_name));
    if timestamp >= min(t) && timestamp <= max(t)
        remaining_spikes(channel_idx, timestamp - min(t)) = 1;
    else
        fprintf(1, 'Somehow, reading remaining spikes got a spike outside the remaining time range.\n');
    end
    
    % Read snapshot data into hs.snapshots
    if hs.samples_pre_detect > 0
        hs.snapshots(channel_idx, 1:hs.samples_pre_detect) = fread(hs.spike_fid, hs.samples_pre_detect, 'uint16');
    end
    if hs.samples_post_detect > 0
        hs.snapshots(channel_idx, hs.samples_pre_detect + 1:end) = fread(hs.spike_fid, hs.samples_post_detect, 'uint16');
    end
    
    % Flag that snapshots have been populated, and scale them to microvolts
    if hs.samples_per_snapshot > 0
        hs.snapshot_added(channel_idx) = 1;
        hs.snapshots(channel_idx,:) = 0.195 * (hs.snapshots(channel_idx,:) - 32768);
    end
end

end


% Read spikes with a max timestamp of last_current_timestamp into
% current_spikes. Note this function assumes spike data is available
function [current_spikes, filled_up_current] = read_spikes(current_spikes, last_current_timestamp, samples_per_plot)
global hs
total_spike_bytes = dir('spike.dat').bytes;
filled_up_current = false;

% While spike data remains, read it
while ftell(hs.spike_fid) < total_spike_bytes
    
    % Read this spike
    channel_name = readChars(hs.spike_fid, 5);
    timestamp = fread(hs.spike_fid, 1, 'int32');
    spike_id = fread(hs.spike_fid, 1, 'uint8'); % Currently unused
    channel_idx = find(contains(hs.native_list, channel_name));
    
    % If this timestamp precedes the current t_range, report that it's
    % too slow
    if timestamp < last_current_timestamp - samples_per_plot
        fprintf(1, 'Spikes being read too slow...\n');
        
    % If this spike belongs in the current t_range (maximum timestamp of
    % last current timestamp), add it to current_spikes
    elseif timestamp <= last_current_timestamp
        current_spikes(channel_idx, timestamp - (last_current_timestamp - samples_per_plot)) = 1;
        
    % If this timestamp surpasses the current t_range, revert to before
    % this spike was read and break the loop, allowing timestamps to catch
    % up
    else
        fseek(hs.spike_fid, -10, 'cof');
        filled_up_current = true;
        break;
    end
    
    % Read snapshot data into hs.snapshots
    if hs.samples_pre_detect > 0
        hs.snapshots(channel_idx, 1:hs.samples_pre_detect) = fread(hs.spike_fid, hs.samples_pre_detect, 'uint16');
    end
    if hs.samples_post_detect > 0
        hs.snapshots(channel_idx, hs.samples_pre_detect + 1:end) = fread(hs.spike_fid, hs.samples_post_detect, 'uint16');
    end
    
    % Flag that snapshots have been populated, and scale them to microvolts
    if hs.samples_per_snapshot > 0
        hs.snapshot_added(channel_idx) = 1;
        hs.snapshots(channel_idx,:) = 0.195 * (hs.snapshots(channel_idx,:) - 32768);
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

% Read an unknown-length string that ends with 0
function this_str = readNullTerminatedString(fid)
last_read_byte = 1;
read_bytes = [];
while last_read_byte ~= 0
    last_read_byte = fread(fid, 1, 'uint8');
    read_bytes = [read_bytes last_read_byte];
end
this_str = char(read_bytes(1:end-1));
end

% Read the next num_chars bytes as chars in a string
function this_str = readChars(fid, num_chars)
read_bytes = zeros(1, num_chars);
for this_char = 1:num_chars
    read_bytes(this_char) = fread(fid, 1, 'uint8');
end

this_str = char(read_bytes);
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
hs.main_ui = uifigure('Name', 'RHX Realtime Read GUI, for Spikes in One File Per Signal Type',...
    'Position', [10, 100, 500, 240]);
hs.button_group = uibuttongroup(hs.main_ui,...
    'Position', [10, 153, 120, 82]);
hs.start_button = uitogglebutton(hs.button_group,...
    'Text', 'Start',...
    'Position', [10, 50, 100, 22],...
    'Value', 0);
hs.stop_button = uitogglebutton(hs.button_group,...
    'Text', 'Stop',...
    'Position', [10, 10, 100, 22],...
    'Value', 1);
hs.samples_per_plot_label = uilabel(hs.main_ui,...
    'Text', 'Samples per plot',...
    'Position', [10, 125, 100, 20]);
hs.samples_per_plot_spinner = uispinner(hs.main_ui,...
    'Limits', [10, 99999],...
    'Value', 30000,...
    'Step', 1000,...
    'ValueDisplayFormat', '%u',...
    'RoundFractionalValues', 'on',...
    'Position', [110, 125, 70, 20]);
hs.snapshot_group = uibuttongroup(hs.main_ui,...
    'Position', [10, 35, 300, 82]);
hs.snapshot_setting_label = uilabel(hs.snapshot_group,...
    'Text', 'Snapshot settings',...
    'Position', [100, 60, 100, 20]);
hs.max_snapshots_label = uilabel(hs.snapshot_group,...
    'Text', 'Max # snapshots',...
    'Position', [10, 35, 100, 20]);
hs.max_snapshots_spinner = uispinner(hs.snapshot_group,...
    'Limits', [1, 49],...
    'Value', 10,...
    'Position', [110, 35, 70, 20]);
hs.snapshot_channel_label = uilabel(hs.snapshot_group,...
    'Text', 'Channel name',...
    'Position', [10, 10, 100, 20]);
hs.snapshot_channel_edit = uieditfield(hs.snapshot_group,...
    'Position', [110, 10, 70, 20],...
    'Value', 'A-000');
hs.status_text = uilabel(hs.main_ui,...
    'Text', 'Read info file before reading can begin.',...
    'Position', [10, 5, 450, 30]);
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

% Plot all channels
function plot_channels(t, d_to_plot)
global hs

% Create an array the same size as 'd' containing offsets to add to each
% sample so that plotted waveforms have a uniform spacing between them.
raster_size = 0.5;
offset_step = 1 / raster_size;

offset_vector = 0:offset_step:(hs.num_channels - 1)*offset_step;
offset_array = repmat(offset_vector', 1, size(d_to_plot, 2));

% Apply the offset array to data
d_to_plot = offset_array + d_to_plot;

% Plot each channel's data, only clearing the plot for the first channel,
% allowing for overlaying multiple channels on the same plot
set(0, 'CurrentFigure', hs.raster_figure);
for i = 1:hs.num_channels
    if i > 1, hold on; end
    plot(t(1:size(d_to_plot, 2)), d_to_plot(i,:));
    if i == 1
        xlabel('Time (s)');
        ylabel('Spike Rasters of All Channels');
    end
end
hold off

% Constrain the x-axis to the domain of the t-vector
min_x = min(t);
max_x = max(t);

% Constrain the y-axis to a little larger than the range of the channels
min_y = -2 * offset_step;
max_y = (hs.num_channels + 1) * offset_step;

% Set the axis to these constraints
axis([min_x max_x min_y max_y]);

% Write a tick on the y-axis for each filename
set(gca, 'YTick', offset_vector, 'YTickLabel', cellstr(hs.native_list));

max_snapshots = hs.max_snapshots_spinner.Value;

% Look for channel name in native_list. If it's there, update
% currently_plotted_snapshot_idx
search_for_index = find(strcmp(hs.native_list, hs.snapshot_channel_edit.Value));
if ~isempty(search_for_index)
    hs.snapshot_idx = search_for_index;
    hs.snapshot_name = hs.snapshot_channel_edit.Value;
    hs.snapshot_figure.Name = ['Snapshots - ', hs.snapshot_name];
end

% If this channel has a snapshot added, plot the snapshot
if hs.snapshot_added(hs.snapshot_idx) ~= 0
    
    this_snapshot = hs.snapshots(hs.snapshot_idx,:);
    
    % Prepend this snapshot to current vector
    hs.snapshot_history = [this_snapshot; hs.snapshot_history];
    hs.snapshot_added(hs.snapshot_idx) = 0;
    
    % If snapshot_history is now too large, remove the last (oldest)
    % snapshot
    if size(hs.snapshot_history,1) > max_snapshots
        hs.snapshot_history = hs.snapshot_history(1:max_snapshots, :);
    end
    
    set(0, 'CurrentFigure', hs.snapshot_figure);
    % Iterate through snapshot_history, plotting each snapshot
    for history_iterator = 1:size(hs.snapshot_history,1)
        if history_iterator == 1, hold off;
        else, hold on; end
        plot(hs.snapshot_t, hs.snapshot_history(history_iterator,:));
        if history_iterator == 1
            xlabel('Time (ms)');
            ylabel('Electrode Voltage (\muV)');
        end
    end
    hold off;
end
drawnow;

end