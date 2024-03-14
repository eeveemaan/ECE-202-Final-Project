function gameWindowSetup()
% Global variables for game images
global swiper;  global swiperImg;   global sBrain;  global sBrainImg;
global pBrain;  global pBrainImg;   global uTom;    global uTomImg;
global pSwiper; global pSwiperImg;

% Scene window size
LxI = 4000;     % [px] display window width
LyI = 2000;     % [px] display window height
xSwiper = 500;  % [px] swiper distance from window edge

%% Read in Images
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

end