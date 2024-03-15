% In order to run this example script successfully, the IntanRHX software
% should first be started, and through Network -> Remote TCP Control:

% Command Output should open a connection at 127.0.0.1, Port 5000.
% Status should read "Pending" for the Command Port

% Waveform output (in the Data Output tab) should open a connection at
% 127.0.0.1, Port 5001.
% Status should read "Pending" for the Waveform Port

% Spike output (in the Data Output tab) should open a connection at
% 127.0.0.1, Port 5002.
% Status should read "Pending" for the Spike Port

% Plots channel A-000 and A-001 amplifier data (LOW, WIDE, or HIGH) in
% realtime, with sweep-style plotting. Also indicates rasters in red over
% the waveform for detected spikes. Depending on the speed of the machine,
% data backup may occur if this client can't process the data quickly
% enough. If this is the case, sampling rate should be lowered.

% If Bytes in Port keeps increasing, that means this client can't process
% the data quickly enough and is beginning to lag, likely dependent on
% the speed of the computer. If this is the case, sampling rate should be
% lowered

% Set up main UI
createMainUI();

global savedata
global savetime
global savesound;
global savesoundblock;
global SoundSel;
global soundTypeDir

savedata=[];
savetime=[];
savesound=[];
InitSound;
%FinMLOnline_InitSound;

global Ball;
load('predict/TrainedMNR_fixed.mat');

% Initialize variable used for playing periodic sounds
global csound
csound = timer;
csound.Period = 3;
csound.TasksToExecute = 10;
csound.ExecutionMode = 'fixedRate';
csound.TimerFcn = @(src, event) playSoundCallback();

% Timer to ensure actions happen Tsnip seconds after the sound is played
global action_timer
action_timer = timer;
action_timer.Period = 1;
action_timer.TasksToExecute = 1;
action_timer.ExecutionMode = 'fixedRate';
action_timer.StartDelay = 1;
action_timer.TimerFcn = @(src, event) UpdateAngle();

%global amplifierTimestamps

% Global variables for game images
global swiper;  global swiperImg;   global sBrain;  global sBrainImg;
global pBrain;  global pBrainImg;   global uTom;    global uTomImg;
global pSwiper; global pSwiperImg;

% timer for game
% global tom_timer
% tom_timer = timer;
% % tom_timer.Period = 0.2;
% % tom_timer.TasksToExecute = 5;
% % tom_timer.ExecutionMode = 'fixedRate';
% % tom_timer.BusyMode = 'drop';
% tom_timer.StartDelay = 0.5;
% tom_timer.TimerFcn = @(src, event) transparenTom();

global guess_timer
guess_timer = timer;
guess_timer.StartDelay = 0.7;

global swin_timer
swin_timer = timer;
% swin_timer.BusyMode = 'drop';
% swin_timer.StartDelay = 0.5;

global sloss_timer
sloss_timer = timer;
% sloss_timer.BusyMode = 'drop';
% sloss_timer.StartDelay = 0.5;

% When 'run' is clicked - begin realtime streaming and plotting
function run(runButtonGroup)

% Global variables accessed in other functions
global initialized
global tcommand
global typeString
global currentPlotBand
global ampDataFigure
global stopped
global gameFigure

global savedata
global savetime
global savesound
global amplifierTimestamps

% Global variables that should be retained when this function is called
% multiple times
global twaveformdata
global tspikedata
global timestep

% If this is the first time 'run' has been clicked, first initialize TCP
% communication, send commands to initialize RHX software's settings, and
% create plotting figure
numAmpChannels = 2;
StartChannel = 19;
if initialized == 0
    
    % Connect to TCP servers
    updateUIStatus('Connecting to TCP command server...');
    tcommand = tcpclient('127.0.0.1', 5000);
    updateUIStatus('Connecting to TCP waveform server...');
    twaveformdata = tcpclient('127.0.0.1', 5001);
    updateUIStatus('Connecting to TCP spike server...');
    tspikedata = tcpclient('127.0.0.1', 5002);
    
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
    
    % Calculate timestep based on sample rate
    sampleRate = getSampleRate();
    timestep = 1 / sampleRate;
    
    % Send TCP commands to set up TCP Data Output Enabled for all bands of 1
    % channel
    for channel = 1+StartChannel:StartChannel+numAmpChannels
        channelName = ['a-' num2str(channel - 1, '%03d')];
        %channelName = 'a-013';
        commandString = ['set ' channelName '.tcpdataoutputenabled true;'];
        commandString = [commandString ' set ' channelName '.tcpdataoutputenabledlow true;'];
        commandString = [commandString ' set ' channelName '.tcpdataoutputenabledhigh true;'];
        commandString = [commandString ' set ' channelName '.tcpdataoutputenabledspike true;'];
        sendCommand(commandString);
    end
    
    % Wait 1 second to make sure data sockets are ready to begin
    updateUIStatus('Preparing MATLAB to start streaming...');
    pause(1);
    
    % Create figure
    ampDataFigure = figure(1);
    ampDataFigure.Name = ['Amplifier Data - ', currentPlotBand];
    
    % Mark initialization as complete
    initialized = 1;   
    
    ts=0; tg=-pi/2;
    subplot(2,2,[2 4])
    disp_arrows;

    % Create figure for game
    gameFigure = figure(2);
    gameWindowSetup; % call a function to initialize all images

    figure(ampDataFigure)
end

% Mark system as running
stopped = 0;

% Amplifier channels can be displayed as LOW, WIDE, or HIGH
numBandsPerChannel = 3;
numAmplifierBands = numBandsPerChannel * numAmpChannels;

% Calculations for accurate parsing
framesPerBlock = 128;
waveformBytesPerFrame = 4 + 2 * numAmplifierBands;
waveformBytesPerBlock = framesPerBlock * waveformBytesPerFrame + 4;
blocksPerRead = 10;
waveformBytes10Blocks = blocksPerRead * waveformBytesPerBlock;

% Pre-allocate memory for 10 blocks of waveform data (the amount that's
% plotted at once)
amplifierData = 32768 * ones(numAmpChannels, framesPerBlock * 10);
global amplifierTimestamps
amplifierTimestamps = zeros(1, framesPerBlock * 10);

% Initialize amplifier timestamps index
global amplifierTimestampsIndex;
amplifierTimestampsIndex = 1;

global savesoundblock
savesoundblock=zeros(1,blocksPerRead*framesPerBlock);

% Each spike chunk contains 4 bytes for magic number, 5 bytes for native
% channel name, 4 bytes for timestamp, and 1 byte for id. Total: 14 bytes
bytesPerSpikeChunk = 14;

% Create a struct for each 10 blocks of spike data.
SpikesToPlot = struct;

% Initialize the number of spikes for this 10 data blocks to 0.
numSpikes = 0;

% Initialize variables used to process spikes
chunkCounter = 0;
minAxis = 0;
maxAxis = 0;
latestPlottedWaveformTimestamp = 0;
delayedT1 = [];
delayedT2 = [];

% Start board running
updateUIStatus('Streaming data...');
write(tcommand, uint8('set runmode run'));
processingTimeAvailable = 10 * framesPerBlock * timestep;

% Enter run loop
while get(runButtonGroup.Children(2), 'Value')
    
    % If twaveformdata or tspikedata has been closed already, just exit
    if twaveformdata == 0 || tspikedata == 0
        break
    end
    
    % Read spike data immediately as it comes in
    spikeBytesToRead = tspikedata.BytesAvailable;
    
    % If at least one complete chunk has come in, process incoming data
    if spikeBytesToRead > 0 && mod(spikeBytesToRead, bytesPerSpikeChunk) == 0
        chunksToRead = spikeBytesToRead / bytesPerSpikeChunk;
        spikeArray = read(tspikedata, spikeBytesToRead);
        spikeIndex = 1;
        
        % Process all incoming chunks
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
            
            % For every spike event, add it to the most recent SpikesToPlot
            % struct
            if singleID ~= 0
                nextSpikeIndex = size(SpikesToPlot, 2) + 1;
                
                % If this is the first spike in this struct, start with an
                % index of 1
                if numSpikes == 0
                    nextSpikeIndex = 1;
                end
                
                % Add Name, Timestamp, and ID to SpikesToPlot
                SpikesToPlot(nextSpikeIndex).Name = nativeChannelName;
                SpikesToPlot(nextSpikeIndex).Timestamp = double(singleTimestamp) * timestep;
                SpikesToPlot(nextSpikeIndex).ID = singleID;
                
                % Increment numSpikes for this section of 10 datablocks
                numSpikes = numSpikes + 1;
            end
        end
        
        % Plot each channel
        for thisPlot = 1:numAmpChannels
            subplot(numAmpChannels, 2, 2*thisPlot-1);
            if thisPlot == 1
                % For the first channel, sort out immediate spikes to plot,
                % delayed spikes to plot, and actually plot
                [t1, delayedT1] = prepareSpikes(thisPlot, numSpikes, SpikesToPlot, minAxis, maxAxis, delayedT1, latestPlottedWaveformTimestamp);
                ylimits = get(gca, 'YLim');
                ymin = ylimits(1);
                ymax = ylimits(2);
                plotPreparedSpikes(t1, ymin, ymax);
                delayedT1 = plotDelayedSpikes(delayedT1, minAxis, maxAxis);
            else
                % For the second channel, sort out immediate spikes to
                % plot, delayed spikes to plot, and actually plot
                [t2, delayedT2] = prepareSpikes(thisPlot, numSpikes, SpikesToPlot, minAxis, maxAxis, delayedT2, latestPlottedWaveformTimestamp);
                ylimits = get(gca, 'YLim');
                ymin = ylimits(1);
                ymax = ylimits(2);
                plotPreparedSpikes(t2, ymin, ymax);
                delayedT2 = plotDelayedSpikes(delayedT2, minAxis, maxAxis);
            end
        end
        SpikesToPlot = struct;
        numSpikes = 0;
    end
    
    % Read waveform data in 10-block chunks
    if twaveformdata.BytesAvailable >= waveformBytes10Blocks
        drawnow;
        
        % Track which 10-block chunk has just come in. If there have
        % already been 10 blocks plotted, then reset to 1.
        chunkCounter = chunkCounter + 1;
        if chunkCounter > 10
            chunkCounter = 1;
        end
        
        % Exit now if user has requested stop
        if stopped == 1
            break
        end
        
        waveformArray = read(twaveformdata, waveformBytes10Blocks);
        updateUIBytesInPort(['Bytes in Port: ' num2str(twaveformdata.BytesAvailable)]);
        rawIndex = 1;
        
        global savesoundblock;        

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

            global amplifierTimestampsIndex;
            for frame = 1:framesPerBlock
                
                % Expect 4 bytes to be timestamp as int32
                [amplifierTimestamps(1, amplifierTimestampsIndex), rawIndex] = ...
                    int32ReadFromArray(waveformArray, rawIndex);
                amplifierTimestamps(1, amplifierTimestampsIndex) = timestep * amplifierTimestamps(1, amplifierTimestampsIndex);
                
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
                end
                amplifierTimestampsIndex = amplifierTimestampsIndex + 1;
            end
        end

        
        
        % DO PROCESSING   
        % global lastplayedsound;
        % ts= pi/2*((lastplayedsound==0)+(lastplayedsound==3))+pi*(lastplayedsound==1);
        tg=randi(180)*pi/180;              

        
        % For every 10 chunks, recalculate the minimum and maximum time
        % values that will be plotted (and should be used both during spike
        % and waveform plotting)
        if chunkCounter == 1
            minAxis = amplifierTimestamps(1,1);
            maxAxis = minAxis + 100 * framesPerBlock * timestep;
        end
        
        % Scale these 10 data blocks
        amplifierData = 0.195 * (amplifierData - 32768);
        
        % Plot
        % Amp channels
        figure(ampDataFigure);
        
        % Plot each channel
        for thisPlot = 1:numAmpChannels
            subplot(numAmpChannels, 2, 2*thisPlot-1);
            % For every 10 chunks, plot with hold 'off' to clear the
            % previous plot. In all other cases, plot with hold 'on' to add
            % each 10 data-block chunk to the previous chunks
            if chunkCounter ~= 1
                hold on
            end
            plot(amplifierTimestamps, amplifierData(thisPlot, :), 'Color', 'blue');
            hold off
            latestPlottedWaveformTimestamp = amplifierTimestamps(end); 

            if thisPlot == 1
                title(['Channel A-' num2str(StartChannel, '%03d')])
            else
                title(['Channel A-' num2str(StartChannel+1, '%03d')])
            end
            %axis([minAxis maxAxis -400 400]);

        end
    
        % subplot(numAmpChannels,2,2*numAmpChannels+1)
        %     if chunkCounter ~= 1
        %         hold on
        %     end
        %     plot(amplifierTimestamps, savesoundblock(1:length(amplifierTimestamps)), 'Color', 'blue');
        %     hold off
        %     latestPlottedWaveformTimestamp = amplifierTimestamps(end); 
        % 
        %     title("Sound signal played?");
        %     axis([minAxis maxAxis -0.1 3.1]);
        
        savedata=[savedata amplifierData];
        savetime=[savetime amplifierTimestamps];
        savesound=[savesound savesoundblock];

        % subplot(numAmpChannels+1,2,[2 4])
        % disp_arrows;
        
        % Reset timestamp index
        amplifierTimestampsIndex = 1;   
        savesoundblock=zeros(1,blocksPerRead*framesPerBlock);
    end
end

end

% When 'stop' is clicked - stop realtime streaming
function stop
global stopped
global tspikedata
global twaveformdata

global savedata
global savetime
global savesound
global SoundSel

updateUIStatus('Stopped');
sendCommand('set runmode stop');
stopped = 1;
read(tspikedata);
read(twaveformdata);

if(SoundSel==1)
    WhatSound="BFsine_";
elseif(SoundSel==2)
    WhatSound="BFwhite_";
elseif(SoundSel==3)
    WhatSound="PlainWhite_";
elseif(SoundSel==4)
    WhatSound="HomoAnti_";
end

% Selections: 1-Blackman filtered sine, 2-Blackman filtered gaussian
% 3-Plain gaussian 4-Homophasic-Antiphasic,

savefname=strcat("Private/",WhatSound,string(datetime('now',format='MM-dd_HHmmSS')),".mat");
save(savefname,"savetime","savedata","savesound");
%savedata=[];
%savetime=[];
%savesound=[];
end

% Iterate through SpikesToPlot to populate t and delayedT with spikes that
% should be plotted. If a spike should be plotted immediately, it is
% added to t. If a spike's plotting should be delayed to synchronize with
% waveform plotting, it is added to delayedT.
function [t, delayedT] = prepareSpikes(thisPlot, numSpikes, SpikesToPlot, minTimestamp, maxTimestamp, delayedT, latestPlottedWaveformTimestamp)
t = [];
% For every spike, determine if it belongs in t (same time range as
% waveform plot), or delayedT (future time range - wait for waveform plot
% to catch up)


for spikeToPlotIndex = 1:numSpikes
    thisSpikeToPlot = SpikesToPlot(spikeToPlotIndex);
    if strcmp(thisSpikeToPlot.Name, 'A-000') && thisPlot ~= 1
        continue;
    elseif strcmp(thisSpikeToPlot.Name, 'A-001') && thisPlot ~= 2
        continue;
    end
    
    if thisSpikeToPlot.Timestamp >= minTimestamp && thisSpikeToPlot.Timestamp <= maxTimestamp
        if thisSpikeToPlot.Timestamp <= latestPlottedWaveformTimestamp
            t(length(t) + 1) = thisSpikeToPlot.Timestamp;
        else
            delayedT(length(delayedT) + 1) = thisSpikeToPlot.Timestamp;
        end
    elseif thisSpikeToPlot.Timestamp > maxTimestamp
        delayedT(length(delayedT) + 1) = thisSpikeToPlot.Timestamp;
    end
end
end

% Iterate through all spikes in t and plot each immediately
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

% Iterate through all spikes in delayedT. If the current waveform position
% has passed the spike, then it is lost for good. If the current waveform
% position range includes the spike, then it is plotted. If the current
% waveform position still hasn't reached the spike, then it stays in
% delayedT
function delayedT = plotDelayedSpikes(delayedT, minAxis, maxAxis)
hold on
y1 = -350;
y2 = -250;
deleteIndices = [];
for spikeIndex = 1:length(delayedT)
    tSpike = delayedT(spikeIndex);
    if tSpike < minAxis
        % lost for good - mark this spike for deletion
        fprintf(1, 'LOST SPIKE\n');
        deleteIndices(length(deleteIndices) + 1) = spikeIndex;
    elseif tSpike > maxAxis
        % delayed and still waiting for waveform to catch up - do nothing
    else
        % valid to plot - plot and mark this spike for deletion
        line([tSpike tSpike], [y1 y2], 'Color', 'red', 'LineWidth', 2);
        deleteIndices(length(deleteIndices) + 1) = spikeIndex;
    end
end
hold off
% Delete all entries in delayedT that have been marked for deletion
for index = length(deleteIndices):-1:1
    delayedT(deleteIndices(index)) = [];
end
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

% Send the given command over the TCP command socket
function sendCommand(command)
global tcommand
write(tcommand, uint8(command));
end

% Read the result of a command over the TCP command socket
function command = readCommand()
global tcommand
tic;
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
global gameFigure
global initialized
global currentPlotBand
global SoundSel
global soundTypeDir
% Add the UI components
hs = addUIComponents();
% Make figure visible after adding components
hs.fig.Visible = 'on';
% Initialize ampDataFigure to 0 to be changed when actually created
ampDataFigure = 0;
gameFigure = 0;
initialized = 0;
currentPlotBand = 'Wide';
SoundSel = 3;
soundTypeDir = "Silence";
end

% Populate the UI with the components it needs
function hs = addUIComponents()
global SoundSel
% Add components, save handles in a struct
hs.mainUI = uifigure('Name', 'RHX Stream GUI',...
    'Position', [50, 50, 470, 164]);
hs.statusText = uilabel(hs.mainUI,...
    'Text', 'Stopped',...
    'Position', [10, 45, 250, 22]);
hs.bytesInPort = uilabel(hs.mainUI,...
    'Text', 'Bytes in Port: ',...
    'Position', [10, 25, 250, 22]);
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

% hs.bandButtonGroup = uibuttongroup(hs.mainUI,...
%     'Position', [150, 114, 80, 40]); % [150, 72, 80, 82]);
% hs.wideButton = uiradiobutton(hs.bandButtonGroup,...
%     'Text', 'Wide',...
%     'Position', [10, 5, 100, 22],... %[10, 55, 100, 22],...
%     'Value', 1);
% hs.lowButton = uiradiobutton(hs.bandButtonGroup,...
%     'Text', 'Low',...
%     'Position', [10, 30, 100, 22],...
%     'Value', 0);
% hs.highButton = uiradiobutton(hs.bandButtonGroup,...
%     'Text', 'High',...
%     'Position', [10, 5, 100, 22],...
%     'Value', 0);
% set(hs.bandButtonGroup, 'SelectionChangedFcn', @bandButtonChanged);

% Add "Play Sound" button
hs.playSoundButton = uibutton(hs.mainUI,...
    'Text', 'Play Sound',...
    'Position', [350, 102, 100, 22],... % [10, 4, 100, 22],...
    'ButtonPushedFcn', @(btn,event) playSoundCallback());

% Add Sound Options
hs.soundPickGroup = uibuttongroup(hs.mainUI,...
    'Position', [150, 102, 190, 52]);% [250, 102, 190, 52]);
% hs.blackmanSineButton = uiradiobutton(hs.soundPickGroup,...
%     'Text', 'Blackman Filtered Sine',...
%     'Position', [10, 77, 200, 22],...
%     'Value', 1);
% hs.blackmanGaussButton = uiradiobutton(hs.soundPickGroup,...
%     'Text', 'Blackman Filtered Gaussian',...
%     'Position', [10, 52, 200, 22],...
%     'Value', 0);
hs.plainGaussButton = uiradiobutton(hs.soundPickGroup,...
    'Text', 'Plain Gaussian',...
    'Position', [10, 27, 200, 22],...
    'Value', 1);
hs.haPhasicButton = uiradiobutton(hs.soundPickGroup,...
    'Text', 'Homophasic-Antiphasic',...
    'Position', [10, 2, 200, 22],...
    'Value', 0);
set(hs.soundPickGroup, 'SelectionChangedFcn', @soundButtonChanged);

% Add "Loop Sound" button
hs.LoopSoundButton = uibutton(hs.mainUI,...
    'Text', 'Loop sound',...
    'Position', [170, 74, 250, 22],... % [200, 4, 250, 22],...
    'ButtonPushedFcn', @(btn,event) LoopSoundCallback());

% Add "Calibrate" button
hs.CalibrateButton = uibutton(hs.mainUI,...
    'Text', 'Calibrate',...
    'Position', [350, 131, 100, 22],...
    'ButtonPushedFcn', @(btn,event) CalibrateAudio());

% Add text indicating sound & direction
hs.soundPlaying = uilabel(hs.mainUI,...
    'Text', 'Playing: ',...
    'Position', [150, 25, 250, 25],...
    'FontSize', 18);
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

function playSoundCallback()
    global SoundSel;
    global soundTypeDir;
    global ampDataFigure;
    global gameFigure;
    
    %WhatSound=PlaySoundSel(SoundSel); % Old fn, uses normal sound fn
    WhatSound=PSS_AP(SoundSel);        % Uses the new audio playback thingy
    updateUISoundPlaying(['Playing: ' num2str(soundTypeDir)]);
    global amplifierTimestampsIndex;
    global savesoundblock;
    savesoundblock(1,amplifierTimestampsIndex)=WhatSound;
    
    % global lastplayedsound;
    % lastplayedsound= WhatSound;
    global ts
    ts= pi/2*((WhatSound==0)+(WhatSound==3))+pi*(WhatSound==1);
    tg=-pi/2;
    figure(ampDataFigure);
    subplot(2,2,[2 4])
    disp_arrows;
    
    figure(gameFigure);
    % defaultScene();
    swiperIn(WhatSound);
    global checkWS
    checkWS = WhatSound;
    figure(ampDataFigure);

    global action_timer
    start(action_timer);
end

function soundButtonChanged(source, event)
global SoundSel;
soundText = event.NewValue.Text;

if strcmp(soundText, 'Blackman Filtered Sine')
    SoundSel = 1;
elseif strcmp(soundText, 'Blackman Filtered Gaussian')
    SoundSel = 2;
elseif strcmp(soundText, 'Plain Gaussian')
    SoundSel = 3;
else
    SoundSel = 4;
end
end

function LoopSoundCallback()
    global csound
    csound.Period = 3;
    start(csound);
end

function UpdateAngle()
    % REAL TIME EEG DEMO STUFF GOES HERE
    Trt = 1; Fs=5000;
    Nrt = Fs*Trt;

    global ampDataFigure;
    global gameFigure;
    
    global savedata
    curr_block = savedata(:,end-Nrt:end);
    
    alphaBand = [8 12]; 
    betaBand = [13 20];

    alphaPower = [bandpower(curr_block(1,:), Fs, alphaBand); bandpower(curr_block(2,:), Fs, alphaBand)];
    betaPower  = [bandpower(curr_block(1,:), Fs, betaBand); bandpower(curr_block(2,:), Fs, betaBand)];
   
    global Ball    
    prob = mnrval(Ball, [alphaPower; betaPower]');
    disp(prob);
    
    confsound = 1-prob(1);

    if(prob(2)>prob(3))
        dirsound=1;
    else
        dirsound=-1;
    end
        
    %tg=randi(180)*pi/180;
    tg = pi/2*(1+confsound*dirsound);

    global ts
    figure(ampDataFigure);
    subplot(2,2,[2 4]);
    disp_arrows;

    figure(gameFigure);
    brainGuess(tg);
    % global tom_timer; start(tom_timer);
    global guess_timer; global checkWS;
    guess_timer.TimerFcn = @(src,event) swiperOut(checkWS, tg);
    start(guess_timer);

    figure(ampDataFigure);
end

% Update soundPlaying with last played sound
function updateUISoundPlaying(newSound)
    global hs
    set(hs.soundPlaying, 'Text', newSound);
    drawnow;
end

function CalibrateAudio()
    % Get baseline for current user
    global Ball
    global savedata
    global savesound
    
    % Set snipping parameters
    Tsnip=1; after=1;
    
    % Take data measured so far, filter and save. 
    Fs = 5000; N = Fs*Tsnip; t = 0:1/Fs:Tsnip;
    lsave = length(savedata(1,:)); 
    %disp(lsave);

    idx_filt=int32(50/Fs*lsave); % Sets the freq after which you want to set to 0. 
    data_f = [fft(savedata(1,:)); fft(savedata(2,:))]; data_f(:,idx_filt:end-idx_filt)=0;
    data_filt = real([ifft(data_f(1,:)); ifft(data_f(2,:))]);
    % data_filt = savedata(:,:);
        
    discard_sf=1000;
      
    idx_sound = find(savesound); L=length(idx_sound);                
    %disp(idx_sound);
    %snippets_labels = zeros(L,1); snippets_issound = zeros(L,1);
    
    dcount=0; lcounter=1; rcounter=1; scounter=1;
    
    % Split out snippets
    for ii=1:L
        for jj=1:2
            temp(:,jj)=data_filt(jj,idx_sound(ii)-round(N*(1-after),0):idx_sound(ii)+round(N*after,0));        
        end
        
        if(sum(sum(temp.^2))>5e9)
            disp(sum(sum(temp.^2)));
            continue;
        end
        dcount=dcount+1;
        snippets_d(dcount,:,:)   =temp;
        snippets_labels(dcount)  =savesound(idx_sound(ii));
        snippets_issound(dcount) =(savesound(idx_sound(ii))~=3);
    
        if(savesound(idx_sound(ii))==1)
            snippets_l(lcounter,:,:)=snippets_d(dcount,:,:);
            lcounter=lcounter+1;
        elseif(savesound(idx_sound(ii))==2)
            snippets_r(rcounter,:,:)=snippets_d(dcount,:,:);
            rcounter=rcounter+1;
        elseif(savesound(idx_sound(ii))==3)
            snippets_s(scounter,:,:)=snippets_d(dcount,:,:);
            scounter=scounter+1;
        end
    end   
    lcount=lcounter-1; rcount=rcounter-1; scount=scounter-1;
    disp([dcount lcount rcount scount]);
    
    seconds = size(snippets_d,1);
    alphaBand = [8 12]; 
    betaBand = [13 20];
    alphaPower = zeros(seconds, 2); %two channels
    betaPower = zeros(seconds, 2);
    
    for ii = 1:seconds
        for jj=1:2
        % Calculate alpha power for each channel
        alphaPower(ii, jj) = bandpower(snippets_d(ii,:,jj), Fs, alphaBand);
        betaPower(ii, jj) = bandpower(snippets_d(ii,:,jj), Fs, betaBand);    
        end
    end
        
    features = [alphaPower, betaPower];
    
    % INSERT TRAINING CODE
    disp(size(features));
    disp(size(snippets_labels));
    [Ball_new,dev,stat] = mnrfit(features, snippets_labels');
    
    
    % OUTCOME: IT SHOULD SET / OVERWRITE BALL
    disp(Ball);
    Ball = Ball_new;
    disp(Ball);
end

% GAME FUNCTIONS BELOW
function swiperIn(sound)
% Move Swiper onscreen
% Currently he only teleports in, can hopefully modify to slide in
% sound: double of value 1 (left), 2 (right), or 3 (silence)

global swiper;  global swiperImg;   % global variables

% Swiper start position: (-1)^(sound-1) will flip image if sound=2
swiperImg.XData = swiper.imgX*(-1)^(sound-1) + swiper.def(sound,1);
swiperImg.YData = swiper.imgY + swiper.def(sound,2);

% swiper sliding in happens here

% Swiper end position
swiperImg.XData = swiper.imgX*(-1)^(sound-1) + swiper.ctr(sound,1);
swiperImg.YData = swiper.imgY + swiper.ctr(sound,2);
end

function brainGuess(guess)
% brain makes a guess
% guess: [rad] tg from RealtimeProcessing UpdateAngle()

% global variables
global sBrainImg;   global pBrainImg;   global uTomImg;
global sBrain;      global pBrain;      global uTom;
global qArrow;

% checking which side
gVal = (guess<pi/2) + 1;  % right = 2, left = 1 (for flipping image)

% unsettled tom time
uTomImg.XData = uTom.imgX*(-1)^(gVal-1) + uTom.ctr(gVal,1);
uTomImg.YData = uTom.imgY + uTom.ctr(gVal,2);
uTomImg.AlphaData = 1;  % solidifying tom just in case

% move straight brain offscreen
sBrainImg.XData = sBrain.imgX + sBrain.def(gVal,1);
sBrainImg.YData = sBrain.imgY + sBrain.def(gVal,2);

% move brain profile onscreen
pBrainImg.XData = pBrain.imgX*(-1)^(gVal-1) + pBrain.ctr(gVal,1);
pBrainImg.YData = pBrain.imgY + pBrain.ctr(gVal,2);

% add arrow
% [ADD CODE FOR ARROWS]
qArrow = quiver(400*cos(guess)+2000, 1500-400*sin(guess), 500*cos(guess), -500*sin(guess), LineWidth=2);
end


function swiperOut(sound, guess)
% Move Swiper offscreen
% Calls functions depending on guess correctness
% sound: [rad] of value pi (left), 0 (right), or pi/2 (silence)
% guess: [rad] between (0,pi)

% global variables
global swiper;  global swiperImg; global pSwiper; global pSwiperImg;
global swin_timer; global sloss_timer;
global qArrow;

% checking which side guessed
% sVal = (sound<pi/2) + (sound==3*pi/2) + 1; % right = 2, left = 1, silence = 3
gVal = (guess<pi/2) + 1;  % right = 2, left = 1

transparenTom();    % remove tom by changing opacity to 0

sloss_timer.TimerFcn = @(src, event) swiperLoses(sound);
swin_timer.TimerFcn = @(src, event) swiperWins(sound);
swin_timer.StopFcn = @(src, event) defaultScene();
sloss_timer.StopFcn = @(src, event) defaultScene();
% compare guess with actual, initialize swiper, call win/loss functions
if(gVal == sound)
    % polish jerry that swiper
    swiperImg.XData = swiper.imgX + swiper.def(sound,1);
    swiperImg.YData = swiper.imgY + swiper.def(sound,2);
    pSwiperImg.XData = pSwiper.imgX*(-1)^(sound-1) + pSwiper.ctr(sound,1);
    pSwiperImg.YData = pSwiper.imgY + pSwiper.ctr(sound,2);
    start(sloss_timer);
    % swiperLoses(sVal);
else
    swiperImg.XData = swiper.imgX*(-1)^(sound) + swiper.ctr(sound,1);
    swiperImg.YData = swiper.imgY + swiper.ctr(sound,2);
    start(swin_timer);
    % swiperWins(sVal);  % also called when silence
end
% [ADD CODE TO REMOVE ARROWS]
delete(qArrow);
end


function swiperWins(sound)
% Moves swiper offscreen - he currently teleports out
% Swiper turns around before leaving
% sound: double of value 1 (left), 2 (right), or 3 (silence)

% global variables
global swiper;  global swiperImg;   %global swiper_timer;

% % Swiper start position
% swiperImg.XData = swiper.imgX*(-1)^(sound) + swiper.ctr(sound,1);
% swiperImg.YData = swiper.imgY + swiper.ctr(sound,2);


% swiper sliding out happens here


% Swiper end position
swiperImg.XData = swiper.imgX + swiper.def(sound,1);
swiperImg.YData = swiper.imgY + swiper.def(sound,2);
end


function swiperLoses(sound)
% Swaps swiper out for polish jerry version
% Moves swiper offscreen - he currently teleports out
% sound: double of value 1 (left) or 2 (right)

% global variables
global swiper;  global swiperImg;
global pSwiper; global pSwiperImg;

% % removes normal swiper
% swiperImg.XData = swiper.imgX + swiper.def(sound,1);
% swiperImg.YData = swiper.imgY + swiper.def(sound,2);
% 
% % replace with polish jerry swiper - starting position
% pSwiperImg.XData = pSwiper.imgX*(-1)^(sound-1) + pSwiper.ctr(sound,1);
% pSwiperImg.YData = pSwiper.imgY + pSwiper.ctr(sound,2);

% swiper sliding out happens here

% Polish Swiper ending position
pSwiperImg.XData = pSwiper.imgX*(-1)^(sound-1) + pSwiper.def(sound,1);
pSwiperImg.YData = pSwiper.imgY + pSwiper.def(sound,2);
end


function defaultScene()
% default scene with straight brain in center, others offscreen

% global variables
global swiper;  global swiperImg;   global sBrain;  global sBrainImg;
global pBrain;  global pBrainImg;   global uTom;    global uTomImg;
global pSwiper; global pSwiperImg;

% straight brain in center
sBrainImg.XData = sBrain.imgX + sBrain.ctr(1,1);
sBrainImg.YData = sBrain.imgY + sBrain.ctr(1,2);

% everyone else default (offscreen)
swiperImg.XData = swiper.imgX + swiper.def(1,1);
swiperImg.YData = swiper.imgY + swiper.def(1,2);

pBrainImg.XData = pBrain.imgX + pBrain.def(1,1);
pBrainImg.YData = pBrain.imgY + pBrain.def(1,2);

uTomImg.XData = uTom.imgX + uTom.def(1,1);
uTomImg.YData = uTom.imgY + uTom.def(1,2);

pSwiperImg.XData = pSwiper.imgX + pSwiper.def(1,1);
pSwiperImg.YData = pSwiper.imgY + pSwiper.def(1,2);
end

function transparenTom()
global uTomImg;
uTomImg.AlphaData = 0;
end