clear; close all;
% NOTE: need to modify to initialize all images once only (var/func/script)
% also a lot of the code is repeated/can probably be dumped into func if time permits

% this script is designed to rely on WhatSound and tg from RealTimeProcessing
% currently they aren't used and values are hardcoded in line 31 below

% EXTREMELY IMPORTANT: this script uses pause(); unfortunately, that stops
% all MATLAB scripts. looking for a workaround

%% Initialize variables

% which sound played
global WhatSound;   % (1=left, 2=right, 3=silence) from RealTimeProcessing
% guessing sound direction
global tg;  % from RealTimeProcessing - UpdateAngle()


global LastSound;   % sound previously played


% NOTE: ADD EXCLAMATION PT in same manner as disp arrow (at angle)
% NOTE: ^arrow for guess & use transparency of tom to imply confidence

% Misc
global dt;  % [s] timestep
dt = 0.01;

% Scene window size
LxI = 4000;     % [px] display window width
LyI = 2000;     % [px] display window height
xSwiper = 500;  % [px] swiper distance from window edge

%% Temporary variable assignment testing
WhatSound = 2;
LastSound = WhatSound;
tg = 3*pi/4;

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
% actually straightbrain is the only one onscreen
sBrainImg = image(sBrain.imgX + sBrain.ctr(1,1), sBrain.imgY + sBrain.ctr(1,2), sBrain.pic);
sBrainImg.AlphaData = sBrain.alpha;     % sets transparency

pBrainImg = image(pBrain.imgX - 800, pBrain.imgY - 800, pBrain.pic);
pBrainImg.AlphaData = pBrain.alpha;

swiperImg = image(swiper.imgX - 800, swiper.imgY - 800, swiper.pic);
swiperImg.AlphaData = swiper.alpha;

uTomImg = image(uTom.imgX - 800, uTom.imgY - 800, uTom.pic);

pSwiperImg = image(pSwiper.imgX - 800, pSwiper.imgY - 800, pSwiper.pic);%.*(pSwiper.alpha/255));
pSwiperImg.AlphaData = pSwiper.alpha;

%% Game Test

% if sound played, swiper appears
swiperIn(WhatSound);
pause(0.5);

% brain notices and predicts
brainGuess(tg);
pause(1);

% swiper leaves
% if guess correctly, swiper turns into polish jerry and backs off
% if guess wrong, swiper turns around before leaving
swiperOut(WhatSound, tg)
pause(0.5);

% return to default
defaultScene();

%% Quick Note
% 'XData' and 'YData' are the image x and y limits
% to change the position of the image, do:
% imgObj.XData = imgStruct.imgX + (desired img position center x coord)
% and same for YData

%% Functions

function swiperIn(sound)
% Move Swiper onscreen
% Currently he only teleports in, can hopefully modify to slide in
% sound: double of value 1 (left), 2 (right), or 3 (silence)
% pauseT: [s] time to move swiper offscreen

global swiper;  global swiperImg;   % global variables

% Swiper start position: (-1)^(sound-1) will flip image if sound=2
swiperImg.XData = swiper.imgX*(-1)^(sound-1) + swiper.def(sound,1);
swiperImg.YData = swiper.imgY + swiper.def(sound,2);

% swiper sliding in happens here

% Swiper end position
swiperImg.XData = swiper.imgX*(-1)^(sound-1) + swiper.ctr(sound,1);
swiperImg.YData = swiper.imgY + swiper.ctr(sound,2);
end


function brainGuess(guess)
% brain makes a guess
% guess: [rad] tg from RealtimeProcessing UpdateAngle()

% global variables
global sBrainImg;   global pBrainImg;   global uTomImg;
global sBrain;      global pBrain;      global uTom;
global dt;
global q;

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

% reduce tom's transparency - consider mapping it to abs(pi/2 - tg)
for i=1:100  % run a for loop for 1s
    uTomImg.AlphaData = uTomImg.AlphaData - 1/100;
end

% add arrow
% [ADD CODE FOR ARROW]
q = quiver(400*cos(guess)+2000, 1500-400*sin(guess), 500*cos(guess), -500*sin(guess), LineWidth=2);
end


function swiperOut(sound, guess)
% Move Swiper offscreen
% Calls functions depending on guess correctness
% sound: double of value 1 (left), 2 (right), or 3 (silence)
% guess: [rad] between (0,pi)

global q;
% checking which side guessed
gVal = (guess<pi/2) + 1;  % right = 2, left = 1

% compare guess with actual
if(gVal == sound)
    swiperLoses(sound);
else
    swiperWins(sound);  % also called when silence
end

% [ADD CODE TO REMOVE ARROWS]
delete(q)
end


function swiperWins(sound)
% Moves swiper offscreen - he currently teleports out
% Swiper turns around before leaving
% sound: double of value 1 (left), 2 (right), or 3 (silence)

global swiper;  global swiperImg;   % global variables

% Swiper start position
swiperImg.XData = swiper.imgX*(-1)^(sound) + swiper.ctr(sound,1);
swiperImg.YData = swiper.imgY + swiper.ctr(sound,2);

% swiper sliding out happens here

% Swiper end position
swiperImg.XData = swiper.imgX + swiper.def(sound,1);
swiperImg.YData = swiper.imgY + swiper.def(sound,2);
end


function swiperLoses(sound)
% Swaps swiper out for polish jerry version
% Moves swiper offscreen - he currently teleports out
% sound: double of value 1 (left) or 2 (right)

% global variables
global swiper;  global swiperImg;
global pSwiper; global pSwiperImg;

% removes normal swiper
swiperImg.XData = swiper.imgX + swiper.def(sound,1);
swiperImg.YData = swiper.imgY + swiper.def(sound,2);

% polish jerry that swiper - starting position
pSwiperImg.XData = pSwiper.imgX*(-1)^(sound-1) + pSwiper.ctr(sound,1);
pSwiperImg.YData = pSwiper.imgY + pSwiper.ctr(sound,2);

% swiper sliding out happens here

% Polish Swiper ending position
pSwiperImg.XData = pSwiper.imgX*(-1)^(sound-1) + pSwiper.def(sound,1);
pSwiperImg.YData = pSwiper.imgY + pSwiper.def(sound,2);
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