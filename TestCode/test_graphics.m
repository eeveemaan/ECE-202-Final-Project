% Read swiper image
swiper = imread('swiper.png');
[Lx, Ly, ~] = size(swiper);

% Read brain images
brain = imread('brain.png');
brain = brain(1:2:end,1:2:end,:);
L=length(brain);

% Initialize unsettled tom
utom = imread('unsettled_tom.jpg');
[Lxt, Lyt, ~] = size(utom);

ustom_timer = timer;
ustom_timer.StartDelay=0.3;
ustom_timer.TimerFcn=@(src, event) updatefigure();
%ustom_timer.StopFcn=@(src, event) jerryanimation();

% Initialize polish jerry swiper creature thingy
global pjerry
pjerry = imread('swiper_jerry.png');
pjerry = pjerry(1:2:end,1:end,:);
[Lxj, Lyj, ~] = size(pjerry);


global pjerry_timer
pjerry_timer = timer;
pjerry_timer.StartDelay=0.3;
pjerry_timer.TimerFcn=@(src, event) jerryanimation();

global restore_timer;
restore_timer = timer;
restore_timer.StartDelay=0.3oooiii;
restore_timer.TimerFcn=@(src, event) restorefigure();

global side
%side=2;
global Ifull;
Ifull = zeros(2*Lx,3*Ly,3);

if(side==1)
    i_x = 1100;
    i_y = 50;
    Ifull(i_x:i_x+Lx-1,i_y:i_y+Ly-1,:)=swiper/244;
else    
    i_x = 1100;
    i_y = 1500;
    Ifull(i_x:i_x+Lx-1,i_y:i_y+Ly-1,:)=flipdim(swiper,2)/244;
end
          
i_x = 1000;
i_y = 750;

if(side==1)
    Ifull(i_x:i_x+L-1,i_y:i_y+L-1,:)=brain/244;
    i_x = 1000;
    i_y = 650;
    Ioldtom=Ifull(i_x:i_x+Lxt-1,i_y:i_y+Lyt-1,:);
    Ifull(i_x:i_x+Lxt-1,i_y:i_y+Lyt-1,:)=utom/254;
else
    Ifull(i_x:i_x+L-1,i_y:i_y+L-1,:)=flipdim(brain,2)/244;
    i_x = 1000;
    i_y = 650;
    Ioldtom=Ifull(i_x:i_x+Lxt-1,i_y:i_y+Lyt-1,:);
    Ifull(i_x:i_x+Lxt-1,i_y:i_y+Lyt-1,:)=flipdim(utom,2)/254;    
end

%Ifull(i_x:i_x+Lxt-1,i_y:i_y+Lyt-1,:)=utom/254;

imshow(Ifull); ax=gcf; ax.Position=[0 0 1000 1000];
%updatefigure;
Ifull(i_x:i_x+Lxt-1,i_y:i_y+Lyt-1,:)=Ioldtom;

start(ustom_timer);

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