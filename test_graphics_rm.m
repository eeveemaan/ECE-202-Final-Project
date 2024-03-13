clear
dt=0.1;
x = 0:dt:500;
y = 3;
% plot(x, y); hold on

%i want my image to move in this way
fname = 'brain.png';   
[inpict,~,alpha] = imread(fname); 
inpict = flipud(inpict); % necessary to keep image upright
alpha = flipud(alpha);
imgsize = [0.7 0.8]; % [x y] in plot coordinates

% get current coordinates for the image 
xx = [-0.5, 0.5]*imgsize(1) + x(1);
yy = [-0.5, 0.5]*imgsize(2) + y(1);
hi = image(xx,yy,inpict);
hi.AlphaData = alpha; % set alpha

% enforce axes extents
axis equal
x = 0:dt:500;
y = sin(x);
plot(x, y); hold on

%i want my image to move in this way
fname = 'brain.png';   
[inpict,~,alpha] = imread(fname); 
inpict = flipud(inpict); % necessary to keep image upright
alpha = flipud(alpha);
imgsize = [0.7 0.8]; % [x y] in plot coordinates

% get current coordinates for the image 
xx = [-0.5, 0.5]*imgsize(1) + x(1);
yy = [-0.5, 0.5]*imgsize(2) + y(1);
hi = image(xx,yy,inpict);
hi.AlphaData = alpha; % set alpha

% enforce axes extents
axis equal
xlim([0 2*pi] + [-0.5 0.5]*imgsize(1))
ylim([-1 1] + [-0.5 0.5].*imgsize(2))

for k= 1:numel(x)
    hi.XData = [-0.5 0.5]*imgsize(1) + x(k);
    hi.YData = [-0.5 0.5]*imgsize(2) + y(k);
    % wait
    pause(dt)	
end

for k= 1:numel(x)
    hi.XData = xlim - [-0.5 0.5]*imgsize(1) + x(k);
    hi.YData = ylim - [-0.5 0.5]*imgsize(1) + x(k);
    % wait
    pause(dt)	
end