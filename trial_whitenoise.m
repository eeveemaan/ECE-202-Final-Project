Fs = 44100;
T = 0.018; dt = 1/Fs; t =0:dt:T;
pad =0.2*Fs;
y = zeros(length(t)+pad,2);

ii = randi(2);
y(1:length(t),ii) = 0.1*randn(length(t),1).*blackman(length(t)); % comment out the blackman part for unfiltered trial. 

ITD = 4e-4;
ILD = 1;
delta = round(ITD*Fs,0);

y(1+delta:length(t),3-ii)=y(1:length(t)-delta,ii);
sound(y,Fs)

if(ii==1)
    disp("left");
else
    disp("right");
end