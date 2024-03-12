I = imread('swiper.png');
brain = imread('brain.png');
brain = brain(1:2:end,1:2:end,:);

utom = imread('unsettled_tom.jpg');
[Lxt, Lyt, ~] = size(utom);

[Lx, Ly, ~] = size(I);
L=length(brain);

%side=2;
global Ifull;
Ifull = zeros(2*Lx,3*Ly,3);

if(side==1)
    i_x = 1100;
    i_y = 50;
    Ifull(i_x:i_x+Lx-1,i_y:i_y+Ly-1,:)=I/244;
else    
    i_x = 1100;
    i_y = 1500;
    Ifull(i_x:i_x+Lx-1,i_y:i_y+Ly-1,:)=flipdim(I,2)/244;
end
          
i_x = 1000;
i_y = 750;

if(side==1)
    Ifull(i_x:i_x+L-1,i_y:i_y+L-1,:)=brain/244;
    i_x = 1000;
    i_y = 650;
    Iold=Ifull(i_x:i_x+Lxt-1,i_y:i_y+Lyt-1,:);
    Ifull(i_x:i_x+Lxt-1,i_y:i_y+Lyt-1,:)=utom/254;
else
    Ifull(i_x:i_x+L-1,i_y:i_y+L-1,:)=flipdim(brain,2)/244;
    i_x = 1000;
    i_y = 650;
    Iold=Ifull(i_x:i_x+Lxt-1,i_y:i_y+Lyt-1,:);
    Ifull(i_x:i_x+Lxt-1,i_y:i_y+Lyt-1,:)=flipdim(utom,2)/254;    
end

%Ifull(i_x:i_x+Lxt-1,i_y:i_y+Lyt-1,:)=utom/254;

imshow(Ifull)
Ifull(i_x:i_x+Lxt-1,i_y:i_y+Lyt-1,:)=Iold;

ustom_timer = timer;
ustom_timer.StartDelay=0.1;
ustom_timer.TimerFcn=@(src, event) updatefigure();

start(ustom_timer);

function updatefigure()
    global Ifull;
    imshow(Ifull);
end