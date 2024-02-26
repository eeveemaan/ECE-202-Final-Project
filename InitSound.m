global y_bfs
global y_bfw
global y_w
global y_homo
global y_anti

Fsound = 44100;
T = 0.018; dt = 1/Fsound; t =0:dt:T;
pad =0.2*Fsound;

y_bfs = zeros(length(t)+pad,2);
y_bfw = zeros(length(t)+pad,2);
y_w = zeros(length(t)+pad,2);
y_homo = zeros(length(t)+pad,2);
y_anti = zeros(length(t)+pad,2);

ITD = 4e-4; delta = round(ITD*Fsound,0);
ILD = 1;

f  = 500;
So =    (1*sin(2*pi*f*t)).*blackman(length(t))';
Spi = -((1*sin(2*pi*f*t)).*blackman(length(t))');

% Selections: 1-Blackman filtered sine, 2-Blackman filtered gaussian
% 3-Plain gaussian 4-Homophasic-Antiphasic,

y_bfs(1:length(t),1) = 0.1*sin(2*pi*500*t)'.*blackman(length(t)); 
y_bfs(1+delta:length(t),2)=y_bfs(1:length(t)-delta,1);

y_bfw(1:length(t),1) = 0.1*randn(length(t),1).*blackman(length(t)); 
y_bfw(1+delta:length(t),2)=y_bfw(1:length(t)-delta,1);

y_w(1:length(t),1) = 0.1*randn(length(t),1); 
y_w(1+delta:length(t),2)=y_w(1:length(t)-delta,1);

% -1: Homo, 1: Anti
y_homo(1:length(t),:)=[So; So]';
y_anti(1:length(t),:)=[So; Spi]';

clear("delta","dt","T","ILD","ITD","pad","t","So","Spi");