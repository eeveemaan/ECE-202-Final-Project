clear; close all;
% NOTE: need to modify to initialize all images once only (var/func/script)
% also a lot of the code is repeated/can probably be dumped into func if time permits

% this script is designed to rely on WhatSound and tg from RealTimeProcessing
% currently they aren't used and values are hardcoded in line 31 below

%% Initialize variables

% which sound played
global WhatSound;   % (1=left, 2=right, 3=silence) from RealTimeProcessing
% guessing sound direction
global tg;  % from RealTimeProcessing - UpdateAngle()


global LastSound;   % sound previously played
global side;    % guess for which side brain turns

% NOTE: ADD EXCLAMATION PT in same manner as disp arrow (at angle)
% NOTE: ^arrow for guess & use transparency of tom to imply confidence

% Misc
global dt;  % [s] timestep
dt = 0.01;

% Scene window size
LxI = 4000; % 3*Ly_swiper
LyI = 2000; % 2*Lx_swiper
xSwiper = 500;  % swiper distance from screen edge

%% Temporary variable assignment testing
WhatSound = 2;
LastSound = WhatSound;
tg = pi/4;

%% Loading in Images

% Global variables
global swiper;      global pBrain;      global sBrain;
global uTom;    global pSwiper;

% Read swiper image
[swiper.pic, ~, swiper.alpha] = imread('swiper.png');
[y,x,~] = size(swiper.pic);
resz = 1;   % resizing image

% set image x and y limits (based on resz)
swiper.imgX = [-resz resz]*x; swiper.imgY = [-resz resz]*y;

% image onscreen center coords left (1,:), right (2,:), and silence (3,:)
swiper.ctr = [xSwiper, LyI-500; LxI-xSwiper, LyI-500; -800, -800];

% image offscreen default coords left (1,:), right (2,:), and silence (3,:)
swiper.def = [-x, LyI-500; LxI+x, LyI-500; -800, -800];


% Read brain images
[pBrain.pic, ~, pBrain.alpha] = imread('brain.png');
[y,x,~] = size(pBrain.pic);
resz = 0.25;
pBrain.imgX = [-resz resz]*x; pBrain.imgY = [-resz resz]*y;
pBrain.ctr = [LxI/2, LyI-500; LxI/2, LyI-500];
pBrain.def = [-x, LyI-500; LxI+x, LyI-500];

[sBrain.pic, ~, sBrain.alpha] = imread('brain_straight.png');
[y,x,~] = size(sBrain.pic);
resz = 0.1;
sBrain.imgX = [-resz resz]*x; sBrain.imgY = [-resz resz]*y;
sBrain.ctr = [LxI/2, LyI-500; LxI/2, LyI-500];
sBrain.def = [-x, LyI-500; LxI+x, LyI-500];

% Read unsettled tom
[uTom.pic, ~, uTom.alpha] = imread('unsettled_tom.jpg');
[y,x,~] = size(uTom.pic);
resz = 0.5;
uTom.imgX = [-resz resz]*x; uTom.imgY = [-resz resz]*y;
uTom.ctr = [LxI/2, LyI-500; LxI/2, LyI-500];
uTom.def = [-x, LyI-500; LxI+x, LyI-500];

% Read polish swiper
[pSwiper.pic, ~, pSwiper.alpha] = imread('swiper_jerry.png');
[y,x,~] = size(pSwiper.pic);
resz = 0.5;
pSwiper.imgX = [-resz resz]*x; pSwiper.imgY = [-resz resz]*y;
pSwiper.ctr = [xSwiper, LyI-500; LxI-xSwiper, LyI-500];
pSwiper.def = [-x, LyI-500; LxI+x, LyI-500];


%% Setting up scene

% initialize background for scene
scene_bg = zeros(LyI,LxI,3, "uint8");
imshow(scene_bg); hold on;

% Global image variables
global sBrainImg;   global pBrainImg;   global swiperImg;
global uTomImg;     global pSwiperImg;

% initialize images (all offscreen lol)
% NOTE: order of image creation matters; they will layer on top of each other
sBrainImg = image(sBrain.imgX + sBrain.ctr(1,1), sBrain.imgY + sBrain.ctr(1,2), sBrain.pic);
sBrainImg.AlphaData = sBrain.alpha;

pBrainImg = image(pBrain.imgX - 800, pBrain.imgY - 800, pBrain.pic);
pBrainImg.AlphaData = pBrain.alpha;

swiperImg = image(swiper.imgX - 800, swiper.imgY - 800, swiper.pic);
swiperImg.AlphaData = swiper.alpha;

uTomImg = image(uTom.imgX - 800, uTom.imgY - 800, uTom.pic);

pSwiperImg = image(pSwiper.imgX - 800, pSwiper.imgY - 800, pSwiper.pic);%.*(pSwiper.alpha/255));
pSwiperImg.AlphaData = pSwiper.alpha;

%% Game Test

% if sound played, swiper appears
swiperIn(WhatSound);    % 0.2 s
pause(30*dt);   % 0.3 secs for brain to react

% brain notices and predicts
brainGuess(tg);

% swiper leaves
% if guess correctly, swiper turns into polish jerry and backs off
% if guess wrong, swiper turns around before leaving
swiperOut(LastSound, tg);   % 0.2 s

% return to default
defaultScene();

%% Functions

function swiperIn(sound)
% Move Swiper onscreen - takes 0.2s
% Currently he only teleports in, can hopefully modify to slide in
% sound: double of value 1 (left), 2 (right), or 3 (silence)

global swiper;  global swiperImg;   global dt;  % global variables

% Swiper start position: (-1)^(sound-1) will flip image if sound=2
swiperImg.XData = swiper.imgX*(-1)^(sound-1) + swiper.def(sound,1);
swiperImg.YData = swiper.imgY + swiper.def(sound,2);

pause(20*dt);   % pauses for 0.2s

% Swiper end position
swiperImg.XData = swiper.imgX*(-1)^(sound-1) + swiper.ctr(sound,1);
swiperImg.YData = swiper.imgY + swiper.ctr(sound,2);
end


function swiperOut(sound, guess)
% Move Swiper offscreen - takes 0.2s
% Currently teleports in, if changing swiperIn can easily modify this
% sound: double of value 1 (left), 2 (right), or 3 (silence)

% global variables
global swiper;  global swiperImg;   global dt;
global pSwiper; global pSwiperImg;

% Swiper start position
swiperImg.XData = swiper.imgX + swiper.ctr(sound,1);
swiperImg.YData = swiper.imgY + swiper.ctr(sound,2);

pause(20*dt);   % pauses for 0.2s

% Swiper end position
swiperImg.XData = swiper.imgX + swiper.def(sound,1);
swiperImg.YData = swiper.imgY + swiper.def(sound,2);

% [ADD CODE TO REMOVE ARROWS]
end


function brainGuess(guess)
% brain makes a guess
% guess: [rad] tg from RealtimeProcessing UpdateAngle()

% global variables
global sBrainImg;   global pBrainImg;   global uTomImg;
global sBrain;      global pBrain;      global uTom;
global dt;

% checking which side
gVal = (guess<pi/2) + 1;  % right = 2, left = 1 (for flipping image)

% unsettled tom time
uTomImg.XData = uTom.imgX*(-1)^(gVal-1) + uTom.ctr(gVal,1);
uTomImg.YData = uTom.imgY + uTom.ctr(gVal,2);
uTomImg.AlphaData = 1;  % solidifying tom just in case

% move straight brain offscreen
sBrainImg.XData = sBrain.imgX + sBrain.def(gVal,1);
sBrainImg.YData = sBrain.imgY + sBrain.def(gVal,2);

% move brain profile onscreen
pBrainImg.XData = pBrain.imgX*(-1)^(gVal-1) + pBrain.ctr(gVal,1);
pBrainImg.YData = pBrain.imgY + pBrain.ctr(gVal,2);

% reduce tom's transparency - consider mapping it to 
for i=1:100  % run a for loop for 1s
    uTomImg.AlphaData = uTomImg.AlphaData - 1/100;
    pause(dt);
end

% add arrows
end

function defaultScene()
% default scene with straight brain in center, others offscreen

% global variables
global swiper;  global swiperImg;   global sBrain;  global sBrainImg;
global pBrain;  global pBrainImg;   global uTom;    global uTomImg;
global pSwiper; global pSwiperImg;

% straight brain in center
sBrainImg.XData = sBrain.imgX + sBrain.ctr(1,1);
sBrainImg.YData = sBrain.imgY + sBrain.ctr(1,2);

% everyone else default (offscreen)
swiperImg.XData = swiper.imgX + swiper.def(1,1);
swiperImg.YData = swiper.imgY + swiper.def(1,2);

pBrainImg.XData = pBrain.imgX + pBrain.def(1,1);
pBrainImg.YData = pBrain.imgY + pBrain.def(1,2);

uTomImg.XData = uTom.imgX + uTom.def(1,1);
uTomImg.YData = uTom.imgY + uTom.def(1,2);

pSwiperImg.XData = pSwiper.imgX + pSwiper.def(1,1);
pSwiperImg.YData = pSwiper.imgY + pSwiper.def(1,2);
end

%% Loading in Images
% % Read swiper image
% swiperA = imread('swiper.png');
% [Lx_swiper, Ly_swiper, ~] = size(swiperA);
% imgLimits(sS,:) = [1-ceil(Lx_swiper/2), floor(Lx_swiper/2), 1-ceil(Ly_swiper/2), floor(Ly_swiper/2)];
% 
% % Read brain images
% brainprofileA = imread('brain.png');
% brainprofileA = brainprofileA(1:2:end,1:2:end,:);   % downsampling
% L=length(brainprofileA);
% imgLimits(pB,:) = [1-ceil(L/2), floor(L/2), 1-ceil(L/2), floor(L/2)];
% 
% brainstraightA = imread('brain_straight.png');
% brainstraightA = brainstraightA(1:4:end, 1:4:end, :); % downsampling
% [Lx_straightbrain, Ly_straightbrain, ~] = size(brainstraightA);
% imgLimits(sB,:) = [1-ceil(Lx_straightbrain/2), floor(Lx_straightbrain/2), 1-ceil(Ly_straightbrain/2), floor(Ly_straightbrain/2)];
% 
% % Read unsettled tom
% utomA = imread('unsettled_tom.jpg');
% [Lx_tom, Ly_tom, ~] = size(utomA);
% imgLimits(uT,:) = [1-ceil(Lx_tom/2), floor(Lx_tom/2), 1-ceil(Ly_tom/2), floor(Ly_tom/2)];
% 
% % Read polish swiper
% pswiperA = imread('swiper_jerry.png');
% pswiperA = pswiperA(1:2:end,1:2:end,:); % downsampling
% [Lx_ps, Ly_ps, ~] = size(pswiperA);
% imgLimits(pS,:) = [1-ceil(Lx_ps/2), floor(Lx_ps/2), 1-ceil(Ly_ps/2), floor(Ly_ps/2)];

%% Setting up Scenes
% scene_bg = zeros(LyI,LxI,3, "uint8");     % initialize scene to black bg
% 
% % Default: straight brain in center
% scene_default = scene_bg;
% refpts_bstr = [(LyI - Lx_straightbrain), (LyI-1); (LxI/2-Ly_straightbrain/2), (LxI/2+Ly_straightbrain/2-1)];
% scene_default(refpts_bstr(1,1):refpts_bstr(1,2), refpts_bstr(2,1):refpts_bstr(2,2),:) = brainstraightA;
% 
% % Sound played (LEFT): swiper
% scene_swiper = scene_bg;
% refpts_swiper = [(LyI - Lx_swiper), (LyI-1); 1, Ly_swiper]; % (LxI-Ly_swiper), (LxI-1)];
% % scene_swiper(refpts_bstr(1,1):refpts_bstr(1,2), refpts_bstr(2,1):refpts_bstr(2,2),:) = brainstraight;
% scene_swiper(refpts_swiper(1,1):refpts_swiper(1,2), refpts_swiper(2,1):refpts_swiper(2,2),:) = swiperA;
% 
% % Sound guess scene (LEFT): brain profile
% scene_guess = scene_bg;
% refpts_guess = [(LyI - L), (LyI-1); (LxI/2-L/2), (LxI/2+L/2-1)];
% scene_guess(refpts_guess(1,1):refpts_guess(1,2), refpts_guess(2,1):refpts_guess(2,2), :) = brainprofileA;
% 
% % Unsettled Tom Brain (LEFT)
% scene_utom = scene_bg;
% refpts_utom = [(LyI - Lx_tom), (LyI-1); (LxI/2-Ly_tom/2), (LxI/2+Ly_tom/2-1)];
% scene_utom(refpts_utom(1,1):refpts_utom(1,2), refpts_utom(2,1):refpts_utom(2,2), :) = utomA/2;
% 
% % Polish Swiper
% scene_pswiper = scene_bg;
% refpts_pswiper = [(LyI - Lx_ps), (LyI-1); 1, Ly_ps];
% scene_pswiper(refpts_pswiper(1,1):refpts_pswiper(1,2), refpts_pswiper(2,1):refpts_pswiper(2,2), :) = pswiperA;

%% Storage

% clear
% dt=0.05;
% x = 0:dt:2*pi;
% y = 3;
% % plot(x, y); hold on
% 
% %i want my image to move in this way
% fname = 'brain.png';   
% [inpict,~,alpha] = imread(fname); 
% inpict = flipud(inpict); % necessary to keep image upright
% alpha = flipud(alpha);
% imgsize = [0.7 0.8]; % [x y] in plot coordinates
% 
% % get current coordinates for the image 
% xx = [-0.5, 0.5]*imgsize(1) + x(1);
% yy = [-0.5, 0.5]*imgsize(2) + y(1);
% hi = image(xx,yy,inpict);
% hi.AlphaData = alpha; % set alpha
% 
% % enforce axes extents
% axis equal
% x = 0:dt:2*pi;
% y = sin(x);
% plot(x, y); hold on
% 
% x2 = flip(x);
% %i want my image to move in this way
% fname = 'brain.png';   
% [inpict,~,alpha] = imread(fname); 
% inpict = flipud(inpict); % necessary to keep image upright
% alpha = flipud(alpha);
% imgsize = [0.7 0.8]; % [x y] in plot coordinates
% 
% % get current coordinates for the image 
% xx = [-0.5, 0.5]*imgsize(1) + x(1);
% yy = [-0.5, 0.5]*imgsize(2) + y(1);
% hi = image(xx,yy,inpict);
% hi.AlphaData = alpha; % set alpha
% 
% % enforce axes extents
% axis equal
% xlim([0 2*pi] + [-0.5 0.5]*imgsize(1))
% ylim([-1 1] + [-0.5 0.5].*imgsize(2))
% 
% for k= 1:numel(x)
%     hi.XData = [-0.5 0.5]*imgsize(1) + x(k);
%     hi.YData = [-0.5 0.5]*imgsize(2) + y(k);
%     % wait
%     pause(dt)	
% end
% 
% for k= 1:numel(x)
%     hi.XData = [-0.5 0.5]*imgsize(1) + x2(k);
%     hi.YData = [-0.5 0.5]*imgsize(2) + y(k);
%     % wait
%     pause(dt)	
% end