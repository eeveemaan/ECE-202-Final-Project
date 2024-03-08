% Define parameters
hr = 6; hor = 6.2;
sr = 15; sar = 4; gar = 4;

th = 0:pi/20:2*pi;

%ts = 0*pi/6; tg = 0*pi/6;
%ts=randi(180)*pi/180;tg=randi(180)*pi/180;

%figure(pos=[0 1000 600 350]); axis equal; hold on;

plot(hr * cos(th),hr * sin(th),LineWidth=2);
axis equal; hold on;
x = sr*cos(ts); y = sr*sin(ts);
u = sar * cos(pi+ts); % convert polar (theta,r) to cartesian
v = sar * sin(pi+ts);
quiver(x,y,u,v,LineWidth=2);

x = hor*cos(tg); y = hor*sin(tg);
u = sar * cos(tg); % convert polar (theta,r) to cartesian
v = sar * sin(tg);
quiver(x,y,u,v,LineWidth=2);

xlim([-15 15]);
ylim([-0.5 15]);
ax = gca; ax.LineWidth = 2; ax.FontName = 'Arial'; ax.FontSize = 12;
title("Where is the sound coming from?",FontSize = 14)
ylabel("Front and back",FontSize=14)
xlabel("Left and right",FontSize=14)

hold off;