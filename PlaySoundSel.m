function WhatSound = PlaySoundSel(sel)

Fs = 44100;
T = 0.018; dt = 1/Fs; t =0:dt:T;
pad =0.2*Fs;
y = zeros(length(t)+pad,2);

ITD = 4e-4;
ILD = 1;

ii = randi(2);

f  = 500;
So =    (1*sin(2*pi*f*t)).*blackman(length(t))';
Spi = -((1*sin(2*pi*f*t)).*blackman(length(t))');


% Selections: 1-Blackman filtered sine, 2-Blackman filtered gaussian
% 3-Plain gaussian 4-Homophasic-Antiphasic,

if(sel==1)
    y(1:length(t),ii) = 0.1*sin(2*pi*500*t)'.*blackman(length(t)); 
    delta = round(ITD*Fs,0);
    y(1+delta:length(t),3-ii)=y(1:length(t)-delta,ii);
elseif(sel==2)
    y(1:length(t),ii) = 0.1*randn(length(t),1).*blackman(length(t)); 
    delta = round(ITD*Fs,0);
    y(1+delta:length(t),3-ii)=y(1:length(t)-delta,ii);
elseif(sel==3)
    y(1:length(t),ii) = 0.1*randn(length(t),1); 
    delta = round(ITD*Fs,0);
    y(1+delta:length(t),3-ii)=y(1:length(t)-delta,ii);
else    
    % -1: Homo, 1: Anti
    if(ii==1)
        y(1:length(t),2)=So;
    else
        y(1:length(t),2)=Spi;
    end
end
sound(y,Fs)


if(ii==1)
    disp("left/homo");
    WhatSound=-1;
else
    disp("right/anti");
    WhatSound=+1;
end
end