# ECE_202_Final_Project

**Trial_X.m:** plays an audio (X) of random type and displays the type. Useful for guessing. Packaged into PlaySoundSel(sel). <br/>

**PlaySoundSel.m:** Sel= 1-Blackman filtered sine, 2-Blackman filtered gaussian
3-Plain gaussian, 4-Homophasic-Antiphasic. Returns 1 or -1 depending on type played. <br/>

**disp_arrows.m:** Displays arrows around a head. Needs to be rewritten to take inputs based on the audio we played and the guess based on user EEG. <br/>

**RealtimeOld/:** Contains all older versions of the real-time read file. 
- Realtime_Save.m: saves incoming waveform
- Realtime_SS.m: Plays sound (integration of Sashank's and Rommani's code)
- Realtime_SStimeaxis: plots the sound status in addition to the incoming waveform data. plots -1 or 1 when sound played depending on "WhatSound" returned by PlaySoundSel(sel). 
- **CURRENT VERSION: Realtime_SSTCS.m**. Implements channel selection on top of  SStimeaxis. TO BE TESTED. 

Recordings are saved as a .mat file. Exact format was fixed in SStimeaxis and later. "Demo MM-DD_hhmmss.mat". Files contain 3 variables: savetime (common time axis), savedata (EEG waveforms) and savesound(points where sound is played). Savedata typically has 2 channels; set by NumAmpChannels. StartChannel in SSTCS sets which channels we want to record. <br/>

For quickly reading, one can use **viewrecording.m** after double clicking and selecting MAT file to load of choice. Can improve this by using uigetfile but too lazy rn. <br/>