%% Initialize global variables
global Ifull;   % displaying scene
global side;     % guess for which side brain turns

% global variables prevent having to redefine values (otherwise will need
% to pass in as argument
% NOTE: ADD EXCLAMATION PT in same manner as disp arrow (at angle)
% NOTE: ^arrow for guess & use transparency of tom to imply confidence

%% Loading in Images
% Read swiper image
swiper = imread('swiper.png');
[Lx_swiper, Ly_swiper, ~] = size(swiper);

% Read brain images
brainprofile = imread('brain.png');
brainprofile = brainprofile(1:2:end,1:2:end,:);   % downsampling
L=length(brainprofile);

brainstraight = imread('brain_straight.png');
brainstraight = brainstraight(1:4:end, 1:4:end, :); % downsampling
[Lx_straightbrain, Ly_straightbrain, ~] = size(brainstraight);

% Read unsettled tom
utom = imread('unsettled_tom.jpg');
[Lx_tom, Ly_tom, ~] = size(utom);

% Read polish swiper
pswiper = imread('swiper_jerry.png');
pswiper = pswiper(1:2:end,1:2:end,:); % downsampling
[Lx_ps, Ly_ps, ~] = size(pswiper);

%% Setting up Scenes
LxI = 3000; % 3*Ly_swiper
LyI = 1500; % 2*Lx_swiper
scene_bg = zeros(LyI,LxI,3, "uint8");     % initialize scene to black bg

% Default: straight brain in center
scene_default = scene_bg;
refpts_bstr = [(LyI - Lx_straightbrain), (LyI-1); (LxI/2-Ly_straightbrain/2), (LxI/2+Ly_straightbrain/2-1)];
scene_default(refpts_bstr(1,1):refpts_bstr(1,2), refpts_bstr(2,1):refpts_bstr(2,2),:) = brainstraight;

% Sound played (LEFT): swiper
scene_swiper = scene_bg;
refpts_swiper = [(LyI - Lx_swiper), (LyI-1); 1, Ly_swiper]; % (LxI-Ly_swiper), (LxI-1)];
% scene_swiper(refpts_bstr(1,1):refpts_bstr(1,2), refpts_bstr(2,1):refpts_bstr(2,2),:) = brainstraight;
scene_swiper(refpts_swiper(1,1):refpts_swiper(1,2), refpts_swiper(2,1):refpts_swiper(2,2),:) = swiper;

% Sound guess scene (LEFT): brain profile
scene_guess = scene_bg;
refpts_guess = [(LyI - L), (LyI-1); (LxI/2-L/2), (LxI/2+L/2-1)];
scene_guess(refpts_guess(1,1):refpts_guess(1,2), refpts_guess(2,1):refpts_guess(2,2), :) = brainprofile;

% Unsettled Tom Brain (LEFT)
scene_utom = scene_bg;
refpts_utom = [(LyI - Lx_tom), (LyI-1); (LxI/2-Ly_tom/2), (LxI/2+Ly_tom/2-1)];
scene_utom(refpts_utom(1,1):refpts_utom(1,2), refpts_utom(2,1):refpts_utom(2,2), :) = utom/2;

% Polish Swiper
scene_pswiper = scene_bg;
refpts_pswiper = [(LyI - Lx_ps), (LyI-1); 1, Ly_ps];
scene_pswiper(refpts_pswiper(1,1):refpts_pswiper(1,2), refpts_pswiper(2,1):refpts_pswiper(2,2), :) = pswiper;

%% Test Function: run basic images w/ 1 sec delay
Ifull = scene_bg;   imshow(Ifull);  % sets up black background and displays

% WITHIN 3 SECS
% if sound played, add swiper
% if guess, flash unsettled tom, swap to brain profile, add error
% if right, swap swiper out for pswiper

t_default = timer;  t_default.StartDelay = 1;
t_swiper = timer;   t_swiper.StartDelay = 1;
t_notice = timer;   t_notice.StartDelay = 1;
t_pswiper = timer;  t_pswiper.StartDelay = 1;

% start w/ brain straight
t_default.TimerFcn = @(src, event) dispScene(scene_default);

% add swiper
t_default.StopFcn = @(src, event) start(t_swiper);
t_swiper.TimerFcn = @(src, event) dispScene(scene_swiper);

% flash unsettled tom and change to brain profile
t_swiper.StopFcn = @(src, event) start(t_notice);
t_notice.TimerFcn = @(src, event) dispScene(scene_utom);

% polish swiper
t_notice.StopFcn = @(src, event) start(t_pswiper);
t_pswiper.TimerFcn = @(src, event) dispScene(scene_pswiper);

% reset
t_pswiper.StopFcn = @(src, event) dispScene(scene_pswiper);

% %% Set off the timer chain
% start(t_default);
% 
% %% Timers, Functions, n Stuff
% ustom_timer = timer;
% ustom_timer.StartDelay=0.3;
% ustom_timer.TimerFcn=@(src, event) updatefigure();
% %ustom_timer.StopFcn=@(src, event) jerryanimation();
% 
% % Initialize polish jerry swiper creature thingy
% global pjerry
% pjerry = imread('swiper_jerry.png');
% pjerry = pjerry(1:2:end,1:2:end,:); % downsampling
% [Lxj, Lyj, ~] = size(pjerry);
% 
% 
% global pjerry_timer
% pjerry_timer = timer;
% pjerry_timer.StartDelay=0.3;
% pjerry_timer.TimerFcn=@(src, event) jerryanimation();
% 
% global restore_timer;
% restore_timer = timer;
% restore_timer.StartDelay=0.3;
% restore_timer.TimerFcn=@(src, event) restorefigure();
% 
% global side     % left=1, right=2
% %side=2;
% % global Ifull;
% % Ifull = zeros(2*Lx,3*Ly,3);
% 
% if(side==1)
%     i_x = 1100;
%     i_y = 50;
%     Ifull(i_x:i_x+Lx_swiper-1,i_y:i_y+Ly_swiper-1,:)=swiper/244;
% else    
%     i_x = 1100;
%     i_y = 1500;
%     Ifull(i_x:i_x+Lx_swiper-1,i_y:i_y+Ly_swiper-1,:)=flipdim(swiper,2)/244;
% end
% 
% i_x = 1000;
% i_y = 750;
% 
% if(side==1)
%     Ifull(i_x:i_x+L-1,i_y:i_y+L-1,:)=brainprofile/244;
%     i_x = 1000;
%     i_y = 650;
%     Ioldtom=Ifull(i_x:i_x+Lx_tom-1,i_y:i_y+Ly_tom-1,:);
%     Ifull(i_x:i_x+Lx_tom-1,i_y:i_y+Ly_tom-1,:)=utom/254;
% else
%     Ifull(i_x:i_x+L-1,i_y:i_y+L-1,:)=flipdim(brainprofile,2)/244;
%     i_x = 1000;
%     i_y = 650;
%     Ioldtom=Ifull(i_x:i_x+Lx_tom-1,i_y:i_y+Ly_tom-1,:);
%     Ifull(i_x:i_x+Lx_tom-1,i_y:i_y+Ly_tom-1,:)=flipdim(utom,2)/254;    
% end
% 
% %Ifull(i_x:i_x+Lxt-1,i_y:i_y+Lyt-1,:)=utom/254;
% 
% imshow(Ifull); ax=gcf; ax.Position=[0 0 1000 1000];
% %updatefigure;
% Ifull(i_x:i_x+Lx_tom-1,i_y:i_y+Ly_tom-1,:)=Ioldtom;
% 
% start(ustom_timer);

%% Functions
function dispScene(imgS)
    global Ifull;
    Ifull = imgS;
    disp('called');
    imshow(Ifull);
end

function updatefigure()
    global Ifull;
    global pjerry_timer
    imshow(Ifull);   
    ax=gcf; ax.Position=[0 0 1000 1000];
    start(pjerry_timer);
end

function jerryanimation()
    global side
    global pjerry
    global Ifull

    [Lxj, Lyj, ~] = size(pjerry);
    disp("Function Reached");
    % IF GUESS IS CORRECT SIDE, THEN PLAY THIS
    if(side==1)
        i_x = 1050;
        i_y = 50;
        Ioldswiper=Ifull(i_x:i_x+Lxj-1,i_y:i_y+Lyj-1,:);
        Ifull(i_x:i_x+Lxj-1,i_y:i_y+Lyj-1,:)=pjerry/244;
    else    
        i_x = 1050;
        i_y = 1240;
        Ioldswiper=Ifull(i_x:i_x+Lxj-1,i_y:i_y+Lyj-1,:);
        Ifull(i_x:i_x+Lxj-1,i_y:i_y+Lyj-1,:)=flipdim(pjerry,2)/244;    
    end
    
    imshow(Ifull); ax=gcf; ax.Position=[0 0 1000 1000];
    Ifull(i_x:i_x+Lxj-1,i_y:i_y+Lyj-1,:)=Ioldswiper;

    global restore_timer
    start(restore_timer);
end

function restorefigure()
    global Ifull;
    global pjerry_timer
    imshow(Ifull);   
    ax=gcf; ax.Position=[0 0 1000 1000];    
end