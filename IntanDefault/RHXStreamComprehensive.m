% In order to run this example script successfully, the IntanRHX software
% should first be started, and through Network -> Remote TCP Control:

% Command Output should open a connection at 127.0.0.1, Port 5000.
% Status should read "Pending" for the Command Port

% Waveform Output (in the Data Output tab) should open a connection at
% 127.0.0.1, Port 5001.
% Status should read "Pending" for the Waveform Port (Spike Port is unused
% for this example, and can be left disconnected)

% Plots channel A-000 and A-001 amplifier data (LOW, WIDE, or HIGH), in
% realtime with a degree of latency. Also plots ANALOG-IN-1, ANALOG-IN-2,
% DIGITAL-IN-1, and DIGITAL-IN-2. For RHD, also plots AUX-IN-1, AUX-IN-2,
% and AUX-IN-3. For RHS, also plots DC and Stimulation data for A-000 and
% A-001

% If Bytes in Port keeps increasing, that means this client can't process
% the data quickly enough and is beginning to lag, likely dependent on
% the speed of the computer. If this is the case, sampling rate should be
% lowered

% Set up main UI
createMainUI();

% When 'run' is clicked - begin realtime streaming and plotting
function run(runButtonGroup)

% Global variables accessed in other functions
global initialized
global tcommand
global typeString
global currentPlotBand
global ampDataFigure

% Global variables that should be retained when this function is called
% multiple times
global twaveformdata
global timestep
global stimStepSizeuA
global numAmpChannels
global numAuxChannels
global numBoardAdcChannels
global numBoardDigitalInChannels
global auxDataFigure
global analogInDataFigure
global digitalInDataFigure
global dcDataFigure
global stimDataFigure

% If this is the first time 'run' has been clicked, first initialize TCP
% communication, send commands to initialize RHX sfotware's settings, and
% create plotting figure
if initialized == 0
    
    % Connect to TCP servers
    updateUIStatus('Connecting to TCP command server...');
    tcommand = tcpclient('localhost', 5000);
    updateUIStatus('Connecting to TCP waveform server...');
    twaveformdata = tcpclient('localhost', 5001);
    
    % Clear TCP data output to ensure no TCP channels are enabled at the
    % beginning of this script
    updateUIStatus('Clearing current TCP outputs...');
    sendCommand('execute clearalldataoutputs');

    % Query controller type
    updateUIStatus('Enabling channels...');
    sendCommand('get type');
    commandReturn = readCommand();
    if strcmp(commandReturn, 'Return: Type ControllerRecordUSB2')
        typeString = 'ControllerRecordUSB2';
    elseif strcmp(commandReturn, 'Return: Type ControllerRecordUSB3')
        typeString = 'ControllerRecordUSB3'; 
    elseif strcmp(commandReturn, 'Return: Type ControllerStimRecordUSB2')
        typeString = 'ControllerStimRecordUSB2';
    else
        error('Unrecognized Controller Type');
    end
    
    % Set up number of channels to read data from
    numAmpChannels = 2;
    numBoardAdcChannels = 2;
    numBoardDigitalInChannels = 2;
    if strcmp(typeString, 'ControllerStimRecordUSB2')
        numAuxChannels = 0;
    else
        numAuxChannels = 3;
    end
    
    % Calculate timestep based on sample rate
    sampleRate = getSampleRate();
    timestep = 1 / sampleRate;
    
    % Get Stim Step size
    if strcmp(typeString, 'ControllerStimRecordUSB2')
        stimStepSizeuA = getStimStepSize();
    end
    
    % Query numAmpChannels, on each port and total
    portPrefixes = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
    
    % Send TCP commands to set up TCP Data Output Enabled for all bands of
    % 2 channels
    for channel = 1:numAmpChannels
        channelName = [portPrefixes(1) '-' num2str(channel - 1, '%03d')];
        commandString = ['set ' channelName '.tcpdataoutputenabled true;'];
        commandString = [commandString ' set ' channelName '.tcpdataoutputenabledlow true;'];
        commandString = [commandString ' set ' channelName '.tcpdataoutputenabledhigh true;'];
        commandString = [commandString ' set ' channelName '.tcpdataoutputenabledspike true;'];
        if strcmp(typeString, 'ControllerStimRecordUSB2')
            commandString = [commandString ' set ' channelName '.tcpdataoutputenableddc true;'];
            commandString = [commandString ' set ' channelName '.tcpdataoutputenabledstim true;'];
        end
        sendCommand(commandString);
    end
    
    % Send TCP commands to set up TCP Data Output Enabled for 3 aux channels
    for channel = 1:numAuxChannels
        channelName = [portPrefixes(1) '-AUX' num2str(channel)];
        commandString = ['set ' channelName '.tcpdataoutputenabled true;'];
        sendCommand(commandString);
    end

    % Send TCP commands to set up TCP Data Output Enabled for 2 analog in
    % channels
    for channel = 1:numBoardAdcChannels
        if strcmp(typeString, 'ControllerRecordUSB2')
            channelName = ['ANALOG-IN-' num2str(channel - 1, '%02d')];
        else
            channelName = ['ANALOG-IN-' num2str(channel)];
        end
        commandString = ['set ' channelName '.tcpdataoutputenabled true;'];
        sendCommand(commandString);
    end

    % Send TCP commands to set up TCP Data Output Enabled for 2 digital in
    % channels
    for channel = 1:numBoardDigitalInChannels
        if strcmp(typeString, 'ControllerRecordUSB2')
            channelName = ['DIGITAL-IN-', num2str(channel - 1, '%02d')];
        else
            channelName = ['DIGITAL-IN-', num2str(channel, '%02d')];
        end
        commandString = ['set ' channelName '.tcpdataoutputenabled true;'];
        sendCommand(commandString);
    end
    
    % Wait 1 second to make sure data sockets are ready to begin
    updateUIStatus('Preparing MATLAB to start streaming...');
    pause(1);
    
    % Create figures and put them in order on the screen so that they don't
    % cover each other
    figureIndex = 1;
    
    ampDataFigure = figure(figureIndex);
    ampDataFigure.Name = ['Amplifier Data - ', currentPlotBand];
    figureIndex = figureIndex + 1;
    
    if strcmp(typeString, 'ControllerStimRecordUSB2')
        dcDataFigure = figure(figureIndex);
        dcDataFigure.Name = 'DC Amplifier Data';
        figureIndex = figureIndex + 1;
        
        stimDataFigure = figure(figureIndex);
        stimDataFigure.Name = 'Stimulation Data';
        figureIndex = figureIndex + 1;
    else
        auxDataFigure = figure(figureIndex);
        auxDataFigure.Name = 'Auxiliary Data';
        figureIndex = figureIndex + 1; 
    end
    
    analogInDataFigure = figure(figureIndex);
    analogInDataFigure.Name = 'Board Analog In Data';
    figureIndex = figureIndex + 1;
    
    digitalInDataFigure = figure(figureIndex);
    digitalInDataFigure.Name = 'Board Digital In Data';

    % Position figures
    set(0, 'units', 'pixels');
    pixelSize = get(0, 'screensize');
    screenWidth = pixelSize(3);
    screenHeight = pixelSize(4);

    % If each plot will have a width of 400 and height of 300, determine the
    % positions of 4 plots for RHD, 5 plots for RHS, starting from top-left
    numPlots = 4;
    if strcmp(typeString, 'ControllerStimRecordUSB2')
        numPlots = 5;
    end

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

    if strcmp(typeString, 'ControllerStimRecordUSB2')
        ampDataFigure.Position = plotPositions(1,:);
        dcDataFigure.Position = plotPositions(2,:);
        stimDataFigure.Position = plotPositions(3,:);
        analogInDataFigure.Position = plotPositions(4,:);
        digitalInDataFigure.Position = plotPositions(5,:);
    else
        ampDataFigure.Position = plotPositions(1,:);
        auxDataFigure.Position = plotPositions(2,:);
        analogInDataFigure.Position = plotPositions(3,:);
        digitalInDataFigure.Position = plotPositions(4,:);
    end
    
    % Mark initialization as complete
    initialized = 1;
end

% All controllers will have WIDE, LOW, and HIGH bands on amplifier channels.
% If Stim, there will also be DC and STIM bands
if strcmp(typeString, 'ControllerStimRecordUSB2')
    numBandsPerAmplifierChannel = 5;
else
    numBandsPerAmplifierChannel = 3;
end
numAmplifierBands = numAmpChannels * numBandsPerAmplifierChannel;

% Calculations for accurate parsing
framesPerBlock = 128;
digInWordPresent = 0;
if numBoardDigitalInChannels > 0
    digInWordPresent = 1;
end
waveformBytesPerFrame = 4 + 2 * (numAmplifierBands + numAuxChannels + ...
    numBoardAdcChannels + digInWordPresent);
waveformBytesPerBlock = framesPerBlock * waveformBytesPerFrame + 4;
blocksPerRead = 100;
waveformBytes100Blocks = blocksPerRead * waveformBytesPerBlock;

% Pre-allocate memory for blocksPerRead blocks of waveform data (the amount
% that's plotted at once)
amplifierData = zeros(numAmpChannels, framesPerBlock * blocksPerRead);
if strcmp(typeString, 'ControllerStimRecordUSB2')
    amplifierDataDc = zeros(numAmpChannels, framesPerBlock * blocksPerRead);
    stimData = zeros(numAmpChannels, framesPerBlock * blocksPerRead);
else
    auxData = zeros(numAuxChannels, framesPerBlock * blocksPerRead);
end
boardAdcData = zeros(numBoardAdcChannels, framesPerBlock * blocksPerRead);
if numBoardDigitalInChannels > 0
    boardDigitalInData = zeros(16, framesPerBlock * blocksPerRead);
end
amplifierTimestamps = zeros(1, framesPerBlock * blocksPerRead);

% Initialize amplifier timestamps index
amplifierTimestampsIndex = 1;

% Each spike chunk contains 4 bytes for magic number, 5 bytes for native
% channel name, 4 bytes for timestamp, and 1 byte for id. Total: 14 bytes
bytesPerSpikeChunk = 14;

% Start board running
updateUIStatus('Streaming data...');
write(tcommand, uint8('set runmode run'));
processingTimeAvailable = 100 * framesPerBlock * timestep;

% Enter run loop
while get(runButtonGroup.Children(2), 'Value')
    
    % If twaveformdata has been closed already, just exit
    if twaveformdata == 0
        break
    end
    
    % Read waveform data in 100-block chunks
    if twaveformdata.BytesAvailable >= waveformBytes100Blocks
        drawnow;
        
        waveformArray = read(twaveformdata, waveformBytes100Blocks);
        updateUIBytesInPort(['Bytes in Port: ' num2str(twaveformdata.BytesAvailable)]);
        rawIndex = 1;
        
        % Read all incoming blocks
        for block = 1:blocksPerRead
            % Expect 4 bytes to be TCP Magic Number as uint32.
            % If not what's expected, print that there was an error.
            [magicNumber, rawIndex] = uint32ReadFromArray(waveformArray, rawIndex);
            if magicNumber ~= 0x2ef07a08
                fprintf(1, 'Error... block %d magic number incorrect.\n', block);
            end
            % Each block should contain 128 frames of data - process each
            % of these one-by-one
            for frame = 1:framesPerBlock
                % Expect 4 bytes to be timestamp as int32
                [amplifierTimestamps(1, amplifierTimestampsIndex), rawIndex] = ...
                    int32ReadFromArray(waveformArray, rawIndex);
                
                % Parse all bands of amplifier channels
                for channel = 1:numAmpChannels
                    
                    if strcmp(currentPlotBand, 'Wide')
                        
                        % 2 bytes of wide, then 2 bytes of low (ignored),
                        % then 2 bytes of high (ignored)
                        [amplifierData(channel, amplifierTimestampsIndex), rawIndex] = ...
                            uint16ReadFromArray(waveformArray, rawIndex);
                        rawIndex = rawIndex + (2 * 2);
                        
                    elseif strcmp(currentPlotBand, 'Low')
                        
                        % 2 bytes of wide (ignored), then 2 bytes of low,
                        % then 2 bytes of high (ignored)
                        rawIndex = rawIndex + 2;
                        [amplifierData(channel, amplifierTimestampsIndex), rawIndex] = ...
                            uint16ReadFromArray(waveformArray, rawIndex);
                        rawIndex = rawIndex + 2;
                        
                    else
                        
                        % 2 bytes of wide (ignored), then 2 bytes of low
                        % (ignored), then 2 bytes of high
                        rawIndex = rawIndex + (2 * 2);
                        [amplifierData(channel, amplifierTimestampsIndex), rawIndex] = ...
                            uint16ReadFromArray(waveformArray, rawIndex);
                        
                    end
                    
                    if strcmp(typeString, 'ControllerStimRecordUSB2')
                        % Expect 2 bytes to be A-###|DC as uint16
                        [amplifierDataDc(channel, amplifierTimestampsIndex), rawIndex] = ...
                            uint16ReadFromArray(waveformArray, rawIndex);
                        
                        % Expect 2 bytes to be A-###|STIM as uint16
                        [stimData(channel, amplifierTimestampsIndex), rawIndex] = ...
                            uint16ReadFromArray(waveformArray, rawIndex);
                    end
                end
                
                % For non-Stim, parse aux channels
                if ~strcmp(typeString, 'ControllerStimRecordUSB2')
                    for channel = 1:numAuxChannels
                        % Expect 2 bytes for AUX as uint16
                        [auxData(channel, amplifierTimestampsIndex), rawIndex] = ...
                            uint16ReadFromArray(waveformArray, rawIndex);
                    end
                end
                
                % Parse analog in channels
                for channel = 1:numBoardAdcChannels
                    % Expect 2 bytes to be ANALOG-IN-# as uint16
                    [boardAdcData(channel, amplifierTimestampsIndex), rawIndex] = ...
                        uint16ReadFromArray(waveformArray, rawIndex);
                end
                
                % If at least one digital input, parse the digital in word
                if numBoardDigitalInChannels > 0
                    % Expect 2 bytes to be DIGITAL-IN-WORD as uint16
                    [digInWord, rawIndex] = uint16ReadFromArray(waveformArray, rawIndex);
                    % Extract digital input channels to separate variables.
                    for channel = 0:15
                        mask = 2^channel;
                        boardDigitalInData(channel + 1, amplifierTimestampsIndex) = ...
                            (bitand(digInWord, mask) > 0);
                    end
                end
                
                amplifierTimestampsIndex = amplifierTimestampsIndex + 1;
            end
        end
        
        % Scale timestamps to seconds
        amplifierTimestamps = amplifierTimestamps * timestep;

        % Scale amplifier data to microVolts
        amplifierData = 0.195 * (amplifierData - 32768);

        % For Stim, scale dc amplifier data to volts, and stim data to microamps.
        % For non-Stim, scale aux and vdd data to volts.
        if strcmp(typeString, 'ControllerStimRecordUSB2')
            amplifierDataDc = -0.01923 * (amplifierDataDc - 512);
            for i = 1:length(amplifierTimestamps)
                stimData(1,i) = parseStim(stimData(1,i), stimStepSizeuA);
                stimData(2,i) = parseStim(stimData(2,i), stimStepSizeuA);
            end
        else
            auxData = 37.4e-6 * auxData;
        end

        % For USB Interface board, scale analog in data to volts.
        % For other controllers, scale analog in data to volts at a different
        % scale.
        if strcmp(typeString, 'ControllerRecordUSB2')
            boardAdcData = 50.354e-6 * boardAdcData;
        else
            boardAdcData = 312.5e-6 * (boardAdcData - 32768);
        end
        
        % Plot
        % Amp channels
        figure(ampDataFigure);
        minTimestamp = min(amplifierTimestamps(1,:));
        maxTimestamp = max(amplifierTimestamps(1,:));
        % If the lowest entry in amplifierTimestamps is zero or less
        % than zero, then amplifierTimestamps hasn't been fully
        % populated with valid data yet. Avoid plotting until fully
        % populated.
        if minTimestamp > 0
            for thisPlot = 1:numAmpChannels
                subplot(numAmpChannels, 1, thisPlot);
                plot(amplifierTimestamps, amplifierData(thisPlot, :), 'Color', 'blue');
            
                if thisPlot == 1
                    title('Channel A-000')
                else
                    title('Channel A-001')
                end
                axis([minTimestamp maxTimestamp -400 400]);
            end
            xlabel('Time (s)');
            ylabel('Electrode Voltage (\muV)');
        
            if strcmp(typeString, 'ControllerStimRecordUSB2')
                % DC channels
                figure(dcDataFigure);
                for thisPlot = 1:numAmpChannels
                    subplot(numAmpChannels, 1, thisPlot);
                    plot(amplifierTimestamps, amplifierDataDc(thisPlot, :));
                    if thisPlot == 1
                        title('Channel A-000')
                    else
                        title('Channel A-001')
                    end
                    axis([minTimestamp maxTimestamp -10 10]);
                    xlabel('Time (s)');
                    ylabel('DC Voltage (V)');
                end
            
                % Stim channels
                figure(stimDataFigure);
                for thisPlot = 1:numAmpChannels
                    subplot(numAmpChannels, 1, thisPlot);
                    plot(amplifierTimestamps, stimData(thisPlot, :));
                    if thisPlot == 1
                        title('Channel A-000')
                    else
                        title('Channel A-001')
                    end
                    xlim([minTimestamp, maxTimestamp]);
                    axis 'auto y';
                    xlabel('Time (s)');
                    ylabel('Stimulation Current (uA)');
                end

            else
        
                % Aux channels
                figure(auxDataFigure);
                for thisPlot = 1:numAuxChannels
                    subplot(numAuxChannels, 1, thisPlot);
                    plot(amplifierTimestamps, auxData(thisPlot, :));
                    title(['Channel AUX-IN-' num2str(thisPlot)]);
                    axis([minTimestamp maxTimestamp 0 5]);
                    xlabel('Time (s)');
                    ylabel('Auxiliary Input (V)');
                end
            end
        
            % Analog in channels
            figure(analogInDataFigure);
            for thisPlot = 1:numBoardAdcChannels
                subplot(numBoardAdcChannels, 1, thisPlot);
                plot(amplifierTimestamps, boardAdcData(thisPlot, :));
                title(['Channel ANALOG-IN-' num2str(thisPlot)]);
                axis([minTimestamp maxTimestamp -10 10]);
                xlabel('Time (s)');
                ylabel('Analog In (V)');
            end

            % Digital in channels
            figure(digitalInDataFigure);
            for thisPlot = 1:numBoardDigitalInChannels
                subplot(numBoardDigitalInChannels, 1, thisPlot);
                plot(amplifierTimestamps, boardDigitalInData(thisPlot, :));
                title(['Channel DIGITAL-IN-' num2str(thisPlot)]);
                axis([minTimestamp maxTimestamp 0 1]);
                xlabel('Time (s)');
                ylabel('Digital In');
            end
        end
        
        % Reset timestamp index
        amplifierTimestampsIndex = 1;
    end
end

end

% When 'stop' is clicked - stop realtime streaming
function stop
updateUIStatus('Stopped');
sendCommand('set runmode stop');
end

% Update statusText on the UI with the given message
function updateUIStatus(statusMessage)
global hs
set(hs.statusText, 'Text', statusMessage);
drawnow;
end

% Update bytesInPort on the UI with the given message
function updateUIBytesInPort(bytesMessage)
global hs
set(hs.bytesInPort, 'Text', bytesMessage);
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

% Query the stim step size from the board and get it as a double
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
hs.mainUI = uifigure('Name', 'RHX Stream GUI',...
    'Position', [50, 50, 300, 164]);
hs.statusText = uilabel(hs.mainUI,...
    'Text', 'Stopped',...
    'Position', [10, 40, 250, 22]);
hs.bytesInPort = uilabel(hs.mainUI,...
    'Text', 'Bytes in Port: ',...
    'Position', [10, 10, 250, 22]);
hs.runButtonGroup = uibuttongroup(hs.mainUI,...
    'Position', [10, 72, 120, 82]);
hs.runButton = uitogglebutton(hs.runButtonGroup,...
    'Text', 'Run',...
    'Position', [10, 50, 100, 22],...
    'Value', 0);
hs.stopButton = uitogglebutton(hs.runButtonGroup,...
    'Text', 'Stop',...
    'Position', [10, 10, 100, 22],...
    'Value', 1);
set(hs.runButtonGroup, 'SelectionChangedFcn', @runButtonChanged);

hs.bandButtonGroup = uibuttongroup(hs.mainUI,...
    'Position', [150, 72, 80, 82]);
hs.wideButton = uiradiobutton(hs.bandButtonGroup,...
    'Text', 'Wide',...
    'Position', [10, 55, 100, 22],...
    'Value', 1);
hs.lowButton = uiradiobutton(hs.bandButtonGroup,...
    'Text', 'Low',...
    'Position', [10, 30, 100, 22],...
    'Value', 0);
hs.highButton = uiradiobutton(hs.bandButtonGroup,...
    'Text', 'High',...
    'Position', [10, 5, 100, 22],...
    'Value', 0);
set(hs.bandButtonGroup, 'SelectionChangedFcn', @bandButtonChanged);
end

% Band button change callback function
function bandButtonChanged(source,event)
global currentPlotBand
global ampDataFigure
currentPlotBand = event.NewValue.Text;
% If ampDataFigure already exists, change its name
if ampDataFigure ~= 0
    ampDataFigure.Name = ['Amplifier Data - ', currentPlotBand];
end
end

% Run button change callback function
function runButtonChanged(source,event)
if strcmp(event.NewValue.Text, 'Run')
    run(source);
else
    stop;
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