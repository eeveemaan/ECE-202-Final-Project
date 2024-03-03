Fs = 44100;
dt = 1/Fs;
f  = 500;

T=0:dt:0.218;
pad=0.2*Fs;
t=0:dt:0.018;

So =    (1*sin(2*pi*f*t)).*blackman(length(t))';
Spi = -((1*sin(2*pi*f*t)).*blackman(length(t))');

%So = [So zeros(1,pad)];
%Spi = [Spi zeros(1,pad)];

% subplot(2,1,1);
% plot(T,So);
% subplot(2,1,2);
% plot(T,Spi);

ii = randi(2);
y = zeros(length(T),2);
y(1:length(t),ii)=So;
y(1:length(t),3-ii)=Spi;

sound(y,Fs);

if(ii==1)
    disp("left");
else
    disp("right");
end