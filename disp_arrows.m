% Define parameters
hr = 6;
hor = 6.2;
sr = 15;

sar = 4;
gar = 4;

th = 0:pi/20:2*pi;

ts = pi/6;
tg = -pi/6;

figure(pos=[0 1000 600 600]); axis equal; hold on;
plot(hr * cos(th),hr * sin(th),LineWidth=2);

x = sr*cos(ts); y = sr*sin(ts);
u = sar * cos(pi+ts); % convert polar (theta,r) to cartesian
v = sar * sin(pi+ts);
quiver(x,y,u,v,LineWidth=2);

x = hor*cos(tg); y = hor*sin(tg);
u = sar * cos(tg); % convert polar (theta,r) to cartesian
v = sar * sin(tg);
quiver(x,y,u,v,LineWidth=2);

xlim([-15 15]);
ylim([-15 15]);
ax = gca; ax.LineWidth = 2; ax.FontName = 'Arial'; ax.FontSize = 12;
title("Guessing game: Where is the sound coming from?",FontSize = 16)
ylabel("Front and back",FontSize=14)
xlabel("Left and right",FontSize=14)
