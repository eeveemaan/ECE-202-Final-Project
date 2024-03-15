# ECE_202_Final_Project

**Trial_X.m:** plays an audio (X) of random type and displays the type. Useful for guessing. Packaged into PlaySoundSel(sel). <br/>

**PlaySoundSel.m:** Sel= 1-Blackman filtered sine, 2-Blackman filtered gaussian. Line 38 initializes to 2. Can be changed via terminal. 
3-Plain gaussian, 4-Homophasic-Antiphasic. Returns 1 or -1 depending on type played. <br/>

**disp_arrows.m:** Displays arrows around a head. Needs to be rewritten to take inputs based on the audio we played and the guess based on user EEG. <br/>

**RealtimeOld/:** Contains all older versions of the real-time read file. 
- Realtime_Save.m: saves incoming waveform
- Realtime_SS.m: Plays sound (integration of Sashank's and Rommani's code)
- Realtime_SStimeaxis: plots the sound status in addition to the incoming waveform data. plots -1 or 1 when sound played depending on "WhatSound" returned by PlaySoundSel(sel). 
- **CURRENT VERSION: Realtime_SSTCS.m**. Implements channel selection on top of  SStimeaxis. TO BE TESTED. 

Recordings are saved as a .mat file. Exact format was fixed in SStimeaxis and later. "Demo MM-DD_hhmmss.mat". Files contain 3 variables: savetime (common time axis), savedata (EEG waveforms) and savesound(points where sound is played). Savedata typically has 2 channels; set by NumAmpChannels. StartChannel in SSTCS sets which channels we want to record. <br/>

For quickly reading, one can use **viewrecording.m** after double clicking and selecting MAT file to load of choice. Can improve this by using uigetfile but too lazy rn. <br/>

## Outline of RHXStreamRealtime_SSTCS.m
In essense, the program is an infinite loop that records data in the configuration it is initialized in. When you press buttons, the actions corresponding to the buttons are played. Buttons are Run, Stop and Sound. 
- Run: Receives a block of data from the loop in real-time. This is where the modifications for saving were made. Real-time processing will also go here. 
    - First time Run is called, the system is initialized. Initialization = using TCP, getting RHX's settings and telling RHX what data it should send?

Running through the code once line by line, 
- 000-058: Initialization of misc global variables
- 059-063: We specify # channels recorded, and the first channel position via NumAmpChannels and StartChannel. Eg for NAC=2, SC=13, channels 13 and 14 are recorded and plotted. 
- 064-120: Initialization via TCP
- 121-169: Initializing a bunch of variables for recording in real-time. I initialized the variables for saving data here. 
- 171-384: The "infinite" loop that runs as long as the button state is "run". 
    - 172-225: Gets spike data via TCP from RHX. 
    - 225-252: Plots spike data
    - 253-326: Reads frames and block of real-time data as they arrive
    - 328-334: Resets time axis once enough data arrives
    - 336-363: Plots the data that came from the channels. I increased the number of subplots to include a sound channel. We can do real-time processing right before plotting, include as many subplots as we want and plot whatever we want. 
    - 365-383: Plot sound state (left/homo=-1, right/anti=1, no sound=0). 
- 388-410: The Stop state. The data left in the buffer is read, displayed and read is stopped. I save the data each time stop is pressed, reset variables and make it such that we start a new session when we press run again. 

Rest of the code is just misc stuff. Changes we've made:
- 589-593: Inclusion of sound button and attaching playsoundcallback to it. 
- 651-660: PlaySoundCallback: Plays a sound using playsoundsel, records sound playing to the savesoundblock variable.

## TO DO
In slicerecording.m:
- Variables
    - Tsnip: time window/snippets of epoch
    - D: downsampling frequency
- Loading files in "Feb 28" folder
    - savesound: records sound type as integer values at specific time index (0: none, 1:left, 2:right, 3:silence)
        - Want to analyze 0 & 3 to get a baseline (of sound not being played) 
    - Want to experiment with Tsnip and D to create a table of values for frequencies/results
        - Goal is to be able to compare the results and pick the best parameters/conditions for analysis
- Minor things
    - Make code more flexible
        - Easily adjust time window of epoch (%% Split out snippets block)
            - Amount of time before/after sound played
            - Will also need to adjust window of subsequent plot
