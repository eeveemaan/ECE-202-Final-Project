% In order to run this example script successfully, the IntanRHX software
% should be started with a Stimulation/Recording Controller (or a synthetic
% Stimulation/Recording Controller); other controller types will not work
% with this script

% Through Network -> Remote TCP Control:

% Command Output should open a connection at 127.0.0.1, Port 5000.
% Status should read "Pending" for the Command Port

% Waveform Output (in the Data Output tab) should open a connection at
% 127.0.0.1, Port 5001.
% Status should read "Pending" for the Waveform Port

% Spike Output (in the Data Output tab) should open a connection at
% 127.0.0.1, Port 5002.
% Status should read "Pending" for the Spike Port

% Sets up stimulation on A-000, runs the controller and stimulates, records
% the highpass and spike data, and plots. Repeats this 3 times with
% increasing amplitudes - stimulation parameters can be changed for each
% iteration. Also moves recorded highpass, stim, spike, and timestamp data
% to the workspace.

% Set up main UI
createMainUI();

% When 'execute' is clicked - begin stim/record routine
function execute()

% Global variables accessed in other functions
global initialized
global tcommand
global ampDataFigure1
global ampDataFigure2
global ampDataFigure3
global hs
global stopped

% Global variables that should be retained when this function is called
% multiple times
global twaveformdata
global tspikedata
global timestep
global stimStepSizeuA

% If this is the first time 'run' has been clicked, first initialize TCP
% communication, send commands to initialize RHX software's settings, and
% create plotting figure
if initialized == 0
    
    % Connect to TCP servers
    updateUIStatus('Connecting to TCP command server...');
    tcommand = tcpclient('localhost', 5000);
    updateUIStatus('Connecting to TCP waveform server...');
    twaveformdata = tcpclient('localhost', 5001);
    updateUIStatus('Connecting to TCP spike server...');
    tspikedata = tcpclient('localhost', 5002);
    
    % Clear TCP data output to ensure no TCP channels are enabled at the
    % beginning of this script
    updateUIStatus('Clearing current TCP outputs...');
    sendCommand('execute clearalldataoutputs');
    
    % Query controller type
    updateUIStatus('Enabling channels...');
    sendCommand('get type');
    commandReturn = readCommand();
    if ~strcmp(commandReturn, 'Return: Type ControllerStimRecord')
        error('This script is intended for Intan Stim/Record Controller only');
    end
    
    % Calculate timestep based on sample rate
    sampleRate = getSampleRate();
    timestep = 1 / sampleRate;
    
    % Get Stim Step size
    stimStepSizeuA = getStimStepSize();
    
    % Set up stim parameters that WON'T change for each cycle iterations
    sendCommand('set a-000.stimenabled true');
    sendCommand('set a-000.source keypressf1');
    
    % Set up TCP Data Output Enabled for high and spike bands of A-000
    sendCommand('set a-000.tcpdataoutputenabledhigh true');
    sendCommand('set a-000.tcpdataoutputenabledspike true');
    sendCommand('set a-000.tcpdataoutputenabledstim true');
    
    % Wait 1 second to make sure data sockets are ready to begin
    updateUIStatus('Preparing MATLAB to start streaming...');
    pause(1);
    
    ampDataFigure1 = figure(1);
    ampDataFigure1.Name = 'Amplifier Data - HIGH';
    
    ampDataFigure2 = figure(2);
    ampDataFigure2.Name = 'Amplifier Data - HIGH';
    
    ampDataFigure3 = figure(3);
    ampDataFigure3.Name = 'Amplifier Data - HIGH';
    
    % Position figures
    set(0, 'units', 'pixels');
    pixelSize = get(0, 'screensize');
    screenWidth = pixelSize(3);
    screenHeight = pixelSize(4);
    
    % If each plot will have a width of 400 and height of 300, determine
    % the position of the 3 plots, starting from top-left
    numPlots = 3;
    plotWidth = 400;
    plotHeight = 300;
    
    currentX = 20;
    currentY = screenHeight - (plotHeight + 100);
    
    for thisPlot = 1:numPlots
        if thisPlot == 1
            plotPositions = [currentX, currentY, plotWidth, plotHeight];
        else
            plotPositions = [plotPositions; [currentX, currentY, plotWidth, plotHeight]];
        end
        currentX = currentX + plotWidth + 20;
        if currentX + plotWidth > screenWidth
            currentX = 20;
            currentY = currentY - (plotHeight + 100);
        end
    end
    
    ampDataFigure1.Position = plotPositions(1,:);
    ampDataFigure2.Position = plotPositions(2,:);
    ampDataFigure3.Position = plotPositions(3,:);
    
    
    % Mark initialization as complete
    initialized = 1;
end

% Mark system as running
stopped = 0;

% Calculations for accurate parsing
framesPerBlock = 128;
waveformBytesPerFrame = 4 + (2 + 2);
waveformBytesPerBlock = framesPerBlock * waveformBytesPerFrame + 4;
blocksPerRead = 100;
waveformBytes100Blocks = blocksPerRead * waveformBytesPerBlock;

% Pre-allocate memory for blocksPerRead blocks of waveform data (the amount
% that's plotted at once)
amplifierData1 = zeros(1, framesPerBlock * blocksPerRead);
stimData1 = zeros(1, framesPerBlock * blocksPerRead);
amplifierTimestamps1 = zeros(1, framesPerBlock * blocksPerRead);

amplifierData2 = zeros(1, framesPerBlock * blocksPerRead);
stimData2 = zeros(1, framesPerBlock * blocksPerRead);
amplifierTimestamps2 = zeros(1, framesPerBlock * blocksPerRead);

amplifierData3 = zeros(1, framesPerBlock * blocksPerRead);
stimData3 = zeros(1, framesPerBlock * blocksPerRead);
amplifierTimestamps3 = zeros(1, framesPerBlock * blocksPerRead);

% Initialize amplifier timestamps index
amplifierTimestampsIndex = 1;

% Each spike chunk contains 4 bytes for magic number, 5 bytes for native
% channel name, 4 bytes for timestamp, and 1 byte for id. Total: 14 bytes
bytesPerSpikeChunk = 14;

% Create a struct for each 100 blocks of spike data.
SpikesToPlot1 = struct;
SpikesToPlot2 = struct;
SpikesToPlot3 = struct;

% Start board running
updateUIStatus('Streaming data...');

for cyclesCompleted = 1:3
    % Initialize the number of spikes for this 100 data blocks to 0.
    numSpikes = 0;
    
    if cyclesCompleted == 1
        thisCycleAmplifierData = amplifierData1;
        thisCycleStimData = stimData1;
        thisCycleAmplifierTimestamps = amplifierTimestamps1;
    elseif cyclesCompleted == 2
        thisCycleAmplifierData = amplifierData2;
        thisCycleStimData = stimData2;
        thisCycleAmplifierTimestamps = amplifierTimestamps2;
    else
        thisCycleAmplifierData = amplifierData3;
        thisCycleStimData = stimData3;
        thisCycleAmplifierTimestamps = amplifierTimestamps3;
    end
    
    % Set up stim parameters
    amplitudeMicroAmps = stimStepSizeuA * cyclesCompleted;
    amplitudeStr = num2str(amplitudeMicroAmps);
    durationMicroSeconds = 5000;
    durationStr = num2str(durationMicroSeconds);
    commandString = [' set a-000.firstphaseamplitudemicroamps ' amplitudeStr ';' ...
        ' set a-000.secondphaseamplitudemicroamps ' amplitudeStr ';' ...
        ' set a-000.firstphasedurationmicroseconds ' durationStr ';' ...
        ' set a-000.secondphasedurationmicroseconds ' durationStr ';'];
    sendCommand(commandString);
    write(tcommand, uint8('execute uploadstimparameters a-000'));
    
    % Clear out any left-over data on data sockets
    read(twaveformdata);
    read(tspikedata);
    
    % Wait for 'uploadstimparameters' to complete.
    % Query if upload is currently in progress. If it still is, then wait
    % 500 ms and try again until it's not
    uploadInProgress = "True";
    while ~strcmp(uploadInProgress, "False")
        uploadInProgress = getUploadInProgress();
        pause(0.5);
    end
    
    % Start running, stimulate, and wait for 100 blocks of data to appear
    % on TCP port (at 30 kHz, 0.427 seconds)
    write(tcommand, uint8('set runmode run'));
    pause(0.05);
    write(tcommand, uint8('execute manualstimtriggerpulse f1'));
    
    while twaveformdata.BytesAvailable < waveformBytes100Blocks
        % Do nothing while waiting
    end
    write(tcommand, uint8('set runmode stop'));
    
    waveformArray = read(twaveformdata, waveformBytes100Blocks);
    spikeArray = read(tspikedata); % We don't know how ahead of time how many spike events are here
    rawIndex = 1;
    spikeIndex = 1;
    
    % Read all incoming blocks
    for block = 1:100
        
        % Read waveform data
        
        % Expect 4 bytes to be TCP Magic Number as uint32.
        % If not what's expected, print that there was an error.
        [magicNumber, rawIndex] = uint32ReadFromArray(waveformArray, rawIndex);
        if magicNumber ~= 0x2ef07a08
            fprintf(1, 'Error... block %d magic number incorrect.\n', block);
        end
        % Each block should contains 128 frames of data - process each of
        % these one-by-one
        for frame = 1:framesPerBlock
            
            % Expect 4 bytes to be timestamp as int32.
            [thisCycleAmplifierTimestamps(1, amplifierTimestampsIndex), rawIndex] = ...
                int32ReadFromArray(waveformArray, rawIndex);
            thisCycleAmplifierTimestamps(1, amplifierTimestampsIndex) = timestep * thisCycleAmplifierTimestamps(1, amplifierTimestampsIndex);
            
            % Parse wide band of channel a-000.
            [thisCycleAmplifierData(1, amplifierTimestampsIndex), rawIndex] = ...
                uint16ReadFromArray(waveformArray, rawIndex);
            
            % Parse stim data of channel a-000.
            [thisCycleStimData(1, amplifierTimestampsIndex), rawIndex] = ...
                uint16ReadFromArray(waveformArray, rawIndex);
            
            amplifierTimestampsIndex = amplifierTimestampsIndex + 1;
        end
        
    end
    
    minAxis = thisCycleAmplifierTimestamps(1,1);
    maxAxis = minAxis + 100 * framesPerBlock * timestep;
    
    % Read spike data
    spikeBytesToRead = length(spikeArray);
    chunksToRead = spikeBytesToRead / bytesPerSpikeChunk;
    
    if cyclesCompleted == 1
        ThisSpikeStruct = SpikesToPlot1;
    elseif cyclesCompleted == 2
        ThisSpikeStruct = SpikesToPlot2;
    else
        ThisSpikeStruct = SpikesToPlot3;
    end
    
    % Process all spike chunks
    for chunk = 1:chunksToRead

        % Make sure we get the correct magic number for this chunk
        [magicNumber, spikeIndex] = uint32ReadFromArray(spikeArray, spikeIndex);
        if magicNumber ~= 0x3ae2710f
            error('Incorrect spike magic number');
        end

        % Next 5 bytes are chars of native channel name
        [nativeChannelName, spikeIndex] = char5ReadFromArray(spikeArray, spikeIndex);

        % Next 4 bytes are uint32 timestamp
        [singleTimestamp, spikeIndex] = uint32ReadFromArray(spikeArray, spikeIndex);

        % Next 1 byte is uint8 id
        [singleID, spikeIndex] = uint8ReadFromArray(spikeArray, spikeIndex);
        
        % For every spike event, add it to ThisSpikeStruct struct
        if singleID ~= 0
            nextSpikeIndex = size(ThisSpikeStruct, 2) + 1;

            % If this is the first spike in this struct, start with an
            % index of 1
            if numSpikes == 0
                nextSpikeIndex = 1;
            end

            % Add Name, Timestamp, and ID to SpikesToPlot
            ThisSpikeStruct(nextSpikeIndex).Name = nativeChannelName;
            ThisSpikeStruct(nextSpikeIndex).Timestamp = double(singleTimestamp) * timestep;
            ThisSpikeStruct(nextSpikeIndex).ID = singleID;

            % Increment numSpikes for this section of 100 datablocks
            numSpikes = numSpikes + 1;
        end
    end
    
    % Scale these 100 data blocks
    thisCycleAmplifierData = 0.195 * (thisCycleAmplifierData - 32768);
    for i = 1:length(thisCycleAmplifierTimestamps)
        thisCycleStimData(1,i) = parseStim(thisCycleStimData(1,i), stimStepSizeuA);
    end
    
    if cyclesCompleted == 1
        amplifierData1 = thisCycleAmplifierData;
        stimData1 = thisCycleStimData;
        amplifierTimestamps1 = thisCycleAmplifierTimestamps;
        spikes1 = ThisSpikeStruct;
        move_to_base_workspace(amplifierData1);
        move_to_base_workspace(stimData1);
        move_to_base_workspace(amplifierTimestamps1);
        move_to_base_workspace(spikes1);
        figure(ampDataFigure1);
    elseif cyclesCompleted == 2
        amplifierData2 = thisCycleAmplifierData;
        stimData2 = thisCycleStimData;
        amplifierTimestamps2 = thisCycleAmplifierTimestamps;
        spikes2 = ThisSpikeStruct;
        move_to_base_workspace(amplifierData2);
        move_to_base_workspace(stimData2);
        move_to_base_workspace(amplifierTimestamps2);
        move_to_base_workspace(spikes2);
        figure(ampDataFigure2);
    else
        amplifierData3 = thisCycleAmplifierData;
        stimData3 = thisCycleStimData;
        amplifierTimestamps3 = thisCycleAmplifierTimestamps;
        spikes3 = ThisSpikeStruct;
        move_to_base_workspace(amplifierData3);
        move_to_base_workspace(stimData3);
        move_to_base_workspace(amplifierTimestamps3);
        move_to_base_workspace(spikes3);
        figure(ampDataFigure3);
    end
    
    % Plot
    subplot(2, 1, 1);
    plot(thisCycleAmplifierTimestamps, thisCycleAmplifierData(1, :), 'Color', 'blue');
    t1 = prepareSpikes(numSpikes, ThisSpikeStruct, minAxis, maxAxis);
    ylimits = get(gca, 'YLim');
    ymin = ylimits(1);
    ymax = ylimits(2);
    plotPreparedSpikes(t1, ymin, ymax);
    
    subplot(2, 1, 2);
    plot(thisCycleAmplifierTimestamps, thisCycleStimData(1, :), 'Color', 'red');
    
    % Reset timestamp index
    amplifierTimestampsIndex = 1;
    
    read(tspikedata);
    pause(1);
    
end

updateUIStatus('Finished');

set(hs.executeButton, 'Value', 0);
set(hs.executeButton, 'Enable', 1);
set(hs.executeButton, 'Text', 'Execute');

% Empty spike and waveform sockets
read(tspikedata);
read(twaveformdata);

end

function t = prepareSpikes(numSpikes, SpikesToPlot, minTimestamp, maxTimestamp)
t = [];
for spikeToPlotIndex = 1:numSpikes
    thisSpikeToPlot = SpikesToPlot(spikeToPlotIndex);
    if ~strcmp(thisSpikeToPlot.Name, 'A-000')
        continue;
    end
    
    if thisSpikeToPlot.Timestamp >= minTimestamp && thisSpikeToPlot.Timestamp <= maxTimestamp
        t(length(t) + 1) = thisSpikeToPlot.Timestamp;
    end
end
end

function plotPreparedSpikes(t, ymin, ymax)
hold on
deltay = ymax - ymin;
y1 = ymin + (1.0 / 8.0) * deltay;
y2 = ymin + (2.0 / 8.0) * deltay;
for tSpike = t
    line([tSpike tSpike], [y1 y2], 'Color', 'red', 'LineWidth', 2);
end
hold off
end


% Update statusText on the UI with the given message
function updateUIStatus(statusMessage)
global hs
set(hs.statusText, 'Text', statusMessage);
drawnow;
end

% Query the sample rate from the board and get it as a double
function sampleRate = getSampleRate()
sendCommand('get sampleratehertz');
commandString = readCommand();
expectedReturnString = 'Return: SampleRateHertz ';
if ~contains(commandString, expectedReturnString)
    error('Unable to get sample rate from server');
else
    sampleRateString = commandString(length(expectedReturnString):end);
    sampleRate = str2double(sampleRateString);
end
end

% Query the controller's stim step size and get it as a double
function stimStepSizeuA = getStimStepSize()
sendCommand('get stimstepsizemicroamps');
commandString = readCommand();
expectedReturnString = 'Return: StimStepSizeMicroAmps ';
if ~contains(commandString, expectedReturnString)
    error('Unable to get stim step size from server');
else
    stimStepSizeString = commandString(length(expectedReturnString):end);
    stimStepSizeuA = str2double(stimStepSizeString);
end
end

% Query if the controller currently has an upload in progress
function uploadInProgress = getUploadInProgress()
sendCommand('get uploadinprogress');
commandString = readCommand();
expectedReturnString = 'Return: UploadInProgress ';
if ~contains(commandString, expectedReturnString)
    error('Unable to get upload in progress from server');
else
    uploadInProgress = commandString(length(expectedReturnString)+1:end);
end
end

% If the stimWord's 9th LSB is 1, stim is negative. Otherwise, it's
% positive. Stim's magnitude is stimWord's 8 LSBs multipled by stim step
% size
function parsedCurrent = parseStim(stimWord, stimStepSizeuA)
parsedCurrent = bitand(stimWord, 255);
negative = bitand(stimWord, 256) > 0;
if negative
    parsedCurrent = -1 * parsedCurrent;
end
parsedCurrent = parsedCurrent * stimStepSizeuA;
end

% Send the given command over the TCP command socket
function sendCommand(command)
global tcommand
write(tcommand, uint8(command));
end

% Read the result of a command over the TCP comand socket
function command = readCommand()
global tcommand
tic
while tcommand.BytesAvailable == 0
    elapsedTime = toc;
    if elapsedTime > 2
        error('Reading command timed out');
    end
    pause(0.01)
end
commandArray = read(tcommand);
command = char(commandArray);
end

% Create the main UI window that contains control buttons
function createMainUI()
global hs
global ampDataFigure
global initialized
global currentPlotBand
% Add the UI components
hs = addUIComponents();
% Make figure visible after adding components
hs.fig.Visible = 'on';
% Initialize ampDataFigure to 0 to be changed when actually created
ampDataFigure = 0;
initialized = 0;
currentPlotBand = 'Wide';
end

% Populate the UI with the components it needs
function hs = addUIComponents()

% Add components, save handles in a struct
hs.mainUI = uifigure('Name', 'Stim/Record GUI',...
    'Position', [50, 50, 300, 84]);
hs.statusText = uilabel(hs.mainUI,...
    'Text', 'Stopped',...
    'Position', [10, 10, 280, 22]);
hs.executeButton = uibutton(hs.mainUI,...
    'state',...
    'Text', 'Execute',...
    'Position', [10, 50, 100, 22],...
    'ValueChangedFcn', @(object,event) executeButtonClicked(object,event));
end

function executeButtonClicked(object,event)
    % Only execute when button goes from not clicked to clicked
    if event.Value == 1 && event.PreviousValue == 0
        object.Enable = 0;
        object.Text = 'Executing...';
        execute;
    end
end

% Read 4 bytes from array as uint32
function [var, arrayIndex] = uint32ReadFromArray(array, arrayIndex)
varBytes = array(arrayIndex : arrayIndex + 3);
var = typecast(uint8(varBytes), 'uint32');
arrayIndex = arrayIndex + 4;
end

% Read 4 bytes from array as int32
function [var, arrayIndex] = int32ReadFromArray(array, arrayIndex)
varBytes = array(arrayIndex : arrayIndex + 3);
var = typecast(uint8(varBytes), 'int32');
arrayIndex = arrayIndex + 4;
end

% Read 2 bytes from array as uint16
function [var, arrayIndex] = uint16ReadFromArray(array, arrayIndex)
varBytes = array(arrayIndex : arrayIndex + 1);
var = typecast(uint8(varBytes), 'uint16');
arrayIndex = arrayIndex + 2;
end

% Read 1 byte from array as uint8
function [var, arrayIndex] = uint8ReadFromArray(array, arrayIndex)
var = array(arrayIndex);
arrayIndex = arrayIndex + 1;
end

% Read 5 bytes from array as 5 chars
function [var, arrayIndex] = char5ReadFromArray(array, arrayIndex)
varBytes = array(arrayIndex : arrayIndex + 4);
var = native2unicode(varBytes);
arrayIndex = arrayIndex + 5;
end

% Move given variable to base workspace (useful for debugging)
function move_to_base_workspace(variable)

% move_to_base_workspace(variable)
%
% Move variable from function workspace to base MATLAB workspace so
% user will have access to it after the program ends.

variable_name = inputname(1);
assignin('base', variable_name, variable);

return;
end