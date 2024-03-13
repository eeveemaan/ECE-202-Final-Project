clear
dt=0.05;
x = -5:dt:5;
y = 3;
% plot(x, y); hold on

%i want my image to move in this way
fname = 'brain_straight.png';   
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
x = -5:dt:5;
y = sin(x);
plot(1,1); hold on
set(gca,'Color','k')

x2 = flip(x);
%i want my image to move in this way
fname = 'brain_glow.png';   
[inpict,~,alpha] = imread(fname); 
inpict = flipud(inpict); % necessary to keep image upright
alpha = flipud(alpha);
imgsize = [1.8 1.7]; % [x y] in plot coordinates
% get current coordinates for the image 
xx = [-0.5, 0.5]*imgsize(1) + x(1);
yy = [-0.5, 0.5]*imgsize(2) + y(1);
hi = image(xx,yy,inpict);
hi.AlphaData = alpha; % set alpha

%i want my image to move in this way
fname1 = 'swiper.png';   
[inpict1,~,alpha1] = imread(fname1); 
inpict1 = flipud(inpict1); % necessary to keep image upright
alpha1 = flipud(alpha1);
imgsize1 = [1.8 1.7]; % [x y] in plot coordinates

% get current coordinates for the image 
xx1 = [-0.5, 0.5]*imgsize1(1) + x(1);
yy1 = [-0.5, 0.5]*imgsize(2) + y(1);
hi1 = image(xx1,yy1,inpict1);
hi1.AlphaData = alpha1; % set alpha

% enforce axes extents
axis equal
xlim([-5 5])
ylim([-4 4])
tic
for k= 1:numel(x)
    y_c = rand(1) ;
    x_c = rand(1) ; 
    hi.XData = [-0.5 0.5]*imgsize(1) + x_c;
    hi1.XData = [-0.5 0.5]*imgsize1(1) + x(k) -2 ;
    hi.YData = [-0.5 0.5]*imgsize(2) + y_c;
    hi1.YData = [-0.5 0.5]*imgsize1(2) + y(k);
    % wait
    pause(dt)	
end
toc 
for k= 1:numel(x)
    y_c = rand(1);
    x_c = rand(1);
    hi.XData = [-0.5 0.5]*imgsize(1) + x_c;
    hi.YData = [-0.5 0.5]*imgsize(2) + y_c;
    % wait
    pause(dt)	
end